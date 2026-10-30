// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { after, before, describe, it } from "node:test";
import jwt from "jsonwebtoken";
import type { Db } from "mongodb";
import { createApp } from "../../../app.js";
import type { Environment } from "../../../config/environment.js";
import { AuthService } from "../application/auth.service.js";
import type { AuthUser } from "../domain/auth.types.js";

const user: AuthUser = {
  id: "user-1",
  identity: "2024.1.00001",
  normalizedIdentity: "2024.1.00001",
  email: "student@example.edu",
  displayName: "Estudante",
  profile: "aluno",
  passwordHash: "hashed:correct-password",
  active: true,
};

const authService = new AuthService({
  users: {
    async findByIdentity(identity) {
      return identity.trim().toLowerCase() === user.normalizedIdentity
        ? user
        : null;
    },
    async updatePassword() {},
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
    async delete() {},
  },
  passwords: {
    async hash(password) {
      return `hashed:${password}`;
    },
    async verify(password, passwordHash) {
      return `hashed:${password}` === passwordHash;
    },
  },
  accessTokens: {
    issue(account) {
      return `token:${account.id}`;
    },
  },
  recoveryEmail: {
    async sendRecoveryCode() {},
  },
  dummyPasswordHash: "hashed:timing-decoy",
  environment: {
    jwtSecret: "a-secure-test-secret-with-at-least-32-characters",
    otpSecret: "a-different-secure-test-secret-with-at-least-32-chars",
    otpTtlSeconds: 300,
    otpMaxAttempts: 3,
  },
});

const adminJwtSecret = "admin-route-test-secret-with-at-least-32-characters";
const storedCourses: Array<Record<string, unknown>> = [];
let nextCourseId = 1;
const courseCollection = {
  find() {
    return {
      sort() {
        return { toArray: async () => storedCourses };
      },
    };
  },
  async insertOne(course: Record<string, unknown>) {
    const id = `course-${nextCourseId++}`;
    storedCourses.push({ ...course, _id: { toString: () => id } });
    return { insertedId: { toString: () => id } };
  },
};
const database = {
  collection(_name: string) {
    return courseCollection;
  },
} as unknown as Db;

const app = createApp(authService, {
  nodeEnv: "test",
  corsOrigins: ["http://localhost:5000"],
} satisfies Pick<Environment, "nodeEnv" | "corsOrigins">, {
  database,
  jwtSecret: adminJwtSecret,
});
const server = createServer(app);
let baseUrl: string;

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

describe("auth HTTP API", () => {
  it("reports health and issues a bearer token after valid login", async () => {
    const health = await fetch(`${baseUrl}/health`);
    assert.equal(health.status, 200);
    assert.deepEqual(await health.json(), { status: "ok" });

    const login = await fetch(`${baseUrl}/api/auth/login`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        identity: user.identity,
        password: "correct-password",
        profile: "aluno",
      }),
    });
    assert.equal(login.status, 200);
    assert.deepEqual(await login.json(), {
      success: true,
      accessToken: "token:user-1",
      tokenType: "Bearer",
    });
  });

  it("rejects profiles outside the three supported roles", async () => {
    const response = await fetch(`${baseUrl}/api/auth/login`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        identity: user.identity,
        password: "correct-password",
        profile: "monitor",
      }),
    });

    assert.equal(response.status, 400);
    assert.equal(
      (await response.json()).code,
      "invalid_request",
    );
  });

  it("restricts course management to an authenticated administrator", async () => {
    const unauthorized = await fetch(`${baseUrl}/api/admin/courses`);
    assert.equal(unauthorized.status, 401);

    const studentToken = jwt.sign(
      { sub: user.id, profile: "aluno" },
      adminJwtSecret,
    );
    const forbidden = await fetch(`${baseUrl}/api/admin/courses`, {
      headers: { authorization: `Bearer ${studentToken}` },
    });
    assert.equal(forbidden.status, 403);

    const adminToken = jwt.sign(
      { sub: "admin-1", profile: "admin" },
      adminJwtSecret,
    );
    const created = await fetch(`${baseUrl}/api/admin/courses`, {
      method: "POST",
      headers: {
        authorization: `Bearer ${adminToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        code: "CS-TEST",
        name: "Curso de teste",
        matrix: "2026",
        workload: "3000h",
        formula: "Média ponderada",
        department: "Computação",
        modality: "Graduação",
        components: [],
      }),
    });
    assert.equal(created.status, 201);
    assert.equal((await created.json()).code, "CS-TEST");

    const listed = await fetch(`${baseUrl}/api/admin/courses`, {
      headers: { authorization: `Bearer ${adminToken}` },
    });
    assert.equal(listed.status, 200);
    assert.equal((await listed.json()).length, 1);
  });
});
