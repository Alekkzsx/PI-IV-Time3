// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { randomUUID } from "node:crypto";
import { after, before, describe, it } from "node:test";
import jwt from "jsonwebtoken";
import { ObjectId, type Db, type Document } from "mongodb";
import { createApp } from "../../app.js";
import type { Environment } from "../../config/environment.js";
import { AuthService } from "../../modules/auth/application/auth.service.js";

interface TestUser extends Document {
  _id: ObjectId;
  identity: string;
  normalizedIdentity: string;
  email: string;
  displayName: string;
  profile: string;
  passwordHash: string;
  active: boolean;
  department?: string;
}

interface TestClass extends Document {
  code: string;
  professorId?: string;
  professorIdentity?: string;
}

const jwtSecret = "admin-teacher-video-call-test-secret-at-least-32";
const student: TestUser = {
  _id: new ObjectId(),
  identity: "STU-101",
  normalizedIdentity: "stu-101",
  email: "student@example.edu",
  displayName: "Estudante",
  profile: "aluno",
  passwordHash: "not-used",
  active: true,
};
const users: TestUser[] = [student];
const classRecord: TestClass = { code: "CLASS-101" };
const activeSessions = new Map<string, Record<string, unknown>>();
const authSessions = new Map<string, Record<string, unknown>>();
const webSocketTickets = new Map<string, Record<string, unknown>>();
const userCollection = {
  async findOne(query: Record<string, unknown>) {
    return (
      users.find((user) => {
        if (query._id instanceof ObjectId && !user._id.equals(query._id)) {
          return false;
        }
        if (
          typeof query.normalizedIdentity === "string" &&
          user.normalizedIdentity !== query.normalizedIdentity
        ) {
          return false;
        }
        if (
          typeof query.profile === "string" &&
          user.profile !== query.profile
        ) {
          return false;
        }
        if (query.active === true && !user.active) return false;
        if (query.email && typeof query.email === "object") {
          const matcher = query.email as { $regex: string; $options: string };
          if (!new RegExp(matcher.$regex, matcher.$options).test(user.email)) {
            return false;
          }
        }
        return true;
      }) ?? null
    );
  },
  find() {
    return {
      project() {
        return this;
      },
      sort() {
        return this;
      },
      async toArray() {
        return users.filter((user) => user.profile === "docente");
      },
    };
  },
  async insertOne(input: Document) {
    const user = { ...input, _id: new ObjectId() } as TestUser;
    users.push(user);
    return { insertedId: user._id };
  },
};
const classCollection = {
  async findOne(query: Record<string, unknown>) {
    const code = query.code;
    if (typeof code === "string") {
      return classRecord.code === code ? classRecord : null;
    }
    if (code && typeof code === "object") {
      const matcher = code as { $regex: string; $options: string };
      return new RegExp(matcher.$regex, matcher.$options).test(classRecord.code)
        ? classRecord
        : null;
    }
    return null;
  },
  async updateOne(
    _query: Record<string, unknown>,
    update: { $set: Record<string, unknown> },
  ) {
    Object.assign(classRecord, update.$set);
    return { matchedCount: 1 };
  },
};
const enrollmentCollection = {
  async findOne(query: Record<string, unknown>) {
    return query.studentId === student._id.toString() &&
        query.classCode === classRecord.code &&
        query.status === "active"
      ? { classCode: classRecord.code }
      : null;
  },
};
const sessionCollection = {
  async updateOne(
    _query: Record<string, unknown>,
    update: { $set: Record<string, unknown> },
  ) {
    activeSessions.set(String(update.$set.roomCode), update.$set);
    return { upsertedCount: 1 };
  },
  async findOne(query: Record<string, unknown>) {
    return activeSessions.get(String(query.roomCode)) ?? null;
  },
  async deleteOne(query: Record<string, unknown>) {
    return {
      deletedCount: activeSessions.delete(String(query.roomCode)) ? 1 : 0,
    };
  },
};
const webSocketTicketCollection = {
  async insertOne(input: Document) {
    webSocketTickets.set(String(input.tokenDigest), input);
    return { insertedId: new ObjectId() };
  },
  async findOneAndDelete(query: Record<string, unknown>) {
    const digest = String(query.tokenDigest);
    const record = webSocketTickets.get(digest);
    const expiresAfter = (query.expiresAt as { $gt: Date } | undefined)?.$gt;
    if (
      !record ||
      record.roomCode !== query.roomCode ||
      !(record.expiresAt instanceof Date) ||
      !expiresAfter ||
      record.expiresAt <= expiresAfter
    ) {
      return null;
    }
    webSocketTickets.delete(digest);
    return record;
  },
};
const authSessionCollection = {
  async findOne(query: Record<string, unknown>) {
    const record = authSessions.get(String(query.sessionId));
    const expiration = (query.expiresAt as { $gt: Date } | undefined)?.$gt;
    return record &&
        record.userId === query.userId &&
        record.expiresAt instanceof Date &&
        expiration instanceof Date &&
        record.expiresAt > expiration
      ? record
      : null;
  },
};
const database = {
  collection(name: string) {
    switch (name) {
      case "auth_users":
        return userCollection;
      case "academic_classes":
        return classCollection;
      case "academic_enrollments":
        return enrollmentCollection;
      case "academic_live_sessions":
        return sessionCollection;
      case "video_call_ws_tickets":
        return webSocketTicketCollection;
      case "auth_sessions":
        return authSessionCollection;
      default:
        return {
          find() {
            return {
              sort() {
                return { toArray: async () => [] };
              },
            };
          },
        };
    }
  },
} as unknown as Db;

const authService = new AuthService({
  users: {
    async findByIdentity() {
      return null;
    },
    async updatePassword() {},
  },
  security: {
    async assertLoginAllowed() {},
    async recordLoginFailure() {},
    async clearLoginFailures() {},
    async saveSession() {},
    async saveChallenge() {},
    async consumeChallenge() {
      return null;
    },
  },
  recoveryCodes: {
    async save() {},
    async find() {
      return null;
    },
    async incrementFailedAttempts() {
      return null;
    },
    async issueResetGrant() {},
    async consumeResetGrant() {
      return false;
    },
    async resetPassword() {
      return false;
    },
    async delete() {},
  },
  passwords: {
    async hash(password) {
      return password;
    },
    async verify() {
      return false;
    },
  },
  accessTokens: {
    issue() {
      return "unused";
    },
  },
  recoveryEmail: {
    async sendRecoveryCode() {},
  },
  dummyPasswordHash: "unused",
  environment: {
    jwtSecret,
    otpSecret: "a-different-test-secret-with-at-least-32-characters",
    otpTtlSeconds: 300,
    otpMaxAttempts: 3,
    jwtTtl: "15m",
  },
});
const app = createApp(
  authService,
  {
    nodeEnv: "test",
    corsOrigins: ["http://localhost:5000"],
  } satisfies Pick<Environment, "nodeEnv" | "corsOrigins">,
  { database, jwtSecret },
);
const server = createServer(app);
let baseUrl: string;

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

async function post(
  path: string,
  authToken: string,
  body: Record<string, unknown>,
): Promise<Response> {
  return fetch(`${baseUrl}${path}`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${authToken}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

before(async () => {
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  if (!address || typeof address === "string") {
    throw new Error("Não foi possível iniciar o servidor HTTP de teste.");
  }
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  await new Promise<void>((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

describe("administração de docentes e acesso à videochamada", () => {
  it("persiste docente, atribui turma e permite acesso conforme vínculo", async () => {
    const adminToken = token("admin", new ObjectId());
    const createResponse = await post("/api/admin/teachers", adminToken, {
      name: "Professora Exemplo",
      email: "teacher@example.edu",
      department: "Computação",
    });
    assert.equal(createResponse.status, 201);
    const created = (await createResponse.json()) as { identity: string };
    assert.match(created.identity, /^DOC-[A-F0-9]{10}$/);

    const teacher = users.find((user) => user.identity === created.identity);
    assert.ok(teacher);
    assert.notEqual(teacher.passwordHash, "");

    const listResponse = await fetch(`${baseUrl}/api/admin/teachers`, {
      headers: { authorization: `Bearer ${adminToken}` },
    });
    assert.equal(listResponse.status, 200);
    const listed = (await listResponse.json()) as Array<Record<string, unknown>>;
    assert.equal(listed.length, 1);
    const listedTeacher = listed[0];
    assert.ok(listedTeacher);
    assert.equal(listedTeacher.identity, created.identity);
    assert.equal("passwordHash" in listedTeacher, false);

    const teacherToken = token("docente", teacher._id);
    const deniedBeforeAssignment = await post(
      "/api/video-call/rooms/enter",
      teacherToken,
      { roomCode: classRecord.code },
    );
    assert.equal(deniedBeforeAssignment.status, 403);

    const assignmentResponse = await fetch(
      `${baseUrl}/api/admin/classes/${classRecord.code}/professor`,
      {
        method: "PATCH",
        headers: {
          authorization: `Bearer ${adminToken}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({ professorIdentity: created.identity }),
      },
    );
    assert.equal(assignmentResponse.status, 200);

    const opened = await post(
      "/api/video-call/rooms/enter",
      teacherToken,
      { roomCode: classRecord.code },
    );
    assert.equal(opened.status, 200);
    const openedBody = (await opened.json()) as {
      roomCode: string;
      opened: boolean;
      webSocketTicket: string;
    };
    assert.deepEqual({ roomCode: openedBody.roomCode, opened: openedBody.opened }, {
      roomCode: classRecord.code,
      opened: true,
    });
    assert.match(openedBody.webSocketTicket, /^[A-Za-z0-9_-]{43}$/);
    const ticketQuery = new URLSearchParams({
      ticket: openedBody.webSocketTicket,
      roomCode: classRecord.code,
    });
    const consumedTicket = await fetch(
      `${baseUrl}/api/video-call/rooms/consume-ticket?${ticketQuery}`,
      { method: "POST" },
    );
    assert.equal(consumedTicket.status, 204);
    const reusedTicket = await fetch(
      `${baseUrl}/api/video-call/rooms/consume-ticket?${ticketQuery}`,
      { method: "POST" },
    );
    assert.equal(reusedTicket.status, 401);

    const joined = await post(
      "/api/video-call/rooms/enter",
      token("aluno", student._id),
      { roomCode: classRecord.code },
    );
    assert.equal(joined.status, 200);
    const joinedBody = (await joined.json()) as {
      roomCode: string;
      opened: boolean;
      webSocketTicket: string;
    };
    assert.deepEqual({ roomCode: joinedBody.roomCode, opened: joinedBody.opened }, {
      roomCode: classRecord.code,
      opened: false,
    });
    assert.match(joinedBody.webSocketTicket, /^[A-Za-z0-9_-]{43}$/);
  });
});

