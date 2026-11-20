// Desenvolvido por Murillo Caravita - RA: 25014012
import { randomBytes } from "node:crypto";
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";
import type { UnifiedEmailService } from "../../../notifications/domain/notification.types.js";
import {
  dispatchNotificationSafe,
  resolveActiveEnrolledRecipients,
  resolveActiveRegisteredRecipientById,
} from "../../../notifications/domain/recipient-guard.js";
import { TeacherClassAccess } from "../teacher-class-access.js";

function resolveDueParts(
  dueDateInput: string | undefined,
  dueDateFormattedInput: string,
  dueHourInput: string | undefined,
  fallbackDate: Date,
): { dueDate: Date; dueDateFormatted: string; dueHour: string } {
  const parsed = dueDateInput ? new Date(dueDateInput) : null;
  const hasValidDate = parsed !== null && !Number.isNaN(parsed.getTime());
  const dueDate = hasValidDate ? parsed : fallbackDate;

  let dueDateFormatted = dueDateFormattedInput.trim();
  let dueHour = (dueHourInput ?? "").trim();

  const matchWithHour = /^(.*?)\s+às\s+(\d{1,2}:\d{2})$/i.exec(dueDateFormatted);
  if (matchWithHour) {
    dueDateFormatted = matchWithHour[1]!.trim();
    if (!dueHour) dueHour = matchWithHour[2]!;
  }
  if (!dueHour && hasValidDate) {
    dueHour = `${String(dueDate.getHours()).padStart(2, "0")}:${String(dueDate.getMinutes()).padStart(2, "0")}`;
  }
  if (!dueHour) dueHour = "23:59";
  if (!dueDateFormatted) {
    dueDateFormatted = `${String(dueDate.getDate()).padStart(2, "0")}/${String(dueDate.getMonth() + 1).padStart(2, "0")}/${dueDate.getFullYear()}`;
  }
  return { dueDate, dueDateFormatted, dueHour };
}

function resolveActivityTypeLabel(
  activityTypeInput: string | undefined,
  title: string,
): { activityType: string; typeLabel: string } {
  const normalized = (activityTypeInput ?? "").trim().toLowerCase();
  if (normalized === "forum") return { activityType: "forum", typeLabel: "Fórum Temático" };
  if (normalized === "atividade_pratica") return { activityType: "atividade_pratica", typeLabel: "Atividade Prática" };
  if (normalized === "avaliacao_parcial") return { activityType: "avaliacao_parcial", typeLabel: "Avaliação Parcial" };
  if (normalized === "entrega") return { activityType: "entrega", typeLabel: "Entrega" };

  const lowerTitle = title.toLowerCase();
  if (lowerTitle.includes("fórum") || lowerTitle.includes("forum")) {
    return { activityType: "forum", typeLabel: "Fórum Temático" };
  }
  if (
    lowerTitle.includes("atividade prática") ||
    lowerTitle.includes("atividade pratica") ||
    lowerTitle.includes("laboratório")
  ) {
    return { activityType: "atividade_pratica", typeLabel: "Atividade Prática" };
  }
  if (lowerTitle.includes("avaliação parcial") || lowerTitle.includes("avaliacao parcial") || lowerTitle.includes("lista")) {
    return { activityType: "avaliacao_parcial", typeLabel: "Avaliação Parcial" };
  }
  return { activityType: "entrega", typeLabel: "Entrega" };
}

export class TeacherAssignmentService {
  constructor(
    private readonly database: Db,
    private readonly classAccess: TeacherClassAccess,
    private readonly emailService?: UnifiedEmailService,
  ) {}

  async createAssignment(
    userId: string,
    user: Document,
    classCode: string,
    input: {
      title: string;
      description?: string;
      weight: number;
      stage: string;
      dueDate?: string;
      dueHour?: string;
      dueDateFormatted: string;
      modality: string;
      allowLateWithPenalty: boolean;
      moduleTag?: string;
      activityType?: string;
      allowedFormats?: string;
      rubricCriteria: Array<{ id?: string; title: string; maxPoints: number; description?: string }>;
    },
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const now = new Date();
    const fallbackDue = new Date(now.getTime() + 7 * 86_400_000);
    const { dueDate, dueDateFormatted, dueHour } = resolveDueParts(
      input.dueDate,
      input.dueDateFormatted,
      input.dueHour,
      fallbackDue,
    );
    const { activityType, typeLabel } = resolveActivityTypeLabel(input.activityType, input.title);
    const isUrgent = dueDate.getTime() - now.getTime() <= 48 * 3_600_000;
    const doc = {
      classCode: classroom.code,
      courseCode: classroom.courseCode,
      title: input.title,
      description: input.description ?? "",
      weight: input.weight,
      stage: input.stage,
      maxScore: 10.0,
      dueDate,
      dueHour,
      dueDateFormatted,
      isUrgent,
      modality: input.modality,
      moduleTag: input.moduleTag?.trim() || `MÓDULO ${input.stage}`,
      activityType,
      typeLabel,
      allowedFormats: input.allowedFormats?.trim() || "PDF / ZIP",
      allowLateWithPenalty: input.allowLateWithPenalty,
      rubricCriteria: input.rubricCriteria.map((criterion, index) => ({
        id: criterion.id ?? `rc-${index + 1}`,
        title: criterion.title,
        maxPoints: criterion.maxPoints,
        description: criterion.description ?? "",
      })),
      doubts: [],
      authorName: user.displayName ?? user.identity,
      createdBy: userId,
      createdAt: now,
    };
    const inserted = await this.database.collection("academic_assignments").insertOne(doc);
    await this.database.collection("admin_audit_logs").insertOne({
      actorId: userId,
      actorName: user.displayName,
      actorRole: user.profile,
      action: "assignment_created",
      target: classroom.code,
      details: { assignmentId: String(inserted.insertedId), title: doc.title },
      createdAt: now,
    });

    if (this.emailService) {
      const disciplineName = String(classroom.subjectName ?? classroom.name ?? classroom.code);
      void resolveActiveEnrolledRecipients(this.database, classroom.code)
        .then((recipients) => {
          for (const student of recipients) {
            dispatchNotificationSafe("teacher-assignment-created", student.email, () =>
              this.emailService!.sendAssignmentDeadline({
                to: student.email,
                studentName: student.displayName,
                assignmentTitle: doc.title,
                disciplineName,
                dueDate: doc.dueDate,
              }),
            );
          }
        })
        .catch((err) => {
          console.warn(`[teacher-assignment-created] Falha ao resolver discentes matriculados: ${err?.message}`);
        });
    }

    return { id: String(inserted.insertedId), ...doc };
  }

  async deleteAssignment(userId: string, user: Document, assignmentId: string) {
    if (!ObjectId.isValid(assignmentId)) throw new AuthError(400, "invalid_id", "Atividade inválida.");
    const assignment = await this.database
      .collection("academic_assignments")
      .findOne({ _id: new ObjectId(assignmentId) });
    if (!assignment) throw new AuthError(404, "assignment_not_found", "Atividade não encontrada.");
    await this.classAccess.requireOwnedClass(userId, user, String(assignment.classCode));
    await this.database.collection("academic_assignments").deleteOne({ _id: new ObjectId(assignmentId) });
    await this.database.collection("academic_submissions").deleteMany({ assignmentId });
    return { ok: true, id: assignmentId };
  }

  async evaluateSubmission(
    userId: string,
    user: Document,
    assignmentId: string,
    input: {
      studentId: string;
      calculatedGrade: number;
      feedback: string;
      evaluatedCriteria: Array<{ id: string; title: string; maxPoints: number; assignedScore: number; description?: string }>;
    },
  ) {
    if (!ObjectId.isValid(assignmentId)) throw new AuthError(400, "invalid_id", "Atividade inválida.");
    const assignment = await this.database
      .collection("academic_assignments")
      .findOne({ _id: new ObjectId(assignmentId) });
    if (!assignment) throw new AuthError(404, "assignment_not_found", "Atividade não encontrada.");
    const classroom = await this.classAccess.requireOwnedClass(userId, user, String(assignment.classCode));
    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode: classroom.code,
      studentId: input.studentId,
      status: "active",
    });
    if (!enrollment) throw new AuthError(404, "enrollment_not_found", "Aluno não matriculado nesta turma.");

    const now = new Date();
    await this.database.collection("academic_submissions").updateOne(
      { assignmentId, studentId: input.studentId },
      {
        $set: {
          classCode: classroom.code,
          ra: enrollment.studentIdentity,
          studentName: enrollment.displayName,
          status: "avaliada",
          score: input.calculatedGrade,
          feedback: input.feedback,
          evaluatedCriteria: input.evaluatedCriteria,
          evaluatedBy: userId,
          evaluatedAt: now,
        },
        $setOnInsert: {
          assignmentId,
          studentId: input.studentId,
          submittedAt: now,
          protocolCode: `AGR-AVAL-${randomBytes(3).toString("hex").toUpperCase()}`,
        },
      },
      { upsert: true },
    );

    const isN2Bucket = String(assignment.stage ?? "N1").toUpperCase() === "N2";
    const gradeField = isN2Bucket ? "projectsScore" : "assignmentsScore";

    // Consolida média ponderada de todas as atividades avaliadas dessa etapa nesta turma
    const stageAssignments = await this.database
      .collection("academic_assignments")
      .find({ classCode: classroom.code })
      .toArray();
    const bucketAssignments = stageAssignments.filter(
      (a) => (String(a.stage ?? "N1").toUpperCase() === "N2") === isN2Bucket,
    );
    const weightByAssignmentId = new Map(
      bucketAssignments.map((a) => [String(a._id), Math.max(0.1, Number(a.weight ?? 1))]),
    );
    const evaluatedBucketSubmissions = await this.database
      .collection("academic_submissions")
      .find({
        assignmentId: { $in: Array.from(weightByAssignmentId.keys()) },
        studentId: input.studentId,
        status: "avaliada",
      })
      .toArray();

    let weightedSum = 0;
    let totalWeight = 0;
    for (const sub of evaluatedBucketSubmissions) {
      const score = Number(sub.score ?? sub.grade ?? 0);
      const w = weightByAssignmentId.get(String(sub.assignmentId)) ?? 1;
      weightedSum += score * w;
      totalWeight += w;
    }
    const consolidatedStageGrade =
      totalWeight > 0 ? Number((weightedSum / totalWeight).toFixed(1)) : input.calculatedGrade;

    await this.database.collection("academic_grades").updateOne(
      { classCode: classroom.code, studentId: input.studentId },
      {
        $set: {
          ra: enrollment.studentIdentity,
          studentName: enrollment.displayName,
          [gradeField]: consolidatedStageGrade,
          hasEnteredGrades: true,
          updatedAt: now,
        },
        $setOnInsert: {
          classCode: classroom.code,
          studentId: input.studentId,
          ...(gradeField === "assignmentsScore" ? { projectsScore: 0 } : { assignmentsScore: 0 }),
          p1Score: 0,
          p2Score: 0,
          attendanceRate: 100,
          absences: 0,
          createdAt: now,
        },
      },
      { upsert: true },
    );
    await this.database.collection("admin_audit_logs").insertOne({
      actorId: userId,
      actorName: user.displayName,
      actorRole: user.profile,
      action: "submission_evaluated",
      target: classroom.code,
      details: { assignmentId, studentId: input.studentId, score: input.calculatedGrade, consolidatedStageGrade },
      createdAt: now,
    });

    if (this.emailService) {
      const disciplineName = String(classroom.subjectName ?? classroom.name ?? classroom.code);
      const assignmentTitle = String(assignment.title ?? "Atividade Avaliativa");
      void resolveActiveRegisteredRecipientById(this.database, input.studentId)
        .then((student) => {
          if (!student) return;
          dispatchNotificationSafe("teacher-submission-evaluated", student.email, () =>
            this.emailService!.sendGradePublished({
              to: student.email,
              studentName: student.displayName,
              assignmentTitle,
              disciplineName,
              grade: input.calculatedGrade,
              feedback: input.feedback,
            }),
          );
        })
        .catch((err) => {
          console.warn(`[teacher-submission-evaluated] Falha ao resolver discente avaliado: ${err?.message}`);
        });
    }

    return {
      ok: true,
      score: input.calculatedGrade,
      consolidatedStageGrade,
      stage: isN2Bucket ? "N2" : "N1",
      gradeField,
    };
  }

  async replyAssignmentDoubt(userId: string, user: Document, assignmentId: string, doubtId: string, replyText: string) {
    if (!ObjectId.isValid(assignmentId)) throw new AuthError(400, "invalid_id", "Atividade inválida.");
    const assignment = await this.database
      .collection("academic_assignments")
      .findOne({ _id: new ObjectId(assignmentId) });
    if (!assignment) throw new AuthError(404, "assignment_not_found", "Atividade não encontrada.");
    await this.classAccess.requireOwnedClass(userId, user, String(assignment.classCode));
    const doubts: Document[] = Array.isArray(assignment.doubts) ? assignment.doubts : [];
    const updatedDoubts = doubts.map((doubt) =>
      String(doubt.id) === doubtId
        ? {
            ...doubt,
            reply: replyText,
            repliedBy: user.displayName ?? user.identity,
            repliedAt: new Date().toISOString(),
            resolved: true,
          }
        : doubt,
    );
    await this.database
      .collection("academic_assignments")
      .updateOne({ _id: new ObjectId(assignmentId) }, { $set: { doubts: updatedDoubts } });
    return { ok: true, doubts: updatedDoubts };
  }
}