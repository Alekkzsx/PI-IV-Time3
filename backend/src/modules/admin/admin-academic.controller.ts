// Desenvolvido por Murillo Caravita - RA: 25014012

import { Router, type RequestHandler } from "express";
import { randomBytes } from "node:crypto";
import { ObjectId, type Db, type Document, type ClientSession } from "mongodb";
import jwt, { type JwtPayload } from "jsonwebtoken";
import { z } from "zod";
import { AuthError } from "../../shared/auth-error.js";
import { parse, objectId } from "../../shared/validation.js";
import { authenticated } from "../auth/infrastructure/session.middleware.js";
import { BcryptPasswordHasher } from "../auth/infrastructure/security.providers.js";
import { adminWrite, audit, publicRecord } from "./admin-support.js";

const codeSchema = z.string().trim().min(2).max(32).regex(/^[\p{L}\p{N}._-]+$/u);
const courseSchema = z.object({
  code: codeSchema, name: z.string().trim().min(2).max(120),
  matrix: z.string().trim().min(1).max(80), workload: z.string().trim().min(1).max(40),
  formula: z.string().trim().min(1).max(120), department: z.string().trim().min(1).max(120),
  modality: z.string().trim().min(1).max(60),
  components: z.array(z.record(z.string(), z.unknown())).max(100),
}).strict();

const teacherSchema = z.object({
  name: z.string().trim().min(2).max(120),
  email: z.string().trim().email().max(254),
  department: z.string().trim().min(2).max(120),
});

const professorAssignmentSchema = z.object({
  professorIdentity: z.string().trim().min(1).max(254),
});

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
  const fullAuth = authenticated(database, jwtSecret, true);
  return (request, response, next) => {
    const authorization = request.header("authorization");
    if (!authorization?.startsWith("Bearer ")) {
      next(new AuthError(401, "authentication_required", "Autenticação necessária."));
      return;
    }
    const token = authorization.slice("Bearer ".length);
    try {
      const claims = jwt.decode(token) as JwtPayload | null;
      if (claims && typeof claims === "object" && typeof claims.jti === "string" && Number.isInteger(claims.ver)) {
        return fullAuth(request, response, next);
      }
    } catch {
      // fallback to basic token verification
    }

    let claims: string | JwtPayload;
    try {
      claims = jwt.verify(token, jwtSecret, { algorithms: ["HS256"] });
    } catch {
      next(new AuthError(401, "invalid_token", "Sessão inválida ou expirada."));
      return;
    }

    if (
      typeof claims === "string" ||
      typeof claims.sub !== "string" ||
      typeof claims.profile !== "string"
    ) {
      next(new AuthError(401, "invalid_token", "Sessão inválida ou expirada."));
      return;
    }
    if (claims.profile !== "admin") {
      next(new AuthError(403, "forbidden", "Ação permitida somente ao administrador."));
      return;
    }

    response.locals.adminId = claims.sub;
    next();
  };
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

  router.get("/teachers", async (_request, response) => {
    const records = await database
      .collection("auth_users")
      .find({ profile: "docente" })
      .project({
        identity: 1,
        email: 1,
        displayName: 1,
        department: 1,
        active: 1,
      })
      .sort({ normalizedIdentity: 1 })
      .toArray();
    response.status(200).json(
      records.map((record) => ({
        identity: record.identity,
        email: record.email,
        name: record.displayName,
        department: record.department ?? "",
        active: record.active === true,
        profile: "docente",
      })),
    );
  });

  router.post("/teachers", async (request, response) => {
    const parsed = teacherSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Dados do docente inválidos.");
    }

    const users = database.collection("auth_users");
    const email = parsed.data.email.toLowerCase();
    const existingEmail = await users.findOne({
      email: { $regex: `^${escapeRegExp(email)}$`, $options: "i" },
    });
    if (existingEmail) {
      throw new AuthError(409, "email_exists", "Já existe uma conta com esse e-mail.");
    }

    const identity = `DOC-${randomBytes(5).toString("hex").toUpperCase()}`;
    const passwordHash = await new BcryptPasswordHasher().hash(
      randomBytes(32).toString("base64url"),
    );
    const teacher = {
      identity,
      normalizedIdentity: identity.toLowerCase(),
      email,
      displayName: parsed.data.name,
      profile: "docente",
      passwordHash,
      active: true,
      department: parsed.data.department,
      createdBy: actor(response),
      createdAt: new Date(),
    };

    try {
      await users.insertOne(teacher);
    } catch (error) {
      if (
        error &&
        typeof error === "object" &&
        "code" in error &&
        error.code === 11000
      ) {
        throw new AuthError(
          409,
          "identity_exists",
          "Não foi possível gerar uma identidade única. Tente novamente.",
        );
      }
      throw error;
    }

    response.status(201).json({
      identity,
      name: teacher.displayName,
      email: teacher.email,
      department: teacher.department,
      profile: teacher.profile,
    });
  });

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
    const fields = parse(nonempty(courseSchema.partial()), request.body);
    const updated = await adminWrite(database, actor(response), async (session) => {
      const code = parse(codeSchema, request.params.code);
      if (fields.code && fields.code !== code && await courses.findOne({ code: fields.code }, { session })) {
        throw new AuthError(409, "course_exists", "Já existe um curso com esse código.");
      }
      const record = await courses.findOneAndUpdate({ code }, { $set: { ...fields, updatedAt: new Date() } }, { session, returnDocument: "after" });
      if (!record) throw new AuthError(404, "course_not_found", "Curso não encontrado.");
      await audit(database, actor(response), "course_updated", code, fields, session);
      return publicRecord(record);
    });
    response.json(updated);
  });

  router.get("/classes", async (request, response) => {
    const query: Document = {};
    if (request.query.courseCode) query.courseCode = parse(codeSchema, request.query.courseCode);
    const records = await classes.find(query).sort({ code: 1 }).toArray();
    const enrolled = await enrollments.aggregate<{ _id: string; count: number }>([
      { $match: { status: "active" } },
      { $group: { _id: "$classCode", count: { $sum: 1 } } },
    ]).toArray();
    const map = new Map(enrolled.map((item) => [item._id, item.count]));
    response.json(records.map((c) => ({ ...publicRecord(c), enrolled: map.get(c.code) ?? 0 })));
  });

  router.get("/classes/:code", async (request, response) => {
    const classroom = await getClass(request.params.code);
    const count = await enrollments.countDocuments({ classCode: classroom.code, status: "active" });
    response.json({ ...publicRecord(classroom), enrolled: count });
  });

  router.post("/classes", async (request, response) => {
    const fields = parse(classSchema, request.body);
    const result = await adminWrite(database, actor(response), async (session) => {
      if (await classes.findOne({ code: fields.code }, { session })) throw new AuthError(409, "class_exists", "Já existe uma turma com esse código.");
      const course = await courses.findOne({ code: fields.courseCode, active: true }, { session });
      if (!course) throw new AuthError(404, "course_not_found", "Curso associado não encontrado.");
      const prof = await professorFields(fields.professorIdentity, session);
      const data = { ...fields, ...prof, subjectName: fields.subjectName ?? course.name, courseName: course.name,
        active: true, formulaRegime: fields.formulaRegime ?? "autonomia_docente", createdBy: actor(response),
        createdAt: new Date(), updatedAt: new Date() };
      const inserted = await classes.insertOne(data, { session });
      await audit(database, actor(response), "class_created", fields.code, {}, session);
      return publicRecord({ ...data, _id: inserted.insertedId });
    });
    response.status(201).json({ ...result, enrolled: 0 });
  });

  router.patch("/classes/:classCode/professor", async (request, response) => {
    const parsed = professorAssignmentSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Identidade do docente inválida.");
    }

    const classRecord = await classes.findOne({
      code: request.params.classCode,
    });
    if (!classRecord) {
      throw new AuthError(404, "class_not_found", "Turma não encontrada.");
    }

    const normalizedIdentity = parsed.data.professorIdentity.toLowerCase();
    const professor = await database.collection("auth_users").findOne({
      normalizedIdentity,
      profile: "docente",
      active: true,
    });
    if (!professor) {
      throw new AuthError(404, "professor_not_found", "Docente ativo não encontrado.");
    }

    await classes.updateOne(
      { code: classRecord.code },
      {
        $set: {
          professorId: professor._id.toString(),
          professorIdentity: professor.normalizedIdentity,
          updatedAt: new Date(),
        },
      },
    );
    response.status(200).json({
      classCode: classRecord.code,
      professorIdentity: professor.normalizedIdentity,
    });
  });

  router.patch("/classes/:code", async (request, response) => {
    const fields = parse(nonempty(classSchema.partial()), request.body);
    const updated = await adminWrite(database, actor(response), async (session) => {
      const code = parse(codeSchema, request.params.code);
      if (fields.code && fields.code !== code && await classes.findOne({ code: fields.code }, { session })) {
        throw new AuthError(409, "class_exists", "Já existe uma turma com esse código.");
      }
      if (fields.courseCode) {
        const course = await courses.findOne({ code: fields.courseCode, active: true }, { session });
        if (!course) throw new AuthError(404, "course_not_found", "Curso associado não encontrado.");
      }
      const prof = fields.professorIdentity !== undefined ? await professorFields(fields.professorIdentity, session) : {};
      const record = await classes.findOneAndUpdate({ code }, { $set: { ...fields, ...prof, updatedAt: new Date() } }, { session, returnDocument: "after" });
      if (!record) throw new AuthError(404, "class_not_found", "Turma não encontrada.");
      await audit(database, actor(response), "class_updated", code, fields, session);
      return publicRecord(record);
    });
    const count = await enrollments.countDocuments({ classCode: updated.code, status: "active" });
    response.json({ ...updated, enrolled: count });
  });

  router.get("/classes/:classCode/enrollments", async (request, response) => {
    const classroom = await getClass(request.params.classCode);
    const records = await enrollments.find({ classCode: classroom.code, status: "active" }).sort({ displayName: 1 }).toArray();
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

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
