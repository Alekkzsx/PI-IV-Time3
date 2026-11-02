// Desenvolvido por Guilherme Henrique Moreira

import { config } from "dotenv";
import { setServers } from "node:dns";
import { isIP } from "node:net";
import { fileURLToPath } from "node:url";
import { MongoClient } from "mongodb";
import { loadEnvironment } from "../config/environment.js";
import { demoUsers, seedAdminDemo, SeedValidationError, validateSeedPassword } from "./admin-demo.seed.js";

// Variáveis do terminal têm prioridade sobre os arquivos locais.
config({
  path: [
    fileURLToPath(new URL("../../.env.local", import.meta.url)),
    fileURLToPath(new URL("../../.env", import.meta.url)),
  ],
  quiet: true,
});

async function main(): Promise<void> {
  if (process.env.NODE_ENV === "production") {
    throw new SeedValidationError("Seed demonstrativo bloqueado em NODE_ENV=production.");
  }
  if (!process.env.MONGODB_DATABASE?.trim()) {
    throw new SeedValidationError("Defina MONGODB_DATABASE explicitamente antes de executar o seed.");
  }
  const environment = loadEnvironment();
  const password = process.env.SEED_DEMO_PASSWORD;
  validateSeedPassword(password);

  // Correção opcional para DNS SRV, restrita a este processo.
  const dnsServers = process.env.SEED_DNS_SERVERS ?? process.env.MONGODB_DNS_SERVERS;
  if (dnsServers?.trim()) {
    const servers = dnsServers.split(",").map((server) => server.trim());
    if (servers.some((server) => !isIP(server))) {
      throw new SeedValidationError("SEED_DNS_SERVERS deve conter IPs separados por vírgula.");
    }
    setServers(servers);
    console.info("DNS personalizado habilitado somente para esta execução.");
  }

  const client = new MongoClient(environment.mongoUri, {
    serverSelectionTimeoutMS: 10_000,
    connectTimeoutMS: 5_000,
  });
  try {
    await client.connect();
    const database = client.db(environment.mongoDatabase);
    await database.command({ ping: 1 });
    console.info(`Banco de destino: ${environment.mongoDatabase}.`);
    const summary = await seedAdminDemo(database, password);
    console.table(Object.entries(summary).map(([collection, counts]) => ({
      coleção: collection, criados: counts.created, reutilizados: counts.reused,
    })));
    console.info("Seed concluído. Dados e senhas existentes foram preservados.");
    console.info("Identidades: " + demoUsers.map((user) => user.identity).join(", ") + ".");
    console.info("Senha: valor de SEED_DEMO_PASSWORD (não exibido).");
  } finally {
    await client.close();
  }
}

main().catch((error: unknown) => {
  if (error instanceof SeedValidationError) {
    console.error("Falha no seed: " + error.message);
  } else {
    const details = error as { code?: unknown; message?: unknown; cause?: { code?: unknown } } | null;
    const code = details?.code ?? details?.cause?.code;
    const message = typeof details?.message === "string" ? details.message : "";
    if (code === 18 || /bad auth|authentication failed/i.test(message)) {
      console.error("Falha no seed: autenticação recusada pelo Atlas. Confira o usuário de banco e a senha em MONGODB_URI; não envie as credenciais pelo chat.");
    } else if (/querySrv|queryTxt/.test(message)) {
      console.error("Falha no seed: não foi possível consultar o DNS do Atlas. Confira o resolvedor ou configure SEED_DNS_SERVERS.");
    } else if (code === 11000) {
      console.error("Falha no seed: chave duplicada. Revise os registros existentes; nenhum registro foi sobrescrito.");
    } else {
      console.error("Falha no seed: verifique as variáveis obrigatórias, conexão e permissões do Atlas. Detalhes internos omitidos para proteger credenciais.");
    }
  }
  process.exitCode = 1;
});
