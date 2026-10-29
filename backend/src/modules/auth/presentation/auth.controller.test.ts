// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { after, before, describe, it } from "node:test";
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

const app = createApp(authService, {
  nodeEnv: "test",
  corsOrigins: ["http://localhost:5000"],
} satisfies Pick<Environment, "nodeEnv" | "corsOrigins">);
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
});
