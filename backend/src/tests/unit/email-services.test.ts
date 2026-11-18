// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import assert from "node:assert/strict";
import express from "express";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { describe, it } from "node:test";
import { ObjectId, type Db, type Document } from "mongodb";
import {
  resolveActiveEnrolledRecipients,
  resolveActiveRegisteredRecipientByEmail,
  resolveActiveRegisteredRecipientById,
  type AssignmentDeadlineEmailInput,
  type AuthOtpEmailInput,
  type BaseEmailInput,
  type DiagnosticEmailInput,
  type EmailDeliveryResult,
  type GradePublishedEmailInput,
  type ProtocolDecidedEmailInput,
  type ProtocolSubmittedEmailInput,
  type UnifiedEmailService,
  type WelcomeUserEmailInput,
} from "../../modules/notifications/index.js";
import { registerAdminEmailDiagnosticRoutes } from "../../modules/admin/presentation/operations/system/email-diagnostic.routes.js";
import { StudentCommunicationsService } from "../../modules/student/application/communications/service.js";
import { TeacherService } from "../../modules/teacher/application/index.js";

function matchesFilter(doc: Document, filter: Document): boolean {
  for (const [key, val] of Object.entries(filter)) {
    if (key === "$or" && Array.isArray(val)) {
      if (!val.some((branch) => matchesFilter(doc, branch))) return false;
      continue;
    }
    const docVal = doc[key];
    if (val && typeof val === "object" && "$ne" in val) {
      if (docVal === val.$ne) return false;
      continue;
    }
    if (val && typeof val === "object" && "$in" in val && Array.isArray(val.$in)) {
      const inList = val.$in.map((item: unknown) => String(item));
      if (!inList.includes(String(docVal))) return false;
      continue;
    }
    if (val instanceof ObjectId) {
      if (String(docVal) !== String(val)) return false;
      continue;
    }
    if (String(docVal ?? "").toLowerCase() !== String(val ?? "").toLowerCase()) {
      return false;
    }
  }
  return true;
}

function createFakeDb(seed: Record<string, Document[]> = {}): { db: Db; store: Record<string, Document[]> } {
  const store: Record<string, Document[]> = {};
  for (const [col, docs] of Object.entries(seed)) {
    store[col] = docs.map((d) => ({ ...d }));
  }
  const collection = (name: string) => {
    store[name] ??= [];
    const list = store[name]!;
    return {
      async findOne(filter: Document = {}) {
        return list.find((d) => matchesFilter(d, filter)) ?? null;
      },
      find(filter: Document = {}) {
        const matched = list.filter((d) => matchesFilter(d, filter));
        return {
          sort() { return this; },
          async toArray() { return matched; },
        };
      },
      async insertOne(doc: Document) {
        const _id = doc._id ?? new ObjectId();
        const saved = { _id, ...doc };
        list.push(saved);
        return { insertedId: _id };
      },
      async updateOne(filter: Document, update: Document, options?: { upsert?: boolean }) {
        const idx = list.findIndex((d) => matchesFilter(d, filter));
        if (idx >= 0) {
          const current = { ...list[idx]! };
          if (update.$set) Object.assign(current, update.$set);
          list[idx] = current;
          return { matchedCount: 1, modifiedCount: 1 };
        }
        if (options?.upsert) {
          const inserted = { _id: new ObjectId(), ...filter, ...(update.$setOnInsert ?? {}), ...(update.$set ?? {}) };
          list.push(inserted);
          return { matchedCount: 0, upsertedCount: 1 };
        }
        return { matchedCount: 0, modifiedCount: 0 };
      },
      async countDocuments(filter: Document = {}) {
        return list.filter((d) => matchesFilter(d, filter)).length;
      },
    };
  };
  return { db: { collection } as unknown as Db, store };
}

class RecordingEmailService implements UnifiedEmailService {
  readonly calls: Array<{ type: string; to: string; payload: unknown }> = [];

  private ok(type: string, to: string, payload: unknown): Promise<EmailDeliveryResult> {
    this.calls.push({ type, to, payload });
    return Promise.resolve({
      success: true,
      provider: "webhook",
      deliveredExternally: true,
      errorTrail: [],
      latencyMs: 12,
    });
  }

  sendAuthOtp(input: AuthOtpEmailInput) { return this.ok("auth_otp", input.to, input); }
  sendWelcomeUser(input: WelcomeUserEmailInput) { return this.ok("welcome", input.to, input); }
  sendProtocolSubmitted(input: ProtocolSubmittedEmailInput) { return this.ok("protocol_submitted", input.to, input); }
  sendProtocolDecided(input: ProtocolDecidedEmailInput) { return this.ok("protocol_decided", input.to, input); }
  sendAssignmentDeadline(input: AssignmentDeadlineEmailInput) { return this.ok("assignment_deadline", input.to, input); }
  sendGradePublished(input: GradePublishedEmailInput) { return this.ok("grade_published", input.to, input); }
  sendDiagnostic(input: DiagnosticEmailInput) { return this.ok("diagnostic", input.to, input); }
  sendRaw(input: BaseEmailInput) { return this.ok("raw", input.to, input); }
}

describe("Recipient guards e serviços de e-mail por módulo", () => {
  it("resolve destinatário apenas para contas ativas cadastradas em auth_users", async () => {
    const activeId = new ObjectId();
    const inactiveId = new ObjectId();
    const { db } = createFakeDb({
      auth_users: [
        {
          _id: activeId,
          identity: "aluno.test",
          displayName: "Alex Gabriel",
          email: "alex.soares.gabriel111@gmail.com",
          normalizedEmail: "alex.soares.gabriel111@gmail.com",
          profile: "aluno",
          active: true,
        },
        {
          _id: inactiveId,
          identity: "inativo",
          displayName: "Conta Suspensa",
          email: "inativo@gmail.com",
          normalizedEmail: "inativo@gmail.com",
          profile: "aluno",
          active: false,
        },
      ],
      academic_enrollments: [
        { classCode: "PI4-2026-4N", studentId: String(activeId), status: "active" },
        { classCode: "PI4-2026-4N", studentId: String(inactiveId), status: "active" },
      ],
    });

    assert.equal(await resolveActiveRegisteredRecipientByEmail(db, "naoexiste@gmail.com"), null);
    assert.equal(await resolveActiveRegisteredRecipientByEmail(db, "inativo@gmail.com"), null);
    assert.equal(await resolveActiveRegisteredRecipientById(db, String(inactiveId)), null);

    const found = await resolveActiveRegisteredRecipientByEmail(db, "ALEX.SOARES.GABRIEL111@GMAIL.COM");
    assert.ok(found);
    assert.equal(found.email, "alex.soares.gabriel111@gmail.com");

    const enrolled = await resolveActiveEnrolledRecipients(db, "PI4-2026-4N");
    assert.equal(enrolled.length, 1);
    assert.equal(enrolled[0]?.email, "alex.soares.gabriel111@gmail.com");
  });

  it("Admin /system/test-email bloqueia 404 para e-mail ausente em auth_users e envia quando cadastrado", async () => {
    const adminId = new ObjectId();
    const { db } = createFakeDb({
      auth_users: [
        {
          _id: adminId,
          identity: "admin.test",
          displayName: "Admin Teste",
          email: "admin.real@gmail.com",
          normalizedEmail: "admin.real@gmail.com",
          profile: "admin",
          active: true,
        },
      ],
    });
    const emailService = new RecordingEmailService();
    const app = express();
    app.use(express.json());
    app.use((_req, res, next) => {
      res.locals.adminId = String(adminId);
      res.locals.user = { displayName: "Admin Teste", email: "admin.real@gmail.com" };
      next();
    });
    registerAdminEmailDiagnosticRoutes(app as unknown as express.Router, db, emailService);

    const server = createServer(app);
    await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
    const port = (server.address() as AddressInfo).port;
    try {
      const blocked = await fetch(`http://127.0.0.1:${port}/system/test-email`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ recipientEmail: "estranho@gmail.com" }),
      });
      assert.equal(blocked.status, 404);
      const blockedJson = (await blocked.json()) as Record<string, unknown>;
      assert.equal(blockedJson.code, "email_not_registered");
      assert.equal(emailService.calls.length, 0);

      const allowed = await fetch(`http://127.0.0.1:${port}/system/test-email`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ recipientEmail: "admin.real@gmail.com" }),
      });
      assert.equal(allowed.status, 200);
      assert.equal(emailService.calls.length, 1);
      assert.equal(emailService.calls[0]?.to, "admin.real@gmail.com");
    } finally {
      await new Promise<void>((resolve, reject) => server.close((err) => (err ? reject(err) : resolve())));
    }
  });

  it("StudentCommunicationsService recusa docente sem conta ativa/e-mail e envia quando cadastrado", async () => {
    const studentId = new ObjectId();
    const profId = new ObjectId();
    const { db } = createFakeDb({
      auth_users: [
        {
          _id: profId,
          identity: "prof.test",
          displayName: "Prof. Real",
          email: "prof.real@gmail.com",
          normalizedEmail: "prof.real@gmail.com",
          profile: "docente",
          active: true,
        },
      ],
      academic_classes: [
        { code: "SEM-PROF", professorId: String(new ObjectId()), professorName: "Sem Conta" },
        { code: "COM-PROF", professorId: String(profId), professorName: "Prof. Real", subjectName: "Arquitetura" },
      ],
      academic_enrollments: [
        { classCode: "SEM-PROF", studentId: String(studentId), status: "active" },
        { classCode: "COM-PROF", studentId: String(studentId), status: "active" },
      ],
    });
    const emailService = new RecordingEmailService();
    const service = new StudentCommunicationsService(db, emailService);
    const studentDoc = { _id: studentId, identity: "aluno.test", displayName: "Alex", email: "alex@gmail.com" };

    await assert.rejects(
      () => service.contactProfessor(String(studentId), studentDoc, "SEM-PROF", { subject: "Dúvida", message: "Olá" }),
      (err: any) => err?.statusCode === 404 && err?.code === "professor_email_not_registered",
    );
    assert.equal(emailService.calls.length, 0);

    const sent = await service.contactProfessor(String(studentId), studentDoc, "COM-PROF", { subject: "Dúvida", message: "Olá" });
    assert.equal(sent.recipientEmail, "prof.real@gmail.com");
    await new Promise((r) => setTimeout(r, 20));
    assert.equal(emailService.calls.length, 1);
    assert.equal(emailService.calls[0]?.to, "prof.real@gmail.com");
  });

  it("TeacherService dispara notificação de prazo, nota, parecer de protocolo e comunicado para alunos cadastrados", async () => {
    const teacherId = new ObjectId();
    const studentId = new ObjectId();
    const protocolId = new ObjectId();
    const { db } = createFakeDb({
      auth_users: [
        {
          _id: studentId,
          identity: "aluno.test",
          displayName: "Alex Gabriel",
          email: "alex.soares.gabriel111@gmail.com",
          normalizedEmail: "alex.soares.gabriel111@gmail.com",
          profile: "aluno",
          active: true,
        },
      ],
      academic_classes: [
        { _id: new ObjectId(), code: "IHC-305", subjectName: "Interface Humano-Computador", professorId: String(teacherId) },
      ],
      academic_enrollments: [
        { classCode: "IHC-305", studentId: String(studentId), studentIdentity: "aluno.test", displayName: "Alex Gabriel", status: "active" },
      ],
      academic_protocols: [
        { _id: protocolId, code: "PROT-2026/ABCD", studentId: String(studentId), requestType: "Revisão de Nota", status: "Aguardando Parecer" },
      ],
    });
    const emailService = new RecordingEmailService();
    const service = new TeacherService(db, emailService);
    const teacherDoc = { _id: teacherId, identity: "professor.test", displayName: "Prof. Ricardo", profile: "docente" };

    const created = await service.createAssignment(String(teacherId), teacherDoc, "IHC-305", {
      title: "Entrega Sprint 1",
      weight: 2,
      stage: "N1",
      dueDateFormatted: "25/11/2026",
      modality: "Individual",
      allowLateWithPenalty: false,
      rubricCriteria: [],
    });
    await service.evaluateSubmission(String(teacherId), teacherDoc, created.id, {
      studentId: String(studentId),
      calculatedGrade: 9.5,
      feedback: "Excelente trabalho",
      evaluatedCriteria: [],
    });
    await service.updateStudentGrade(String(teacherId), teacherDoc, "IHC-305", String(studentId), { p1Score: 8.8 });
    await service.publishNotice(String(teacherId), teacherDoc, {
      targetCourse: "IHC-305",
      targetAudience: "Todos os alunos",
      classification: "Informativo",
      title: "Aula em Lab",
      message: "Encontro presencial amanhã no Lab 02.",
    });
    await service.decideProtocol(String(teacherId), teacherDoc, String(protocolId), {
      status: "deferido",
      officialResponse: "Deferido conforme verificação.",
    });

    await new Promise((r) => setTimeout(r, 30));
    const types = emailService.calls.map((c) => c.type);
    assert.ok(types.includes("assignment_deadline"));
    assert.equal(types.filter((t) => t === "grade_published").length, 2);
    assert.ok(types.includes("raw"));
    assert.ok(types.includes("protocol_decided"));
    assert.ok(emailService.calls.every((c) => c.to === "alex.soares.gabriel111@gmail.com"));
  });
});
