// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import cors from "cors";
import express, {
  type ErrorRequestHandler,
  type Express,
} from "express";
import helmet from "helmet";
import { rateLimit } from "express-rate-limit";
import type { Environment } from "./config/environment.js";
import type { AuthService } from "./modules/auth/application/auth.service.js";
import { createAuthRouter } from "./modules/auth/presentation/auth.controller.js";
import { createAdminAcademicRouter } from "./modules/admin/admin-academic.controller.js";
import { AuthError } from "./shared/auth-error.js";
import type { Db } from "mongodb";

/** Monta middlewares e rotas; recebe dependências prontas para facilitar testes. */
export function createApp(
  service: AuthService,
  environment: Pick<Environment, "nodeEnv" | "corsOrigins">,
  adminOptions?: { database: Db; jwtSecret: string },
): Express {
  const app = express();

  app.disable("x-powered-by");
  app.use(helmet());
  app.use(
    cors({
      origin: environment.corsOrigins,
      methods: ["GET", "POST", "OPTIONS"],
      allowedHeaders: ["Content-Type", "Authorization"],
    }),
  );
  app.use(express.json({ limit: "16kb", strict: true }));

  app.get("/health", (_request, response) => {
    response.status(200).json({ status: "ok" });
  });

  const authRateLimit = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 20,
    standardHeaders: "draft-8",
    legacyHeaders: false,
    message: {
      code: "rate_limit_exceeded",
      message: "Muitas tentativas. Aguarde antes de tentar novamente.",
    },
  });
  app.use("/api/auth", authRateLimit, createAuthRouter(service));
  if (adminOptions) {
    app.use(
      "/api/admin",
      createAdminAcademicRouter(adminOptions.database, adminOptions.jwtSecret),
    );
  }
  app.use(notFoundHandler);
  app.use(errorHandler(environment.nodeEnv));

  return app;
}

function notFoundHandler(
  _request: express.Request,
  response: express.Response,
): void {
  response.status(404).json({
    code: "route_not_found",
    message: "Rota não encontrada.",
  });
}

function errorHandler(nodeEnv: Environment["nodeEnv"]): ErrorRequestHandler {
  return (error: unknown, _request, response, _next) => {
    if (error instanceof AuthError) {
      response.status(error.statusCode).json({
        code: error.code,
        message: error.message,
      });
      return;
    }

    if (error instanceof SyntaxError && "body" in error) {
      response.status(400).json({
        code: "invalid_json",
        message: "O corpo da solicitação não contém JSON válido.",
      });
      return;
    }

    console.error("[auth-api] Erro inesperado", error);
    response.status(500).json({
      code: "internal_error",
      message:
        nodeEnv === "production"
          ? "Não foi possível concluir a solicitação."
          : "Erro interno no serviço de autenticação.",
    });
  };
}
