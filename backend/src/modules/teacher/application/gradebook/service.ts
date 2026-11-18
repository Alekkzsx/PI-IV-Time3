// Desenvolvido por Murillo Caravita - RA: 25014012
import { randomBytes } from "node:crypto";
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";
import type { UnifiedEmailService } from "../../../notifications/domain/notification.types.js";
import {
  dispatchNotificationSafe,
  resolveActiveRegisteredRecipientById,
} from "../../../notifications/domain/recipient-guard.js";
import { TeacherClassAccess } from "../teacher-class-access.js";

const STAGE_LABELS: ReadonlyArray<[keyof { assignmentsScore?: number; p1Score?: number; projectsScore?: number; p2Score?: number }, string]> = [
  ["assignmentsScore", "Atividades N1"],
  ["p1Score", "Prova P1"],
  ["projectsScore", "Projetos / Atividades N2"],
  ["p2Score", "Prova P2"],
];

export class TeacherGradebookService {
  constructor(
    private readonly database: Db,
    private readonly classAccess: TeacherClassAccess,
    private readonly emailService?: UnifiedEmailService,
  ) {}

  private notifyGradeUpdated(
    classroom: Document,
    studentId: string,
    assignmentTitle: string,
    grade: number,
    feedback?: string,
  ): void {
    if (!this.emailService) return;
    const disciplineName = String(classroom.subjectName ?? classroom.name ?? classroom.code ?? "");
    void resolveActiveRegisteredRecipientById(this.database, studentId)
      .then((student) => {
        if (!student) return;
        dispatchNotificationSafe("teacher-gradebook", student.email, () =>
          this.emailService!.sendGradePublished({
            to: student.email,
            studentName: student.displayName,
            assignmentTitle,
            disciplineName,
            grade,
            feedback,
          }),
        );
      })
      .catch((err) => {
        console.warn(`[teacher-gradebook] Falha ao resolver discente para envio de nota: ${err?.message}`);
      });
  }

  async updateStudentGrade(
    userId: string,
    user: Document,
    classCode: string,
    studentId: string,
    scores: {
      assignmentsScore?: number;
      p1Score?: number;
      projectsScore?: number;
      p2Score?: number;
    },
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const adminSettings = await this.database
      .collection("admin_settings")
      .findOne({ _id: "institutional" as unknown as ObjectId });
    if (classroom.gradeLocked === true || adminSettings?.regimentalLockActive === true) {
      throw new AuthError(
        409,
        "gradebook_locked",
        "A pauta encontra-se bloqueada pela Trava Regimental ou fechamento oficial.",
      );
    }

    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode: classroom.code,
      studentId,
      status: "active",
    });
    if (!enrollment) throw new AuthError(404, "enrollment_not_found", "Aluno não matriculado nesta turma.");

    const existing = await this.database.collection("academic_grades").findOne({ classCode: classroom.code, studentId });
    const setFields: Record<string, unknown> = {
      ra: enrollment.studentIdentity,
      studentName: enrollment.displayName,
      hasEnteredGrades: true,
      updatedAt: new Date(),
    };
    if (scores.assignmentsScore !== undefined) setFields.assignmentsScore = scores.assignmentsScore;
    if (scores.p1Score !== undefined) setFields.p1Score = scores.p1Score;
    if (scores.projectsScore !== undefined) setFields.projectsScore = scores.projectsScore;
    if (scores.p2Score !== undefined) setFields.p2Score = scores.p2Score;

    await this.database.collection("academic_grades").updateOne(
      { classCode: classroom.code, studentId },
      {
        $set: setFields,
        $setOnInsert: {
          classCode: classroom.code,
          studentId,
          ...(scores.assignmentsScore === undefined ? { assignmentsScore: 0 } : {}),
          ...(scores.p1Score === undefined ? { p1Score: 0 } : {}),
          ...(scores.projectsScore === undefined ? { projectsScore: 0 } : {}),
          ...(scores.p2Score === undefined ? { p2Score: 0 } : {}),
          attendanceRate: 100,
          absences: 0,
          createdAt: new Date(),
        },
      },
      { upsert: true },
    );

    await this.database.collection("admin_audit_logs").insertOne({
      actorId: userId,
      actorName: user.displayName,
      actorRole: user.profile,
      action: "ALTERACAO NOTA",
      target: classroom.code,
      severity: "ATENCAO",
      diffBefore: existing
        ? JSON.stringify({
            assignmentsScore: existing.assignmentsScore,
            p1Score: existing.p1Score,
            projectsScore: existing.projectsScore,
            p2Score: existing.p2Score,
          })
        : null,
      diffAfter: JSON.stringify(scores),
      details: { studentId, ra: enrollment.studentIdentity, ...scores },
      createdAt: new Date(),
    });

    const changedStages = STAGE_LABELS
      .filter(([key]) => scores[key] !== undefined)
      .map(([key, label]) => ({ label, score: scores[key]! }));
    if (changedStages.length > 0) {
      const title = changedStages.map((s) => s.label).join(" / ");
      const summaryFeedback =
        changedStages.length > 1
          ? changedStages.map((s) => `${s.label}: ${s.score.toFixed(1)}`).join(" • ")
          : "Nota lançada ou atualizada no diário acadêmico pelo docente.";
      this.notifyGradeUpdated(classroom, studentId, title, changedStages[0]!.score, summaryFeedback);
    }

    return { ok: true };
  }

  async homologateClassGrades(userId: string, user: Document, classCode: string) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const chancelaCode = `CHANC-2026-${randomBytes(3).toString("hex").toUpperCase()}`;
    await this.database.collection("academic_classes").updateOne(
      { _id: classroom._id },
      {
        $set: {
          pautaHomologated: true,
          chancelaCode,
          homologatedAt: new Date(),
          homologatedBy: userId,
        },
      },
    );
    await this.database.collection("admin_audit_logs").insertOne({
      actorId: userId,
      actorName: user.displayName,
      actorRole: user.profile,
      action: "PAUTA HOMOLOGADA",
      target: classroom.code,
      severity: "INFO",
      details: { chancelaCode },
      createdAt: new Date(),
    });
    return { pautaHomologated: true, chancelaCode };
  }

  async requestGradeRectification(
    userId: string,
    user: Document,
    classCode: string,
    input: { studentId: string; stage: string; newScore: number; justification: string },
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode: classroom.code,
      studentId: input.studentId,
    });
    await this.database.collection("admin_audit_logs").insertOne({
      actorId: userId,
      actorName: user.displayName,
      actorRole: user.profile,
      action: "RETIFICACAO NOTA",
      target: classroom.code,
      severity: "ATENCAO",
      details: {
        studentId: input.studentId,
        ra: enrollment?.studentIdentity ?? "",
        stage: input.stage,
        newScore: input.newScore,
        justification: input.justification,
      },
      createdAt: new Date(),
    });

    if (classroom.gradeLocked !== true) {
      const fieldMap: Record<string, string> = {
        P1: "p1Score",
        P2: "p2Score",
        N1: "p1Score",
        N2: "p2Score",
        ATIVIDADES: "assignmentsScore",
        PROJETOS: "projectsScore",
      };
      const targetField = fieldMap[input.stage.toUpperCase()] ?? "p1Score";
      await this.database.collection("academic_grades").updateOne(
        { classCode: classroom.code, studentId: input.studentId },
        { $set: { [targetField]: input.newScore, updatedAt: new Date() } },
      );
      this.notifyGradeUpdated(
        classroom,
        input.studentId,
        `Retificação de Nota (${input.stage})`,
        input.newScore,
        input.justification,
      );
    }
    return { ok: true };
  }
}