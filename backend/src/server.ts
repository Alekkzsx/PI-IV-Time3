// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import "./config/local-environment.js";
import { createServer } from "node:http";
import { createApp } from "./app.js";
import { loadEnvironment } from "./config/environment.js";
import { ResilientEmailSender } from "./modules/notifications/index.js";
import { createIdentityServerHealthMiddleware } from "./shared/auth/identity-server-health.middleware.js";
import { MongoAcademicDatabase } from "./shared/mongo/database.js";

async function start(): Promise<void> {
  const environment = loadEnvironment();
  const database = new MongoAcademicDatabase(
    environment.mongoUri,
    environment.mongoDatabase,
    environment.mongoDirectUri,
  );
  try { await database.connect(); }
  catch (error) { await database.close(); throw error; }

  const emailSender = new ResilientEmailSender(
    environment,
    database.databaseForModules(),
  );

  const requireIdentityServer =
    (process.env.REQUIRE_IDENTITY_SERVER_ONLINE ?? "true").trim().toLowerCase() !== "false";
  const identityServerBaseUrl =
    process.env.AUTH_API_BASE_URL?.trim() ||
    process.env.JAVA_SERVER_BASE_URL?.trim() ||
    `http://127.0.0.1:${process.env.SERVER_PORT?.trim() || "8080"}`;
  const identityServerHealthGuard = requireIdentityServer
    ? createIdentityServerHealthMiddleware({ baseUrl: identityServerBaseUrl })
    : undefined;

  const server = createServer(
    createApp(environment, {
      database: database.databaseForModules(),
      jwtSecret: environment.jwtSecret,
      internalServiceSecret: environment.internalServiceSecret,
      emailSender,
      identityServerHealthGuard,
    }),
  );
  server.listen(environment.port, () => {
    console.info(`[academic-api] API acadêmica ouvindo na porta ${environment.port}.`);
  });
  server.once("error", () => {
    console.error("[academic-api] Falha ao abrir a porta configurada.");
    void database.close();
    process.exitCode = 1;
  });

  const shutdown = (signal: NodeJS.Signals): void => {
    console.info(`[academic-api] Encerramento solicitado (${signal}).`);
    server.close((error) => {
      void database.close().finally(() => {
        if (error) {
          console.error("[academic-api] Falha ao encerrar o servidor.", error);
          process.exitCode = 1;
        }
      });
    });
  };

  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);
}

start().catch((error: unknown) => {
  console.error("[academic-api] Não foi possível iniciar o serviço.", error);
  process.exitCode = 1;
});
