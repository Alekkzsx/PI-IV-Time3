//Desenvolvido por Rafael Henrique dos Santos Inácio - RA: 25009719

import { config } from "dotenv";
import { fileURLToPath } from "node:url";
import { MongoClient } from "mongodb";

import { loadEnvironment } from "../config/environment.js";

import {
  seedStudentDemo,
  studentDemoUsers,
  StudentSeedError,
  validateStudentPassword,
} from "./student-demo.seed.js";

// Carrega as variáveis locais do backend.
config({
  path: [
    fileURLToPath(new URL("../../.env.local", import.meta.url)),
    fileURLToPath(new URL("../../.env", import.meta.url)),
  ],
  quiet: true,
});

async function main(): Promise<void> {
  // Impede execução em produção.
  if (process.env.NODE_ENV === "production") {
    throw new StudentSeedError(
      "A seed de demonstração não pode ser executada em produção.",
    );
  }

  // Exige a definição explícita do banco.
  if (!process.env.MONGODB_DATABASE?.trim()) {
    throw new StudentSeedError(
      "Configure MONGODB_DATABASE antes de executar a seed.",
    );
  }

  const environment = loadEnvironment();

  const password = process.env.SEED_DEMO_PASSWORD;
  validateStudentPassword(password);

  const client = new MongoClient(environment.mongoUri, {
    serverSelectionTimeoutMS: 10_000,
    connectTimeoutMS: 5_000,
  });

  try {
    // Conecta ao MongoDB.
    await client.connect();

    const database = client.db(environment.mongoDatabase);

    await database.command({ ping: 1 });

    console.log(
      `Banco de destino: ${environment.mongoDatabase}`,
    );

    // Executa a seed dos alunos.
    const summary = await seedStudentDemo(database, password);

    // Mostra os resultados.
    console.table(
      Object.entries(summary).map(([collection, counts]) => ({
        colecao: collection,
        criados: counts.created,
        reutilizados: counts.reused,
      })),
    );

    console.log("Seed dos alunos concluída!");

    console.log(
      "Identidades:",
      studentDemoUsers.map((user) => user.identity).join(", "),
    );

    console.log(
      "Senha: valor de SEED_DEMO_PASSWORD (não exibido).",
    );
  } finally {
    await client.close();
  }
}

main().catch((error: unknown) => {
  console.error("Erro ao executar a seed:");

  if (error instanceof StudentSeedError) {
    console.error(error.message);
  } else {
    console.error(error);
  }

  process.exitCode = 1;
});
