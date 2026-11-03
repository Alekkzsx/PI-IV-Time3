// Desenvolvido por Murillo Caravita - RA: 25014012
import type { RequestHandler } from "express";
import jwt, { type JwtPayload } from "jsonwebtoken";
import type { Db } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";
import { authenticated } from "../../auth/infrastructure/session.middleware.js";

/**
 * Garante acesso exclusivo a administradores autenticados.
 * Quando o token contem jti e ver de sessao persistida, exige sessao ativa no MongoDB.
 */
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
      // Fallback para verificacao de assinatura direta
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

