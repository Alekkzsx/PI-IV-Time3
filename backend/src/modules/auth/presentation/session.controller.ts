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

const profileUpdateSchema = z
  .object({
    displayName: z.string().trim().min(2).max(120).optional(),
    socialName: z.string().trim().max(120).optional(),
    phone: z.string().trim().max(40).optional(),
    personalEmail: z.string().trim().max(254).optional(),
    biography: z.string().trim().max(2000).optional(),
    departmentOrCourse: z.string().trim().max(160).optional(),
    department: z.string().trim().max(160).optional(),
    campus: z.string().trim().max(160).optional(),
    semester: z.string().trim().max(80).optional(),
    shift: z.string().trim().max(60).optional(),
    preferences: z.record(z.string(), z.unknown()).optional(),
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0);

export function createSessionRouter(database: Db, secret: string, service: AuthService): Router {
  const router = Router();
  router.use(authenticated(database, secret));

  router.get("/me", (_request, response) => {
    const user = response.locals.user;
    response.json({
      id: String(user._id),
      identity: user.identity,
      displayName: user.displayName,
      socialName: user.socialName ?? "",
      email: user.email,
      personalEmail: user.personalEmail ?? "",
      phone: user.phone ?? "",
      biography: user.biography ?? "",
      profile: user.profile,
      departmentOrCourse: user.departmentOrCourse ?? user.department ?? "",
      department: user.department ?? user.departmentOrCourse ?? "",
      campus: user.campus ?? "Campus Central",
      semester: user.semester ?? "2026/2",
      shift: user.shift ?? "",
      requirePasswordChange: user.requirePasswordChange === true,
      twoFactorRequired: user.twoFactorRequired === true,
      preferences: user.preferences ?? {},
      lastLogin: user.lastLogin ?? null,
    });
  });

  router.patch("/profile", async (request, response) => {
    const fields = parse(profileUpdateSchema, request.body);
    const userId = response.locals.userId as string;
    const setFields: Record<string, unknown> = {
      ...fields,
      updatedAt: new Date(),
    };
    if (fields.department && !fields.departmentOrCourse) {
      setFields.departmentOrCourse = fields.department;
    }
    if (fields.departmentOrCourse && !fields.department) {
      setFields.department = fields.departmentOrCourse;
    }

    const updated = await database.collection("auth_users").findOneAndUpdate(
      { _id: new ObjectId(userId), active: true },
      { $set: setFields },
      { returnDocument: "after" },
    );
    if (!updated) throw new AuthError(404, "user_not_found", "Conta não encontrada.");

    if (fields.displayName) {
      await database
        .collection("academic_enrollments")
        .updateMany({ studentId: userId }, { $set: { displayName: fields.displayName } });
      await database
        .collection("academic_classes")
        .updateMany({ professorId: userId }, { $set: { professorName: fields.displayName } });
    }

    response.json({
      id: String(updated._id),
      identity: updated.identity,
      displayName: updated.displayName,
      socialName: updated.socialName ?? "",
      email: updated.email,
      personalEmail: updated.personalEmail ?? "",
      phone: updated.phone ?? "",
      biography: updated.biography ?? "",
      profile: updated.profile,
      departmentOrCourse: updated.departmentOrCourse ?? updated.department ?? "",
      department: updated.department ?? updated.departmentOrCourse ?? "",
      campus: updated.campus ?? "Campus Central",
      semester: updated.semester ?? "2026/2",
      shift: updated.shift ?? "",
      twoFactorRequired: updated.twoFactorRequired === true,
      preferences: updated.preferences ?? {},
    });
  });

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
