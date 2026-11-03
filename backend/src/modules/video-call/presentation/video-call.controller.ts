// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { Router } from "express";
import type { Response } from "express";
import type { Db } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../../shared/auth-error.js";
import { authenticated } from "../../auth/infrastructure/session.middleware.js";
import {
  VideoCallRoomService,
  type AuthenticatedVideoUser,
} from "../application/video-call-room.service.js";

const enterRoomSchema = z.object({
  roomCode: z.string().trim().min(2).max(60),
});

const consumeTicketSchema = z.object({
  ticket: z.string().regex(/^[A-Za-z0-9_-]{43}$/),
  roomCode: z.string().trim().min(2).max(60),
});

const attendanceSchema = z.object({
  roomCode: z.string().trim().min(2).max(60),
  event: z.enum(["join", "leave"]),
  connectedSeconds: z.number().int().min(0).max(86_400).optional(),
});

export function createVideoCallRouter(database: Db, jwtSecret: string): Router {
  const router = Router();
  const authenticate = authenticated(database, jwtSecret, false);
  const service = new VideoCallRoomService(database);

  router.get("/rooms", authenticate, async (_request, response) => {
    const claims = videoUser(response);
    const rooms = await service.listAccessibleRooms(claims);
    response.status(200).json(rooms);
  });

  router.post("/rooms/consume-ticket", async (request, response) => {
    const parsed = consumeTicketSchema.safeParse(request.query);
    if (!parsed.success) {
      throw new AuthError(401, "invalid_room_ticket", "Autorização da sala ausente ou expirada.");
    }
    await service.consumeWebSocketTicket(parsed.data.ticket, parsed.data.roomCode);
    response.status(204).end();
  });

  router.post("/rooms/enter", authenticate, async (request, response) => {
    const parsed = enterRoomSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Código da turma inválido.");
    }

    const claims = videoUser(response);
    const result = await service.enterRoom(claims, parsed.data.roomCode);
    response.status(200).json(result);
  });

  router.post("/rooms/close", authenticate, async (request, response) => {
    const parsed = enterRoomSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Código da turma inválido.");
    }

    const claims = videoUser(response);
    await service.closeRoom(claims, parsed.data.roomCode);
    response.status(204).end();
  });

  router.post("/rooms/attendance", authenticate, async (request, response) => {
    const parsed = attendanceSchema.safeParse(request.body);
    if (!parsed.success) {
      throw new AuthError(400, "invalid_request", "Dados de telemetria inválidos.");
    }
    const claims = videoUser(response);
    const result = await service.recordAttendanceTelemetry(
      claims,
      parsed.data.roomCode,
      parsed.data.event,
      parsed.data.connectedSeconds,
    );
    response.status(200).json(result);
  });

  return router;
}

function videoUser(response: Response): AuthenticatedVideoUser {
  return {
    id: String(response.locals.userId),
    profile: String(response.locals.user.profile),
  };
}
