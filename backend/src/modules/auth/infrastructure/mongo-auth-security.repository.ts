// Desenvolvido por Guilherme Henrique Moreira
import { createHash } from "node:crypto";
import type { Db } from "mongodb";
import type { AuthSecurityRepository, AuthUser } from "../domain/auth.types.js";
import { AuthError } from "../../../shared/auth-error.js";
import { transaction } from "../../../shared/transaction.js";
import { ObjectId } from "mongodb";
import { MongoAuthUserRepository } from "./mongo-auth.repository.js";

export class MongoAuthSecurityRepository implements AuthSecurityRepository {
  constructor(private readonly database: Db) {}
  private key(identity: string): string { return createHash("sha256").update(identity).digest("hex"); }

  async assertLoginAllowed(identity: string): Promise<void> {
    const entry = await this.database.collection("auth_login_limits").findOne({ key: this.key(identity) });
    if (entry?.lockedUntil > new Date()) throw new AuthError(429, "account_locked", "Muitas tentativas. Aguarde 30 segundos e tente novamente.");
  }

  async recordLoginFailure(identity: string): Promise<void> {
    const now = new Date();
    const collection = this.database.collection("auth_login_limits");
    const filter = { key: this.key(identity) };
    const update = [{ $set: {
      key: this.key(identity),
      failures: { $cond: [{ $lte: [{ $ifNull: ["$expiresAt", now] }, now] }, 1, { $add: [{ $ifNull: ["$failures", 0] }, 1] }] },
      expiresAt: new Date(now.getTime() + 30_000),
    } }, { $set: { lockedUntil: { $cond: [{ $gte: ["$failures", 5] }, new Date(now.getTime() + 30_000), now] } } }];
    try { await collection.updateOne(filter, update, { upsert: true }); }
    catch (error) {
      if (!error || typeof error !== "object" || !("code" in error) || error.code !== 11000) throw error;
      await collection.updateOne(filter, update);
    }
  }

  async clearLoginFailures(identity: string): Promise<void> {
    await this.database.collection("auth_login_limits").deleteOne({ key: this.key(identity) });
  }

  async saveSession(user: AuthUser, sessionId: string, expiresAt: Date): Promise<void> {
    await this.database.collection("auth_sessions").insertOne({ sessionId, userId: user.id,
      createdAt: new Date(), expiresAt, profile: user.profile });
    await this.database.collection("auth_users").updateOne({ _id: new ObjectId(user.id) }, { $set: { lastLogin: new Date() } });
  }

  async saveChallenge(user: AuthUser, tokenDigest: string, codeDigest: string, expiresAt: Date): Promise<void> {
    await this.database.collection("auth_challenges").insertOne({ tokenDigest, codeDigest, userId: user.id,
      identity: user.normalizedIdentity, version: user.sessionVersion ?? 0, attempts: 0, expiresAt });
  }

  async consumeChallenge(tokenDigest: string, codeDigest: string, now: Date): Promise<AuthUser | null> {
    const identity = await transaction(this.database, async (session) => {
      const challenges = this.database.collection("auth_challenges");
      const entry = await challenges.findOne({ tokenDigest, expiresAt: { $gt: now }, attempts: { $lt: 3 } }, { session });
      if (!entry) return null;
      if (entry.codeDigest !== codeDigest) {
        await challenges.updateOne({ _id: entry._id }, { $inc: { attempts: 1 } }, { session });
        return null;
      }
      const user = await this.database.collection("auth_users").findOne({ _id: new ObjectId(entry.userId), active: true }, { session });
      await challenges.deleteOne({ _id: entry._id }, { session });
      return user && (user.sessionVersion ?? 0) === entry.version ? user.normalizedIdentity as string : null;
    });
    return identity ? new MongoAuthUserRepository(this.database).findByIdentity(identity) : null;
  }
}
