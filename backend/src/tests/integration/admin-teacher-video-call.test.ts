// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { randomUUID } from "node:crypto";
import { after, before, describe, it } from "node:test";
import jwt from "jsonwebtoken";
import { ObjectId, type Db, type Document } from "mongodb";
import { createApp } from "../../app.js";
import type { Environment } from "../../config/environment.js";

interface TestUser extends Document {
  _id: ObjectId;
  identity: string;
  normalizedIdentity: string;
  email: string;
  displayName: string;
  profile: string;
  passwordHash: string;
  active: boolean;
  sessionVersion: number;
  department?: string;
  departmentOrCourse?: string;
}

interface TestClass extends Document {
  code: string;
  professorId?: string;
  professorIdentity?: string;
  professorName?: string;
}

const jwtSecret = "admin-teacher-video-call-test-secret-at-least-32";
const internalServiceSecret = "admin-teacher-internal-bridge-secret-at-least-32";

const teacher: TestUser = {
  _id: new ObjectId(),
  identity: "DOC-ABCDE12345",
  normalizedIdentity: "doc-abcde12345",
  email: "teacher@example.edu",
  displayName: "Professora Exemplo",
  profile: "docente",
  passwordHash: "secret-hash-never-exposed",
  active: true,
  sessionVersion: 0,
  department: "Computação",
};
const student: TestUser = {
  _id: new ObjectId(),
  identity: "STU-101",
  normalizedIdentity: "stu-101",
  email: "student@example.edu",
  displayName: "Estudante",
  profile: "aluno",
  passwordHash: "not-used",
  active: true,
  sessionVersion: 0,
};
const users: TestUser[] = [teacher, student];
const classRecord: TestClass = { code: "CLASS-101" };
const authSessions = new Map<string, Record<string, unknown>>();
const enrollmentRecords: Array<Record<string, unknown>> = [
  { classCode: "CLASS-101", studentId: student._id.toHexString(), status: "active" },
];

const userCollection = {
  async findOne(query: Record<string, unknown>) {
    return (
      users.find((user) => {
        if (query._id instanceof ObjectId && !user._id.equals(query._id)) return false;
        if (typeof query.normalizedIdentity === "string" && user.normalizedIdentity !== query.normalizedIdentity) return false;
        if (typeof query.profile === "string" && user.profile !== query.profile) return false;
        if (query.active === true && !user.active) return false;
        return true;
      }) ?? null
    );
  },
  find() {
    return {
      project() { return this; },
      sort() { return this; },
      async toArray() {
        return users.filter((user) => user.profile === "docente");
      },
    };
  },
};

const classCollection = {
  async findOne(query: Record<string, unknown>) {
    const code = query.code;
    if (typeof code === "string") return classRecord.code === code ? classRecord : null;
    if (code && typeof code === "object" && "$regex" in code) {
      const matcher = code as { $regex: string; $options: string };
      return new RegExp(matcher.$regex, matcher.$options).test(classRecord.code) ? classRecord : null;
    }
    return null;
  },
  find() {
    return {
      sort() { return this; },
      async toArray() { return [classRecord]; },
    };
  },
  async updateOne(filter: Record<string, unknown>, update: { $set?: Record<string, unknown> }) {
    if (filter.code === classRecord.code && update.$set) {
      Object.assign(classRecord, update.$set);
      return { matchedCount: 1 };
    }
    return { matchedCount: 0 };
  },
};

const enrollmentCollection = {
  async findOne(query: Record<string, unknown>) {
    return (
      enrollmentRecords.find(
        (entry) =>
          entry.classCode === query.classCode &&
          entry.studentId === query.studentId &&
          entry.status === query.status,
      ) ?? null
    );
  },
  find() {
    return { async toArray() { return enrollmentRecords; } };
  },
};

const database = {
  collection(name: string) {
    switch (name) {
      case "auth_users": return userCollection;
      case "auth_sessions":
        return {
          async findOne(query: Record<string, unknown>) {
            const session = authSessions.get(String(query.sessionId ?? ""));
            if (!session || session.userId !== query.userId || !(session.expiresAt instanceof Date)) return null;
            return session.expiresAt > new Date() ? session : null;
          },
        };
      case "academic_classes": return classCollection;
      case "academic_enrollments": return enrollmentCollection;
      case "admin_write_guard":
      case "admin_audit_logs":
        return { async insertOne() {}, async updateOne() {} };
      default:
        return {
          async findOne() { return null; },
          find() {
            return {
              sort() { return { toArray: async () => [] }; },
              async toArray() { return []; },
            };
          },
        };
    }
  },
} as unknown as Db;

const app = createApp(
  {
    nodeEnv: "test",
    corsOrigins: ["http://localhost:5000"],
  } satisfies Pick<Environment, "nodeEnv" | "corsOrigins">,
  { database, jwtSecret, internalServiceSecret },
);
const server = createServer(app);
let baseUrl = "";

function token(profile: string, id: ObjectId): string {
  if (profile === "admin") {
    return jwt.sign({ profile }, jwtSecret, { subject: id.toString() });
  }
  const sessionId = randomUUID();
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000);
  authSessions.set(sessionId, { sessionId, userId: id.toString(), expiresAt });
  return jwt.sign({ profile, ver: 0 }, jwtSecret, {
    subject: id.toString(),
    jwtid: sessionId,
    expiresIn: "15m",
  });
}

before(async () => {
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("Não foi possível iniciar o servidor HTTP de teste.");
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  await new Promise<void>((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
});

describe("alocação acadêmica de docentes e autorização interna de videochamada", () => {
  it("mantém GET /api/admin/teachers somente-leitura, rejeita criação/videochamada pública e autoriza via ponte interna", async () => {
    const adminToken = token("admin", new ObjectId());

    const postTeacher = await fetch(`${baseUrl}/api/admin/teachers`, {
      method: "POST",
      headers: { authorization: `Bearer ${adminToken}`, "content-type": "application/json" },
      body: JSON.stringify({ name: "X", email: "x@example.edu", department: "TI" }),
    });
    assert.equal(postTeacher.status, 404);

    const listResponse = await fetch(`${baseUrl}/api/admin/teachers`, {
      headers: { authorization: `Bearer ${adminToken}` },
    });
    assert.equal(listResponse.status, 200);
    const listed = (await listResponse.json()) as Array<Record<string, unknown>>;
    assert.equal(listed.length, 1);
    assert.equal(listed[0]?.identity, teacher.identity);
    assert.equal("passwordHash" in (listed[0] ?? {}), false);

    // Docente não alocado é bloqueado na ponte interna antes da alocação
    const deniedBefore = await fetch(
      `${baseUrl}/api/internal/academic/video-call/authorize?userId=${teacher._id.toHexString()}&profile=docente&identity=${teacher.identity}&roomCode=${classRecord.code}`,
      { headers: { "x-internal-service-secret": internalServiceSecret } },
    );
    assert.equal(deniedBefore.status, 403);

    // Alocar docente à turma pela API acadêmica
    const assignmentResponse = await fetch(
      `${baseUrl}/api/admin/classes/${classRecord.code}/professor`,
      {
        method: "PATCH",
        headers: { authorization: `Bearer ${adminToken}`, "content-type": "application/json" },
        body: JSON.stringify({ professorIdentity: teacher.identity }),
      },
    );
    assert.equal(assignmentResponse.status, 200);

    const allowedAfter = await fetch(
      `${baseUrl}/api/internal/academic/video-call/authorize?userId=${teacher._id.toHexString()}&profile=docente&identity=${teacher.identity}&roomCode=${classRecord.code}`,
      { headers: { "x-internal-service-secret": internalServiceSecret } },
    );
    assert.equal(allowedAfter.status, 200);
    assert.equal((await allowedAfter.json()).allowed, true);
  });
});
