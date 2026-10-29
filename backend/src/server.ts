// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import "dotenv/config";
import { createServer } from "node:http";
import { createApp } from "./app.js";
import { loadEnvironment } from "./config/environment.js";
import { AuthService } from "./modules/auth/application/auth.service.js";
import { MongoAuthDatabase } from "./modules/auth/infrastructure/mongo-auth.repository.js";
import { SmtpRecoveryEmailSender } from "./modules/auth/infrastructure/smtp-recovery-email.sender.js";
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
  await database.connect();

  const passwords = new BcryptPasswordHasher();
  const authService = new AuthService({
    users: database.users(),
    recoveryCodes: database.recoveryCodes(),
    passwords,
    accessTokens: new JwtAccessTokenIssuer(
      environment.jwtSecret,
      environment.jwtTtl,
    ),
    recoveryEmail: new SmtpRecoveryEmailSender(environment.smtp),
    dummyPasswordHash: await passwords.hash("invalid-login-timing-decoy"),
    environment,
  });

  const server = createServer(createApp(authService, environment));
  server.listen(environment.port, () => {
    console.info(`[auth-api] Serviço de autenticação ouvindo na porta ${environment.port}.`);
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
