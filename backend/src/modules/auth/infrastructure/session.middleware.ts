// Desenvolvido por Guilherme Henrique Moreira
import type { RequestHandler } from "express";
import jwt from "jsonwebtoken";
import { ObjectId, type Db } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";

export function authenticated(database: Db, secret: string, admin = false): RequestHandler {
  return async (request, response, next) => {
    try {
      const authorization = request.header("authorization");
      if (!authorization?.startsWith("Bearer ")) throw new AuthError(401, "authentication_required", "Autenticação necessária.");
      let claims;
      try { claims = jwt.verify(authorization.slice(7), secret, { algorithms: ["HS256"] }); }
      catch { throw new AuthError(401, "invalid_token", "Sessão inválida ou expirada."); }
      if (typeof claims === "string" || typeof claims.sub !== "string" || !ObjectId.isValid(claims.sub) ||
          typeof claims.exp !== "number" || typeof claims.jti !== "string" || !Number.isInteger(claims.ver)) {
        throw new AuthError(401, "invalid_token", "Sessão inválida ou expirada.");
      }
      const user = await database.collection("auth_users").findOne({ _id: new ObjectId(claims.sub), active: true });
      const session = await database.collection("auth_sessions").findOne({
        sessionId: claims.jti, userId: claims.sub, expiresAt: { $gt: new Date() },
      });
      if (!user || !session || (user.sessionVersion ?? 0) !== claims.ver || user.profile !== claims.profile) {
        throw new AuthError(401, "session_revoked", "Sessão encerrada. Entre novamente.");
      }
      if (admin && user.profile !== "admin") throw new AuthError(403, "forbidden", "Ação permitida somente ao administrador.");
      if (user.requirePasswordChange && !["/me", "/logout", "/change-password"].includes(request.path)) {
        throw new AuthError(403, "password_change_required", "Altere sua senha para continuar.");
      }
      response.locals.user = user;
      response.locals.userId = claims.sub;
      response.locals.adminId = claims.sub;
      response.locals.sessionId = claims.jti;
      next();
    } catch (error) { next(error); }
  };
}
