// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { MongoClient, type Db } from "mongodb";
import { isDnsSrvFailure, resolveSrvUriViaDoh } from "./dns-fallback.js";
import {
  ensureAcademicIndexes,
  ensureAdminIndexes,
  ensureAuthIndexes,
  ensureVideoCallIndexes,
} from "./indexes/index.js";

/** Conector MongoDB central para o núcleo acadêmico e garantia de índices compartilhados. */
export class MongoAcademicDatabase {
  private client: MongoClient;
  private database?: Db;

  constructor(
    private readonly uri: string,
    private readonly databaseName: string,
    private readonly directUri?: string,
  ) {
    this.client = MongoAcademicDatabase.createClient(uri);
  }

  private static createClient(uri: string): MongoClient {
    return new MongoClient(uri, {
      serverSelectionTimeoutMS: 5_000,
      connectTimeoutMS: 5_000,
    });
  }

  async connect(): Promise<void> {
    try {
      await this.client.connect();
    } catch (error) {
      if (!this.uri.startsWith("mongodb+srv://") || !isDnsSrvFailure(error)) {
        throw error;
      }
      await this.client.close().catch(() => {});
      let fallbackUri = this.directUri;
      if (!fallbackUri) {
        console.warn("[academic-api] DNS SRV indisponível nesta rede; tentando resolução via DoH (porta 443)...");
        fallbackUri = await resolveSrvUriViaDoh(this.uri);
      } else {
        console.warn("[academic-api] DNS SRV indisponível nesta rede; alternando para MONGODB_DIRECT_URI...");
      }
      this.client = MongoAcademicDatabase.createClient(fallbackUri);
      await this.client.connect();
    }

    this.database = this.client.db(this.databaseName);
    await ensureAuthIndexes(this.database);
    await ensureAdminIndexes(this.database);
    await ensureAcademicIndexes(this.database);
    await ensureVideoCallIndexes(this.database);
  }

  databaseForModules(): Db {
    if (!this.database) {
      throw new Error("Banco de dados ainda não conectado.");
    }
    return this.database;
  }

  async close(): Promise<void> {
    await this.client.close();
  }
}
