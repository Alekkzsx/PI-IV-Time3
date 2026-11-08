// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import "./config/local-environment.js";
import { createServer } from "node:http";
import { createApp } from "./app.js";
import { loadEnvironment } from "./config/environment.js";
import { MongoAuthSecurityRepository } from "./modules/auth/infrastructure/mongo-auth-security.repository.js";
import { AuthService } from "./modules/auth/application/index.js";
import { MongoAuthDatabase } from "./modules/auth/infrastructure/mongo-auth.repository.js";
import { ResilientEmailSender } from "./modules/notifications/index.js";
import {
  BcryptPasswordHasher,
  JwtAccessTokenIssuer,
} from "./modules/auth/infrastructure/security.providers.js";

async function start(): Promise<void> {
  const environment = loadEnvironment();
  const database = new MongoAuthDatabase(
    environment.mongoUri,
    environment.mongoDatabase,
  );
  try { await database.connect(); }
  catch (error) { await database.close(); throw error; }

  const passwords = new BcryptPasswordHasher();
  const emailSender = new ResilientEmailSender(
    environment,
    database.databaseForModules(),
  );

  const authService = new AuthService({
    users: database.users(),
    security: new MongoAuthSecurityRepository(database.databaseForModules()),
    recoveryCodes: database.recoveryCodes(),
    passwords,
    accessTokens: new JwtAccessTokenIssuer(
      environment.jwtSecret,
      environment.jwtTtl,
    ),
    recoveryEmail: emailSender,
    dummyPasswordHash: await passwords.hash("invalid-login-timing-decoy"),
    environment,
  });

  const server = createServer(
    createApp(authService, environment, {
      database: database.databaseForModules(),
      jwtSecret: environment.jwtSecret,
      emailSender,
    }),
  );
  server.listen(environment.port, () => {
    console.info(`[auth-api] Serviço de autenticação ouvindo na porta ${environment.port}.`);
  });
  server.once("error", () => {
    console.error("[auth-api] Falha ao abrir a porta configurada.");
    void database.close();
    process.exitCode = 1;
  });

  const shutdown = (signal: NodeJS.Signals): void => {
    console.info(`[auth-api] Encerramento solicitado (${signal}).`);
    server.close((error) => {
      void database.close().finally(() => {
        if (error) {
          console.error("[auth-api] Falha ao encerrar o servidor.", error);
          process.exitCode = 1;
        }
      });
    });
  };

  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);
}

start().catch((error: unknown) => {
  console.error("[auth-api] Não foi possível iniciar o serviço.", error);
  process.exitCode = 1;
});
