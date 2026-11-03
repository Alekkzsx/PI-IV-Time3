// Desenvolvido por Guilherme Henrique Moreira
import { Router } from "express";
import type { Db } from "mongodb";
import { authenticated } from "../infrastructure/session.middleware.js";
import type { AuthService } from "../application/auth.service.js";
import { registerProfileRoutes } from "./profile/routes.js";
import { registerSessionRoutes } from "./sessions/routes.js";
import { registerSecurityRoutes } from "./security/routes.js";
import { registerPrivacyRoutes } from "./privacy/routes.js";

export function createSessionRouter(database: Db, secret: string, service: AuthService): Router {
  const router = Router();
  router.use(authenticated(database, secret));
  registerProfileRoutes(router, database);
  registerSessionRoutes(router, database);
  registerSecurityRoutes(router, database, service);
  registerPrivacyRoutes(router, database);

  return router;
}
