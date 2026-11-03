// Desenvolvido por Murillo Caravita - RA: 25014012

import { Router, type RequestHandler } from "express";
import { ObjectId, type Db, type Document, type ClientSession } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../shared/auth-error.js";
import { parse, objectId } from "../../shared/validation.js";
import { authenticated } from "../auth/infrastructure/session.middleware.js";
import { adminWrite, audit, publicRecord } from "./admin-support.js";

const codeSchema = z.string().trim().min(2).max(32).regex(/^[\p{L}\p{N}._-]+$/u);
const courseSchema = z.object({
  code: codeSchema, name: z.string().trim().min(2).max(120),
  matrix: z.string().trim().min(1).max(80), workload: z.string().trim().min(1).max(40),
  formula: z.string().trim().min(1).max(120), department: z.string().trim().min(1).max(120),
  modality: z.string().trim().min(1).max(60),
  components: z.array(z.record(z.string(), z.unknown())).max(100),
}).strict();
const classSchema = z.object({
  code: codeSchema, courseCode: codeSchema, semester: z.string().trim().min(3).max(40),
  shift: z.string().trim().min(2).max(40), location: z.string().trim().min(2).max(100),
  maxCapacity: z.number().int().min(1).max(500),
  professorIdentity: z.string().trim().min(1).max(254).nullable().optional(),
  formulaRegime: z.enum(["admin", "autonomia_docente"]).optional(),
  subjectName: z.string().trim().min(2).max(120).optional(),
}).strict();
const sessionSchema = z.object({
  title: z.string().trim().min(2).max(120), startsAt: z.string().datetime({ offset: true }),
  endsAt: z.string().datetime({ offset: true }).nullable().optional(),
}).strict();
const nonempty = <T extends z.ZodRawShape>(schema: z.ZodObject<T>) =>
  schema.refine((value) => Object.keys(value).length > 0);

export function adminOnly(jwtSecret: string, database: Db): RequestHandler {
  return authenticated(database, jwtSecret, true);
}

export function createAdminAcademicRouter(database: Db, jwtSecret: string): Router {
  const router = Router();
  router.use(adminOnly(jwtSecret, database));
  const courses = database.collection("academic_courses");
  const classes = database.collection("academic_classes");
  const enrollments = database.collection("academic_enrollments");
  const sessions = database.collection("academic_class_sessions");
  const actor = (response: { locals: Record<string, any> }) => response.locals.adminId as string;

  async function getClass(value: unknown, session?: ClientSession) {
    const code = parse(codeSchema, value);
    const record = await classes.findOne({ code }, { session });
    if (!record) throw new AuthError(404, "class_not_found", "Turma não encontrada.");
    return record;
  }

  async function professorFields(identity: string | null | undefined, session: ClientSession): Promise<Document> {
    if (!identity) return { professorId: null, professorIdentity: null };
    const professor = await database.collection("auth_users").findOne({
      normalizedIdentity: identity.toLowerCase(), profile: "docente", active: true,
    }, { session });
    if (!professor) throw new AuthError(404, "professor_not_found", "Docente ativo não encontrado.");
    return { professorId: String(professor._id), professorIdentity: professor.normalizedIdentity };
  }

  router.get("/courses", async (_request, response) => {
    const counts = await enrollments.aggregate<{ _id: string; count: number }>([
      { $match: { status: "active" } },
      { $group: { _id: { courseCode: "$courseCode", studentId: "$studentId" } } },
      { $group: { _id: "$_id.courseCode", count: { $sum: 1 } } },
    ]).toArray();
    const totals = new Map(counts.map((item) => [item._id, item.count]));
    const records = await courses.find({}).sort({ code: 1 }).toArray();
    response.json(records.map((course) => ({ ...publicRecord(course), studentsCount: totals.get(course.code) ?? 0 })));
  });

  router.get("/courses/:code", async (request, response) => {
    const course = await courses.findOne({ code: parse(codeSchema, request.params.code) });
    if (!course) throw new AuthError(404, "course_not_found", "Curso não encontrado.");
    response.json(publicRecord(course));
  });

  router.post("/courses", async (request, response) => {
    const fields = parse(courseSchema, request.body);
    const result = await adminWrite(database, actor(response), async (session) => {
      if (await courses.findOne({ code: fields.code }, { session })) throw new AuthError(409, "course_exists", "Já existe um curso com esse código.");
      const course = { ...fields, active: true, studentsCount: 0, createdBy: actor(response), createdAt: new Date(), updatedAt: new Date() };
      const inserted = await courses.insertOne(course, { session });
      await audit(database, actor(response), "course_created", fields.code, {}, session);
      return publicRecord({ ...course, _id: inserted.insertedId });
    });
    response.status(201).json(result);
  });

  router.patch("/courses/:code", async (request, response) => {
    const code = parse(codeSchema, request.params.code);
    const fields = parse(nonempty(courseSchema.omit({ code: true }).partial().extend({ active: z.boolean().optional() })), request.body);
    const updated = await adminWrite(database, actor(response), async (session) => {
      const record = await courses.findOneAndUpdate({ code }, { $set: { ...fields, updatedAt: new Date() } }, { session, returnDocument: "after" });
      if (!record) throw new AuthError(404, "course_not_found", "Curso não encontrado.");
      if (fields.name) await classes.updateMany({ courseCode: code }, { $set: { courseName: fields.name } }, { session });
      await audit(database, actor(response), "course_updated", code, {}, session);
      return publicRecord(record);
    });
    response.json(updated);
  });

  router.get("/classes", async (_request, response) => {
    const counts = await enrollments.aggregate<{ _id: string; count: number }>([
      { $match: { status: "active" } }, { $group: { _id: "$classCode", count: { $sum: 1 } } },
    ]).toArray();
    const totals = new Map(counts.map((item) => [item._id, item.count]));
    const records = await classes.find({}).sort({ code: 1 }).toArray();
    response.json(records.map((record) => ({ ...publicRecord(record), enrolled: totals.get(record.code) ?? 0 })));
  });

  router.get("/classes/:classCode", async (request, response) => {
    const record = await getClass(request.params.classCode);
    response.json({ ...publicRecord(record), enrolled: await enrollments.countDocuments({ classCode: record.code, status: "active" }) });
  });

  router.post("/classes", async (request, response) => {
    const fields = parse(classSchema, request.body);
    const result = await adminWrite(database, actor(response), async (session) => {
      const course = await courses.findOne({ code: fields.courseCode, active: { $ne: false } }, { session });
      if (!course) throw new AuthError(404, "course_not_found", "Curso ativo não encontrado.");
      if (await classes.findOne({ code: fields.code }, { session })) throw new AuthError(409, "class_exists", "Já existe uma turma com esse código.");
      const record = { ...fields, formulaRegime: fields.formulaRegime ?? "autonomia_docente",
        ...await professorFields(fields.professorIdentity, session), active: true,
        courseName: course.name, gradeLocked: false, createdBy: actor(response), createdAt: new Date(), updatedAt: new Date() };
      const inserted = await classes.insertOne(record, { session });
      await audit(database, actor(response), "class_created", fields.code, {}, session);
      return { ...publicRecord({ ...record, _id: inserted.insertedId }), enrolled: 0 };
    });
    response.status(201).json(result);
  });

  router.patch("/classes/:classCode", async (request, response) => {
    const fields = parse(nonempty(classSchema.omit({ code: true, courseCode: true }).partial().extend({
      active: z.boolean().optional(), gradeLocked: z.boolean().optional(),
    })), request.body);
    const updated = await adminWrite(database, actor(response), async (session) => {
      const current = await getClass(request.params.classCode, session);
      const enrolled = await enrollments.countDocuments({ classCode: current.code, status: "active" }, { session });
      if (fields.maxCapacity !== undefined && fields.maxCapacity < enrolled) throw new AuthError(409, "capacity_conflict", "A capacidade não pode ser menor que o número de matrículas ativas.");
      const changes: Document = { ...fields, updatedAt: new Date() };
      if ("professorIdentity" in fields) Object.assign(changes, await professorFields(fields.professorIdentity, session));
      const record = await classes.findOneAndUpdate({ _id: current._id }, { $set: changes }, { session, returnDocument: "after" });
      await audit(database, actor(response), "class_updated", current.code, { fields: Object.keys(fields) }, session);
      return { ...publicRecord(record!), enrolled };
    });
    response.json(updated);
  });

  router.get("/classes/:classCode/enrollments", async (request, response) => {
    const classroom = await getClass(request.params.classCode);
    const records = await enrollments.find({ classCode: classroom.code, status: "active" }).sort({ enrolledAt: 1 }).toArray();
    response.json(records.map(publicRecord));
  });

  router.post("/classes/:classCode/enrollments", async (request, response) => {
    const input = parse(z.object({ studentIdentity: z.string().trim().min(1).max(254) }).strict(), request.body);
    const result = await adminWrite(database, actor(response), async (session) => {
      const classroom = await getClass(request.params.classCode, session);
      if (classroom.active === false) throw new AuthError(409, "inactive_class", "Turma inativa.");
      const student = await database.collection("auth_users").findOne({ normalizedIdentity: input.studentIdentity.toLowerCase(), profile: "aluno", active: true }, { session });
      if (!student) throw new AuthError(404, "student_not_found", "Aluno ativo não encontrado.");
      const filter = { classCode: classroom.code, studentId: String(student._id) };
      const existing = await enrollments.findOne(filter, { session });
      if (existing?.status === "active") throw new AuthError(409, "already_enrolled", "Aluno já matriculado nesta turma.");
      if (await enrollments.countDocuments({ classCode: classroom.code, status: "active" }, { session }) >= classroom.maxCapacity) throw new AuthError(409, "class_full", "A turma atingiu a capacidade máxima.");
      const record = { ...filter, courseCode: classroom.courseCode, studentIdentity: student.normalizedIdentity,
        displayName: student.displayName, status: "active", enrolledAt: new Date(), createdBy: actor(response) };
      const saved = await enrollments.findOneAndUpdate(filter, { $set: record }, { upsert: true, session, returnDocument: "after" });
      await audit(database, actor(response), "student_enrolled", classroom.code, { studentId: String(student._id) }, session);
      return publicRecord(saved!);
    });
    response.status(201).json(result);
  });

  router.patch("/classes/:classCode/enrollments/:id", async (request, response) => {
    const id = objectId(request.params.id);
    parse(z.object({ status: z.literal("cancelled") }).strict(), request.body);
    await adminWrite(database, actor(response), async (session) => {
      const classroom = await getClass(request.params.classCode, session);
      const record = await enrollments.findOneAndUpdate({ _id: id, classCode: classroom.code }, { $set: { status: "cancelled", updatedAt: new Date() } }, { session, returnDocument: "after" });
      if (!record) throw new AuthError(404, "enrollment_not_found", "Matrícula não encontrada.");
      await audit(database, actor(response), "enrollment_cancelled", String(id), {}, session);
    });
    response.status(204).end();
  });

  router.get("/classes/:classCode/sessions", async (request, response) => {
    const classroom = await getClass(request.params.classCode);
    response.json((await sessions.find({ classCode: classroom.code }).sort({ startsAt: 1 }).toArray()).map(publicRecord));
  });

  router.post("/classes/:classCode/sessions", async (request, response) => {
    const input = parse(sessionSchema, request.body);
    if (input.endsAt && new Date(input.endsAt) <= new Date(input.startsAt)) throw new AuthError(400, "invalid_dates", "O término deve ser posterior ao início.");
    const record = await adminWrite(database, actor(response), async (session) => {
      const classroom = await getClass(request.params.classCode, session);
      if (classroom.active === false) throw new AuthError(409, "inactive_class", "Turma inativa.");
      const data = { classCode: classroom.code, courseCode: classroom.courseCode, title: input.title,
        startsAt: new Date(input.startsAt), endsAt: input.endsAt ? new Date(input.endsAt) : null,
        cancelled: false, createdBy: actor(response), createdAt: new Date() };
      const result = await sessions.insertOne(data, { session });
      await audit(database, actor(response), "session_created", classroom.code, {}, session);
      return publicRecord({ ...data, _id: result.insertedId });
    });
    response.status(201).json(record);
  });

  router.patch("/classes/:classCode/sessions/:id", async (request, response) => {
    const id = objectId(request.params.id);
    const fields = parse(nonempty(sessionSchema.partial().extend({ cancelled: z.boolean().optional() })), request.body);
    const updated = await adminWrite(database, actor(response), async (session) => {
      const classroom = await getClass(request.params.classCode, session);
      const current = await sessions.findOne({ _id: id, classCode: classroom.code }, { session });
      if (!current) throw new AuthError(404, "session_not_found", "Aula não encontrada.");
      const startsAt = fields.startsAt ? new Date(fields.startsAt) : current.startsAt;
      const endsAt = fields.endsAt === undefined ? current.endsAt : fields.endsAt ? new Date(fields.endsAt) : null;
      if (endsAt && endsAt <= startsAt) throw new AuthError(400, "invalid_dates", "O término deve ser posterior ao início.");
      const record = await sessions.findOneAndUpdate({ _id: id }, { $set: { ...fields, startsAt, endsAt, updatedAt: new Date() } }, { session, returnDocument: "after" });
      await audit(database, actor(response), "session_updated", String(id), {}, session);
      return publicRecord(record!);
    });
    response.json(updated);
  });

  return router;
}
