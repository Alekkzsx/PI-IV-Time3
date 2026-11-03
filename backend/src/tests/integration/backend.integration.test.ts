// Desenvolvido por Guilherme Henrique Moreira
import assert from "node:assert/strict";
import { before, after, describe, it } from "node:test";
import { createServer, type Server } from "node:http";
import { randomBytes } from "node:crypto";
import jwt from "jsonwebtoken";
import "../../config/local-environment.js";
import { loadEnvironment } from "../../config/environment.js";
import { MongoAuthDatabase } from "../../modules/auth/infrastructure/mongo-auth.repository.js";
import { MongoAuthSecurityRepository } from "../../modules/auth/infrastructure/mongo-auth-security.repository.js";
import { BcryptPasswordHasher, JwtAccessTokenIssuer } from "../../modules/auth/infrastructure/security.providers.js";
import { AuthService } from "../../modules/auth/application/auth.service.js";
import { createApp } from "../../app.js";
import { seedAdminDemo } from "../../scripts/admin-demo.seed.js";
import type { Db } from "mongodb";
import { AuthError } from "../../shared/auth-error.js";

const enabled = process.env.RUN_DB_TESTS === "1";
describe("autenticação e ADMIN com MongoDB real isolado", { skip: !enabled }, () => {
  const environment = loadEnvironment();
  const testDatabaseName = "agmrm_test_" + randomBytes(8).toString("hex");
  const password = "Integration-only-password-2026!";
  const newPassword = "Changed-integration-password-2026!";
  let connection: MongoAuthDatabase;
  let database: Db;
  let server: Server;
  let base: string;
  let adminToken: string;
  let adminId: string;
  const emails = new Map<string, string>();
  let emailAvailable = true;
  let adminUser: Record<string, any>;

  async function request(method: string, path: string, body?: unknown, token?: string) {
    const response = await fetch(base + path, {
      method,
      headers: { "Content-Type": "application/json", ...(token ? { Authorization: "Bearer " + token } : {}) },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    const text = await response.text();
    return { status: response.status, body: text ? JSON.parse(text) : null };
  }
  async function login(identity: string, profile: string, pass = password) {
    return request("POST", "/api/auth/login", { identity, password: pass, profile });
  }
  const admin = (method: string, path: string, body?: unknown) => request(method, "/api/admin" + path, body, adminToken);

  before(async () => {
    connection = new MongoAuthDatabase(environment.mongoUri, testDatabaseName);
    await connection.connect();
    database = connection.databaseForModules();
    await seedAdminDemo(database, password);
    const passwords = new BcryptPasswordHasher();
    const service = new AuthService({
      users: connection.users(),
      security: new MongoAuthSecurityRepository(database),
      recoveryCodes: connection.recoveryCodes(),
      passwords,
      accessTokens: new JwtAccessTokenIssuer(environment.jwtSecret, environment.jwtTtl),
      recoveryEmail: {
        ensureAvailable() {
          if (!emailAvailable) throw new AuthError(503, "recovery_email_unavailable", "Envio indisponível.");
        },
        async sendRecoveryCode(input) {
          emails.set(input.to, input.code);
        },
      },
      dummyPasswordHash: await passwords.hash("integration-decoy"),
      environment,
    });
    server = createServer(createApp(service, { nodeEnv: "test", corsOrigins: environment.corsOrigins }, { database, jwtSecret: environment.jwtSecret }));
    await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
    const address = server.address();
    if (!address || typeof address === "string") throw new Error("Test server failed.");
    base = "http://127.0.0.1:" + address.port;
    adminToken = (await login("admin.demo", "admin")).body.accessToken;
    adminUser = (await database.collection("auth_users").findOne({ normalizedIdentity: "admin.demo" }))!;
    adminId = String(adminUser._id);
  });

  after(async () => {
    if (server) await new Promise<void>((resolve) => server.close(() => resolve()));
    // A limpeza só pode atingir o banco temporário criado por este arquivo.
    if (database && database.databaseName === testDatabaseName && /^agmrm_test_[a-f0-9]{16}$/.test(testDatabaseName)) await database.dropDatabase();
    if (connection) await connection.close();
  });

  it("accepts real identity and email login for all roles without exposing password hashes", async () => {
    for (const [identity, profile] of [["admin.demo", "admin"], ["prof.demo", "docente"], ["aluno.demo1", "aluno"]]) {
      const result = await login(identity!, profile!);
      assert.equal(result.status, 200);
      const me = await request("GET", "/api/auth/me", undefined, result.body.accessToken);
      assert.equal(me.status, 200);
      assert.equal(me.body.profile, profile);
      assert.equal(me.body.passwordHash, undefined);
      if (profile !== "admin") assert.equal((await request("GET", "/api/admin/users", undefined, result.body.accessToken)).status, 403);
    }
    assert.equal((await login("ADMIN.DEMO@EXAMPLE.COM", "admin")).status, 200);
    assert.equal((await login("aluno.demo1", "admin")).status, 401);
  });

  it("rejects missing, forged, expired and session-less tokens", async () => {
    assert.equal((await request("GET", "/api/admin/users")).status, 401);
    const expired = jwt.sign({ sub: adminId, profile: "admin", ver: 0, jti: "none" }, environment.jwtSecret, { expiresIn: -1 });
    const sessionless = jwt.sign({ sub: adminId, profile: "admin", ver: 0, jti: "none" }, environment.jwtSecret, { expiresIn: "15m" });
    for (const token of ["invalid", expired, sessionless]) assert.equal((await request("GET", "/api/auth/me", undefined, token)).status, 401);
  });

  it("persists login lockout and permits login after its expiry", async () => {
    for (let i = 0; i < 5; i++) assert.equal((await login("aluno.demo2", "aluno", "incorrect-password")).status, 401);
    assert.equal((await login("aluno.demo2", "aluno")).status, 429);
    await database.collection("auth_login_limits").updateMany({}, { $set: { lockedUntil: new Date(0), expiresAt: new Date(0) } });
    assert.equal((await login("aluno.demo2", "aluno")).status, 200);
  });

  it("creates and edits users, rejects duplicates, mass assignment and self-demotion", async () => {
    const input = { identity: "test.user", email: "test.user@example.com", displayName: "Test User", profile: "aluno", password };
    const created = await admin("POST", "/users", input);
    assert.equal(created.status, 201);
    assert.equal(created.body.passwordHash, undefined);
    assert.equal((await admin("POST", "/users", { ...input, identity: "another", email: "TEST.USER@example.com" })).status, 409);
    assert.equal((await admin("POST", "/users", { ...input, active: false })).status, 400);
    assert.equal((await admin("PATCH", "/users/" + created.body.id, { displayName: "Updated Test User" })).status, 200);
    assert.equal((await admin("PATCH", "/users/" + created.body.id, { passwordHash: "unsafe" })).status, 400);
    assert.equal((await admin("PATCH", "/users/" + created.body.id, {})).status, 400);
    assert.equal((await admin("PATCH", "/users/" + adminId, { profile: "aluno" })).status, 409);
    assert.equal((await admin("PATCH", "/users/" + adminId + "/status", { active: false })).status, 409);
    assert.equal((await admin("GET", "/users/invalid")).status, 400);
  });

  it("revokes old tokens immediately on suspension and does not restore them on reactivation", async () => {
    const account = await database.collection("auth_users").findOne({ normalizedIdentity: "aluno.demo1" });
    const token = (await login("aluno.demo1", "aluno")).body.accessToken;
    const path = "/users/" + account!._id + "/status";
    assert.equal((await admin("PATCH", path, { active: false, reason: "Integration validation" })).status, 200);
    assert.equal((await request("GET", "/api/auth/me", undefined, token)).status, 401);
    assert.equal((await login("aluno.demo1", "aluno")).status, 401);
    assert.equal((await admin("PATCH", path, { active: true })).status, 200);
    assert.equal((await request("GET", "/api/auth/me", undefined, token)).status, 401);
    assert.equal((await login("aluno.demo1", "aluno")).status, 200);
  });

  it("logs out a single session and revokes all user sessions through ADMIN", async () => {
    const token = (await login("aluno.demo2", "aluno")).body.accessToken;
    assert.equal((await request("POST", "/api/auth/logout", {}, token)).status, 204);
    assert.equal((await request("GET", "/api/auth/me", undefined, token)).status, 401);
    const next = (await login("aluno.demo2", "aluno")).body.accessToken;
    const account = await database.collection("auth_users").findOne({ normalizedIdentity: "aluno.demo2" });
    assert.equal((await admin("POST", "/users/" + account!._id + "/revoke-sessions", {})).status, 204);
    assert.equal((await request("GET", "/api/auth/me", undefined, next)).status, 401);
  });

  it("consumes OTP and reset grant only once under concurrent requests", async () => {
    const identity = "aluno.demo1";
    const oldToken = (await login(identity, "aluno")).body.accessToken;
    assert.equal((await request("POST", "/api/auth/send-recovery-otp", { identity })).status, 200);
    const code = emails.get("aluno.demo1@example.com")!;
    const results = await Promise.all([1, 2].map(() => request("POST", "/api/auth/verify-recovery-otp", { identity, code })));
    assert.deepEqual(results.map((result) => result.status).sort(), [200, 400]);
    const resetToken = results.find((result) => result.status === 200)!.body.resetToken;
    const resets = await Promise.all([1, 2].map(() => request("POST", "/api/auth/reset-password", { identity, resetToken, newPassword })));
    assert.deepEqual(resets.map((result) => result.status).sort(), [204, 400]);
    assert.equal((await request("GET", "/api/auth/me", undefined, oldToken)).status, 401);
    assert.equal((await login(identity, "aluno")).status, 401);
    const changed = await login(identity, "aluno", newPassword);
    assert.equal(changed.status, 200);
    assert.equal((await request("POST", "/api/auth/change-password", { currentPassword: newPassword, newPassword: password }, changed.body.accessToken)).status, 204);
    assert.equal((await request("GET", "/api/auth/me", undefined, changed.body.accessToken)).status, 401);
  });

  it("rejects expired recovery codes and codes exhausted after three attempts", async () => {
    const identity = "aluno.demo2";
    await request("POST", "/api/auth/send-recovery-otp", { identity });
    await database.collection("auth_recovery").updateOne({ normalizedIdentity: identity }, { $set: { expiresAt: new Date(0) } });
    assert.equal((await request("POST", "/api/auth/verify-recovery-otp", { identity, code: emails.get("aluno.demo2@example.com") })).status, 400);
    await request("POST", "/api/auth/send-recovery-otp", { identity });
    for (let i = 0; i < 3; i++) assert.equal((await request("POST", "/api/auth/verify-recovery-otp", { identity, code: "000000" })).status, 400);
    assert.equal((await request("POST", "/api/auth/verify-recovery-otp", { identity, code: emails.get("aluno.demo2@example.com") })).status, 400);
  });

  it("requires actual email 2FA before issuing any usable bearer token", async () => {
    const professor = await database.collection("auth_users").findOne({ normalizedIdentity: "prof.demo" });
    assert.equal((await admin("PATCH", "/users/" + professor!._id, { twoFactorRequired: true })).status, 200);
    assert.equal((await admin("PATCH", "/users/" + professor!._id, { displayName: "Professor Editado" })).body.twoFactorRequired, true);
    const challenge = await login("prof.demo", "docente");
    assert.equal(challenge.status, 202);
    assert.equal(challenge.body.accessToken, undefined);
    assert.equal((await request("GET", "/api/auth/me", undefined, challenge.body.challengeToken)).status, 401);
    const verified = await request("POST", "/api/auth/verify-two-factor", { challengeToken: challenge.body.challengeToken, code: emails.get("prof.demo@example.com") });
    assert.equal(verified.status, 200);
    assert.equal((await request("POST", "/api/auth/verify-two-factor", { challengeToken: challenge.body.challengeToken, code: emails.get("prof.demo@example.com") })).status, 400);
    const exhausted = await login("prof.demo", "docente");
    for (let i = 0; i < 3; i++) await request("POST", "/api/auth/verify-two-factor", { challengeToken: exhausted.body.challengeToken, code: "000000" });
    assert.equal((await request("POST", "/api/auth/verify-two-factor", { challengeToken: exhausted.body.challengeToken, code: emails.get("prof.demo@example.com") })).status, 400);
    await admin("PATCH", "/users/" + professor!._id, { twoFactorRequired: false });
  });

  it("preserves academic relations and enforces class capacity under concurrent enrollment", async () => {
    const classroom = await admin("POST", "/classes", {
      code: "TEST-ONE",
      courseCode: "ES-DEMO",
      semester: "2026/2",
      shift: "Noturno",
      location: "Test Room",
      maxCapacity: 1,
      professorIdentity: "prof.demo",
    });
    assert.equal(classroom.status, 201);
    const results = await Promise.all(["aluno.demo1", "aluno.demo2"].map((studentIdentity) => admin("POST", "/classes/TEST-ONE/enrollments", { studentIdentity })));
    assert.deepEqual(results.map((result) => result.status).sort(), [201, 409]);
    assert.equal((await admin("PATCH", "/classes/TEST-ONE", { maxCapacity: 2, formulaRegime: "admin" })).status, 200);
    assert.equal((await admin("PATCH", "/classes/TEST-ONE", { professorIdentity: "prof.demo" })).body.formulaRegime, "admin");
    assert.equal((await admin("POST", "/classes/TEST-ONE/sessions", { title: "Invalid session", startsAt: "2026-11-09T22:00:00Z", endsAt: "2026-11-09T21:00:00Z" })).status, 400);
    const session = await admin("POST", "/classes/TEST-ONE/sessions", { title: "Valid session", startsAt: "2026-11-09T22:00:00Z", endsAt: "2026-11-09T23:00:00Z" });
    assert.equal(session.status, 201);
    assert.equal((await admin("PATCH", "/classes/TEST-ONE/sessions/" + session.body.id, { cancelled: true })).status, 200);
    const enrollments = await admin("GET", "/classes/TEST-ONE/enrollments");
    assert.equal((await admin("PATCH", "/classes/TEST-ONE/enrollments/" + enrollments.body[0].id, { status: "cancelled" })).status, 204);
    assert.equal((await admin("GET", "/classes/TEST-ONE/enrollments")).body.length, 0);
    assert.equal((await admin("GET", "/classes/NO-SUCH-CLASS/enrollments")).status, 404);
    assert.equal((await admin("GET", "/courses")).body.find((course: any) => course.code === "ES-DEMO").studentsCount, 2);
  });

  it("persists institutional operations and records actual audit events", async () => {
    const protocol = await admin("POST", "/protocols", {
      studentIdentity: "aluno.demo1",
      requestType: "Revisão",
      justification: "Revisão solicitada para teste",
      targetComponent: "PI IV",
    });
    assert.equal(protocol.status, 201);
    const path = "/protocols/" + protocol.body.id + "/decision";
    assert.equal((await admin("PATCH", path, { approved: true, decisionNote: "Deferido após análise." })).status, 200);
    assert.equal((await admin("PATCH", path, { approved: false, decisionNote: "Segunda decisão." })).status, 409);
    assert.equal((await admin("POST", "/announcements", { title: "Aviso de teste", body: "Conteúdo do comunicado", audience: "Todos", category: "Acadêmico" })).status, 201);
    assert.equal((await admin("PATCH", "/settings", { minimumAttendance: 80, regimentalLockActive: false })).status, 200);
    assert.equal((await admin("GET", "/settings")).body.minimumAttendance, 80);
    assert.equal((await admin("PATCH", "/settings", { minimumAttendance: 101 })).status, 400);
    assert.equal((await admin("POST", "/calendar", { title: "Evento de teste", startsAt: "2026-11-09T22:00:00Z", type: "academic" })).status, 201);
    assert.ok((await admin("GET", "/audit-logs")).body.some((entry: any) => entry.action === "protocol_decided"));
    assert.equal((await admin("GET", "/dashboard")).status, 200);
    assert.equal((await admin("GET", "/users/" + adminId + "/dossier")).status, 200);
  });

  it("reports unavailable SMTP uniformly and protects second-factor changes with password confirmation", async () => {
    emailAvailable = false;
    for (const identity of ["aluno.demo1", "unknown.identity"]) {
      assert.equal((await request("POST", "/api/auth/send-recovery-otp", { identity })).status, 503);
    }
    emailAvailable = true;
    const token = (await login("prof.demo", "docente")).body.accessToken;
    assert.equal((await request("POST", "/api/auth/two-factor", { password: "wrong-password", enabled: true }, token)).status, 401);
    assert.equal((await request("GET", "/api/auth/me", undefined, token)).status, 200);
    assert.equal((await request("POST", "/api/auth/two-factor", { password, enabled: true }, token)).status, 204);
    assert.equal((await request("GET", "/api/auth/me", undefined, token)).status, 401);
    const challenge = await login("prof.demo", "docente");
    assert.equal(challenge.status, 202);
    const verified = await request("POST", "/api/auth/verify-two-factor", { challengeToken: challenge.body.challengeToken, code: emails.get("prof.demo@example.com") });
    assert.equal(verified.status, 200);
    assert.equal((await request("POST", "/api/auth/two-factor", { password, enabled: false }, verified.body.accessToken)).status, 204);
    assert.equal((await login("prof.demo", "docente")).status, 200);
  });

  it("preserves one active administrator when administrators attempt simultaneous demotions", async () => {
    const second = await admin("POST", "/users", {
      identity: "second.admin",
      email: "second.admin@example.com",
      displayName: "Second Admin",
      profile: "admin",
      password,
    });
    assert.equal(second.status, 201);
    const secondToken = (await login("second.admin", "admin")).body.accessToken;
    const results = await Promise.all([
      admin("PATCH", "/users/" + second.body.id, { profile: "aluno" }),
      request("PATCH", "/api/admin/users/" + adminId, { profile: "aluno" }, secondToken),
    ]);
    assert.equal(results.filter((result) => result.status === 200).length, 1);
    assert.ok(results.some((result) => result.status === 401 || result.status === 403));
    assert.equal(await database.collection("auth_users").countDocuments({ profile: "admin", active: true }), 1);
  });

  it("integrates teacher, student, file storage, video-call rooms and admin grade audit end-to-end", async () => {
    const teacherToken = (await login("prof.demo", "docente")).body.accessToken;
    const studentToken = (await login("aluno.demo1", "aluno")).body.accessToken;

    const teacherBootstrap = await request("GET", "/api/teacher/bootstrap", undefined, teacherToken);
    assert.equal(teacherBootstrap.status, 200);
    assert.ok(Array.isArray(teacherBootstrap.body.courses));
    assert.ok(teacherBootstrap.body.courses.some((c: any) => c.code === "ES-DEMO-4N"));

    const materialBase64 = Buffer.from("Conteúdo PDF de teste real").toString("base64");
    const createdMat = await request(
      "POST",
      "/api/teacher/courses/ES-DEMO-4N/materials",
      {
        title: "Apostila Unidade 1",
        fileName: "apostila-u1.txt",
        mimeType: "text/plain",
        contentBase64: materialBase64,
      },
      teacherToken,
    );
    assert.equal(createdMat.status, 201);
    assert.ok(createdMat.body.id);

    const createdAssign = await request(
      "POST",
      "/api/teacher/courses/ES-DEMO-4N/assignments",
      {
        title: "Entrega Arquitetura",
        description: "Diagrama C4 completo",
        stage: "N2",
        dueDate: "2026-12-15T23:59:00Z",
        dueDateFormatted: "15/12/2026 às 23:59",
        modality: "Individual",
        allowLateWithPenalty: true,
        weight: 4.0,
        rubricCriteria: [
          { id: "c1", title: "Arquitetura", maxPoints: 5 },
          { id: "c2", title: "Documentação", maxPoints: 5 },
        ],
      },
      teacherToken,
    );
    assert.equal(createdAssign.status, 201);
    const assignmentId = createdAssign.body.id;

    const openedRoom = await request("POST", "/api/video-call/rooms/enter", { roomCode: "ES-DEMO-4N" }, teacherToken);
    assert.equal(openedRoom.status, 200);
    const roomsList = await request("GET", "/api/video-call/rooms", undefined, studentToken);
    assert.equal(roomsList.status, 200);
    assert.ok(roomsList.body.some((r: any) => r.classCode === "ES-DEMO-4N" && r.isOpen === true));

    const studentBoot = await request("GET", "/api/student/bootstrap", undefined, studentToken);
    assert.equal(studentBoot.status, 200);
    assert.ok(studentBoot.body.disciplines.some((d: any) => d.code === "ES-DEMO-4N" && d.isLive === true));
    assert.ok(studentBoot.body.deliveries.some((d: any) => d.id === assignmentId));

    const fileDownload = await request("GET", `/api/files/materials/${createdMat.body.id}`, undefined, studentToken);
    assert.equal(fileDownload.status, 200);
    assert.equal(Buffer.from(fileDownload.body.contentBase64, "base64").toString("utf8"), "Conteúdo PDF de teste real");

    const submission = await request(
      "POST",
      `/api/student/deliveries/${assignmentId}/submit`,
      {
        fileName: "entrega-aluno.txt",
        mimeType: "text/plain",
        contentBase64: Buffer.from("Minha entrega C4").toString("base64"),
        comments: "Entregue no prazo.",
      },
      studentToken,
    );
    assert.equal(submission.status, 201);
    assert.match(submission.body.protocolCode, /^AGR-/);
    assert.equal((submission.body.sha256 ?? submission.body.sha256Hash ?? "").length, 64);

    const studentUser = await database.collection("auth_users").findOne({ normalizedIdentity: "aluno.demo1" });
    const studentId = String(studentUser!._id);

    const evaluated = await request(
      "PATCH",
      `/api/teacher/assignments/${assignmentId}/evaluate`,
      {
        studentId,
        calculatedGrade: 9.2,
        feedback: "Excelente modelagem!",
        evaluatedCriteria: [
          { id: "c1", title: "Arquitetura", maxPoints: 5, assignedScore: 4.7 },
          { id: "c2", title: "Documentação", maxPoints: 5, assignedScore: 4.5 },
        ],
      },
      teacherToken,
    );
    assert.equal(evaluated.status, 200);

    const gradeUpdate = await request(
      "PATCH",
      `/api/teacher/courses/ES-DEMO-4N/grades/${studentId}`,
      { assignmentsScore: 8.5, p1Score: 8.5, projectsScore: 9.2, p2Score: 9.2 },
      teacherToken,
    );
    assert.equal(gradeUpdate.status, 200);

    const homologate = await request(
      "POST",
      "/api/teacher/courses/ES-DEMO-4N/grades/homologate",
      {},
      teacherToken,
    );
    assert.equal(homologate.status, 200);
    assert.ok(homologate.body.chancelaCode);

    const activeAdmin = await database.collection("auth_users").findOne({ profile: "admin", active: true });
    const currentAdminToken = (await login(String(activeAdmin!.normalizedIdentity), "admin")).body.accessToken;
    const adminGrades = await request("GET", "/api/admin/classes/ES-DEMO-4N/grades", undefined, currentAdminToken);
    assert.equal(adminGrades.status, 200);
    const auditedStudent = adminGrades.body.grades.find((g: any) => g.ra === "aluno.demo1");
    assert.ok(auditedStudent);
    assert.equal(auditedStudent.n1, 8.5);
    assert.equal(auditedStudent.n2, 9.2);
  });
});

