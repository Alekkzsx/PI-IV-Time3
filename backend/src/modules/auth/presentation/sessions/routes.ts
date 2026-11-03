// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import type { Router } from "express";
import type { Db } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";

export function registerSessionRoutes(router: Router, database: Db): void {
  router.get("/sessions", async (_request, response) => {
    const records = await database
      .collection("auth_sessions")
      .find(
        { userId: response.locals.userId, expiresAt: { $gt: new Date() } },
        { projection: { _id: 0, createdAt: 1, expiresAt: 1, sessionId: 1, userAgent: 1, ipAddress: 1 } },
      )
      .sort({ createdAt: -1 })
      .toArray();
    response.json(
      records.map(({ sessionId, ...record }) => ({
        id: sessionId,
        sessionId,
        device: record.userAgent ?? "Sessão Web / Desktop",
        ipAddress: record.ipAddress ?? "127.0.0.1",
        ...record,
        current: sessionId === response.locals.sessionId,
      })),
    );
  });

  router.delete("/sessions/:sessionId", async (request, response) => {
    const targetSessionId = String(request.params.sessionId ?? "").trim();
    if (!targetSessionId) throw new AuthError(400, "invalid_session", "Sessão inválida.");
    await database.collection("auth_sessions").deleteOne({
      sessionId: targetSessionId,
      userId: response.locals.userId,
    });
    response.status(204).end();
  });

  router.post("/logout-others", async (_request, response) => {
    await database.collection("auth_sessions").deleteMany({
      userId: response.locals.userId,
      sessionId: { $ne: response.locals.sessionId },
    });
    response.status(204).end();
  });

  router.post("/logout", async (_request, response) => {
    await database.collection("auth_sessions").deleteOne({
      sessionId: response.locals.sessionId,
      userId: response.locals.userId,
    });
    response.status(204).end();
  });
}