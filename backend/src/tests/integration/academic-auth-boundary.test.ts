// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { createServer } from "node:http";
import { randomUUID } from "node:crypto";
import { after, before, describe, it } from "node:test";
import jwt from "jsonwebtoken";
import { ObjectId, type Db, type Document } from "mongodb";
import { createApp } from "../../app.js";

const jwtSecret = "academic-boundary-test-secret-with-at-least-32-chars";
const internalServiceSecret = "internal-bridge-test-secret-with-at-least-32-chars";

const activeStudent = {
  _id: new ObjectId(),
  identity: "2024.1.00001",
  normalizedIdentity: "2024.1.00001",
  email: "student@example.edu",
  displayName: "Estudante",
  profile: "aluno",
  active: true,
  sessionVersion: 2,
  requirePasswordChange: false,
};

const pendingPasswordStudent = {
  _id: new ObjectId(),
  identity: "2024.1.00002",
  normalizedIdentity: "2024.1.00002",
  email: "pending@example.edu",
  displayName: "Estudante Troca",
  profile: "aluno",
  active: true,
  sessionVersion: 0,
  requirePasswordChange: true,
};

const activeAdmin = {
  _id: new ObjectId(),
  identity: "admin.demo",
  normalizedIdentity: "admin.demo",
  email: "admin@example.edu",
  displayName: "Administrador",
  profile: "admin",
  active: true,
  sessionVersion: 1,
  requirePasswordChange: false,
};

const users = [activeStudent, pendingPasswordStudent, activeAdmin];
const authSessions = new Map<string, Record<string, unknown>>();
const emptyCursor = {
  sort() { return this; },
  limit() { return this; },
  skip() { return this; },
  project() { return this; },
  async toArray() { return []; },
};

const database = {
  collection(name: string) {
    switch (name) {
      case "auth_users":
        return {
          async findOne(query: Record<string, unknown>) {
            return (
              users.find((u) => {
                if (query._id instanceof ObjectId && !u._id.equals(query._id)) return false;
                if (query.active === true && !u.active) return false;
                return true;
              }) ?? null
            );
          },
          find() {
            return {
              ...emptyCursor,
              async toArray() {
                return users.filter((u) => u.profile === "docente");
              },
            };
          },
          async countDocuments() { return 0; },
        };
      case "auth_sessions":
        return {
          async findOne(query: Record<string, unknown>) {
            const session = authSessions.get(String(query.sessionId ?? ""));
            if (!session) return null;
            if (session.userId !== query.userId) return null;
            if (session.active === false) return null;
            if (!(session.expiresAt instanceof Date) || session.expiresAt <= new Date()) return null;
            return session;
          },
          find() {
            return {
              ...emptyCursor,
              async toArray() {
                return Array.from(authSessions.values());
              },
            };
          },
        };
      case "admin_settings":
        return { async findOne() { return null; } };
      default:
        return {
          async findOne() { return null; },
          find() { return emptyCursor; },
          async countDocuments() { return 0; },
          aggregate() { return { async toArray() { return []; } }; },
        };
    }
  },
} as unknown as Db;

const app = createApp(
  { nodeEnv: "test", corsOrigins: ["http://localhost:5000"] },
  { database, jwtSecret, internalServiceSecret },
);
const server = createServer(app);
let baseUrl = "";

function issueSessionToken(user: typeof activeStudent): { token: string; sessionId: string } {
  const sessionId = randomUUID();
  authSessions.set(sessionId, {
    sessionId,
    userId: user._id.toHexString(),
    active: true,
    expiresAt: new Date(Date.now() + 15 * 60 * 1000),
  });
  const token = jwt.sign(
    {
      sub: user._id.toHexString(),
      profile: user.profile,
      ver: user.sessionVersion,
      jti: sessionId,
    },
    jwtSecret,
    { expiresIn: "15m" },
  );
  return { token, sessionId };
}

before(async () => {
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("Falha ao abrir porta de teste.");
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  await new Promise<void>((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
});

describe("fronteira de contexto delimitado (API Acadêmica :3001 vs Java :8080)", () => {
  it("expõe health acadêmico e rejeita rotas movidas para o servidor Java (404)", async () => {
    const health = await fetch(`${baseUrl}/health`);
    assert.equal(health.status, 200);
    assert.deepEqual(await health.json(), { status: "ok", service: "agmrm-academic-api" });

    const movedRoutes: Array<[string, string]> = [
      ["POST", "/api/auth/login"],
      ["POST", "/api/auth/verify-two-factor"],
      ["POST", "/api/auth/send-recovery-otp"],
      ["GET", "/api/auth/me"],
      ["PATCH", "/api/auth/profile"],
      ["GET", "/api/auth/sessions"],
      ["GET", "/api/auth/lgpd-export"],
      ["GET", "/api/admin/users"],
      ["POST", "/api/admin/users"],
      ["GET", `/api/admin/users/${activeStudent._id.toHexString()}/dossier`],
      ["POST", "/api/admin/teachers"],
      ["GET", "/api/video-call/rooms"],
      ["POST", "/api/video-call/rooms/enter"],
      ["POST", "/api/video-call/rooms/consume-ticket"],
    ];

    for (const [method, path] of movedRoutes) {
      const response = await fetch(`${baseUrl}${path}`, { method });
      assert.equal(response.status, 404, `Esperado 404 em ${method} ${path}, recebido ${response.status}`);
    }
  });

  it("valida passivamente JWT HS256 do Java + auth_users/auth_sessions nas rotas acadêmicas", async () => {
    const { token, sessionId } = issueSessionToken(activeStudent);
    const allowed = await fetch(`${baseUrl}/api/student/bootstrap`, {
      headers: { authorization: `Bearer ${token}` },
    });
    assert.equal(allowed.status, 200);

    // Revogação imediata da sessão no MongoDB invalida o JWT mesmo antes do exp
    authSessions.delete(sessionId);
    const revoked = await fetch(`${baseUrl}/api/student/bootstrap`, {
      headers: { authorization: `Bearer ${token}` },
    });
    assert.equal(revoked.status, 401);

    // Token com requirePasswordChange=true é bloqueado na API acadêmica
    const pending = issueSessionToken(pendingPasswordStudent);
    const blocked = await fetch(`${baseUrl}/api/student/bootstrap`, {
      headers: { authorization: `Bearer ${pending.token}` },
    });
    assert.equal(blocked.status, 403);

    // GET /api/admin/teachers continua disponível em modo somente-leitura para alocação de turmas
    const admin = issueSessionToken(activeAdmin);
    const teachersRes = await fetch(`${baseUrl}/api/admin/teachers`, {
      headers: { authorization: `Bearer ${admin.token}` },
    });
    assert.equal(teachersRes.status, 200);
  });

  it("aceita loopback IPv6 [::1] e Private Network Access em desenvolvimento", async () => {
    const res = await fetch(`${baseUrl}/health`, {
      method: "OPTIONS",
      headers: {
        origin: "http://[::1]:54321",
        "access-control-request-method": "GET",
        "access-control-request-private-network": "true",
      },
    });
    assert.equal(res.status, 204);
    assert.equal(res.headers.get("access-control-allow-origin"), "http://[::1]:54321");
    assert.equal(res.headers.get("access-control-allow-private-network"), "true");
  });
});
