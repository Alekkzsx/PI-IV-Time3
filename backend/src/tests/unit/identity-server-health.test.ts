// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { createServer, type Server } from "node:http";
import { after, before, describe, it } from "node:test";
import type { Db } from "mongodb";
import { createApp } from "../../app.js";
import { createIdentityServerHealthMiddleware } from "../../shared/auth/identity-server-health.middleware.js";

describe("identityServerHealthGuard (Fail-Closed :3001 -> :8080)", () => {
  let server: Server;
  let baseUrl: string;
  let identityOnline = true;
  let probeCalls = 0;

  before(async () => {
    const fakeDb = {
      collection: () => ({}),
    } as unknown as Db;
    const guard = createIdentityServerHealthMiddleware({
      baseUrl: "http://127.0.0.1:8080",
      okCacheTtlMs: 200,
      failCacheTtlMs: 50,
      probe: async () => {
        probeCalls += 1;
        return identityOnline;
      },
    });
    const app = createApp(
      { nodeEnv: "test", corsOrigins: [] },
      {
        database: fakeDb,
        jwtSecret: "segredo-jwt-teste-minimo-32-caracteres-ok",
        identityServerHealthGuard: guard,
      },
    );
    server = createServer(app);
    await new Promise<void>((resolve) => {
      server.listen(0, "127.0.0.1", () => resolve());
    });
    const address = server.address();
    assert(address && typeof address === "object");
    baseUrl = `http://127.0.0.1:${address.port}`;
  });

  after(async () => {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  });

  it("retorna 503 identity_service_unavailable quando servidor Java (:8080) está offline e mantém /health livre", async () => {
    identityOnline = false;
    probeCalls = 0;

    const healthResp = await fetch(`${baseUrl}/health`);
    assert.equal(healthResp.status, 200);
    assert.equal(probeCalls, 0);

    const studentResp = await fetch(`${baseUrl}/api/student/dashboard`);
    assert.equal(studentResp.status, 503);
    const body = (await studentResp.json()) as { code?: string; message?: string };
    assert.equal(body.code, "identity_service_unavailable");
    assert.equal(probeCalls, 1);

    // Dentro da janela de cache de falha, reutiliza resultado sem novo probe
    const teacherResp = await fetch(`${baseUrl}/api/teacher/classes`);
    assert.equal(teacherResp.status, 503);
    assert.equal(probeCalls, 1);
  });

  it("permite continuar o fluxo normal (401 de autenticação) quando servidor Java (:8080) volta online", async () => {
    await new Promise((resolve) => setTimeout(resolve, 70));
    identityOnline = true;
    const beforeCalls = probeCalls;

    const resp = await fetch(`${baseUrl}/api/student/dashboard`);
    assert.equal(resp.status, 401);
    assert.equal(probeCalls, beforeCalls + 1);
  });
});
