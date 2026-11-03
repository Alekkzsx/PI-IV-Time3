// Desenvolvido por Guilherme Henrique Moreira
import { Router } from "express";
import { randomUUID } from "node:crypto";
import { ObjectId, type Db, type Document } from "mongodb";
import { z } from "zod";
import { adminOnly } from "../infrastructure/admin-auth.middleware.js";
import { adminWrite, audit, publicRecord, publicUser } from "../infrastructure/admin-support.js";
import { parse, objectId } from "../../../shared/validation.js";
import { AuthError } from "../../../shared/auth-error.js";

const settingsSchema = z
  .object({
    regimentalLockActive: z.boolean().optional(),
    minimumGrade: z.number().min(0).max(10).optional(),
    minimumAttendance: z.number().min(0).max(100).optional(),
    specialExamGrade: z.number().min(0).max(10).optional(),
    evaluationFormula: z.string().trim().min(1).max(200).optional(),
    resolutionCode: z.string().trim().max(80).optional(),
    currentSemesterLabel: z.string().trim().max(80).optional(),
    currentWeekLabel: z.string().trim().max(80).optional(),
    campusAlerts: z.record(z.string(), z.unknown()).optional(),
    systemPreferences: z.record(z.string(), z.unknown()).optional(),
    governanceLgpd: z.record(z.string(), z.unknown()).optional(),
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0);

const eventSchema = z.object({
  title: z.string().trim().min(2).max(160),
  startsAt: z.string().datetime({ offset: true }),
  endsAt: z.string().datetime({ offset: true }).nullable().optional(),
  type: z.enum(["academic", "deadline", "holiday"]).default("academic"),
  statusLabel: z.string().trim().max(40).optional(),
  description: z.string().trim().max(2000).default(""),
}).strict();

export function createAdminOperationsRouter(database: Db, secret: string): Router {
  const router = Router();
  router.use(adminOnly(secret, database));
  const protocols = database.collection("academic_protocols");
  const settings = database.collection<{ _id: string; [key: string]: unknown }>("admin_settings");

  router.get("/dashboard", async (_request, response) => {
    const users = database.collection("auth_users");
    const [
      students,
      professors,
      administrators,
      courses,
      allClasses,
      pendingProtocols,
      decidedProtocols,
      gradesList,
      calendarMilestones,
    ] = await Promise.all([
      users.countDocuments({ profile: "aluno", active: true }),
      users.countDocuments({ profile: "docente", active: true }),
      users.countDocuments({ profile: "admin", active: true }),
      database.collection("academic_courses").countDocuments({ active: { $ne: false } }),
      database.collection("academic_classes").find({ active: { $ne: false } }).toArray(),
      protocols.countDocuments({ status: "Aguardando Parecer" }),
      protocols.countDocuments({ status: { $in: ["Deferido", "Indeferido"] } }),
      database.collection("academic_grades").find({}).toArray(),
      database.collection("academic_calendar").find({}).sort({ startsAt: 1 }).limit(10).toArray(),
    ]);

    const classes = allClasses.length;
    const homologatedCount = allClasses.filter((c) => c.pautaHomologated === true || c.gradeLocked === true).length;
    const homologatedPercentage = classes > 0 ? Math.round((homologatedCount / classes) * 100) : 0;
    const attendanceAverage =
      gradesList.length > 0
        ? Number(
            (
              gradesList.reduce((acc, g) => acc + Number(g.attendanceRate ?? 100), 0) /
              gradesList.length
            ).toFixed(1),
          )
        : 100;

    response.json({
      students,
      professors,
      administrators,
      courses,
      classes,
      pendingProtocols,
      decidedProtocols,
      homologatedCount,
      homologatedPercentage,
      attendanceAverage,
      calendarMilestones: calendarMilestones.map(publicRecord),
    });
  });

  router.get("/audit-logs", async (request, response) => {
    const query = parse(
      z.object({
        target: z.string().max(100).optional(),
        limit: z.coerce.number().int().min(1).max(500).default(100),
        offset: z.coerce.number().int().min(0).max(100000).default(0),
      }).strict(),
      request.query,
    );
    const records = await database
      .collection("admin_audit_logs")
      .find(query.target ? { target: query.target } : {})
      .sort({ createdAt: -1, _id: -1 })
      .skip(query.offset)
      .limit(query.limit)
      .toArray();

    const actorIds = Array.from(
      new Set(
        records
          .map((r) => (typeof r.actorId === "string" && ObjectId.isValid(r.actorId) ? r.actorId : null))
          .filter(Boolean) as string[],
      ),
    );
    const actors =
      actorIds.length > 0
        ? await database
            .collection("auth_users")
            .find({ _id: { $in: actorIds.map((id) => new ObjectId(id)) } })
            .toArray()
        : [];
    const actorMap = new Map(actors.map((a) => [String(a._id), a]));

    response.json(
      records.map((entry) => {
        const actorDoc = typeof entry.actorId === "string" ? actorMap.get(entry.actorId) : undefined;
        const actionStr = String(entry.action ?? "");
        const severity =
          entry.severity ??
          (actionStr.includes("suspended") || actionStr.includes("revoked") || actionStr.includes("locked")
            ? "CRITICO"
            : actionStr.includes("updated") || actionStr.includes("decision") || actionStr.includes("rectif")
              ? "ATENCAO"
              : "INFO");
        return {
          ...publicRecord(entry),
          actorName: entry.actorName ?? actorDoc?.displayName ?? "Sistema Institucional",
          actorIdentity: entry.actorIdentity ?? actorDoc?.identity ?? entry.actorId ?? "SISTEMA",
          actorRole: entry.actorRole ?? actorDoc?.profile ?? "admin",
          ipAddress: entry.ipAddress ?? "127.0.0.1",
          severity,
          diffBefore: entry.diffBefore ?? null,
          diffAfter: entry.diffAfter ?? (entry.details ? JSON.stringify(entry.details) : null),
        };
      }),
    );
  });

  router.get("/users/:id/dossier", async (request, response) => {
    const id = objectId(request.params.id);
    const user = await database.collection("auth_users").findOne({ _id: id });
    if (!user) throw new AuthError(404, "user_not_found", "Usuário não encontrado.");
    const [classes, enrollments, logs, protocolsList, gradesList] = await Promise.all([
      database.collection("academic_classes").find({ professorId: String(id) }).toArray(),
      database.collection("academic_enrollments").find({ studentId: String(id) }).toArray(),
      database
        .collection("admin_audit_logs")
        .find({ $or: [{ target: String(id) }, { actorId: String(id) }] })
        .sort({ createdAt: -1 })
        .limit(100)
        .toArray(),
      protocols.find({ studentId: String(id) }, { projection: { attachmentBase64: 0 } }).sort({ createdAt: -1 }).toArray(),
      database.collection("academic_grades").find({ studentId: String(id) }).toArray(),
    ]);
    await audit(database, response.locals.adminId, "dossier_viewed", String(id));
    response.json({
      user: publicUser(user),
      classes: classes.map(publicRecord),
      enrollments: enrollments.map(publicRecord),
      protocols: protocolsList.map(publicRecord),
      grades: gradesList.map(publicRecord),
      auditLogs: logs.map(publicRecord),
    });
  });

  router.get("/protocols", async (_request, response) => {
    const list = await protocols
      .find({}, { projection: { attachmentBase64: 0 } })
      .sort({ createdAt: -1 })
      .limit(500)
      .toArray();
    response.json(list.map(publicRecord));
  });

  router.post("/protocols", async (request, response) => {
    const input = parse(
      z.object({
        studentIdentity: z.string().trim().min(1).max(254),
        requestType: z.string().trim().min(2).max(120),
        targetComponent: z.string().trim().max(120).default(""),
        justification: z.string().trim().min(5).max(3000),
        attachmentName: z.string().trim().max(200).default(""),
      }).strict(),
      request.body,
    );
    const created = await adminWrite(database, response.locals.adminId, async (session) => {
      const student = await database
        .collection("auth_users")
        .findOne({ normalizedIdentity: input.studentIdentity.toLowerCase(), profile: "aluno", active: true }, { session });
      if (!student) throw new AuthError(404, "student_not_found", "Aluno ativo não encontrado.");
      const record = {
        ...input,
        code: "PROT-" + randomUUID().slice(0, 8).toUpperCase(),
        studentId: String(student._id),
        studentRa: student.identity,
        studentName: student.displayName,
        status: "Aguardando Parecer",
        createdAt: new Date(),
        createdBy: response.locals.adminId,
      };
      const saved = await protocols.insertOne(record, { session });
      await audit(database, response.locals.adminId, "protocol_created", String(saved.insertedId), {}, session);
      return publicRecord({ _id: saved.insertedId, ...record });
    });
    response.status(201).json(created);
  });

  router.patch("/protocols/:id/decision", async (request, response) => {
    const id = objectId(request.params.id);
    const input = parse(z.object({ approved: z.boolean(), decisionNote: z.string().trim().min(5).max(3000) }).strict(), request.body);
    const adminUser = response.locals.user as Document | undefined;
    const signedBy = adminUser?.displayName ?? "Secretaria Geral Acadêmica";

    const record = await adminWrite(database, response.locals.adminId, async (session) => {
      const updated = await protocols.findOneAndUpdate(
        { _id: id, status: "Aguardando Parecer" },
        {
          $set: {
            status: input.approved ? "Deferido" : "Indeferido",
            decisionNote: input.decisionNote,
            decidedBy: response.locals.adminId,
            signedBy,
            decidedAt: new Date(),
          },
        },
        { session, returnDocument: "after" },
      );
      if (!updated) throw new AuthError(409, "protocol_unavailable", "Protocolo inexistente ou já decidido.");

      // Se for deferimento de abono/atestado, regulariza faltas justificadas no vínculo acadêmico
      const reqType = String(updated.requestType ?? "").toLowerCase();
      if (input.approved && (reqType.includes("abono") || reqType.includes("atestado") || reqType.includes("falta"))) {
        const targetFilter: Document = { studentId: String(updated.studentId), status: "active" };
        if (updated.targetComponent) {
          targetFilter.classCode = updated.targetComponent;
        }
        await database.collection("academic_enrollments").updateMany(
          targetFilter,
          { $inc: { excusedAbsences: 2 } },
          { session },
        );
      }

      await audit(database, response.locals.adminId, "protocol_decided", String(id), { approved: input.approved }, session);
      return publicRecord(updated);
    });
    response.json(record);
  });

  router.get("/announcements", async (_request, response) => {
    response.json(
      (await database.collection("academic_announcements").find({}).sort({ createdAt: -1 }).limit(100).toArray()).map(publicRecord),
    );
  });

  router.post("/announcements", async (request, response) => {
    const input = parse(
      z.object({
        title: z.string().trim().min(2).max(160),
        body: z.string().trim().min(2).max(5000),
        audience: z.string().trim().min(1).max(120),
        category: z.string().trim().min(1).max(80),
      }).strict(),
      request.body,
    );
    const adminUser = response.locals.user as Document | undefined;
    const record = await adminWrite(database, response.locals.adminId, async (session) => {
      const data = {
        ...input,
        authorName: adminUser?.displayName ?? "Secretaria Geral Acadêmica",
        senderRole: "admin",
        isInstitutional: true,
        readBy: [],
        createdAt: new Date(),
        createdBy: response.locals.adminId,
      };
      const inserted = await database.collection("academic_announcements").insertOne(data, { session });
      await audit(database, response.locals.adminId, "announcement_created", String(inserted.insertedId), {}, session);
      return publicRecord({ _id: inserted.insertedId, ...data });
    });
    response.status(201).json(record);
  });

  router.get("/settings", async (_request, response) => {
    const { _id, ...data } = (await settings.findOne({ _id: "institutional" })) ?? {};
    response.json({
      regimentalLockActive: true,
      minimumGrade: 6,
      minimumAttendance: 75,
      specialExamGrade: 4,
      evaluationFormula: "Média Semestral (MS) = (N1 x 0.4) + (N2 x 0.6)",
      resolutionCode: "RESOLUÇÃO CONSEPE 2026/04",
      currentSemesterLabel: "2026/2",
      currentWeekLabel: "Calendário Vigente 2026/2",
      campusAlerts: {},
      systemPreferences: {},
      governanceLgpd: {},
      ...data,
    });
  });

  router.patch("/settings", async (request, response) => {
    const input = parse(settingsSchema, request.body);
    await adminWrite(database, response.locals.adminId, async (session) => {
      await settings.updateOne(
        { _id: "institutional" },
        { $set: { ...input, updatedAt: new Date(), updatedBy: response.locals.adminId } },
        { upsert: true, session },
      );
      await audit(database, response.locals.adminId, "settings_updated", "institutional", { fields: Object.keys(input) }, session);
    });
    response.json({ ...input });
  });

  router.get("/calendar", async (_request, response) => {
    response.json((await database.collection("academic_calendar").find({}).sort({ startsAt: 1 }).limit(500).toArray()).map(publicRecord));
  });

  router.post("/calendar", async (request, response) => {
    const input = parse(eventSchema, request.body);
    if (input.endsAt && new Date(input.endsAt) < new Date(input.startsAt)) {
      throw new AuthError(400, "invalid_dates", "Término anterior ao início.");
    }
    const record = await adminWrite(database, response.locals.adminId, async (session) => {
      const data = {
        ...input,
        startsAt: new Date(input.startsAt),
        endsAt: input.endsAt ? new Date(input.endsAt) : null,
        createdAt: new Date(),
        createdBy: response.locals.adminId,
      };
      const inserted = await database.collection("academic_calendar").insertOne(data, { session });
      await audit(database, response.locals.adminId, "calendar_event_created", String(inserted.insertedId), {}, session);
      return publicRecord({ _id: inserted.insertedId, ...data });
    });
    response.status(201).json(record);
  });

  router.patch("/calendar/:id", async (request, response) => {
    const id = objectId(request.params.id);
    const input = parse(eventSchema.partial().refine((v) => Object.keys(v).length > 0), request.body);
    const record = await adminWrite(database, response.locals.adminId, async (session) => {
      const current = await database.collection("academic_calendar").findOne({ _id: id }, { session });
      if (!current) throw new AuthError(404, "event_not_found", "Marco do calendário não encontrado.");
      const startsAt = input.startsAt ? new Date(input.startsAt) : current.startsAt;
      const endsAt = input.endsAt === undefined ? current.endsAt : input.endsAt ? new Date(input.endsAt) : null;
      if (endsAt && endsAt < startsAt) throw new AuthError(400, "invalid_dates", "Término anterior ao início.");
      const updated = await database.collection("academic_calendar").findOneAndUpdate(
        { _id: id },
        { $set: { ...input, startsAt, endsAt, updatedAt: new Date() } },
        { session, returnDocument: "after" },
      );
      await audit(database, response.locals.adminId, "calendar_event_updated", String(id), {}, session);
      return publicRecord(updated!);
    });
    response.json(record);
  });

  router.delete("/calendar/:id", async (request, response) => {
    const id = objectId(request.params.id);
    await adminWrite(database, response.locals.adminId, async (session) => {
      const deleted = await database.collection("academic_calendar").deleteOne({ _id: id }, { session });
      if (!deleted.deletedCount) throw new AuthError(404, "event_not_found", "Marco do calendário não encontrado.");
      await audit(database, response.locals.adminId, "calendar_event_deleted", String(id), {}, session);
    });
    response.status(204).end();
  });

  return router;
}
