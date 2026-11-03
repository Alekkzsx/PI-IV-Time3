// Desenvolvido por Guilherme Henrique Moreira
import { createHash, randomBytes } from "node:crypto";
import type { Router } from "express";
import bcrypt from "bcryptjs";
import { ObjectId, type Db } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../../../shared/auth-error.js";
import { parse, passwordSchema } from "../../../../shared/validation.js";
import { transaction } from "../../../../shared/transaction.js";
import type { AuthService } from "../../application/auth.service.js";

export function registerSecurityRoutes(router: Router, database: Db, service: AuthService): void {
  router.get("/security-logs", async (_request, response) => {
    const userId = response.locals.userId as string;
    const logs = await database
      .collection("admin_audit_logs")
      .find({ $or: [{ actorId: userId }, { target: userId }] })
      .sort({ createdAt: -1 })
      .limit(25)
      .toArray();
    response.json(logs.map((entry) => ({
      id: String(entry._id),
      action: entry.action,
      createdAt: entry.createdAt,
      ipAddress: entry.ipAddress ?? "127.0.0.1",
      details: entry.details ?? {},
    })));
  });

  router.post("/backup-codes", async (_request, response) => {
    const codes: string[] = [];
    const digests: string[] = [];
    for (let index = 0; index < 6; index++) {
      const code = `AGMRM-${randomBytes(2).toString("hex").toUpperCase()}-${randomBytes(2).toString("hex").toUpperCase()}`;
      codes.push(code);
      digests.push(createHash("sha256").update(code).digest("hex"));
    }
    await database.collection("auth_users").updateOne(
      { _id: new ObjectId(response.locals.userId), active: true },
      { $set: { backupCodeDigests: digests, backupCodesGeneratedAt: new Date() } },
    );
    await database.collection("admin_audit_logs").insertOne({
      actorId: response.locals.userId,
      action: "backup_codes_generated",
      target: response.locals.userId,
      details: { count: codes.length },
      createdAt: new Date(),
    });
    response.status(200).json({ codes });
  });

  router.post("/two-factor", async (request, response) => {
    const input = parse(z.object({ password: z.string().min(1).max(128), enabled: z.boolean() }).strict(), request.body);
    if (input.enabled) service.ensureEmailAvailable();
    if (!(await bcrypt.compare(input.password, response.locals.user.passwordHash))) {
      throw new AuthError(401, "invalid_password", "Senha atual incorreta.");
    }
    await transaction(database, async (session) => {
      const result = await database.collection("auth_users").updateOne(
        {
          _id: new ObjectId(response.locals.userId),
          active: true,
          passwordHash: response.locals.user.passwordHash,
        },
        { $set: { twoFactorRequired: input.enabled }, $inc: { sessionVersion: 1 } },
        { session },
      );
      if (!result.matchedCount) throw new AuthError(409, "account_changed", "Conta alterada. Entre novamente.");
      await database.collection("auth_sessions").deleteMany({ userId: response.locals.userId }, { session });
    });
    response.status(204).end();
  });

  router.post("/change-password", async (request, response) => {
    const input = parse(
      z.object({ currentPassword: z.string().min(1).max(128), newPassword: passwordSchema }).strict(),
      request.body,
    );
    const user = response.locals.user;
    if (!(await bcrypt.compare(input.currentPassword, user.passwordHash))) {
      throw new AuthError(401, "invalid_password", "Senha atual incorreta.");
    }
    if (input.currentPassword === input.newPassword) {
      throw new AuthError(400, "same_password", "Escolha uma senha diferente da atual.");
    }
    const hash = await bcrypt.hash(input.newPassword, 12);
    await transaction(database, async (session) => {
      const result = await database.collection("auth_users").updateOne(
        {
          _id: new ObjectId(response.locals.userId),
          active: true,
          passwordHash: user.passwordHash,
        },
        {
          $set: { passwordHash: hash, passwordUpdatedAt: new Date(), requirePasswordChange: false },
          $inc: { sessionVersion: 1 },
        },
        { session },
      );
      if (!result.matchedCount) throw new AuthError(409, "account_changed", "Conta alterada. Entre novamente.");
      await database.collection("auth_sessions").deleteMany({ userId: response.locals.userId }, { session });
      await database.collection("auth_recovery").deleteMany({ normalizedIdentity: user.normalizedIdentity }, { session });
    });
    response.status(204).end();
  });
}