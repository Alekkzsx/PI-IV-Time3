// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
import "../../config/local-environment.js";
import { setServers } from "node:dns";
import { isIP } from "node:net";
import { MongoClient, ObjectId, type Db, type Document } from "mongodb";
import { loadEnvironment } from "../../config/environment.js";
import type { SeedSummary, SeedStats } from "./seed.types.js";

export const SEED_TAG = "ecosystem-v1";

export class SeedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "SeedError";
  }
}

export function validateEnvironment(): void {
  if (process.env.NODE_ENV === "production") {
    throw new SeedError("Execução de seeds bloqueada em NODE_ENV=production.");
  }
  if (!process.env.MONGODB_DATABASE?.trim()) {
    throw new SeedError("Defina MONGODB_DATABASE explicitamente antes de executar as seeds.");
  }
}

export function resolveSeedPassword(): string {
  const password = process.env.SEED_DEMO_PASSWORD?.trim() || "Agmrm@2026";
  if (password.length < 8 || Buffer.byteLength(password, "utf8") > 72) {
    throw new SeedError("A senha da seed deve ter no mínimo 8 caracteres e no máximo 72 bytes (limite do bcrypt).");
  }
  return password;
}

export function configureDns(): void {
  const dnsServers = process.env.SEED_DNS_SERVERS ?? process.env.MONGODB_DNS_SERVERS;
  if (dnsServers?.trim()) {
    const servers = dnsServers.split(",").map((s) => s.trim());
    if (servers.some((s) => !isIP(s))) {
      throw new SeedError("SEED_DNS_SERVERS deve conter IPs válidos separados por vírgula.");
    }
    setServers(servers);
    console.info("ℹ DNS personalizado habilitado para esta execução.");
  }
}

export function createSeedHelpers(database: Db, summary: SeedSummary) {
  const now = new Date();

  const recordStat = (col: string, created: boolean) => {
    const bucket = (summary[col] ??= { created: 0, reused: 0 });
    if (created) bucket.created++;
    else bucket.reused++;
  };

  const upsertOnInsert = async (collection: string, filter: Document, doc: Document): Promise<Document> => {
    const existing = await database.collection(collection).findOne(filter);
    if (existing) {
      recordStat(collection, false);
      return existing;
    }
    const { _id: _ignoreId, ...docWithoutId } = doc;
    const toInsert: Document = "_id" in filter ? docWithoutId : { _id: new ObjectId(), ...doc };
    const res = await database
      .collection(collection)
      .updateOne(filter, { $setOnInsert: toInsert }, { upsert: true });
    recordStat(collection, res.upsertedCount === 1);
    return (await database.collection(collection).findOne(filter)) ?? toInsert;
  };

  const upsertSync = async (collection: string, filter: Document, doc: Document): Promise<Document> => {
    const { _id: _ignoreId, createdAt, ...mutableFields } = doc;
    const insertDefaults: Document = { createdAt: createdAt ?? now };
    if (!("_id" in filter)) {
      insertDefaults._id = new ObjectId();
    }
    const res = await database
      .collection(collection)
      .updateOne(
        filter,
        {
          $set: mutableFields,
          $setOnInsert: insertDefaults,
        },
        { upsert: true },
      );
    recordStat(collection, res.upsertedCount === 1);
    return (await database.collection(collection).findOne(filter)) ?? doc;
  };

  return { now, recordStat, upsertOnInsert, upsertSync };
}

export function printSummaryTable(summary: SeedSummary): void {
  const entries = Object.entries(summary);
  if (entries.length === 0) {
    console.info("Nenhuma modificação realizada.");
    return;
  }
  console.table(
    entries.map(([collection, stats]) => ({
      colecao: collection,
      criados: stats.created,
      reutilizados: stats.reused,
    })),
  );
}

export async function withSeedDatabase(
  action: (database: Db, password: string) => Promise<SeedSummary>,
): Promise<void> {
  validateEnvironment();
  configureDns();
  const environment = loadEnvironment();
  const password = resolveSeedPassword();

  const client = new MongoClient(environment.mongoUri, {
    serverSelectionTimeoutMS: 10_000,
    connectTimeoutMS: 5_000,
  });

  try {
    await client.connect();
    const database = client.db(environment.mongoDatabase);
    await database.command({ ping: 1 });
    console.info(`📦 Conectado ao MongoDB: ${environment.mongoDatabase}`);

    const summary = await action(database, password);

    console.info("\n📊 Resumo da execução de seeds:");
    printSummaryTable(summary);
    console.info("✅ Operação concluída com sucesso (senhas pré-existentes preservadas).");
  } finally {
    await client.close();
  }
}

export function handleSeedError(error: unknown): void {
  if (error instanceof SeedError) {
    console.error(`❌ Falha na seed: ${error.message}`);
  } else {
    const details = error as { code?: unknown; message?: unknown; cause?: { code?: unknown } } | null;
    const code = details?.code ?? details?.cause?.code;
    const message = typeof details?.message === "string" ? details.message : "";
    if (code === 18 || /bad auth|authentication failed/i.test(message)) {
      console.error("❌ Falha na seed: autenticação recusada pelo MongoDB Atlas. Verifique as credenciais.");
    } else if (/querySrv|queryTxt/.test(message)) {
      console.error("❌ Falha na seed: erro de DNS do Atlas. Verifique o resolvedor ou configure SEED_DNS_SERVERS.");
    } else if (code === 11000) {
      console.error("❌ Falha na seed: violação de chave única duplicada no banco de dados.");
    } else {
      console.error("❌ Falha na seed:", error);
    }
  }
  process.exitCode = 1;
}
