// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import cors from "cors";
import express, {
  type ErrorRequestHandler,
  type Express,
} from "express";
import helmet from "helmet";
import type { Db } from "mongodb";
import type { Environment } from "./config/environment.js";
import { createAdminAcademicRouter } from "./modules/admin/presentation/academic/index.js";
import { createAdminOperationsRouter } from "./modules/admin/presentation/operations/index.js";
import { createInternalAcademicRouter } from "./modules/internal/internal-academic.controller.js";
import { createStudentDashboardRouter } from "./modules/student/presentation/dashboard/index.js";
import { createFilesRouter } from "./modules/student/presentation/files/index.js";
import { createTeacherRouter } from "./modules/teacher/presentation/index.js";
import { AuthError } from "./shared/auth-error.js";
import type { UnifiedEmailService } from "./modules/notifications/domain/notification.types.js";

const DEV_LOOPBACK_ORIGIN_REGEX = /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:\d{1,5})?$/i;
const LAN_IPV4_ORIGIN_REGEX =
  /^https?:\/\/(10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3})(:\d{1,5})?$/i;

function isAllowedCorsOrigin(
  origin: string,
  environment: Pick<Environment, "nodeEnv" | "corsOrigins"> & { allowLanCors?: boolean },
): boolean {
  if (environment.corsOrigins.includes(origin)) {
    return true;
  }
  if (environment.nodeEnv !== "production") {
    if (DEV_LOOPBACK_ORIGIN_REGEX.test(origin)) {
      return true;
    }
    if (environment.allowLanCors && LAN_IPV4_ORIGIN_REGEX.test(origin)) {
      return true;
    }
  }
  return false;
}

/** Monta middlewares e rotas exclusivas do núcleo acadêmico e ponte interna. */
export function createApp(
  environment: Pick<Environment, "nodeEnv" | "corsOrigins"> & { allowLanCors?: boolean },
  options: {
    database: Db;
    jwtSecret: string;
    internalServiceSecret?: string;
    emailSender?: UnifiedEmailService;
  },
): Express {
  const app = express();

  app.disable("x-powered-by");
  app.use(helmet());
  app.use((request, response, next) => {
    const origin = request.header("origin");
    if (
      request.header("access-control-request-private-network") === "true" &&
      (!origin || isAllowedCorsOrigin(origin, environment))
    ) {
      response.setHeader("Access-Control-Allow-Private-Network", "true");
    }
    next();
  });
  app.use(
    cors({
      origin: (origin, callback) => {
        if (!origin || isAllowedCorsOrigin(origin, environment)) {
          callback(null, true);
          return;
        }
        callback(null, false);
      },
      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      allowedHeaders: ["Content-Type", "Authorization", "X-Internal-Service-Secret"],
      exposedHeaders: ["X-Total-Count"],
    }),
  );
  app.use(express.json({ limit: "10mb", strict: true }));

  app.get("/health", (_request, response) => {
    response.status(200).json({ status: "ok", service: "agmrm-academic-api" });
  });

  if (options.internalServiceSecret) {
    app.use(
      "/api/internal/academic",
      createInternalAcademicRouter(options.database, options.internalServiceSecret),
    );
  }

  app.use("/api/admin/users", notFoundHandler);
  app.post("/api/admin/teachers", notFoundHandler);
  app.use("/api/admin", createAdminOperationsRouter(options.database, options.jwtSecret, options.emailSender));
  app.use("/api/admin", createAdminAcademicRouter(options.database, options.jwtSecret));
  app.use("/api/student", createStudentDashboardRouter(options.database, options.jwtSecret, options.emailSender));
  app.use("/api/teacher", createTeacherRouter(options.database, options.jwtSecret));
  app.use("/api/files", createFilesRouter(options.database, options.jwtSecret));

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
