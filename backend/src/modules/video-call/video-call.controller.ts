// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { Router, type RequestHandler } from "express";
import jwt, { type JwtPayload } from "jsonwebtoken";
import { ObjectId, type Db } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../shared/auth-error.js";

const enterRoomSchema = z.object({
  roomCode: z.string().trim().min(2).max(32),
});

export function createVideoCallRouter(database: Db, jwtSecret: string): Router {
  const router = Router();
  const authenticate = authenticatedUser(jwtSecret);
  const users = database.collection("auth_users");
  const classes = database.collection("academic_classes");
  const enrollments = database.collection("academic_enrollments");
  const liveSessions = database.collection("academic_live_sessions");

  router.post("/rooms/enter", authenticate, async (request, response) => {
    const parsed = enterRoomSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Código da turma inválido.");
    }

    const claims = response.locals.user as {
      id: string;
      profile: string;
    };
    const user = await users.findOne({
      _id: new ObjectId(claims.id),
      profile: claims.profile,
      active: true,
    });
    if (!user) {
      throw new AuthError(401, "invalid_token", "Conta inativa ou inválida.");
    }

    const classRecord = await classes.findOne({
      code: {
        $regex: `^${escapeRegExp(parsed.data.roomCode)}$`,
        $options: "i",
      },
    });
    if (!classRecord) {
      throw new AuthError(404, "class_not_found", "Turma não encontrada.");
    }

    const roomCode = String(classRecord.code).trim().toUpperCase();
    const identity = String(user.normalizedIdentity ?? user.identity)
      .trim()
      .toLowerCase();

    if (claims.profile === "docente" || claims.profile === "admin") {
      const isAssigned =
        claims.profile === "admin" ||
        classRecord.professorId === user._id.toString() ||
        classRecord.professorIdentity === identity;
      if (!isAssigned) {
        throw new AuthError(
          403,
          "class_access_denied",
          "Você não é o docente responsável por esta turma.",
        );
      }

      const now = new Date();
      await liveSessions.updateOne(
        { roomCode },
        {
          $set: {
            roomCode,
            classCode: classRecord.code,
            openedById: user._id.toString(),
            openedByIdentity: identity,
            openedAt: now,
            expiresAt: new Date(now.getTime() + 8 * 60 * 60 * 1000),
          },
        },
        { upsert: true },
      );
      response.status(200).json({ roomCode, opened: true });
      return;
    }

    if (claims.profile !== "aluno") {
      throw new AuthError(403, "forbidden", "Perfil sem acesso à videochamada.");
    }

    const enrollment = await enrollments.findOne({
      classCode: classRecord.code,
      studentId: user._id.toString(),
      status: "active",
    });
    if (!enrollment) {
      throw new AuthError(403, "enrollment_required", "Você não está matriculado nesta turma.");
    }

    const activeSession = await liveSessions.findOne({
      roomCode,
      expiresAt: { $gt: new Date() },
    });
    if (!activeSession) {
      throw new AuthError(409, "room_not_open", "A videochamada ainda não foi aberta pelo docente.");
    }

    response.status(200).json({ roomCode, opened: false });
  });

  router.post("/rooms/close", authenticate, async (request, response) => {
    const parsed = enterRoomSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Código da turma inválido.");
    }

    const claims = response.locals.user as {
      id: string;
      profile: string;
    };
    if (claims.profile !== "docente" && claims.profile !== "admin") {
      throw new AuthError(403, "forbidden", "Somente o docente pode encerrar a sala.");
    }

    const user = await users.findOne({
      _id: new ObjectId(claims.id),
      profile: claims.profile,
      active: true,
    });
    if (!user) {
      throw new AuthError(401, "invalid_token", "Conta inativa ou inválida.");
    }

    const roomCode = parsed.data.roomCode.trim().toUpperCase();
    const filter: Record<string, unknown> = {
      roomCode,
      openedById: user._id.toString(),
    };
    const result = await database
      .collection("academic_live_sessions")
      .deleteOne(filter);
    if (result.deletedCount !== 1) {
      throw new AuthError(
        404,
        "room_not_open",
        "Sala não encontrada ou aberta por outro usuário.",
      );
    }

    response.status(204).end();
  });

  return router;
}

function authenticatedUser(jwtSecret: string): RequestHandler {
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
      !ObjectId.isValid(claims.sub) ||
      typeof claims.profile !== "string"
    ) {
      next(new AuthError(401, "invalid_token", "Sessão inválida ou expirada."));
      return;
    }

    response.locals.user = { id: claims.sub, profile: claims.profile };
    next();
  };
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
