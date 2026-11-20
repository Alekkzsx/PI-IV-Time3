// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { ObjectId, type Db, type Document } from "mongodb";
import { TeacherService } from "../../modules/teacher/application/index.js";
import type {
  AssignmentDeadlineEmailInput,
  AuthOtpEmailInput,
  BaseEmailInput,
  DiagnosticEmailInput,
  EmailDeliveryResult,
  GradePublishedEmailInput,
  ProtocolDecidedEmailInput,
  ProtocolSubmittedEmailInput,
  UnifiedEmailService,
  WelcomeUserEmailInput,
} from "../../modules/notifications/index.js";

function matches(doc: Document, filter: Document): boolean {
  for (const [k, v] of Object.entries(filter)) {
    if (k === "$or" && Array.isArray(v)) {
      if (!v.some((b) => matches(doc, b))) return false;
      continue;
    }
    const dv = doc[k];
    if (v && typeof v === "object" && "$ne" in v) {
      if (dv === v.$ne) return false;
      continue;
    }
    if (v && typeof v === "object" && "$in" in v && Array.isArray(v.$in)) {
      if (!v.$in.map(String).includes(String(dv))) return false;
      continue;
    }
    if (v instanceof ObjectId) {
      if (String(dv) !== String(v)) return false;
      continue;
    }
    if (String(dv ?? "").toLowerCase() !== String(v ?? "").toLowerCase()) return false;
  }
  return true;
}

function makeFakeDb(seed: Record<string, Document[]>): { db: Db; store: Record<string, Document[]> } {
  const store: Record<string, Document[]> = {};
  for (const [col, docs] of Object.entries(seed)) store[col] = docs.map((d) => ({ ...d }));
  const collection = (name: string) => {
    store[name] ??= [];
    const list = store[name]!;
    return {
      async findOne(filter: Document = {}) {
        return list.find((d) => matches(d, filter)) ?? null;
      },
      find(filter: Document = {}) {
        const res = list.filter((d) => matches(d, filter));
        return {
          sort() { return this; },
          async toArray() { return res; },
        };
      },
      async insertOne(doc: Document) {
        const saved = { _id: doc._id ?? new ObjectId(), ...doc };
        list.push(saved);
        return { insertedId: saved._id };
      },
      async updateOne(filter: Document, update: Document, opts?: { upsert?: boolean }) {
        const idx = list.findIndex((d) => matches(d, filter));
        if (idx >= 0) {
          const cur = { ...list[idx]! };
          if (update.$set) Object.assign(cur, update.$set);
          list[idx] = cur;
          return { matchedCount: 1, modifiedCount: 1 };
        }
        if (opts?.upsert) {
          const created = { _id: new ObjectId(), ...filter, ...(update.$setOnInsert ?? {}), ...(update.$set ?? {}) };
          list.push(created);
          return { matchedCount: 0, upsertedCount: 1 };
        }
        return { matchedCount: 0, modifiedCount: 0 };
      },
    };
  };
  return { db: { collection } as unknown as Db, store };
}

class FakeEmailSpy implements UnifiedEmailService {
  readonly sentGrades: GradePublishedEmailInput[] = [];
  private ok(): Promise<EmailDeliveryResult> {
    return Promise.resolve({ success: true, provider: "webhook", deliveredExternally: true, latencyMs: 1 });
  }
  sendAuthOtp(_i: AuthOtpEmailInput) { return this.ok(); }
  sendWelcomeUser(_i: WelcomeUserEmailInput) { return this.ok(); }
  sendProtocolSubmitted(_i: ProtocolSubmittedEmailInput) { return this.ok(); }
  sendProtocolDecided(_i: ProtocolDecidedEmailInput) { return this.ok(); }
  sendAssignmentDeadline(_i: AssignmentDeadlineEmailInput) { return this.ok(); }
  sendGradePublished(input: GradePublishedEmailInput) { this.sentGrades.push(input); return this.ok(); }
  sendDiagnostic(_i: DiagnosticEmailInput) { return this.ok(); }
  sendRaw(_i: BaseEmailInput) { return this.ok(); }
}

describe("Teacher grading batch & flexible evaluation flows", () => {
  it("atualiza notas em lote (updateClassGradesBatch) preservando campos anteriores e bloqueando se pauta travada", async () => {
    const teacherId = new ObjectId();
    const s1 = new ObjectId();
    const s2 = new ObjectId();
    const { db, store } = makeFakeDb({
      auth_users: [
        { _id: s1, identity: "20261", displayName: "Aluno 1", email: "a1@gmail.com", active: true },
        { _id: s2, identity: "20262", displayName: "Aluno 2", email: "a2@gmail.com", active: true },
      ],
      academic_classes: [
        { _id: new ObjectId(), code: "IHC-305", subjectName: "IHC", professorId: String(teacherId), gradeLocked: false },
        { _id: new ObjectId(), code: "LOCKED-1", subjectName: "Travada", professorId: String(teacherId), gradeLocked: true },
      ],
      academic_enrollments: [
        { classCode: "IHC-305", studentId: String(s1), studentIdentity: "20261", displayName: "Aluno 1", status: "active" },
        { classCode: "IHC-305", studentId: String(s2), studentIdentity: "20262", displayName: "Aluno 2", status: "active" },
      ],
      academic_grades: [
        { classCode: "IHC-305", studentId: String(s1), assignmentsScore: 7.0, p1Score: 0, projectsScore: 0, p2Score: 0 },
      ],
    });
    const emailSpy = new FakeEmailSpy();
    const service = new TeacherService(db, emailSpy);
    const teacherDoc = { _id: teacherId, identity: "professor.test", displayName: "Prof.", profile: "docente" };

    const result = await service.updateClassGradesBatch(String(teacherId), teacherDoc, "IHC-305", [
      { studentId: String(s1), p1Score: 8.5 },
      { studentId: String(s2), assignmentsScore: 9.0, p2Score: 7.5 },
    ]);

    assert.equal(result.ok, true);
    assert.equal(result.updatedCount, 2);
    assert.equal(result.grades[0]?.assignmentsScore, 7.0);
    assert.equal(result.grades[0]?.p1Score, 8.5);
    assert.equal(result.grades[1]?.assignmentsScore, 9.0);
    assert.equal(result.grades[1]?.p2Score, 7.5);
    assert.equal(store.academic_grades?.length, 2);

    await new Promise((r) => setTimeout(r, 20));
    assert.equal(emailSpy.sentGrades.length, 2);

    await assert.rejects(
      () => service.updateClassGradesBatch(String(teacherId), teacherDoc, "LOCKED-1", [{ studentId: String(s1), p1Score: 5 }]),
      (err: any) => err?.statusCode === 409 && err?.code === "gradebook_locked",
    );
  });

  it("permite avaliar sem submissão prévia e reavaliar nota de entrega existente", async () => {
    const teacherId = new ObjectId();
    const studentId = new ObjectId();
    const assignmentId = new ObjectId();
    const { db, store } = makeFakeDb({
      auth_users: [{ _id: studentId, identity: "20261", displayName: "Aluno 1", email: "a1@gmail.com", active: true }],
      academic_classes: [{ _id: new ObjectId(), code: "IHC-305", subjectName: "IHC", professorId: String(teacherId) }],
      academic_enrollments: [{ classCode: "IHC-305", studentId: String(studentId), studentIdentity: "20261", displayName: "Aluno 1", status: "active" }],
      academic_assignments: [{ _id: assignmentId, classCode: "IHC-305", title: "Lab Mutex", stage: "N1", weight: 3.0 }],
    });
    const service = new TeacherService(db);
    const teacherDoc = { _id: teacherId, identity: "professor.test", displayName: "Prof.", profile: "docente" };

    const first = await service.evaluateSubmission(String(teacherId), teacherDoc, String(assignmentId), {
      studentId: String(studentId),
      calculatedGrade: 8.0,
      feedback: "Bom desempenho presencial.",
      evaluatedCriteria: [],
    });
    assert.equal(first.ok, true);
    assert.equal(first.score, 8.0);
    assert.equal(first.stage, "N1");
    assert.equal(first.gradeField, "assignmentsScore");
    assert.equal(store.academic_submissions?.length, 1);

    const revised = await service.evaluateSubmission(String(teacherId), teacherDoc, String(assignmentId), {
      studentId: String(studentId),
      calculatedGrade: 9.2,
      feedback: "Revisado após apresentação complementar.",
      evaluatedCriteria: [],
    });
    assert.equal(revised.score, 9.2);
    assert.equal(revised.consolidatedStageGrade, 9.2);
    assert.equal(store.academic_grades?.[0]?.assignmentsScore, 9.2);
  });

  it("cria registro acionável em academic_rectifications se pauta estiver lacrada e bloqueia edição de fórmula sob regime admin", async () => {
    const teacherId = new ObjectId();
    const studentId = new ObjectId();
    const { db, store } = makeFakeDb({
      academic_classes: [
        {
          _id: new ObjectId(),
          code: "LOCKED-2",
          subjectName: "Sistemas Distribuídos",
          professorId: String(teacherId),
          gradeLocked: true,
          formulaRegime: "admin",
          evaluationFormula: "(N1 + N2) / 2",
        },
      ],
      academic_enrollments: [
        { classCode: "LOCKED-2", studentId: String(studentId), studentIdentity: "20261", displayName: "Aluno 1", status: "active" },
      ],
      academic_grades: [
        { classCode: "LOCKED-2", studentId: String(studentId), assignmentsScore: 7, p1Score: 6.5, projectsScore: 8, p2Score: 7 },
      ],
    });
    const service = new TeacherService(db);
    const teacherDoc = { _id: teacherId, identity: "professor.test", displayName: "Prof.", profile: "docente" };

    const recRes = await service.requestGradeRectification(String(teacherId), teacherDoc, "LOCKED-2", {
      studentId: String(studentId),
      stage: "P1",
      newScore: 8.5,
      justification: "Recurso deferido em revisão presencial.",
    });
    assert.equal(recRes.ok, true);
    assert.equal(recRes.pendingApproval, true);
    assert.equal(store.academic_rectifications?.length, 1);
    assert.equal(store.academic_rectifications?.[0]?.status, "Pendente");

    await assert.rejects(
      () =>
        service.updateSyllabusPlan(String(teacherId), teacherDoc, "LOCKED-2", {
          evaluationFormula: "(N1 × 0.4) + (N2 × 0.6)",
        }),
      (err: any) => err?.statusCode === 403 && err?.code === "formula_locked_by_admin",
    );
  });
});
