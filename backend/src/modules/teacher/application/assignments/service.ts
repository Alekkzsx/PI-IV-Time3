// Desenvolvido por Murillo Caravita - RA: 25014012
import { randomBytes } from "node:crypto";
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";
import { TeacherClassAccess } from "../teacher-class-access.js";

export class TeacherAssignmentService {
  constructor(
    private readonly database: Db,
    private readonly classAccess: TeacherClassAccess,
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
      dueDateFormatted: string;
      modality: string;
      allowLateWithPenalty: boolean;
      rubricCriteria: Array<{ id?: string; title: string; maxPoints: number; description?: string }>;
    },
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const now = new Date();
    const parsedDue = input.dueDate ? new Date(input.dueDate) : null;
    const doc = {
      classCode: classroom.code,
      courseCode: classroom.courseCode,
      title: input.title,
      description: input.description ?? "",
      weight: input.weight,
      stage: input.stage,
      maxScore: 10.0,
      dueDate: parsedDue && !Number.isNaN(parsedDue.getTime()) ? parsedDue : new Date(now.getTime() + 7 * 86_400_000),
      dueDateFormatted: input.dueDateFormatted,
      isUrgent: false,
      modality: input.modality,
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
    return { id: String(inserted.insertedId), ...doc };
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

    const gradeField = String(assignment.stage ?? "N1").toUpperCase() === "N2" ? "projectsScore" : "assignmentsScore";
    await this.database.collection("academic_grades").updateOne(
      { classCode: classroom.code, studentId: input.studentId },
      {
        $set: {
          ra: enrollment.studentIdentity,
          studentName: enrollment.displayName,
          [gradeField]: input.calculatedGrade,
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
      details: { assignmentId, studentId: input.studentId, score: input.calculatedGrade },
      createdAt: now,
    });
    return { ok: true, score: input.calculatedGrade };
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