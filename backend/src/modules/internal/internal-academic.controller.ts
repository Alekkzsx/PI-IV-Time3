// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { timingSafeEqual } from "node:crypto";
import { Router, type RequestHandler } from "express";
import { ObjectId, type Collection, type Db, type Document } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../shared/auth-error.js";
import { sanitizeRoomCode } from "../../shared/formatting/room-code.js";
import { parse } from "../../shared/validation.js";

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function internalServiceOnly(internalSecret: string): RequestHandler {
  return (request, _response, next) => {
    const provided = request.header("x-internal-service-secret")?.trim() ?? "";
    if (!internalSecret || !provided) {
      next(new AuthError(401, "internal_auth_required", "Credencial interna ausente."));
      return;
    }
    const expectedBuf = Buffer.from(internalSecret, "utf8");
    const providedBuf = Buffer.from(provided, "utf8");
    if (
      expectedBuf.length !== providedBuf.length ||
      !timingSafeEqual(expectedBuf, providedBuf)
    ) {
      next(new AuthError(403, "internal_forbidden", "Credencial interna inválida."));
      return;
    }
    next();
  };
}

async function findClassByRoomCode(
  classes: Collection<Document>,
  rawRoomCode: string,
): Promise<Document | null> {
  const trimmed = rawRoomCode.trim();
  const sanitized = sanitizeRoomCode(trimmed);
  const direct = await classes.findOne({
    code: { $regex: `^${escapeRegExp(trimmed)}$`, $options: "i" },
  });
  if (direct) return direct;

  if (sanitized !== trimmed.toUpperCase()) {
    const bySanitized = await classes.findOne({
      code: { $regex: `^${escapeRegExp(sanitized)}$`, $options: "i" },
    });
    if (bySanitized) return bySanitized;
  }

  if (typeof classes.find === "function") {
    const allClasses = await classes.find({ active: { $ne: false } }).toArray();
    return (
      allClasses.find((item) => {
        const itemSanitized = sanitizeRoomCode(String(item.code ?? ""));
        return (
          itemSanitized === sanitized ||
          itemSanitized.endsWith(`-${sanitized}`) ||
          sanitized.endsWith(`-${itemSanitized}`)
        );
      }) ?? null
    );
  }
  return null;
}

/**
 * Ponte HTTP interna protegida para o servidor Java (:8080) consultar vínculos acadêmicos,
 * autorizar/sincronizar videochamadas e agregar dados acadêmicos para dossiê/LGPD.
 */
export function createInternalAcademicRouter(
  database: Db,
  internalSecret: string,
): Router {
  const router = Router();
  const classes = database.collection("academic_classes");
  const enrollments = database.collection("academic_enrollments");
  const classSessions = database.collection("academic_class_sessions");

  router.use(internalServiceOnly(internalSecret));

  router.get("/video-call/rooms", async (request, response) => {
    const query = parse(
      z.object({
        userId: z.string().trim().min(1).max(120),
        profile: z.enum(["aluno", "docente", "admin"]),
        identity: z.string().trim().max(254).optional(),
      }),
      request.query,
    );

    const normalizedIdentity = (query.identity ?? "").trim().toLowerCase();
    let classList: Document[] = [];

    if (query.profile === "admin") {
      classList = await classes
        .find({ active: { $ne: false } })
        .sort({ code: 1 })
        .toArray();
    } else if (query.profile === "docente") {
      const orFilters: Document[] = [{ professorId: query.userId }];
      if (normalizedIdentity) {
        orFilters.push({ professorIdentity: normalizedIdentity });
      }
      classList = await classes
        .find({
          active: { $ne: false },
          $or: orFilters,
        })
        .sort({ code: 1 })
        .toArray();
    } else {
      const userEnrollments = await enrollments
        .find({ studentId: query.userId, status: "active" })
        .toArray();
      const codes = userEnrollments.map((entry) => entry.classCode);
      if (codes.length > 0) {
        classList = await classes
          .find({ code: { $in: codes }, active: { $ne: false } })
          .sort({ code: 1 })
          .toArray();
      }
    }

    response.json(
      classList.map((classroom) => ({
        roomCode: sanitizeRoomCode(String(classroom.code)),
        classCode: String(classroom.code),
        title: String(classroom.subjectName ?? classroom.courseName ?? classroom.code),
        courseName: String(classroom.courseName ?? ""),
        semester: String(classroom.semester ?? ""),
        shift: String(classroom.shift ?? ""),
        location: String(classroom.location ?? ""),
        professorId: classroom.professorId ?? null,
        professorIdentity: classroom.professorIdentity ?? null,
        professorName: classroom.professorName ?? classroom.professorIdentity ?? "Docente",
      })),
    );
  });

  router.get("/video-call/authorize", async (request, response) => {
    const query = parse(
      z.object({
        userId: z.string().trim().min(1).max(120),
        profile: z.enum(["aluno", "docente", "admin"]),
        identity: z.string().trim().max(254).optional(),
        roomCode: z.string().trim().min(2).max(80),
      }),
      request.query,
    );

    const classRecord = await findClassByRoomCode(classes, query.roomCode);
    if (!classRecord) {
      throw new AuthError(404, "class_not_found", "Turma não encontrada.");
    }

    const roomCode = sanitizeRoomCode(String(classRecord.code));
    const classCode = String(classRecord.code);
    const normalizedIdentity = (query.identity ?? "").trim().toLowerCase();

    if (query.profile === "docente") {
      const isAssigned =
        classRecord.professorId === query.userId ||
        (normalizedIdentity.length > 0 &&
          String(classRecord.professorIdentity ?? "").trim().toLowerCase() === normalizedIdentity);
      if (!isAssigned) {
        throw new AuthError(
          403,
          "class_access_denied",
          "Você não é o docente responsável por esta turma.",
        );
      }
    } else if (query.profile === "aluno") {
      const enrollment = await enrollments.findOne({
        classCode,
        studentId: query.userId,
        status: "active",
      });
      if (!enrollment) {
        throw new AuthError(
          403,
          "enrollment_required",
          "Você não está matriculado nesta turma.",
        );
      }
    }

    response.json({
      allowed: true,
      roomCode,
      classCode,
      title: String(classRecord.subjectName ?? classRecord.courseName ?? classCode),
      courseName: String(classRecord.courseName ?? ""),
      semester: String(classRecord.semester ?? ""),
      shift: String(classRecord.shift ?? ""),
      location: String(classRecord.location ?? ""),
      professorId: classRecord.professorId ?? null,
      professorIdentity: classRecord.professorIdentity ?? null,
      professorName: classRecord.professorName ?? classRecord.professorIdentity ?? "Docente",
    });
  });

  router.post("/video-call/presence", async (request, response) => {
    const body = parse(
      z
        .object({
          classCode: z.string().trim().min(2).max(80),
          userId: z.string().trim().min(1).max(120),
          identity: z.string().trim().max(254).optional(),
          isConnected: z.boolean(),
        })
        .strict(),
      request.body,
    );

    const latestSession = await classSessions.findOne(
      { classCode: body.classCode },
      { sort: { startsAt: -1, sessionNumber: -1 } },
    );
    if (latestSession && Array.isArray(latestSession.attendanceList)) {
      const updatedList = latestSession.attendanceList.map((entry: Document) => {
        if (
          entry.studentId === body.userId ||
          (body.identity &&
            String(entry.ra ?? "").toLowerCase() === body.identity.toLowerCase())
        ) {
          return { ...entry, isConnected: body.isConnected };
        }
        return entry;
      });
      await classSessions.updateOne(
        { _id: latestSession._id },
        { $set: { attendanceList: updatedList } },
      );
    }

    response.json({ ok: true });
  });

  router.get("/users/:id/links", async (request, response) => {
    const userId = String(request.params.id ?? "").trim();
    if (!userId) {
      throw new AuthError(400, "invalid_id", "ID inválido.");
    }
    const [linkedTeacher, linkedStudent] = await Promise.all([
      classes.findOne({ professorId: userId, active: { $ne: false } }),
      enrollments.findOne({ studentId: userId, status: "active" }),
    ]);
    response.json({
      hasActiveLinks: Boolean(linkedTeacher || linkedStudent),
      hasTeachingLinks: Boolean(linkedTeacher),
      hasEnrollmentLinks: Boolean(linkedStudent),
    });
  });

  router.post("/users/:id/sync", async (request, response) => {
    const userId = String(request.params.id ?? "").trim();
    if (!userId) {
      throw new AuthError(400, "invalid_id", "ID inválido.");
    }
    const body = parse(
      z
        .object({
          identity: z.string().trim().min(1).max(254).optional(),
          displayName: z.string().trim().min(1).max(160).optional(),
        })
        .strict(),
      request.body,
    );
    if (body.identity) {
      const normalized = body.identity.toLowerCase();
      await Promise.all([
        classes.updateMany({ professorId: userId }, { $set: { professorIdentity: normalized } }),
        enrollments.updateMany({ studentId: userId }, { $set: { studentIdentity: normalized } }),
      ]);
    }
    if (body.displayName) {
      await Promise.all([
        classes.updateMany({ professorId: userId }, { $set: { professorName: body.displayName } }),
        enrollments.updateMany({ studentId: userId }, { $set: { displayName: body.displayName } }),
      ]);
    }
    response.json({ ok: true });
  });

  router.get("/users/:id/lgpd-data", async (request, response) => {
    const userId = String(request.params.id ?? "").trim();
    if (!userId) {
      throw new AuthError(400, "invalid_id", "ID inválido.");
    }
    const [userEnrollments, teachingClasses, submissions, protocols, grades] = await Promise.all([
      enrollments.find({ studentId: userId }).toArray(),
      classes.find({ professorId: userId }).toArray(),
      database
        .collection("academic_submissions")
        .find({ studentId: userId }, { projection: { contentBase64: 0 } })
        .toArray(),
      database
        .collection("academic_protocols")
        .find({ studentId: userId }, { projection: { attachmentBase64: 0 } })
        .toArray(),
      database.collection("academic_grades").find({ studentId: userId }).toArray(),
    ]);
    const sanitize = (records: Document[]) =>
      records.map(({ _id, ...rest }) => ({
        id: _id instanceof ObjectId ? _id.toHexString() : String(_id),
        ...rest,
      }));
    const sanitizedClasses = sanitize(teachingClasses);
    response.json({
      classes: sanitizedClasses,
      teachingClasses: sanitizedClasses,
      enrollments: sanitize(userEnrollments),
      submissions: sanitize(submissions),
      protocols: sanitize(protocols),
      grades: sanitize(grades),
    });
  });

  return router;
}
