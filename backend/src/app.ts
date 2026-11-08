// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import cors from "cors";
import express, {
  type ErrorRequestHandler,
  type Express,
} from "express";
import helmet from "helmet";
import { rateLimit } from "express-rate-limit";
import type { Db } from "mongodb";
import type { Environment } from "./config/environment.js";
import type { AuthService } from "./modules/auth/application/index.js";
import { createAuthRouter } from "./modules/auth/presentation/auth.controller.js";
import { createSessionRouter } from "./modules/auth/presentation/session.controller.js";
import { createAdminAcademicRouter } from "./modules/admin/presentation/academic/index.js";
import { createAdminOperationsRouter } from "./modules/admin/presentation/operations/index.js";
import { createAdminUsersRouter } from "./modules/admin/presentation/users/index.js";
import { createStudentDashboardRouter } from "./modules/student/presentation/dashboard/index.js";
import { createFilesRouter } from "./modules/student/presentation/files/index.js";
import { createTeacherRouter } from "./modules/teacher/presentation/index.js";
import { createVideoCallRouter } from "./modules/video-call/presentation/index.js";
import { AuthError } from "./shared/auth-error.js";
import type { UnifiedEmailService } from "./modules/notifications/domain/notification.types.js";

/** Monta middlewares e rotas; recebe dependências prontas para facilitar testes. */
export function createApp(
  service: AuthService,
  environment: Pick<Environment, "nodeEnv" | "corsOrigins">,
  adminOptions?: { database: Db; jwtSecret: string; emailSender?: UnifiedEmailService },
): Express {
  const app = express();

  app.disable("x-powered-by");
  app.use(helmet());
  app.use(
    cors({
      origin: (origin, callback) => {
        if (!origin) {
          callback(null, true);
          return;
        }
        if (environment.corsOrigins.includes(origin)) {
          callback(null, true);
          return;
        }
        if (
          environment.nodeEnv !== "production" &&
          /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin)
        ) {
          callback(null, true);
          return;
        }
        callback(null, false);
      },
      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      allowedHeaders: ["Content-Type", "Authorization"],
      exposedHeaders: ["X-Total-Count"],
    }),
  );
  app.use(express.json({ limit: "10mb", strict: true }));

  app.get("/health", (_request, response) => {
    response.status(200).json({ status: "ok" });
  });

  const authRateLimit = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 200,
    standardHeaders: "draft-8",
    legacyHeaders: false,
    message: {
      code: "rate_limit_exceeded",
      message: "Muitas tentativas. Aguarde antes de tentar novamente.",
    },
  });
  app.use("/api/auth", authRateLimit, createAuthRouter(service));

  if (adminOptions) {
    app.use("/api/auth", createSessionRouter(adminOptions.database, adminOptions.jwtSecret, service));
    app.use("/api/admin/users", createAdminUsersRouter(adminOptions.database, adminOptions.jwtSecret, service, adminOptions.emailSender));
    app.use("/api/admin", createAdminOperationsRouter(adminOptions.database, adminOptions.jwtSecret, adminOptions.emailSender));
    app.use("/api/admin", createAdminAcademicRouter(adminOptions.database, adminOptions.jwtSecret));
    app.use("/api/student", createStudentDashboardRouter(adminOptions.database, adminOptions.jwtSecret, adminOptions.emailSender));
    app.use("/api/teacher", createTeacherRouter(adminOptions.database, adminOptions.jwtSecret));
    app.use("/api/files", createFilesRouter(adminOptions.database, adminOptions.jwtSecret));
    app.use("/api/video-call", createVideoCallRouter(adminOptions.database, adminOptions.jwtSecret));
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
    if (error && typeof error === "object" && "code" in error && error.code === 11000) {
      response.status(409).json({ code: "record_exists", message: "Já existe um registro com esses dados." });
      return;
    }
    if (error && typeof error === "object" && "type" in error && error.type === "entity.too.large") {
      response.status(413).json({ code: "payload_too_large", message: "Requisição excede o limite permitido." });
      return;
    }
    if (error instanceof SyntaxError && "body" in error) {
      response.status(400).json({
        code: "invalid_json",
        message: "O corpo da solicitação não contém JSON válido.",
      });
      return;
    }

    console.error("[auth-api] Erro inesperado; detalhes internos omitidos.", error);
    response.status(500).json({
      code: "internal_error",
      message:
        nodeEnv === "production"
          ? "Não foi possível concluir a solicitação."
          : "Erro interno no serviço de autenticação.",
    });
  };
}
