// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import {
  MongoClient,
  ObjectId,
  type Collection,
  type Db,
  type Document,
} from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";
import { transaction } from "../../../shared/transaction.js";
import type {
  AuthProfile,
  AuthUser,
  AuthUserRepository,
  RecoveryCode,
  RecoveryCodeRepository,
} from "../domain/auth.types.js";
import { authProfiles } from "../domain/auth.types.js";

interface UserDocument extends Document {
  identity: string;
  normalizedIdentity: string;
  email: string;
  displayName: string;
  profile: AuthProfile;
  passwordHash: string;
  active: boolean;
}

interface RecoveryDocument extends Document {
  normalizedIdentity: string;
  codeDigest: string | null;
  failedAttempts: number;
  expiresAt: Date;
  resetTokenDigest?: string;
  verified?: boolean;
}

/** Abre a conexão e garante o índice TTL da coleção de recuperação. */
export class MongoAuthDatabase {
  private readonly client: MongoClient;
  private database?: Db;

  constructor(uri: string, private readonly databaseName: string) {
    this.client = new MongoClient(uri, { serverSelectionTimeoutMS: 5_000 });
  }

  async connect(): Promise<void> {
    await this.client.connect();
    this.database = this.client.db(this.databaseName);
    await this.database.collection("auth_recovery").createIndex({ normalizedIdentity: 1 }, { unique: true });
    await this.database.collection("auth_sessions").createIndex({ sessionId: 1 }, { unique: true });
    await this.database.collection("auth_sessions").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    await this.database.collection("auth_sessions").createIndex({ userId: 1 });
    await this.database.collection("auth_challenges").createIndex({ tokenDigest: 1 }, { unique: true });
    await this.database.collection("auth_challenges").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    await this.database.collection("auth_login_limits").createIndex({ key: 1 }, { unique: true });
    await this.database.collection("auth_login_limits").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    await this.database.collection("auth_users").createIndex({ email: 1 }, {
      unique: true, collation: { locale: "en", strength: 2 }, partialFilterExpression: { email: { $type: "string" } },
    });
    await this.database.collection<{ _id: string; revision: number }>("admin_write_guard")
      .updateOne({ _id: "admin" }, { $setOnInsert: { revision: 0 } }, { upsert: true });
    await this.database.collection("admin_audit_logs").createIndex({ createdAt: -1 });
    await this.database.collection("academic_protocols").createIndex({ code: 1 }, { unique: true });
    await this.database
      .collection<RecoveryDocument>("auth_recovery")
      .createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    await this.database
      .collection<UserDocument>("auth_users")
      .createIndex({ normalizedIdentity: 1 }, { unique: true });
    await this.database
      .collection("academic_courses")
      .createIndex({ code: 1 }, { unique: true });
    await this.database
      .collection("academic_classes")
      .createIndex({ code: 1 }, { unique: true });
    await this.database
      .collection("academic_enrollments")
      .createIndex({ classCode: 1, studentId: 1 }, { unique: true });
    await this.database
      .collection("academic_enrollments")
      .createIndex({ studentId: 1, status: 1 });
    await this.database
      .collection("academic_class_sessions")
      .createIndex({ classCode: 1, startsAt: 1 });
  }

  users(): MongoAuthUserRepository {
    return new MongoAuthUserRepository(this.getDatabase());
  }

  recoveryCodes(): MongoRecoveryCodeRepository {
    return new MongoRecoveryCodeRepository(this.getDatabase());
  }

  databaseForModules(): Db {
    return this.getDatabase();
  }

  async close(): Promise<void> {
    await this.client.close();
  }

  private getDatabase(): Db {
    if (!this.database) throw new Error("Banco de autenticação ainda não conectado.");
    return this.database;
  }
}

/** Adaptador MongoDB para identidades e credenciais institucionais. */
export class MongoAuthUserRepository implements AuthUserRepository {
  private readonly collection: Collection<UserDocument>;

  constructor(database: Db) {
    this.collection = database.collection<UserDocument>("auth_users");
  }

  async findByIdentity(identity: string): Promise<AuthUser | null> {
    const document = await this.collection.findOne({
      $or: [{ normalizedIdentity: identity.trim().toLowerCase() }, { email: identity.trim().toLowerCase() }],
    }, { collation: { locale: "en", strength: 2 } });
    if (!document || !authProfiles.includes(document.profile)) return null;

    return {
      id: document._id.toString(),
      identity: document.identity,
      normalizedIdentity: document.normalizedIdentity,
      email: document.email,
      displayName: document.displayName,
      profile: document.profile,
      passwordHash: document.passwordHash,
      active: document.active,
      sessionVersion: document.sessionVersion ?? 0,
      twoFactorRequired: document.twoFactorRequired === true,
    };
  }

  async updatePassword(userId: string, passwordHash: string): Promise<void> {
    if (!ObjectId.isValid(userId)) {
      throw new AuthError(500, "user_record_invalid", "Registro de usuário inválido.");
    }

    const result = await this.collection.updateOne(
      { _id: new ObjectId(userId) },
      { $set: { passwordHash, passwordUpdatedAt: new Date() } },
    );
    if (result.matchedCount !== 1) {
      throw new AuthError(404, "user_not_found", "Conta não encontrada.");
    }
  }
}

/** Adaptador MongoDB com atualizações atômicas para tentativas e grants de senha. */
export class MongoRecoveryCodeRepository implements RecoveryCodeRepository {
  private readonly collection: Collection<RecoveryDocument>;

  constructor(private readonly database: Db) {
    this.collection = database.collection<RecoveryDocument>("auth_recovery");
  }

  async save(recoveryCode: RecoveryCode): Promise<void> {
    const { normalizedIdentity, ...fields } = recoveryCode;
    await this.collection.replaceOne(
      { normalizedIdentity },
      { normalizedIdentity, ...fields },
      { upsert: true },
    );
  }

  async find(normalizedIdentity: string): Promise<RecoveryCode | null> {
    const document = await this.collection.findOne({ normalizedIdentity });
    if (!document) return null;

    return {
      normalizedIdentity: document.normalizedIdentity,
      codeDigest: document.codeDigest,
      failedAttempts: document.failedAttempts,
      expiresAt: document.expiresAt,
      resetTokenDigest: document.resetTokenDigest,
      verified: document.verified,
    };
  }

  async incrementFailedAttempts(
    normalizedIdentity: string,
    maximumAttempts: number,
    expectedCodeDigest: string,
  ): Promise<number | null> {
    const updated = await this.collection.findOneAndUpdate(
      {
        normalizedIdentity,
        codeDigest: expectedCodeDigest,
        expiresAt: { $gt: new Date() },
        failedAttempts: { $lt: maximumAttempts },
      },
      { $inc: { failedAttempts: 1 } },
      { returnDocument: "after" },
    );
    return updated?.failedAttempts ?? null;
  }

  async issueResetGrant(
    normalizedIdentity: string,
    tokenDigest: string,
    expiresAt: Date,
    expectedCodeDigest: string,
    maximumAttempts: number,
  ): Promise<void> {
    const result = await this.collection.updateOne(
      {
        normalizedIdentity,
        codeDigest: expectedCodeDigest,
        failedAttempts: { $lt: maximumAttempts },
        expiresAt: { $gt: new Date() },
      },
      {
        $set: {
          codeDigest: null,
          resetTokenDigest: tokenDigest,
          verified: true,
          expiresAt,
        },
      },
    );
    if (result.matchedCount !== 1) {
      throw new AuthError(
        400,
        "invalid_or_expired_code",
        "Código inválido ou expirado. Solicite um novo código.",
      );
    }
  }

  async consumeResetGrant(
    normalizedIdentity: string,
    tokenDigest: string,
    now: Date,
  ): Promise<boolean> {
    const result = await this.collection.deleteOne({
      normalizedIdentity,
      resetTokenDigest: tokenDigest,
      verified: true,
      expiresAt: { $gt: now },
    });
    return result.deletedCount === 1;
  }

  async resetPassword(identity: string, userId: string, digest: string, passwordHash: string, now: Date): Promise<boolean> {
    return transaction(this.database, async (session) => {
      const grant = await this.collection.findOne({ normalizedIdentity: identity, resetTokenDigest: digest,
        verified: true, expiresAt: { $gt: now } }, { session });
      if (!grant) return false;
      const user = await this.database.collection("auth_users").updateOne({ _id: new ObjectId(userId), active: true }, {
        $set: { passwordHash, passwordUpdatedAt: now, requirePasswordChange: false }, $inc: { sessionVersion: 1 },
      }, { session });
      if (!user.matchedCount) return false;
      await this.collection.deleteOne({ _id: grant._id }, { session });
      await this.database.collection("auth_sessions").deleteMany({ userId }, { session });
      return true;
    });
  }

  async delete(normalizedIdentity: string, expectedCodeDigest?: string): Promise<void> {
    await this.collection.deleteOne({ normalizedIdentity, ...(expectedCodeDigest ? { codeDigest: expectedCodeDigest } : {}) });
  }
}
