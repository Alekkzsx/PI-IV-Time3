// Desenvolvido por Guilherme Henrique Moreira

import assert from "node:assert/strict";
import { describe, it } from "node:test";
import bcrypt from "bcryptjs";
import { ObjectId, type Db, type Document } from "mongodb";
import { seedAdminDemo, validateSeedPassword } from "./admin-demo.seed.js";

const password = "Demo-password-for-tests-2026!";

// Dublê local: os testes não usam credenciais nem acessam o Atlas.
class MemoryDatabase {
  readonly records = new Map<string, Document[]>();
  writes = 0;

  collection(name: string) {
    const records = this.records.get(name) ?? [];
    this.records.set(name, records);
    return {
      find: (filter: Document) => {
        let limit = Infinity;
        return {
          limit(value: number) { limit = value; return this; },
          async toArray() { return records.filter((record) => matches(record, filter)).slice(0, limit); },
        };
      },
      async countDocuments(filter: Document) {
        return records.filter((record) => matches(record, filter)).length;
      },
      createIndex: async () => "test-index",
      updateOne: async (filter: Document, update: Document) => {
        if (records.some((record) => matches(record, filter))) {
          return { upsertedCount: 0 };
        }
        records.push(structuredClone(update.$setOnInsert) as Document);
        // structuredClone não preserva ObjectId; conserve esse identificador.
        records[records.length - 1]!._id = update.$setOnInsert._id;
        this.writes++;
        return { upsertedCount: 1 };
      },
    };
  }

  asDb(): Db { return this as unknown as Db; }
}

function matches(record: Document, filter: Document): boolean {
  return Object.entries(filter).every(([key, value]) => {
    if (key === "$or") return (value as Document[]).some((part) => matches(record, part));
    if (value instanceof RegExp) return typeof record[key] === "string" && value.test(record[key]);
    return record[key] === value;
  });
}

describe("seed ADMIN", () => {
  it("validates password length including the bcrypt byte limit", () => {
    for (const invalid of [undefined, "", "1234567", "        ", "é".repeat(37), "a".repeat(73)]) {
      assert.throws(() => validateSeedPassword(invalid), /SEED_DEMO_PASSWORD/);
    }
    assert.doesNotThrow(() => validateSeedPassword("a".repeat(72)));
  });

  it("creates linked records and reuses them without overwriting on the second execution", async () => {
    const memory = new MemoryDatabase();
    const unrelated = { _id: new ObjectId(), normalizedIdentity: "real.user", email: "real@example.com", active: true };
    memory.records.set("auth_users", [unrelated]);
    const first = await seedAdminDemo(memory.asDb(), password);
    assert.deepEqual(first, {
      auth_users: { created: 4, reused: 0 },
      academic_courses: { created: 1, reused: 0 },
      academic_classes: { created: 1, reused: 0 },
      academic_enrollments: { created: 2, reused: 0 },
      academic_class_sessions: { created: 1, reused: 0 },
    });
    const users = memory.records.get("auth_users")!;
    const admin = users.find((user) => user.profile === "admin")!;
    const professor = users.find((user) => user.profile === "docente")!;
    for (const account of users.filter((user) => user !== unrelated)) {
      assert.notEqual(account.passwordHash, password);
      assert.equal(await bcrypt.compare(password, account.passwordHash), true);
      assert.equal(bcrypt.getRounds(account.passwordHash), 12);
      assert.equal(account.active, true);
    }
    assert.equal(new Set(users.filter((user) => user !== unrelated).map((user) => user.passwordHash)).size, 4);
    assert.equal(memory.records.get("academic_courses")![0]!.studentsCount, 2);
    const classroom = memory.records.get("academic_classes")![0]!;
    assert.equal(classroom.professorId, String(professor._id));
    assert.equal(classroom.createdBy, String(admin._id));
    for (const enrollment of memory.records.get("academic_enrollments")!) {
      assert.equal(enrollment.classCode, classroom.code);
      assert.equal(enrollment.courseCode, classroom.courseCode);
      assert.ok(users.some((user) => String(user._id) === enrollment.studentId && user.profile === "aluno"));
    }
    const session = memory.records.get("academic_class_sessions")![0]!;
    assert.equal(session.classCode, classroom.code);
    assert.ok(session.endsAt > session.startsAt);
    admin.displayName = "Nome atualizado pelo administrador";
    const before = JSON.stringify([...memory.records]);
    const second = await seedAdminDemo(memory.asDb(), password);
    assert.deepEqual(second, {
      auth_users: { created: 0, reused: 4 },
      academic_courses: { created: 0, reused: 1 },
      academic_classes: { created: 0, reused: 1 },
      academic_enrollments: { created: 0, reused: 2 },
      academic_class_sessions: { created: 0, reused: 1 },
    });
    assert.equal(memory.writes, 9);
    assert.equal(JSON.stringify([...memory.records]), before);
    assert.equal(memory.records.get("auth_users")![0], unrelated);
  });

  it("refuses a conflicting email before inserting any record", async () => {
    const memory = new MemoryDatabase();
    const existing = { _id: new ObjectId(), normalizedIdentity: "another.user", email: "ALUNO.DEMO2@example.com", profile: "aluno", active: true };
    memory.records.set("auth_users", [existing]);
    await assert.rejects(seedAdminDemo(memory.asDb(), password), /incompatível/);
    assert.equal(memory.writes, 0);
    assert.deepEqual(memory.records.get("auth_users"), [existing]);
  });

  it("preserves existing credentials and refuses a different demonstration password", async () => {
    const memory = new MemoryDatabase();
    await seedAdminDemo(memory.asDb(), password);
    const before = JSON.stringify([...memory.records]);
    await assert.rejects(seedAdminDemo(memory.asDb(), "Another-password-2026!"), /senha existente foi preservada/);
    assert.equal(JSON.stringify([...memory.records]), before);
  });

  it("rejects a suspended demo account before any further writes", async () => {
    const memory = new MemoryDatabase();
    await seedAdminDemo(memory.asDb(), password);
    memory.records.get("auth_users")![1]!.active = false;
    const writes = memory.writes;
    await assert.rejects(seedAdminDemo(memory.asDb(), password), /campo active/);
    assert.equal(memory.writes, writes);
  });

  it("detects incompatible academic links before creating demo users", async () => {
    const memory = new MemoryDatabase();
    memory.records.set("academic_classes", [{
      _id: new ObjectId(), code: "ES-DEMO-4N", courseCode: "REAL-COURSE",
    }]);
    await assert.rejects(seedAdminDemo(memory.asDb(), password), /campo courseCode/);
    assert.equal(memory.writes, 0);
  });

  it("can finish a previous partial execution without duplicating users", async () => {
    const memory = new MemoryDatabase();
    await seedAdminDemo(memory.asDb(), password);
    memory.records.set("academic_courses", []);
    memory.records.set("academic_classes", []);
    memory.records.set("academic_enrollments", []);
    memory.records.set("academic_class_sessions", []);
    const originalUsers = JSON.stringify(memory.records.get("auth_users"));
    const summary = await seedAdminDemo(memory.asDb(), password);
    assert.deepEqual(summary.auth_users, { created: 0, reused: 4 });
    assert.equal(summary.academic_enrollments?.created, 2);
    assert.equal(JSON.stringify(memory.records.get("auth_users")), originalUsers);
  });

  it("refuses inconsistent session dates without overwriting existing data", async () => {
    const memory = new MemoryDatabase();
    await seedAdminDemo(memory.asDb(), password);
    memory.records.get("academic_class_sessions")![0]!.endsAt = new Date("2020-01-01");
    const before = JSON.stringify([...memory.records]);
    await assert.rejects(seedAdminDemo(memory.asDb(), password), /aula demonstrativa/);
    assert.equal(JSON.stringify([...memory.records]), before);
  });
});
