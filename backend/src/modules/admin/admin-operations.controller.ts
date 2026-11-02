// Desenvolvido por Guilherme Henrique Moreira
import { Router } from "express";
import { randomUUID } from "node:crypto";
import type { Db } from "mongodb";
import { z } from "zod";
import { adminOnly } from "./admin-academic.controller.js";
import { adminWrite, audit, publicRecord } from "./admin-support.js";
import { parse, objectId } from "../../shared/validation.js";
import { AuthError } from "../../shared/auth-error.js";
import { publicUser } from "./admin-users.controller.js";

const settingsSchema = z.object({
  regimentalLockActive: z.boolean().optional(),
  minimumGrade: z.number().min(0).max(10).optional(),
  minimumAttendance: z.number().min(0).max(100).optional(),
  specialExamGrade: z.number().min(0).max(10).optional(),
  evaluationFormula: z.string().trim().min(1).max(200).optional(),
}).strict().refine((value) => Object.keys(value).length > 0);

export function createAdminOperationsRouter(database: Db, secret: string): Router {
  const router = Router();
  router.use(adminOnly(secret, database));
  const protocols = database.collection("academic_protocols");
  const settings = database.collection<{ _id: string; [key: string]: unknown }>("admin_settings");

  router.get("/dashboard", async (_request, response) => {
    const users = database.collection("auth_users");
    const [students, professors, administrators, courses, classes, pendingProtocols] = await Promise.all([
      users.countDocuments({ profile: "aluno", active: true }), users.countDocuments({ profile: "docente", active: true }),
      users.countDocuments({ profile: "admin", active: true }),
      database.collection("academic_courses").countDocuments({ active: { $ne: false } }),
      database.collection("academic_classes").countDocuments({ active: { $ne: false } }),
      protocols.countDocuments({ status: "Aguardando Parecer" }),
    ]);
    response.json({ students, professors, administrators, courses, classes, pendingProtocols });
  });

  router.get("/audit-logs", async (request, response) => {
    const query = parse(z.object({ target: z.string().max(100).optional(), limit: z.coerce.number().int().min(1).max(500).default(100),
      offset: z.coerce.number().int().min(0).max(100000).default(0) }).strict(), request.query);
    const records = await database.collection("admin_audit_logs").find(query.target ? { target: query.target } : {})
      .sort({ createdAt: -1, _id: -1 }).skip(query.offset).limit(query.limit).toArray();
    response.json(records.map(publicRecord));
  });

  router.get("/users/:id/dossier", async (request, response) => {
    const id = objectId(request.params.id);
    const user = await database.collection("auth_users").findOne({ _id: id });
    if (!user) throw new AuthError(404, "user_not_found", "Usuário não encontrado.");
    const [classes, enrollments, logs] = await Promise.all([
      database.collection("academic_classes").find({ professorId: String(id) }).toArray(),
      database.collection("academic_enrollments").find({ studentId: String(id) }).toArray(),
      database.collection("admin_audit_logs").find({ target: String(id) }).sort({ createdAt: -1 }).limit(100).toArray(),
    ]);
    await audit(database, response.locals.adminId, "dossier_viewed", String(id));
    response.json({ user: publicUser(user), classes: classes.map(publicRecord), enrollments: enrollments.map(publicRecord), auditLogs: logs.map(publicRecord) });
  });

  router.get("/protocols", async (_request, response) => {
    response.json((await protocols.find({}).sort({ createdAt: -1 }).limit(500).toArray()).map(publicRecord));
  });

  router.post("/protocols", async (request, response) => {
    const input = parse(z.object({ studentIdentity: z.string().trim().min(1).max(254),
      requestType: z.string().trim().min(2).max(120), targetComponent: z.string().trim().max(120).default(""),
      justification: z.string().trim().min(5).max(3000), attachmentName: z.string().trim().max(200).default(""),
    }).strict(), request.body);
    const created = await adminWrite(database, response.locals.adminId, async (session) => {
      const student = await database.collection("auth_users").findOne({ normalizedIdentity: input.studentIdentity.toLowerCase(), profile: "aluno", active: true }, { session });
      if (!student) throw new AuthError(404, "student_not_found", "Aluno ativo não encontrado.");
      const record = { ...input, code: "PROT-" + randomUUID(), studentId: String(student._id), studentRa: student.identity,
        studentName: student.displayName, status: "Aguardando Parecer", createdAt: new Date(), createdBy: response.locals.adminId };
      const saved = await protocols.insertOne(record, { session });
      await audit(database, response.locals.adminId, "protocol_created", String(saved.insertedId), {}, session);
      return publicRecord({ _id: saved.insertedId, ...record });
    });
    response.status(201).json(created);
  });

  router.patch("/protocols/:id/decision", async (request, response) => {
    const id = objectId(request.params.id);
    const input = parse(z.object({ approved: z.boolean(), decisionNote: z.string().trim().min(5).max(3000) }).strict(), request.body);
    const record = await adminWrite(database, response.locals.adminId, async (session) => {
      const updated = await protocols.findOneAndUpdate({ _id: id, status: "Aguardando Parecer" },
        { $set: { status: input.approved ? "Deferido" : "Indeferido", decisionNote: input.decisionNote,
          decidedBy: response.locals.adminId, decidedAt: new Date() } }, { session, returnDocument: "after" });
      if (!updated) throw new AuthError(409, "protocol_unavailable", "Protocolo inexistente ou já decidido.");
      await audit(database, response.locals.adminId, "protocol_decided", String(id), { approved: input.approved }, session);
      return publicRecord(updated);
    });
    response.json(record);
  });

  router.get("/announcements", async (_request, response) => {
    response.json((await database.collection("academic_announcements").find({}).sort({ createdAt: -1 }).limit(100).toArray()).map(publicRecord));
  });
  router.post("/announcements", async (request, response) => {
    const input = parse(z.object({ title: z.string().trim().min(2).max(160), body: z.string().trim().min(2).max(5000),
      audience: z.string().trim().min(1).max(120), category: z.string().trim().min(1).max(80) }).strict(), request.body);
    const record = await adminWrite(database, response.locals.adminId, async (session) => {
      const data = { ...input, createdAt: new Date(), createdBy: response.locals.adminId };
      const inserted = await database.collection("academic_announcements").insertOne(data, { session });
      await audit(database, response.locals.adminId, "announcement_created", String(inserted.insertedId), {}, session);
      return publicRecord({ _id: inserted.insertedId, ...data });
    });
    response.status(201).json(record);
  });

  router.get("/settings", async (_request, response) => {
    const { _id, ...data } = await settings.findOne({ _id: "institutional" }) ?? {};
    response.json({ regimentalLockActive: true, minimumGrade: 6, minimumAttendance: 75, specialExamGrade: 4,
      evaluationFormula: "Média Semestral (MS) = (N1 x 0.4) + (N2 x 0.6)", ...data });
  });
  router.patch("/settings", async (request, response) => {
    const input = parse(settingsSchema, request.body);
    await adminWrite(database, response.locals.adminId, async (session) => {
      await settings.updateOne({ _id: "institutional" }, { $set: { ...input, updatedAt: new Date(), updatedBy: response.locals.adminId } }, { upsert: true, session });
      await audit(database, response.locals.adminId, "settings_updated", "institutional", { fields: Object.keys(input) }, session);
    });
    response.json({ ...input });
  });

  const eventSchema = z.object({ title: z.string().trim().min(2).max(160),
    startsAt: z.string().datetime({ offset: true }), endsAt: z.string().datetime({ offset: true }).nullable().optional(),
    type: z.enum(["academic", "deadline", "holiday"]).default("academic"), description: z.string().trim().max(2000).default(""),
  }).strict();
  router.get("/calendar", async (_request, response) => {
    response.json((await database.collection("academic_calendar").find({}).sort({ startsAt: 1 }).limit(500).toArray()).map(publicRecord));
  });
  router.post("/calendar", async (request, response) => {
    const input = parse(eventSchema, request.body);
    if (input.endsAt && new Date(input.endsAt) < new Date(input.startsAt)) throw new AuthError(400, "invalid_dates", "Término anterior ao início.");
    const record = await adminWrite(database, response.locals.adminId, async (session) => {
      const data = { ...input, startsAt: new Date(input.startsAt), endsAt: input.endsAt ? new Date(input.endsAt) : null,
        createdAt: new Date(), createdBy: response.locals.adminId };
      const inserted = await database.collection("academic_calendar").insertOne(data, { session });
      await audit(database, response.locals.adminId, "calendar_event_created", String(inserted.insertedId), {}, session);
      return publicRecord({ _id: inserted.insertedId, ...data });
    });
    response.status(201).json(record);
  });
  return router;
}
