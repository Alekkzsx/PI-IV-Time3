// Desenvolvido por Guilherme Henrique Moreira
import { Router } from "express";
import { ObjectId, type Db } from "mongodb";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { authenticated } from "../infrastructure/session.middleware.js";
import { AuthError } from "../../../shared/auth-error.js";
import { parse, passwordSchema } from "../../../shared/validation.js";
import { transaction } from "../../../shared/transaction.js";
import type { AuthService } from "../application/auth.service.js";

export function createSessionRouter(database: Db, secret: string, service: AuthService): Router {
  const router = Router();
  router.use(authenticated(database, secret));
  router.get("/me", (_request, response) => {
    const user = response.locals.user;
    response.json({ id: String(user._id), identity: user.identity, displayName: user.displayName,
      email: user.email, profile: user.profile, requirePasswordChange: user.requirePasswordChange === true,
      twoFactorRequired: user.twoFactorRequired === true });
  });
  router.get("/sessions", async (_request, response) => {
    const records = await database.collection("auth_sessions").find({
      userId: response.locals.userId, expiresAt: { $gt: new Date() },
    }, { projection: { _id: 0, createdAt: 1, expiresAt: 1, sessionId: 1 } }).toArray();
    response.json(records.map(({ sessionId, ...record }) => ({ ...record, current: sessionId === response.locals.sessionId })));
  });
  router.post("/logout", async (_request, response) => {
    await database.collection("auth_sessions").deleteOne({ sessionId: response.locals.sessionId, userId: response.locals.userId });
    response.status(204).end();
  });
  router.post("/two-factor", async (request, response) => {
    const input = parse(z.object({ password: z.string().min(1).max(128), enabled: z.boolean() }).strict(), request.body);
    if (input.enabled) service.ensureEmailAvailable();
    if (!await bcrypt.compare(input.password, response.locals.user.passwordHash)) throw new AuthError(401, "invalid_password", "Senha atual incorreta.");
    await transaction(database, async (session) => {
      const result = await database.collection("auth_users").updateOne({ _id: new ObjectId(response.locals.userId), active: true,
        passwordHash: response.locals.user.passwordHash }, { $set: { twoFactorRequired: input.enabled }, $inc: { sessionVersion: 1 } }, { session });
      if (!result.matchedCount) throw new AuthError(409, "account_changed", "Conta alterada. Entre novamente.");
      await database.collection("auth_sessions").deleteMany({ userId: response.locals.userId }, { session });
    });
    response.status(204).end();
  });
  router.post("/change-password", async (request, response) => {
    const input = parse(z.object({ currentPassword: z.string().min(1).max(128), newPassword: passwordSchema }).strict(), request.body);
    const user = response.locals.user;
    if (!await bcrypt.compare(input.currentPassword, user.passwordHash)) throw new AuthError(401, "invalid_password", "Senha atual incorreta.");
    if (input.currentPassword === input.newPassword) throw new AuthError(400, "same_password", "Escolha uma senha diferente da atual.");
    const hash = await bcrypt.hash(input.newPassword, 12);
    await transaction(database, async (session) => {
      const result = await database.collection("auth_users").updateOne({ _id: new ObjectId(response.locals.userId),
        active: true, passwordHash: user.passwordHash }, { $set: { passwordHash: hash, passwordUpdatedAt: new Date(),
        requirePasswordChange: false }, $inc: { sessionVersion: 1 } }, { session });
      if (!result.matchedCount) throw new AuthError(409, "account_changed", "Conta alterada. Entre novamente.");
      await database.collection("auth_sessions").deleteMany({ userId: response.locals.userId }, { session });
      await database.collection("auth_recovery").deleteMany({ normalizedIdentity: user.normalizedIdentity }, { session });
    });
    response.status(204).end();
  });
  return router;
}
