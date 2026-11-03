// Desenvolvido por Murillo Caravita - RA: 25014012

import { Router } from "express";
import { randomBytes } from "node:crypto";
import { ObjectId, type Db, type Document, type ClientSession } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../../shared/auth-error.js";
import { parse, objectId } from "../../../shared/validation.js";
import { BcryptPasswordHasher } from "../../auth/infrastructure/security.providers.js";
import { adminOnly } from "../infrastructure/admin-auth.middleware.js";
import { adminWrite, audit, publicRecord } from "../infrastructure/admin-support.js";

const codeSchema = z.string().trim().min(2).max(60).regex(/^[\p{L}\p{N}._\-\s]+$/u);
const courseSchema = z.object({
  code: codeSchema,
  name: z.string().trim().min(2).max(120),
  matrix: z.string().trim().min(1).max(80),
  workload: z.string().trim().min(1).max(40),
  formula: z.string().trim().min(1).max(120),
  department: z.string().trim().min(1).max(120),
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
  code: codeSchema,
  courseCode: codeSchema,
  semester: z.string().trim().min(3).max(60),
  shift: z.string().trim().min(2).max(40),
  location: z.string().trim().min(2).max(100),
  schedule: z.string().trim().max(120).optional(),
  totalHours: z.number().int().min(10).max(400).optional(),
  maxCapacity: z.number().int().min(1).max(500),
  professorIdentity: z.string().trim().min(1).max(254).nullable().optional(),
  formulaRegime: z.enum(["admin", "autonomia_docente"]).optional(),
  evaluationFormula: z.string().trim().max(200).optional(),
  justificationNote: z.string().trim().max(1000).optional(),
  gradeLocked: z.boolean().optional(),
  pautaHomologated: z.boolean().optional(),
  subjectName: z.string().trim().min(2).max(120).optional(),
}).strict();

const sessionSchema = z.object({
  title: z.string().trim().min(2).max(120),
  startsAt: z.string().datetime({ offset: true }),
  endsAt: z.string().datetime({ offset: true }).nullable().optional(),
}).strict();

const nonempty = <T extends z.ZodRawShape>(schema: z.ZodObject<T>) =>
  schema.refine((value) => Object.keys(value).length > 0);

export function createAdminAcademicRouter(database: Db, jwtSecret: string): Router {
  const router = Router();
  router.use(adminOnly(jwtSecret, database));
  const courses = database.collection("academic_courses");
  const classes = database.collection("academic_classes");
  const enrollments = database.collection("academic_enrollments");
  const sessions = database.collection("academic_class_sessions");
  const grades = database.collection("academic_grades");
  const liveSessions = database.collection("academic_live_sessions");
  const actor = (response: { locals: Record<string, unknown> }) => response.locals.adminId as string;

  async function getClass(value: unknown, session?: ClientSession) {
    const code = parse(codeSchema, value);
    const record = await classes.findOne({ code }, { session });
    if (!record) throw new AuthError(404, "class_not_found", "Turma não encontrada.");
    return record;
  }

  async function professorFields(identity: string | null | undefined, session?: ClientSession): Promise<Document> {
    if (!identity) return { professorId: null, professorIdentity: null, professorName: null };
    const normalized = identity.trim().toLowerCase();
    const professor = await database.collection("auth_users").findOne(
      {
        $or: [
          { normalizedIdentity: normalized },
          { email: normalized },
          { displayName: { $regex: `^${escapeRegExp(identity.trim())}$`, $options: "i" } },
        ],
        profile: "docente",
        active: true,
      },
      session ? { session } : undefined,
    );
    if (!professor) throw new AuthError(404, "professor_not_found", "Docente ativo não encontrado.");
    return {
      professorId: String(professor._id),
      professorIdentity: professor.normalizedIdentity,
      professorName: professor.displayName,
    };
  }

  async function enrichClassList(records: Document[]) {
    if (records.length === 0) return [];
    const codes = records.map((c) => c.code);
    const activeEnrollments = await enrollments
      .find({ classCode: { $in: codes }, status: "active" })
      .toArray();
    const profIds = Array.from(
      new Set(
        records
          .map((c) => (typeof c.professorId === "string" && ObjectId.isValid(c.professorId) ? c.professorId : null))
          .filter(Boolean) as string[],
      ),
    );
    const profDocs =
      profIds.length > 0
        ? await database
            .collection("auth_users")
            .find({ _id: { $in: profIds.map((id) => new ObjectId(id)) } })
            .toArray()
        : [];
    const profMap = new Map(profDocs.map((p) => [String(p._id), p]));
    const activeRooms = await liveSessions.find({ expiresAt: { $gt: new Date() } }).toArray();
    const liveSet = new Set(activeRooms.map((r) => String(r.classCode ?? r.roomCode).toUpperCase()));

    const byClass = new Map<string, Document[]>();
    for (const entry of activeEnrollments) {
      const list = byClass.get(entry.classCode) ?? [];
      list.push(entry);
      byClass.set(entry.classCode, list);
    }

    return records.map((c) => {
      const classEnrollments = byClass.get(c.code) ?? [];
      const profDoc = c.professorId ? profMap.get(String(c.professorId)) : undefined;
      return {
        ...publicRecord(c),
        subjectName: c.subjectName ?? c.courseName ?? c.code,
        courseName: c.courseName ?? c.subjectName ?? c.courseCode,
        professorName: c.professorName ?? profDoc?.displayName ?? c.professorIdentity ?? "Não alocado",
        enrolled: classEnrollments.length,
        enrolledStudentRas: classEnrollments.map((e) => String(e.studentIdentity ?? "")),
        enrolledStudents: classEnrollments.map((e) => ({
          enrollmentId: String(e._id),
          studentId: String(e.studentId),
          identity: String(e.studentIdentity ?? ""),
          displayName: String(e.displayName ?? e.studentIdentity ?? ""),
          enrolledAt: e.enrolledAt ?? null,
        })),
        isLive: liveSet.has(String(c.code).toUpperCase()),
      };
    });
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
        departmentOrCourse: 1,
        active: 1,
      })
      .sort({ normalizedIdentity: 1 })
      .toArray();
    response.status(200).json(
      records.map((record) => ({
        id: String(record._id),
        identity: record.identity,
        email: record.email,
        name: record.displayName,
        department: record.department ?? record.departmentOrCourse ?? "",
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
      departmentOrCourse: parsed.data.department,
      createdBy: actor(response),
      createdAt: new Date(),
    };

    try {
      await users.insertOne(teacher);
    } catch (error) {
      if (error && typeof error === "object" && "code" in error && error.code === 11000) {
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
    const records = await courses.find({ active: { $ne: false } }).sort({ code: 1 }).toArray();
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
      if (await courses.findOne({ code: fields.code }, { session })) {
        throw new AuthError(409, "course_exists", "Já existe um curso com esse código.");
      }
      const course = {
        ...fields,
        active: true,
        studentsCount: 0,
        createdBy: actor(response),
        createdAt: new Date(),
        updatedAt: new Date(),
      };
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
      const record = await courses.findOneAndUpdate(
        { code },
        { $set: { ...fields, updatedAt: new Date() } },
        { session, returnDocument: "after" },
      );
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
    response.json(await enrichClassList(records));
  });

  router.get("/classes/:code", async (request, response) => {
    const classroom = await getClass(request.params.code);
    const enriched = await enrichClassList([classroom]);
    response.json(enriched[0]);
  });

  router.get("/classes/:classCode/grades", async (request, response) => {
    const classroom = await getClass(request.params.classCode);
    const [classEnrollments, classGrades] = await Promise.all([
      enrollments.find({ classCode: classroom.code, status: "active" }).sort({ displayName: 1 }).toArray(),
      grades.find({ classCode: classroom.code }).toArray(),
    ]);
    const gradeByStudent = new Map(classGrades.map((g) => [String(g.studentId), g]));
    const rows = classEnrollments.map((enrollment) => {
      const g = gradeByStudent.get(String(enrollment.studentId));
      const assignmentsScore = Number(g?.assignmentsScore ?? 0);
      const p1Score = Number(g?.p1Score ?? 0);
      const projectsScore = Number(g?.projectsScore ?? 0);
      const p2Score = Number(g?.p2Score ?? 0);
      const n1 = Number((assignmentsScore * 0.4 + p1Score * 0.6).toFixed(1));
      const n2 = Number((projectsScore * 0.4 + p2Score * 0.6).toFixed(1));
      const finalAverage = Number((n1 * 0.4 + n2 * 0.6).toFixed(1));
      return {
        studentId: String(enrollment.studentId),
        ra: String(enrollment.studentIdentity ?? ""),
        studentName: String(enrollment.displayName ?? enrollment.studentIdentity ?? ""),
        assignmentsScore,
        p1Score,
        projectsScore,
        p2Score,
        n1,
        n2,
        finalAverage,
        attendanceRate: Number(g?.attendanceRate ?? enrollment.attendanceRate ?? 100),
        absences: Number(g?.absences ?? enrollment.absences ?? 0),
        hasGrades: Boolean(g),
      };
    });
    response.json({
      classCode: classroom.code,
      subjectName: classroom.subjectName ?? classroom.courseName ?? classroom.code,
      formulaRegime: classroom.formulaRegime ?? "autonomia_docente",
      evaluationFormula: classroom.evaluationFormula ?? "(N1 × 0.4) + (N2 × 0.6)",
      gradeLocked: classroom.gradeLocked === true,
      pautaHomologated: classroom.pautaHomologated === true,
      chancelaCode: classroom.chancelaCode ?? null,
      grades: rows,
    });
  });

  router.post("/classes", async (request, response) => {
    const fields = parse(classSchema, request.body);
    const result = await adminWrite(database, actor(response), async (session) => {
      if (await classes.findOne({ code: fields.code }, { session })) {
        throw new AuthError(409, "class_exists", "Já existe uma turma com esse código.");
      }
      const course = await courses.findOne({ code: fields.courseCode, active: { $ne: false } }, { session });
      if (!course) throw new AuthError(404, "course_not_found", "Curso associado não encontrado.");
      const prof = await professorFields(fields.professorIdentity, session);
      const data = {
        ...fields,
        ...prof,
        subjectName: fields.subjectName ?? course.name,
        courseName: course.name,
        schedule: fields.schedule ?? "Segundas e Quartas, 19:00 - 20:40",
        totalHours: fields.totalHours ?? 80,
        completedHours: 0,
        active: true,
        gradeLocked: fields.gradeLocked ?? false,
        pautaHomologated: false,
        formulaRegime: fields.formulaRegime ?? "autonomia_docente",
        evaluationFormula: fields.evaluationFormula ?? course.formula ?? "(N1 × 0.4) + (N2 × 0.6)",
        createdBy: actor(response),
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      const inserted = await classes.insertOne(data, { session });
      await audit(database, actor(response), "class_created", fields.code, {}, session);
      return publicRecord({ ...data, _id: inserted.insertedId });
    });
    response.status(201).json({ ...result, enrolled: 0, enrolledStudentRas: [], enrolledStudents: [] });
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

    const prof = await professorFields(parsed.data.professorIdentity);
    await classes.updateOne(
      { code: classRecord.code },
      {
        $set: {
          ...prof,
          updatedAt: new Date(),
        },
      },
    );
    await audit(database, actor(response), "professor_assigned", classRecord.code, {
      professorIdentity: prof.professorIdentity,
    });
    response.status(200).json({
      classCode: classRecord.code,
      professorIdentity: prof.professorIdentity,
      professorName: prof.professorName,
    });
  });

  router.patch("/classes/:code", async (request, response) => {
    const fields = parse(nonempty(classSchema.partial()), request.body);
    const updated = await adminWrite(database, actor(response), async (session) => {
      const code = parse(codeSchema, request.params.code);
      const before = await classes.findOne({ code }, { session });
      if (!before) throw new AuthError(404, "class_not_found", "Turma não encontrada.");
      if (fields.code && fields.code !== code && await classes.findOne({ code: fields.code }, { session })) {
        throw new AuthError(409, "class_exists", "Já existe uma turma com esse código.");
      }
      if (fields.courseCode) {
        const course = await courses.findOne({ code: fields.courseCode, active: { $ne: false } }, { session });
        if (!course) throw new AuthError(404, "course_not_found", "Curso associado não encontrado.");
      }
      const prof = fields.professorIdentity !== undefined ? await professorFields(fields.professorIdentity, session) : {};
      const chancelaUpdate =
        fields.gradeLocked === true && !before.chancelaCode
          ? {
              pautaHomologated: true,
              chancelaCode: `AGR-CHANC-${randomBytes(3).toString("hex").toUpperCase()}`,
              lockedAt: new Date(),
              lockedBy: actor(response),
            }
          : {};
      const record = await classes.findOneAndUpdate(
        { code },
        { $set: { ...fields, ...prof, ...chancelaUpdate, updatedAt: new Date() } },
        { session, returnDocument: "after" },
      );
      if (!record) throw new AuthError(404, "class_not_found", "Turma não encontrada.");
      await audit(database, actor(response), "class_updated", code, fields, session);
      return record;
    });
    const enriched = await enrichClassList([updated]);
    response.json(enriched[0]);
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
      const normalized = input.studentIdentity.toLowerCase();
      const student = await database
        .collection("auth_users")
        .findOne(
          {
            $or: [{ normalizedIdentity: normalized }, { email: normalized }],
            profile: "aluno",
            active: true,
          },
          { session },
        );
      if (!student) throw new AuthError(404, "student_not_found", "Aluno ativo não encontrado.");
      const filter = { classCode: classroom.code, studentId: String(student._id) };
      const existing = await enrollments.findOne(filter, { session });
      if (existing?.status === "active") throw new AuthError(409, "already_enrolled", "Aluno já matriculado nesta turma.");
      if (await enrollments.countDocuments({ classCode: classroom.code, status: "active" }, { session }) >= classroom.maxCapacity) {
        throw new AuthError(409, "class_full", "A turma atingiu a capacidade máxima.");
      }
      const record = {
        ...filter,
        courseCode: classroom.courseCode,
        studentIdentity: student.normalizedIdentity,
        displayName: student.displayName,
        status: "active",
        enrolledAt: new Date(),
        createdBy: actor(response),
      };
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
      const record = await enrollments.findOneAndUpdate(
        { _id: id, classCode: classroom.code },
        { $set: { status: "cancelled", updatedAt: new Date() } },
        { session, returnDocument: "after" },
      );
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
    if (input.endsAt && new Date(input.endsAt) <= new Date(input.startsAt)) {
      throw new AuthError(400, "invalid_dates", "O término deve ser posterior ao início.");
    }
    const record = await adminWrite(database, actor(response), async (session) => {
      const classroom = await getClass(request.params.classCode, session);
      if (classroom.active === false) throw new AuthError(409, "inactive_class", "Turma inativa.");
      const sessionCount = await sessions.countDocuments({ classCode: classroom.code }, { session });
      const data = {
        classCode: classroom.code,
        courseCode: classroom.courseCode,
        sessionNumber: sessionCount + 1,
        hours: 2,
        title: input.title,
        contentProgram: input.title,
        methodology: "Aula expositiva e prática orientada.",
        location: classroom.location ?? "Sala Virtual",
        isHomologated: false,
        attendanceList: [],
        startsAt: new Date(input.startsAt),
        endsAt: input.endsAt ? new Date(input.endsAt) : null,
        cancelled: false,
        createdBy: actor(response),
        createdAt: new Date(),
      };
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
      const record = await sessions.findOneAndUpdate(
        { _id: id },
        { $set: { ...fields, startsAt, endsAt, updatedAt: new Date() } },
        { session, returnDocument: "after" },
      );
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
