// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { after, before, describe, it } from "node:test";
import jwt from "jsonwebtoken";
import { ObjectId, type Db } from "mongodb";
import { createApp } from "../../app.js";
import type { Environment } from "../../config/environment.js";
import { AuthService } from "../../modules/auth/application/auth.service.js";
import type { AuthUser } from "../../modules/auth/domain/auth.types.js";

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
  users: {
    async findByIdentity(identity) {
      return identity.trim().toLowerCase() === user.normalizedIdentity
        ? user
        : null;
    },
    async updatePassword() {},
  },
  recoveryCodes: {
    async resetPassword() {
      return false;
    },
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
    jwtTtl: "15m",
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
  collection(name: string) {
    if (name === "auth_users") {
      return {
        async findOne(filter: Record<string, unknown>) {
          return {
            _id: filter._id,
            active: true,
            profile: String(filter._id) === "000000000000000000000001" ? "admin" : "aluno",
            sessionVersion: 0,
          };
        },
      };
    }
    if (name === "auth_sessions") {
      return {
        async findOne() {
          return {};
        },
      };
    }
    if (name === "academic_enrollments") {
      return {
        aggregate() {
          return {
            async toArray() {
              return [];
            },
          };
        },
      };
    }
    return courseCollection;
  },
} as unknown as Db;

const app = createApp(
  authService,
  {
    nodeEnv: "test",
    corsOrigins: ["http://localhost:5000"],
  } satisfies Pick<Environment, "nodeEnv" | "corsOrigins">,
  {
    database,
    jwtSecret: adminJwtSecret,
  },
);
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
    assert.equal((await response.json()).code, "invalid_request");
  });

  it("restricts course management to an authenticated administrator", async () => {
    const unauthorized = await fetch(`${baseUrl}/api/admin/courses`);
    assert.equal(unauthorized.status, 401);

    const studentToken = jwt.sign(
      { sub: "000000000000000000000002", profile: "aluno", ver: 0, jti: "student-session" },
      adminJwtSecret,
      { expiresIn: "15m" },
    );
    const forbidden = await fetch(`${baseUrl}/api/admin/courses`, {
      headers: { authorization: `Bearer ${studentToken}` },
    });
    assert.equal(forbidden.status, 403);

    const adminToken = jwt.sign(
      { sub: "000000000000000000000001", profile: "admin", ver: 0, jti: "admin-session" },
      adminJwtSecret,
      { expiresIn: "15m" },
    );
    storedCourses.push({ _id: new ObjectId(), code: "CS-TEST", name: "Curso de teste" });
    const listed = await fetch(`${baseUrl}/api/admin/courses`, {
      headers: { authorization: `Bearer ${adminToken}` },
    });
    assert.equal(listed.status, 200);
    assert.equal((await listed.json()).length, 1);
  });
});

