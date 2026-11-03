// Desenvolvido por: Rafael Henrique dos Santos Inácio
import { createHash, randomBytes, randomUUID } from "node:crypto";
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";
import { formatShortDate } from "../../../../shared/formatting/date-formatters.js";

export class StudentDeliveryService {
  constructor(private readonly database: Db) {}

  async submit(
    studentId: string,
    user: Document,
    assignmentId: string,
    input: {
      fileName: string;
      fileSize?: string;
      contentBase64?: string;
      gitUrl?: string;
      comments?: string;
    },
  ) {
    if (!ObjectId.isValid(assignmentId)) throw new AuthError(400, "invalid_id", "Atividade inválida.");
    const assignment = await this.database
      .collection("academic_assignments")
      .findOne({ _id: new ObjectId(assignmentId) });
    if (!assignment) throw new AuthError(404, "assignment_not_found", "Atividade não encontrada.");
    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode: assignment.classCode,
      studentId: String(studentId),
      status: "active",
    });
    if (!enrollment) throw new AuthError(403, "enrollment_required", "Você não está matriculado nesta turma.");

    const now = new Date();
    const rawBuffer = input.contentBase64
      ? Buffer.from(input.contentBase64, "base64")
      : Buffer.from(`${studentId}:${assignmentId}:${input.fileName}:${input.gitUrl ?? ""}:${now.toISOString()}`);
    const sha256 = createHash("sha256").update(rawBuffer).digest("hex");
    const protocolCode = `AGR-2026-${randomBytes(3).toString("hex").toUpperCase()}`;
    const computedSize =
      input.fileSize ??
      (rawBuffer.byteLength >= 1024 * 1024
        ? `${(rawBuffer.byteLength / (1024 * 1024)).toFixed(2)} MB`
        : `${Math.max(1, Math.round(rawBuffer.byteLength / 1024))} KB`);
    const isLate = assignment.dueDate ? now > new Date(assignment.dueDate) : false;
    if (isLate && assignment.allowLateWithPenalty === false) {
      throw new AuthError(409, "deadline_closed", "O prazo desta atividade está encerrado e não aceita atrasos.");
    }

    const submissionWrite = await this.database.collection("academic_submissions").updateOne(
      { assignmentId, studentId: String(studentId) },
      {
        $set: {
          assignmentId,
          classCode: assignment.classCode,
          studentId: String(studentId),
          ra: user.identity,
          studentName: user.displayName,
          fileName: input.fileName,
          fileSize: computedSize,
          contentBase64: input.contentBase64 ?? null,
          sha256,
          gitUrl: input.gitUrl ?? "",
          comments: input.comments ?? "",
          protocolCode,
          status: "aguardandoCorrecao",
          isLate,
          submittedAt: now,
          submittedAtFormatted: formatShortDate(now),
        },
      },
      { upsert: true },
    );
    const submissionId = submissionWrite.upsertedId
      ? String(submissionWrite.upsertedId)
      : String(
          (
            await this.database.collection("academic_submissions").findOne(
              { assignmentId, studentId: String(studentId) },
              { projection: { _id: 1 } },
            )
          )?._id ?? "",
        );
    await this.database.collection("admin_audit_logs").insertOne({
      actorId: String(studentId),
      actorName: user.displayName,
      actorRole: "aluno",
      action: "delivery_submitted",
      target: String(assignment.classCode),
      details: { assignmentId, protocolCode, fileName: input.fileName, sha256 },
      createdAt: now,
    });
    return {
      submissionId,
      protocolCode,
      sha256,
      submittedAt: formatShortDate(now),
      fileName: input.fileName,
      fileSize: computedSize,
      status: "Em Análise",
    };
  }

  async postAssignmentDoubt(studentId: string, user: Document, assignmentId: string, question: string) {
    if (!ObjectId.isValid(assignmentId)) throw new AuthError(400, "invalid_id", "Atividade inválida.");
    const assignment = await this.database
      .collection("academic_assignments")
      .findOne({ _id: new ObjectId(assignmentId) });
    if (!assignment) throw new AuthError(404, "assignment_not_found", "Atividade não encontrada.");
    const doubt = {
      id: randomUUID(),
      studentId: String(studentId),
      studentRa: user.identity,
      studentName: user.displayName,
      question,
      reply: null,
      resolved: false,
      createdAt: new Date().toISOString(),
    };
    await this.database.collection("academic_assignments").updateOne(
      { _id: new ObjectId(assignmentId) },
      { $push: { doubts: doubt } as unknown as Document },
    );
    return doubt;
  }
}