// Desenvolvido por Guilherme Henrique Moreira
import { createHash, randomBytes } from "node:crypto";
import { Router } from "express";
import { ObjectId, type Db } from "mongodb";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { authenticated } from "../infrastructure/session.middleware.js";
import { AuthError } from "../../../shared/auth-error.js";
import { parse, passwordSchema } from "../../../shared/validation.js";
import { transaction } from "../../../shared/transaction.js";
import type { AuthService } from "../application/auth.service.js";
import { registerProfileRoutes } from "./profile/routes.js";

export function createSessionRouter(database: Db, secret: string, service: AuthService): Router {
  const router = Router();
  router.use(authenticated(database, secret));
  registerProfileRoutes(router, database);

  router.get("/sessions", async (_request, response) => {
    const records = await database
      .collection("auth_sessions")
      .find(
        { userId: response.locals.userId, expiresAt: { $gt: new Date() } },
        { projection: { _id: 0, createdAt: 1, expiresAt: 1, sessionId: 1, userAgent: 1, ipAddress: 1 } },
      )
      .sort({ createdAt: -1 })
      .toArray();
    response.json(
      records.map(({ sessionId, ...record }) => ({
        id: sessionId,
        sessionId,
        device: record.userAgent ?? "Sessão Web / Desktop",
        ipAddress: record.ipAddress ?? "127.0.0.1",
        ...record,
        current: sessionId === response.locals.sessionId,
      })),
    );
  });

  router.delete("/sessions/:sessionId", async (request, response) => {
    const targetSessionId = String(request.params.sessionId ?? "").trim();
    if (!targetSessionId) throw new AuthError(400, "invalid_session", "Sessão inválida.");
    await database.collection("auth_sessions").deleteOne({
      sessionId: targetSessionId,
      userId: response.locals.userId,
    });
    response.status(204).end();
  });

  router.post("/logout-others", async (_request, response) => {
    await database.collection("auth_sessions").deleteMany({
      userId: response.locals.userId,
      sessionId: { $ne: response.locals.sessionId },
    });
    response.status(204).end();
  });

  router.get("/security-logs", async (_request, response) => {
    const userId = response.locals.userId as string;
    const logs = await database
      .collection("admin_audit_logs")
      .find({ $or: [{ actorId: userId }, { target: userId }] })
      .sort({ createdAt: -1 })
      .limit(25)
      .toArray();
    response.json(
      logs.map((entry) => ({
        id: String(entry._id),
        action: entry.action,
        createdAt: entry.createdAt,
        ipAddress: entry.ipAddress ?? "127.0.0.1",
        details: entry.details ?? {},
      })),
    );
  });

  router.post("/backup-codes", async (_request, response) => {
    const codes: string[] = [];
    const digests: string[] = [];
    for (let i = 0; i < 6; i++) {
      const partA = randomBytes(2).toString("hex").toUpperCase();
      const partB = randomBytes(2).toString("hex").toUpperCase();
      const code = `AGMRM-${partA}-${partB}`;
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

  router.get("/lgpd-export", async (_request, response) => {
    const userId = response.locals.userId as string;
    const user = response.locals.user;
    const [enrollments, classes, submissions, protocols, sessions, auditLogs] = await Promise.all([
      database.collection("academic_enrollments").find({ studentId: userId }).toArray(),
      database.collection("academic_classes").find({ professorId: userId }).toArray(),
      database.collection("academic_submissions").find({ studentId: userId }, { projection: { contentBase64: 0 } }).toArray(),
      database.collection("academic_protocols").find({ studentId: userId }, { projection: { attachmentBase64: 0 } }).toArray(),
      database.collection("auth_sessions").find({ userId }, { projection: { _id: 0, sessionId: 1, createdAt: 1, expiresAt: 1 } }).toArray(),
      database.collection("admin_audit_logs").find({ $or: [{ actorId: userId }, { target: userId }] }).limit(100).toArray(),
    ]);
    response.json({
      exportedAt: new Date().toISOString(),
      holder: {
        id: userId,
        identity: user.identity,
        displayName: user.displayName,
        email: user.email,
        profile: user.profile,
        departmentOrCourse: user.departmentOrCourse ?? user.department ?? "",
        preferences: user.preferences ?? {},
      },
      enrollments,
      teachingClasses: classes,
      submissions,
      protocols,
      activeSessions: sessions,
      auditTrail: auditLogs,
    });
  });

  router.post("/logout", async (_request, response) => {
    await database.collection("auth_sessions").deleteOne({
      sessionId: response.locals.sessionId,
      userId: response.locals.userId,
    });
    response.status(204).end();
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

  return router;
}
