// Desenvolvido por Murillo Caravita - RA: 25014012

import { Router, type RequestHandler } from "express";
import { type Db, type Document } from "mongodb";
import jwt, { type JwtPayload } from "jsonwebtoken";
import { z } from "zod";
import { AuthError } from "../../shared/auth-error.js";

interface AcademicCourseDocument extends Document {
  code: string;
  name: string;
  matrix: string;
  workload: string;
  studentsCount: number;
  formula: string;
  department: string;
  modality: string;
  components: Record<string, unknown>[];
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}

interface AcademicClassDocument extends Document {
  code: string;
  courseCode: string;
  courseName: string;
  semester: string;
  shift: string;
  location: string;
  maxCapacity: number;
  professorId?: string;
  professorIdentity?: string;
  formulaRegime: string;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}

const courseSchema = z.object({
  code: z.string().trim().min(2).max(32),
  name: z.string().trim().min(2).max(120),
  matrix: z.string().trim().min(1).max(80),
  workload: z.string().trim().min(1).max(40),
  formula: z.string().trim().min(1).max(120),
  department: z.string().trim().min(1).max(120),
  modality: z.string().trim().min(1).max(60),
  components: z.array(z.record(z.string(), z.unknown())).max(100),
});

const classSchema = z.object({
  code: z.string().trim().min(2).max(32),
  courseCode: z.string().trim().min(2).max(32),
  semester: z.string().trim().min(3).max(40),
  shift: z.string().trim().min(2).max(40),
  location: z.string().trim().min(2).max(100),
  maxCapacity: z.number().int().min(1).max(500),
  professorIdentity: z.string().trim().min(1).max(254).optional(),
  formulaRegime: z.enum(["admin", "autonomia_docente"]).default("autonomia_docente"),
});

const enrollmentSchema = z.object({
  studentIdentity: z.string().trim().min(1).max(254),
});

const classSessionSchema = z.object({
  title: z.string().trim().min(2).max(120),
  startsAt: z.string().datetime({ offset: true }),
  endsAt: z.string().datetime({ offset: true }).optional(),
});

export function createAdminAcademicRouter(
  database: Db,
  jwtSecret: string,
): Router {
  const router = Router();
  const courses = database.collection<AcademicCourseDocument>("academic_courses");
  const classes = database.collection<AcademicClassDocument>("academic_classes");
  const enrollments = database.collection("academic_enrollments");
  const sessions = database.collection("academic_class_sessions");
  const requireAdmin = adminOnly(jwtSecret);

  router.get("/courses", requireAdmin, async (_request, response) => {
    const records = await courses.find({}).sort({ code: 1 }).toArray();
    response.status(200).json(
      records.map(({ _id, ...course }) => ({ id: _id.toString(), ...course })),
    );
  });

  router.post("/courses", requireAdmin, async (request, response) => {
    const parsed = courseSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Dados do curso inválidos.");
    }

    const now = new Date();
    const course = {
      ...parsed.data,
      studentsCount: 0,
      createdBy: response.locals.adminId as string,
      createdAt: now,
      updatedAt: now,
    };

    try {
      const result = await courses.insertOne(course);
      response.status(201).json({ id: result.insertedId.toString(), ...course });
    } catch (error) {
      if (
        error &&
        typeof error === "object" &&
        "code" in error &&
        error.code === 11000
      ) {
        throw new AuthError(409, "course_exists", "Já existe um curso com esse código.");
      }
      throw error;
    }
  });

  router.get("/classes", requireAdmin, async (_request, response) => {
    const records = await classes.find({}).sort({ code: 1 }).toArray();
    const classCodes = records.map((record) => record.code);
    const counts = await enrollments
      .aggregate<{ _id: string; count: number }>([
        { $match: { classCode: { $in: classCodes }, status: "active" } },
        { $group: { _id: "$classCode", count: { $sum: 1 } } },
      ])
      .toArray();
    const enrollmentCounts = new Map(counts.map((entry) => [entry._id, entry.count]));

    response.status(200).json(
      records.map(({ _id, ...classRecord }) => ({
        id: _id.toString(),
        ...classRecord,
        enrolled: enrollmentCounts.get(classRecord.code) ?? 0,
      })),
    );
  });

  router.post("/classes", requireAdmin, async (request, response) => {
    const parsed = classSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Dados da turma inválidos.");
    }

    const course = await courses.findOne({ code: parsed.data.courseCode });
    if (!course) {
      throw new AuthError(404, "course_not_found", "Curso não encontrado.");
    }

    const normalizedProfessorIdentity = parsed.data.professorIdentity
      ?.trim()
      .toLowerCase();
    const professor = normalizedProfessorIdentity
      ? await database.collection("auth_users").findOne({
          normalizedIdentity: normalizedProfessorIdentity,
          profile: "docente",
          active: true,
        })
      : null;
    if (normalizedProfessorIdentity && !professor) {
      throw new AuthError(404, "professor_not_found", "Docente ativo não encontrado.");
    }

    const now = new Date();
    const classRecord = {
      ...parsed.data,
      courseName: course.name,
      professorId: professor?._id.toString(),
      professorIdentity: professor?.normalizedIdentity,
      createdBy: response.locals.adminId as string,
      createdAt: now,
      updatedAt: now,
    };

    try {
      const result = await classes.insertOne(classRecord);
      response.status(201).json({ id: result.insertedId.toString(), ...classRecord, enrolled: 0 });
    } catch (error) {
      if (
        error &&
        typeof error === "object" &&
        "code" in error &&
        error.code === 11000
      ) {
        throw new AuthError(409, "class_exists", "Já existe uma turma com esse código.");
      }
      throw error;
    }
  });

  router.get("/classes/:classCode/enrollments", requireAdmin, async (request, response) => {
    const records = await enrollments
      .find({ classCode: request.params.classCode, status: "active" })
      .sort({ enrolledAt: 1 })
      .toArray();
    response.status(200).json(
      records.map(({ _id, ...enrollment }) => ({ id: _id.toString(), ...enrollment })),
    );
  });

  router.post("/classes/:classCode/enrollments", requireAdmin, async (request, response) => {
    const parsed = enrollmentSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Identidade do aluno inválida.");
    }

    const classRecord = await classes.findOne({ code: request.params.classCode });
    if (!classRecord) {
      throw new AuthError(404, "class_not_found", "Turma não encontrada.");
    }
    const normalizedIdentity = parsed.data.studentIdentity.toLowerCase();
    const student = await database.collection("auth_users").findOne({
      normalizedIdentity,
      profile: "aluno",
      active: true,
    });
    if (!student) {
      throw new AuthError(404, "student_not_found", "Aluno ativo não encontrado.");
    }

    const currentCount = await enrollments.countDocuments({
      classCode: classRecord.code,
      status: "active",
    });
    if (currentCount >= classRecord.maxCapacity) {
      throw new AuthError(409, "class_full", "A turma atingiu a capacidade máxima.");
    }

    const enrollment = {
      classCode: classRecord.code,
      courseCode: classRecord.courseCode,
      studentId: student._id.toString(),
      studentIdentity: student.normalizedIdentity,
      displayName: student.displayName,
      status: "active",
      enrolledAt: new Date(),
      createdBy: response.locals.adminId as string,
    };
    try {
      const result = await enrollments.insertOne(enrollment);
      response.status(201).json({ id: result.insertedId.toString(), ...enrollment });
    } catch (error) {
      if (
        error &&
        typeof error === "object" &&
        "code" in error &&
        error.code === 11000
      ) {
        throw new AuthError(409, "already_enrolled", "Aluno já matriculado nesta turma.");
      }
      throw error;
    }
  });

  router.get("/classes/:classCode/sessions", requireAdmin, async (request, response) => {
    const records = await sessions
      .find({ classCode: request.params.classCode })
      .sort({ startsAt: 1 })
      .toArray();
    response.status(200).json(
      records.map(({ _id, ...session }) => ({ id: _id.toString(), ...session })),
    );
  });

  router.post("/classes/:classCode/sessions", requireAdmin, async (request, response) => {
    const parsed = classSessionSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Dados da aula inválidos.");
    }
    const classRecord = await classes.findOne({ code: request.params.classCode });
    if (!classRecord) {
      throw new AuthError(404, "class_not_found", "Turma não encontrada.");
    }

    const session = {
      classCode: classRecord.code,
      courseCode: classRecord.courseCode,
      title: parsed.data.title,
      startsAt: new Date(parsed.data.startsAt),
      endsAt: parsed.data.endsAt ? new Date(parsed.data.endsAt) : null,
      createdBy: response.locals.adminId as string,
      createdAt: new Date(),
    };
    const result = await sessions.insertOne(session);
    response.status(201).json({ id: result.insertedId.toString(), ...session });
  });

  return router;
}

function adminOnly(jwtSecret: string): RequestHandler {
  return (request, response, next) => {
    const authorization = request.header("authorization");
    const token = authorization?.startsWith("Bearer ")
      ? authorization.slice("Bearer ".length)
      : undefined;

    if (!token) {
      next(new AuthError(401, "authentication_required", "Autenticação necessária."));
      return;
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