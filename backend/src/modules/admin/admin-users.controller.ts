// Desenvolvido por Guilherme Henrique Moreira

import { Router } from "express";
import { type Db, type Document } from "mongodb";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { AuthError } from "../../shared/auth-error.js";
import { emailSchema, identitySchema, objectId, parse, passwordSchema } from "../../shared/validation.js";
import { adminOnly } from "./admin-academic.controller.js";
import { adminWrite, audit } from "./admin-support.js";
import type { AuthService } from "../auth/application/auth.service.js";

const newUserSchema = z.object({
  identity: identitySchema, email: emailSchema, displayName: z.string().trim().min(2).max(120),
  profile: z.enum(["admin", "docente", "aluno"]), password: passwordSchema,
  departmentOrCourse: z.string().trim().max(160).optional(),
  twoFactorRequired: z.boolean().optional(),
}).strict();
const updateUserSchema = newUserSchema.omit({ password: true }).partial()
  .refine((value) => Object.keys(value).length > 0);
const collation = { locale: "en", strength: 2 };

export function publicUser(document: Document): Document {
  return {
    id: String(document._id), identity: document.identity, email: document.email,
    displayName: document.displayName, profile: document.profile, active: document.active,
    departmentOrCourse: document.departmentOrCourse ?? "",
    twoFactorRequired: document.twoFactorRequired === true,
    suspensionReason: document.suspensionReason ?? null,
    lastLogin: document.lastLogin ?? null,
    requirePasswordChange: document.requirePasswordChange === true,
  };
}

export function createAdminUsersRouter(database: Db, jwtSecret: string, service: AuthService): Router {
  const router = Router();
  const users = database.collection("auth_users");
  router.use(adminOnly(jwtSecret, database));

  router.get("/", async (request, response) => {
    const query = parse(z.object({
      profile: z.enum(["admin", "docente", "aluno"]).optional(),
      active: z.enum(["true", "false"]).optional(),
      search: z.string().trim().max(100).optional(),
      limit: z.coerce.number().int().min(1).max(500).default(100),
      offset: z.coerce.number().int().min(0).max(100000).default(0),
    }).strict(), request.query);
    const filter: Document = {};
    if (query.profile) filter.profile = query.profile;
    if (query.active) filter.active = query.active === "true";
    if (query.search) {
      const escaped = query.search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      filter.$or = ["identity", "email", "displayName"].map((field) => ({ [field]: { $regex: escaped, $options: "i" } }));
    }
    const records = await users.find(filter).sort({ displayName: 1, _id: 1 }).skip(query.offset).limit(query.limit).toArray();
    const sessions = await database.collection("auth_sessions").aggregate<{ _id: string; count: number }>([
      { $match: { userId: { $in: records.map((record) => String(record._id)) }, expiresAt: { $gt: new Date() } } },
      { $group: { _id: "$userId", count: { $sum: 1 } } },
    ]).toArray();
    const counts = new Map(sessions.map((entry) => [entry._id, entry.count]));
    response.setHeader("X-Total-Count", await users.countDocuments(filter));
    response.json(records.map((record) => ({ ...publicUser(record), activeSessionsCount: counts.get(String(record._id)) ?? 0 })));
  });

  router.get("/:id", async (request, response) => {
    const user = await users.findOne({ _id: objectId(request.params.id) });
    if (!user) throw new AuthError(404, "user_not_found", "Usuário não encontrado.");
    response.json(publicUser(user));
  });

  router.post("/", async (request, response) => {
    const { password, ...fields } = parse(newUserSchema, request.body);
    if (fields.twoFactorRequired) service.ensureEmailAvailable();
    const passwordHash = await bcrypt.hash(password, 12);
    const created = await adminWrite(database, response.locals.adminId, async (session) => {
      const normalizedIdentity = fields.identity.toLowerCase();
      const duplicate = await users.findOne({ $or: [
        { normalizedIdentity }, { email: fields.email }, { email: normalizedIdentity }, { normalizedIdentity: fields.email },
      ] }, { session, collation });
      if (duplicate) throw new AuthError(409, "user_exists", "E-mail ou identidade institucional já cadastrado.");
      const user = { ...fields, departmentOrCourse: fields.departmentOrCourse ?? "", twoFactorRequired: fields.twoFactorRequired ?? false,
        normalizedIdentity, passwordHash, active: true, sessionVersion: 0,
        createdAt: new Date(), updatedAt: new Date() };
      const result = await users.insertOne(user, { session });
      await audit(database, response.locals.adminId, "user_created", String(result.insertedId), { profile: fields.profile }, session);
      return publicUser({ _id: result.insertedId, ...user });
    });
    response.status(201).json(created);
  });

  router.patch("/:id", async (request, response) => {
    const id = objectId(request.params.id);
    const fields = parse(updateUserSchema, request.body);
    if (fields.twoFactorRequired) service.ensureEmailAvailable();
    const result = await adminWrite(database, response.locals.adminId, async (session) => {
      const existing = await users.findOne({ _id: id }, { session });
      if (!existing) throw new AuthError(404, "user_not_found", "Usuário não encontrado.");
      if (fields.profile && fields.profile !== existing.profile && existing.profile === "admin") {
        if (String(id) === response.locals.adminId) throw new AuthError(409, "self_demotion", "Você não pode remover seu próprio perfil administrativo.");
        if (existing.active && await users.countDocuments({ profile: "admin", active: true }, { session }) <= 1) {
          throw new AuthError(409, "last_admin", "Não é possível remover o último administrador ativo.");
        }
      }
      const identity = (fields.identity ?? existing.identity).toLowerCase();
      const email = fields.email ?? existing.email;
      if (await users.findOne({ _id: { $ne: id }, $or: [
        { normalizedIdentity: identity }, { email }, { email: identity }, { normalizedIdentity: email },
      ] }, { session, collation })) throw new AuthError(409, "user_exists", "E-mail ou identidade institucional já cadastrado.");
      if (fields.profile && fields.profile !== existing.profile) {
        const linkedTeacher = await database.collection("academic_classes").findOne({ professorId: String(id), active: { $ne: false } }, { session });
        const linkedStudent = await database.collection("academic_enrollments").findOne({ studentId: String(id), status: "active" }, { session });
        if (linkedTeacher || linkedStudent) throw new AuthError(409, "linked_profile", "Remova os vínculos acadêmicos ativos antes de alterar o perfil.");
      }
      const securityChanged = !!fields.profile && fields.profile !== existing.profile ||
        !!fields.identity && fields.identity !== existing.identity ||
        fields.twoFactorRequired !== undefined && fields.twoFactorRequired !== existing.twoFactorRequired ||
        !!fields.email && fields.email !== existing.email;
      const user = await users.findOneAndUpdate({ _id: id }, { $set: { ...fields, normalizedIdentity: identity, updatedAt: new Date() },
        ...(securityChanged ? { $inc: { sessionVersion: 1 } } : {}) }, { session, returnDocument: "after" });
      if (securityChanged) {
        await database.collection("auth_sessions").deleteMany({ userId: String(id) }, { session });
        await database.collection("auth_recovery").deleteMany({ normalizedIdentity: existing.normalizedIdentity }, { session });
      }
      if (fields.identity) {
        await database.collection("academic_classes").updateMany({ professorId: String(id) }, { $set: { professorIdentity: identity } }, { session });
        await database.collection("academic_enrollments").updateMany({ studentId: String(id) }, { $set: { studentIdentity: identity } }, { session });
      }
      if (fields.displayName) await database.collection("academic_enrollments").updateMany({ studentId: String(id) }, { $set: { displayName: fields.displayName } }, { session });
      await audit(database, response.locals.adminId, "user_updated", String(id), { fields: Object.keys(fields) }, session);
      return publicUser(user!);
    });
    response.json(result);
  });

  router.patch("/:id/status", async (request, response) => {
    const id = objectId(request.params.id);
    const input = parse(z.object({ active: z.boolean(), reason: z.string().trim().max(500).optional() }).strict(), request.body);
    const updated = await adminWrite(database, response.locals.adminId, async (session) => {
      const existing = await users.findOne({ _id: id }, { session });
      if (!existing) throw new AuthError(404, "user_not_found", "Usuário não encontrado.");
      if (!input.active && existing.active && existing.profile === "admin") {
        if (String(id) === response.locals.adminId) throw new AuthError(409, "self_suspension", "Você não pode suspender sua própria conta.");
        if (await users.countDocuments({ profile: "admin", active: true }, { session }) <= 1) throw new AuthError(409, "last_admin", "Não é possível suspender o último administrador ativo.");
      }
      if (input.active === existing.active) return publicUser(existing);
      const user = await users.findOneAndUpdate({ _id: id }, { $set: { active: input.active,
        suspensionReason: input.active ? null : input.reason ?? null, updatedAt: new Date() },
        $inc: { sessionVersion: 1 } }, { session, returnDocument: "after" });
      await database.collection("auth_sessions").deleteMany({ userId: String(id) }, { session });
      await database.collection("auth_recovery").deleteMany({ normalizedIdentity: existing.normalizedIdentity }, { session });
      await audit(database, response.locals.adminId, input.active ? "user_activated" : "user_suspended", String(id), {}, session);
      return publicUser(user!);
    });
    response.json(updated);
  });

  router.get("/:id/sessions", async (request, response) => {
    const id = objectId(request.params.id);
    if (!await users.findOne({ _id: id })) throw new AuthError(404, "user_not_found", "Usuário não encontrado.");
    const records = await database.collection("auth_sessions").find({ userId: String(id), expiresAt: { $gt: new Date() } },
      { projection: { createdAt: 1, expiresAt: 1 } }).sort({ createdAt: -1 }).toArray();
    response.json(records.map(({ _id, ...record }) => ({ id: String(_id), ...record })));
  });

  router.post("/:id/revoke-sessions", async (request, response) => {
    const id = objectId(request.params.id);
    await adminWrite(database, response.locals.adminId, async (session) => {
      if (!(await users.updateOne({ _id: id }, { $inc: { sessionVersion: 1 } }, { session })).matchedCount) throw new AuthError(404, "user_not_found", "Usuário não encontrado.");
      await database.collection("auth_sessions").deleteMany({ userId: String(id) }, { session });
      await audit(database, response.locals.adminId, "sessions_revoked", String(id), {}, session);
    });
    response.status(204).end();
  });

  router.post("/:id/reset-password", async (request, response) => {
    const id = objectId(request.params.id);
    const flags = parse(z.object({
      forceNextLogin: z.boolean().default(true), sendRecoveryEmail: z.literal(true).default(true),
      revokeActiveSessions: z.boolean().default(true),
    }).strict(), request.body ?? {});
    const existing = await users.findOne({ _id: id, active: true });
    if (!existing) throw new AuthError(404, "user_not_found", "Usuário ativo não encontrado.");
    await service.requestRecoveryCode(existing.identity);
    await adminWrite(database, response.locals.adminId, async (session) => {
      const result = await users.updateOne({ _id: id, active: true }, { $set: { requirePasswordChange: flags.forceNextLogin },
        ...(flags.revokeActiveSessions ? { $inc: { sessionVersion: 1 } } : {}) }, { session });
      if (!result.matchedCount) throw new AuthError(409, "account_changed", "Conta alterada durante a solicitação.");
      if (flags.revokeActiveSessions) await database.collection("auth_sessions").deleteMany({ userId: String(id) }, { session });
      await audit(database, response.locals.adminId, "password_recovery_requested", String(id), {}, session);
    });
    response.status(202).json({ message: "Código de recuperação enviado ao e-mail cadastrado." });
  });

  return router;
}
