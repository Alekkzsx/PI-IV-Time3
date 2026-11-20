// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
import assert from "node:assert/strict";
import { before, after, describe, it } from "node:test";
import { createServer, type Server } from "node:http";
import { randomBytes, randomUUID } from "node:crypto";
import jwt from "jsonwebtoken";
import "../../config/local-environment.js";
import { loadEnvironment } from "../../config/environment.js";
import { MongoAcademicDatabase } from "../../shared/mongo/database.js";
import { createApp } from "../../app.js";
import { runSeeds } from "../../scripts/index.js";
import type { Db, Document } from "mongodb";

const enabled = process.env.RUN_DB_TESTS === "1";

describe("núcleo acadêmico e ponte interna com MongoDB real isolado", { skip: !enabled }, () => {
  const environment = loadEnvironment();
  const testDatabaseName = "agmrm_test_" + randomBytes(8).toString("hex");
  const password = "Integration-only-password-2026!";
  let connection: MongoAcademicDatabase;
  let database: Db;
  let server: Server;
  let base: string;
  let adminToken: string;

  async function issueTokenForIdentity(normalizedIdentity: string): Promise<{ token: string; sessionId: string; user: Document }> {
    const user = await database.collection("auth_users").findOne({ normalizedIdentity });
    if (!user) throw new Error(`Usuário seed não encontrado: ${normalizedIdentity}`);
    const sessionId = randomUUID();
    await database.collection("auth_sessions").insertOne({
      sessionId,
      userId: String(user._id),
      active: true,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + 15 * 60 * 1000),
    });
    const token = jwt.sign(
      {
        sub: String(user._id),
        profile: user.profile,
        ver: user.sessionVersion ?? 0,
        jti: sessionId,
      },
      environment.jwtSecret,
      { expiresIn: "15m" },
    );
    return { token, sessionId, user };
  }

  async function request(method: string, path: string, body?: unknown, token?: string) {
    const response = await fetch(base + path, {
      method,
      headers: { "Content-Type": "application/json", ...(token ? { Authorization: "Bearer " + token } : {}) },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    const text = await response.text();
    return { status: response.status, body: text ? JSON.parse(text) : null };
  }

  const admin = (method: string, path: string, body?: unknown) => request(method, "/api/admin" + path, body, adminToken);

  before(async () => {
    connection = new MongoAcademicDatabase(environment.mongoUri, testDatabaseName);
    await connection.connect();
    database = connection.databaseForModules();
    await runSeeds(database, password);
    server = createServer(
      createApp(
        { nodeEnv: "test", corsOrigins: environment.corsOrigins },
        {
          database,
          jwtSecret: environment.jwtSecret,
          internalServiceSecret: environment.internalServiceSecret,
        },
      ),
    );
    await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
    const address = server.address();
    if (!address || typeof address === "string") throw new Error("Test server failed.");
    base = "http://127.0.0.1:" + address.port;
    adminToken = (await issueTokenForIdentity("admin.demo")).token;
  });

  after(async () => {
    if (server) await new Promise<void>((resolve) => server.close(() => resolve()));
    // A limpeza só pode atingir o banco temporário criado por este arquivo.
    if (database && database.databaseName === testDatabaseName && /^agmrm_test_[a-f0-9]{16}$/.test(testDatabaseName)) {
      await database.dropDatabase();
    }
    if (connection) await connection.close();
  });

  it("enforces bounded-context 404s and passive session/password-change checks against MongoDB", async () => {
    assert.equal((await request("POST", "/api/auth/login", {})).status, 404);
    assert.equal((await request("GET", "/api/admin/users")).status, 404);
    assert.equal((await request("GET", "/api/video-call/rooms")).status, 404);

    const { token, sessionId, user } = await issueTokenForIdentity("aluno.demo1");
    assert.equal((await request("GET", "/api/student/bootstrap", undefined, token)).status, 200);
    assert.equal((await request("GET", "/api/admin/courses", undefined, token)).status, 403);

    await database.collection("auth_sessions").deleteOne({ sessionId });
    assert.equal((await request("GET", "/api/student/bootstrap", undefined, token)).status, 401);

    await database.collection("auth_users").updateOne({ _id: user._id }, { $set: { requirePasswordChange: true } });
    const pending = await issueTokenForIdentity("aluno.demo1");
    assert.equal((await request("GET", "/api/student/bootstrap", undefined, pending.token)).status, 403);
    await database.collection("auth_users").updateOne({ _id: user._id }, { $set: { requirePasswordChange: false } });
  });

  it("preserves academic relations and enforces class capacity under concurrent enrollment", async () => {
    const classroom = await admin("POST", "/classes", {
      code: "TEST-ONE",
      courseCode: "ES-2026",
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
    const seededCourse = (await admin("GET", "/courses")).body.find((course: any) => course.code === "ES-2026");
    assert.ok(seededCourse);
    assert.ok(seededCourse.studentsCount >= 1);
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
    const announcement = await admin("POST", "/announcements", { title: "Aviso de teste", body: "Conteúdo do comunicado", audience: "Todos", category: "Acadêmico" });
    assert.equal(announcement.status, 201);
    const updatedAnnouncement = await admin("PATCH", "/announcements/" + announcement.body.id, { title: "Aviso atualizado" });
    assert.equal(updatedAnnouncement.status, 200);
    assert.equal(updatedAnnouncement.body.title, "Aviso atualizado");
    assert.equal((await admin("PATCH", "/announcements/invalid", { title: "Aviso atualizado" })).status, 400);
    assert.equal((await admin("PATCH", "/announcements/" + announcement.body.id, {})).status, 400);
    assert.equal((await admin("PATCH", "/settings", { minimumAttendance: 80, regimentalLockActive: false })).status, 200);
    assert.equal((await admin("GET", "/settings")).body.minimumAttendance, 80);
    assert.equal((await admin("PATCH", "/settings", { minimumAttendance: 101 })).status, 400);
    assert.equal((await admin("POST", "/calendar", { title: "Evento de teste", startsAt: "2026-11-09T22:00:00Z", type: "academic" })).status, 201);
    assert.ok((await admin("GET", "/audit-logs")).body.some((entry: any) => entry.action === "protocol_decided"));
    assert.equal((await admin("GET", "/dashboard")).status, 200);
    assert.equal((await admin("GET", "/teachers")).status, 200);
  });

  it("integrates teacher, student, file storage, internal bridge and admin grade audit end-to-end", async () => {
    const targetClass = await database.collection("academic_classes").findOne({ code: "PI4-2026-4N" });
    assert.ok(targetClass, "Turma seed PI4-2026-4N deveria existir");
    const classCode = String(targetClass.code);
    const teacherIdentity = String(targetClass.professorIdentity).toLowerCase();
    const teacherToken = (await issueTokenForIdentity(teacherIdentity)).token;
    const studentIssued = await issueTokenForIdentity("aluno.demo1");
    const studentToken = studentIssued.token;
    const studentId = String(studentIssued.user._id);

    const teacherBootstrap = await request("GET", "/api/teacher/bootstrap", undefined, teacherToken);
    assert.equal(teacherBootstrap.status, 200);
    assert.ok(Array.isArray(teacherBootstrap.body.courses));
    assert.ok(teacherBootstrap.body.courses.some((c: any) => c.code === classCode));

    const materialBase64 = Buffer.from("Conteúdo PDF de teste real").toString("base64");
    const createdMat = await request(
      "POST",
      `/api/teacher/courses/${classCode}/materials`,
      {
        title: "Apostila Unidade 1",
        fileName: "apostila-u1.txt",
        mimeType: "text/plain",
        category: "Apostila",
        contentBase64: materialBase64,
      },
      teacherToken,
    );
    assert.equal(createdMat.status, 201);
    assert.ok(createdMat.body.id);

    const syllabusPatch = await requestPatch(
      `/api/teacher/courses/${classCode}/syllabus-plan`,
      {
        syllabus: "Ementa atualizada para integração docente-discente.",
        objectives: "Validar sincronização da sala de aula.",
        evaluationFormula: "N1 * 0.4 + N2 * 0.6",
      },
      teacherToken,
    );
    assert.equal(syllabusPatch.status, 200);

    const forumTopic = await request(
      "POST",
      `/api/teacher/courses/${classCode}/forum`,
      { title: "Dúvida P1", body: "Qual o peso da lista 1?", category: "Dúvidas" },
      teacherToken,
    );
    assert.equal(forumTopic.status, 201);
    const topicId = forumTopic.body.id;

    const forumReply = await request(
      "POST",
      `/api/teacher/courses/${classCode}/forum/${topicId}/reply`,
      { body: "A lista 1 compõe a N1 proporcionalmente ao peso." },
      teacherToken,
    );
    assert.equal(forumReply.status, 201);

    const forumResolve = await requestPatch(
      `/api/teacher/courses/${classCode}/forum/${topicId}/resolve`,
      { isResolved: true },
      teacherToken,
    );
    assert.equal(forumResolve.status, 200);
    assert.equal(forumResolve.body.isResolved, true);

    const squadsRes = await request(
      "PUT",
      `/api/teacher/courses/${classCode}/squads`,
      {
        squads: [
          {
            name: "Squad Alpha",
            projectTitle: "Portal Integrado AVA",
            repoUrl: "https://github.com/agmrm/alpha",
            sprintStatus: "Em andamento",
            members: ["aluno.demo1"],
          },
        ],
      },
      teacherToken,
    );
    assert.equal(squadsRes.status, 200);
    assert.ok(Array.isArray(squadsRes.body.squads));
    assert.equal(squadsRes.body.squads.length, 1);

    const createdAssign = await request(
      "POST",
      `/api/teacher/courses/${classCode}/assignments`,
      {
        title: "Entrega Arquitetura",
        description: "Diagrama C4 completo",
        stage: "N2",
        dueDate: "2026-12-15",
        dueHour: "23:59",
        dueDateFormatted: "15/12/2026",
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

    const n1AssignA = await request(
      "POST",
      `/api/teacher/courses/${classCode}/assignments`,
      {
        title: "Lista N1 - A",
        description: "Parte A",
        stage: "N1",
        dueDate: "2026-11-20",
        dueHour: "19:00",
        dueDateFormatted: "20/11/2026",
        modality: "Individual",
        allowLateWithPenalty: false,
        weight: 2.0,
        rubricCriteria: [{ id: "n1a", title: "Correção", maxPoints: 10 }],
      },
      teacherToken,
    );
    assert.equal(n1AssignA.status, 201);
    const n1AssignB = await request(
      "POST",
      `/api/teacher/courses/${classCode}/assignments`,
      {
        title: "Lista N1 - B",
        description: "Parte B",
        stage: "N1",
        dueDate: "2026-11-25",
        dueHour: "19:00",
        dueDateFormatted: "25/11/2026",
        modality: "Individual",
        allowLateWithPenalty: false,
        weight: 2.0,
        rubricCriteria: [{ id: "n1b", title: "Correção", maxPoints: 10 }],
      },
      teacherToken,
    );
    assert.equal(n1AssignB.status, 201);

    const tempAssign = await request(
      "POST",
      `/api/teacher/courses/${classCode}/assignments`,
      {
        title: "Atividade Temporária",
        description: "Será removida",
        stage: "N1",
        dueDate: "2026-12-01",
        dueHour: "20:00",
        dueDateFormatted: "01/12/2026",
        modality: "Individual",
        allowLateWithPenalty: false,
        weight: 1.0,
        rubricCriteria: [],
      },
      teacherToken,
    );
    assert.equal(tempAssign.status, 201);
    const deletedAssign = await request("DELETE", `/api/teacher/assignments/${tempAssign.body.id}`, undefined, teacherToken);
    assert.equal(deletedAssign.status, 200);

    const tempMat = await request(
      "POST",
      `/api/teacher/courses/${classCode}/materials`,
      {
        title: "Material Temporário",
        fileName: "temp.txt",
        mimeType: "text/plain",
        contentBase64: materialBase64,
      },
      teacherToken,
    );
    assert.equal(tempMat.status, 201);
    const deletedMat = await request("DELETE", `/api/teacher/courses/${classCode}/materials/${tempMat.body.id}`, undefined, teacherToken);
    assert.equal(deletedMat.status, 200);

    const teacherNotice = await request(
      "POST",
      "/api/teacher/notices",
      {
        targetCourse: classCode,
        targetAudience: "Turma",
        classification: "informativo",
        title: "Comunicado de integração",
        message: "Mensagem para validar a leitura.",
      },
      teacherToken,
    );
    assert.equal(teacherNotice.status, 201);

    // Simular sala ao vivo aberta pelo Java em academic_live_sessions + autorização via ponte interna
    const bridgeHeaders = { "x-internal-service-secret": environment.internalServiceSecret, "content-type": "application/json" };
    const authRes = await fetch(
      `${base}/api/internal/academic/video-call/authorize?userId=${studentId}&profile=aluno&identity=aluno.demo1&roomCode=${classCode}`,
      { headers: bridgeHeaders },
    );
    assert.equal(authRes.status, 200);
    await database.collection("academic_live_sessions").insertOne({
      roomCode: classCode,
      classCode,
      openedAt: new Date(),
      expiresAt: new Date(Date.now() + 3600_000),
    });

    const studentBoot = await request("GET", "/api/student/bootstrap", undefined, studentToken);
    assert.equal(studentBoot.status, 200);
    const matchedDisc = studentBoot.body.disciplines.find((d: any) => d.code === classCode && d.isLive === true);
    assert.ok(matchedDisc);
    assert.equal(matchedDisc.ementa, "Ementa atualizada para integração docente-discente.");
    assert.equal(matchedDisc.objectives, "Validar sincronização da sala de aula.");
    assert.equal(matchedDisc.evaluationFormula, "N1 * 0.4 + N2 * 0.6");
    assert.ok(Array.isArray(matchedDisc.squads) && matchedDisc.squads.some((s: any) => s.name === "Squad Alpha"));
    assert.ok(!matchedDisc.materials.some((m: any) => m.id === tempMat.body.id));
    assert.ok(matchedDisc.materials.some((m: any) => m.id === createdMat.body.id));

    const matchedAssign = studentBoot.body.deliveries.find((d: any) => d.id === assignmentId);
    assert.ok(matchedAssign);
    assert.equal(matchedAssign.dueDate, "15/12/2026");
    assert.equal(matchedAssign.dueHour, "23:59");
    assert.equal(matchedAssign.maxScore, 10);
    assert.ok(Array.isArray(matchedAssign.rubrics) && matchedAssign.rubrics.length === 2);
    assert.ok(!studentBoot.body.deliveries.some((d: any) => d.id === tempAssign.body.id));
    const resolvedTopic = (studentBoot.body.forumTopics ?? matchedDisc.forumTopics ?? []).find((t: any) => t.id === topicId);
    if (resolvedTopic) {
      assert.equal(resolvedTopic.isResolved, true);
    }

    const declaration = await request("POST", "/api/student/enrollment-declaration", {}, studentToken);
    assert.equal(declaration.status, 201);
    assert.match(declaration.body.verificationKey, /^AGMRM-[A-F0-9]{32}$/);

    const noticeRead = await requestPatch(`/api/student/messages/${teacherNotice.body.id}/read`, {}, studentToken);
    assert.equal(noticeRead.status, 200);
    const noticeReads = await request("GET", `/api/teacher/notices/${teacherNotice.body.id}/reads`, undefined, teacherToken);
    assert.equal(noticeReads.status, 200);
    assert.equal(noticeReads.body.readCount, 1);

    const fileDownload = await request("GET", `/api/files/materials/${createdMat.body.id}`, undefined, studentToken);
    assert.equal(fileDownload.status, 200);
    assert.equal(Buffer.from(fileDownload.body.contentBase64, "base64").toString("utf8"), "Conteúdo PDF de teste real");

    // A avaliação de múltiplas atividades N1 deve calcular a média ponderada sem sobrescrever as atividades anteriores
    const evalN1A = await requestPatch(
      `/api/teacher/assignments/${n1AssignA.body.id}/evaluate`,
      {
        studentId,
        calculatedGrade: 6.0,
        feedback: "N1 parte A",
        evaluatedCriteria: [{ id: "n1a", title: "Correção", maxPoints: 10, assignedScore: 6.0 }],
      },
      teacherToken,
    );
    assert.equal(evalN1A.status, 200);
    const evalN1B = await requestPatch(
      `/api/teacher/assignments/${n1AssignB.body.id}/evaluate`,
      {
        studentId,
        calculatedGrade: 9.0,
        feedback: "N1 parte B",
        evaluatedCriteria: [{ id: "n1b", title: "Correção", maxPoints: 10, assignedScore: 9.0 }],
      },
      teacherToken,
    );
    assert.equal(evalN1B.status, 200);
    const teacherBootAfterN1 = await request("GET", "/api/teacher/bootstrap", undefined, teacherToken);
    assert.equal(teacherBootAfterN1.status, 200);
    const studentGradeAfterN1 = teacherBootAfterN1.body.grades.find(
      (g: any) => g.classCode === classCode && g.ra === "aluno.demo1",
    );
    assert.ok(studentGradeAfterN1);
    assert.equal(studentGradeAfterN1.assignmentsScore, 7.5);
    assert.equal(studentGradeAfterN1.hasGrades, true);

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

    const evaluated = await requestPatch(
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

    const gradeUpdate = await requestPatch(
      `/api/teacher/courses/${classCode}/grades/${studentId}`,
      { assignmentsScore: 8.5, p1Score: 8.5, projectsScore: 9.2, p2Score: 9.2 },
      teacherToken,
    );
    assert.equal(gradeUpdate.status, 200);

    const homologate = await request("POST", `/api/teacher/courses/${classCode}/grades/homologate`, {}, teacherToken);
    assert.equal(homologate.status, 200);
    assert.ok(homologate.body.chancelaCode);

    const adminGrades = await admin("GET", `/classes/${classCode}/grades`);
    assert.equal(adminGrades.status, 200);
    const auditedStudent = adminGrades.body.grades.find((g: any) => g.ra === "aluno.demo1");
    assert.ok(auditedStudent);
    assert.equal(auditedStudent.n1, 8.5);
    assert.equal(auditedStudent.n2, 9.2);

    const lgpdBridge = await fetch(`${base}/api/internal/academic/users/${studentId}/lgpd-data`, { headers: bridgeHeaders });
    assert.equal(lgpdBridge.status, 200);
    const lgpdPayload = await lgpdBridge.json();
    assert.ok(lgpdPayload.enrollments.length >= 1);
    assert.ok(lgpdPayload.submissions.length >= 1);
  });

  async function requestPatch(path: string, body: unknown, token: string) {
    return request("PATCH", path, body, token);
  }
});
