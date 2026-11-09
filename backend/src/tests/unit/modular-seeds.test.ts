// Desenvolvido por Time 3 - PI IV
import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { ObjectId, type Db, type Document } from "mongodb";
import { allSeeds, runSeeds } from "../../scripts/index.js";
import { realAccounts } from "../../scripts/modules/01-users.seed.js";
import { resolveSeedPassword, validateEnvironment, SeedError } from "../../scripts/shared/seed.runner.js";

class MemoryDatabase {
  readonly collections = new Map<string, Document[]>();

  collection(name: string) {
    const docs = this.collections.get(name) ?? [];
    this.collections.set(name, docs);

    return {
      find: (filter: Document = {}) => {
        let maxLimit = Infinity;
        const cursor = {
          limit: (n: number) => {
            maxLimit = n;
            return cursor;
          },
          toArray: async () => docs.filter((d) => matchesFilter(d, filter)).slice(0, maxLimit),
        };
        return cursor;
      },
      findOne: async (filter: Document = {}) => {
        return docs.find((d) => matchesFilter(d, filter)) ?? null;
      },
      countDocuments: async (filter: Document = {}) => {
        return docs.filter((d) => matchesFilter(d, filter)).length;
      },
      createIndex: async () => "index_created",
      updateOne: async (filter: Document, update: Document, options?: { upsert?: boolean }) => {
        const index = docs.findIndex((d) => matchesFilter(d, filter));
        if (index >= 0) {
          if (update.$set) {
            Object.assign(docs[index]!, update.$set);
          }
          return { upsertedCount: 0, modifiedCount: 1 };
        }
        if (options?.upsert) {
          const newDoc = {
            _id: new ObjectId(),
            ...(update.$setOnInsert ?? {}),
            ...(update.$set ?? {}),
          };
          docs.push(newDoc);
          return { upsertedCount: 1, modifiedCount: 0 };
        }
        return { upsertedCount: 0, modifiedCount: 0 };
      },
      findOneAndUpdate: async (filter: Document, update: Document, options?: { upsert?: boolean; returnDocument?: string }) => {
        const index = docs.findIndex((d) => matchesFilter(d, filter));
        if (index >= 0) {
          if (update.$set) Object.assign(docs[index]!, update.$set);
          return docs[index];
        }
        if (options?.upsert) {
          const newDoc = {
            _id: new ObjectId(),
            ...(update.$setOnInsert ?? {}),
            ...(update.$set ?? {}),
          };
          docs.push(newDoc);
          return newDoc;
        }
        return null;
      },
      deleteMany: async () => ({ deletedCount: 0 }),
    };
  }

  asDb(): Db {
    return this as unknown as Db;
  }
}

function matchesFilter(doc: Document, filter: Document): boolean {
  for (const [key, val] of Object.entries(filter)) {
    if (key === "$or" && Array.isArray(val)) {
      if (!val.some((sub) => matchesFilter(doc, sub))) return false;
      continue;
    }
    if (val && typeof val === "object" && "$in" in val) {
      if (!val.$in.includes(doc[key])) return false;
      continue;
    }
    if (doc[key] !== val) return false;
  }
  return true;
}

describe("Arquitetura Modular de Seeds (src/scripts)", () => {
  it("contém exatamente os 6 módulos ordenados por dependência relacional", () => {
    const ids = allSeeds.map((s) => s.id);
    assert.deepEqual(ids, [
      "users",
      "courses",
      "classes",
      "teacher",
      "student",
      "institutional",
    ]);
  });

  it("mapeia contas para todos os perfis do sistema (admin, docente, aluno)", () => {
    const profiles = new Set(realAccounts.map((a) => a.profile));
    assert.ok(profiles.has("admin"), "Deve conter conta de admin");
    assert.ok(profiles.has("docente"), "Deve conter conta de docente");
    assert.ok(profiles.has("aluno"), "Deve conter conta de aluno");
  });

  it("valida a senha da seed respeitando limite mínimo e limite bcrypt (72 bytes)", () => {
    const pass = resolveSeedPassword();
    assert.ok(pass.length >= 8);
    assert.ok(Buffer.byteLength(pass, "utf8") <= 72);
  });

  it("bloqueia execução acidental se NODE_ENV=production", () => {
    const originalEnv = process.env.NODE_ENV;
    try {
      process.env.NODE_ENV = "production";
      assert.throws(() => validateEnvironment(), SeedError);
    } finally {
      process.env.NODE_ENV = originalEnv;
    }
  });

  it("rejeita módulo inexistente com mensagem clara", async () => {
    const memDb = new MemoryDatabase();
    await assert.rejects(
      runSeeds(memDb.asDb(), "TestPass1234!", "modulo-inexistente"),
      /Módulo de seed não encontrado/,
    );
  });

  it("executa os 6 módulos em sequência acumulando resumo com pelo menos 30 registros por entidade", async () => {
    const memDb = new MemoryDatabase();
    const summary = await runSeeds(memDb.asDb(), "TestPass1234!");

    assert.ok(summary.auth_users && summary.auth_users.created >= 30, "Deve criar pelo menos 30 usuários");
    assert.ok(summary.academic_classes && summary.academic_classes.created >= 30, "Deve criar pelo menos 30 turmas");
    assert.ok(summary.academic_class_sessions && summary.academic_class_sessions.created >= 30, "Deve criar pelo menos 30 sessões de aula");
    assert.ok(summary.academic_materials && summary.academic_materials.created >= 30, "Deve criar pelo menos 30 materiais didáticos");
    assert.ok(summary.academic_assignments && summary.academic_assignments.created >= 30, "Deve criar pelo menos 30 atividades avaliativas");
    assert.ok(summary.academic_forum_topics && summary.academic_forum_topics.created >= 30, "Deve criar pelo menos 30 tópicos de fórum");
    assert.ok(summary.academic_submissions && summary.academic_submissions.created >= 30, "Deve criar pelo menos 30 submissões de tarefas");
    assert.ok(summary.academic_protocols && summary.academic_protocols.created >= 30, "Deve criar pelo menos 30 protocolos da secretaria");
    assert.ok(summary.academic_calendar && summary.academic_calendar.created >= 30, "Deve criar pelo menos 30 marcos do calendário");
    assert.ok(summary.academic_announcements && summary.academic_announcements.created >= 30, "Deve criar pelo menos 30 comunicados");

    assert.ok(summary.academic_courses && summary.academic_courses.created > 0, "academic_courses deve estar no resumo");
    assert.ok(summary.academic_enrollments && summary.academic_enrollments.created >= 30, "academic_enrollments deve conter dezenas de matrículas");
    assert.ok(summary.admin_settings, "admin_settings deve estar no resumo");

    // Na segunda execução sobre o mesmo banco em memória, registros devem ser reutilizados
    const secondSummary = await runSeeds(memDb.asDb(), "TestPass1234!");
    assert.ok(secondSummary.auth_users && secondSummary.auth_users.reused >= 30, "Deve reutilizar os usuários existentes");
  });
});
