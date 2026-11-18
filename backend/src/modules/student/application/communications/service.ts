// Desenvolvido por: Rafael Henrique dos Santos Inácio
import { randomBytes } from "node:crypto";
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";
import { formatShortDate } from "../../../../shared/formatting/date-formatters.js";
import type { UnifiedEmailService } from "../../../notifications/domain/notification.types.js";
import {
  dispatchNotificationSafe,
  resolveActiveRegisteredRecipientById,
} from "../../../notifications/domain/recipient-guard.js";

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export class StudentCommunicationsService {
  constructor(
    private readonly database: Db,
    private readonly emailService?: UnifiedEmailService,
  ) {}

  async markMessageRead(studentId: string, messageId: string) {
    if (!ObjectId.isValid(messageId)) throw new AuthError(400, "invalid_id", "Comunicado inválido.");
    await this.database.collection("academic_announcements").updateOne(
      { _id: new ObjectId(messageId) },
      { $addToSet: { readBy: String(studentId) } },
    );
    return { ok: true };
  }

  async markAllMessagesRead(studentId: string) {
    const enrollments = await this.database
      .collection("academic_enrollments")
      .find({ studentId: String(studentId), status: "active" })
      .toArray();
    const classCodes = enrollments.map((enrollment) => String(enrollment.classCode));
    await this.database.collection("academic_announcements").updateMany(
      { $or: [{ isInstitutional: true }, { classCode: { $in: classCodes } }] },
      { $addToSet: { readBy: String(studentId) } },
    );
    return { ok: true };
  }

  async contactProfessor(
    studentId: string,
    user: Document,
    classCode: string,
    input: { subject: string; message: string },
  ) {
    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode,
      studentId: String(studentId),
      status: "active",
    });
    if (!enrollment) {
      throw new AuthError(403, "enrollment_required", "Você não está matriculado nesta turma.");
    }
    const classroom = await this.database.collection("academic_classes").findOne({ code: classCode });
    if (!classroom) {
      throw new AuthError(404, "class_not_found", "Disciplina não localizada.");
    }

    const professor = await resolveActiveRegisteredRecipientById(
      this.database,
      String(classroom.professorId ?? ""),
    );
    if (!professor) {
      throw new AuthError(
        404,
        "professor_email_not_registered",
        "O docente responsável por esta disciplina não possui e-mail ativo cadastrado no sistema.",
      );
    }
    const recipientName = professor.displayName || String(classroom.professorName ?? "Docente Titular");
    const recipientEmail = professor.email;
    const now = new Date();
    const protocolCode = `MSG-DOC-${randomBytes(3).toString("hex").toUpperCase()}`;

    await this.database.collection("student_professor_messages").insertOne({
      protocolCode,
      classCode,
      subjectName: String(classroom.subjectName ?? classCode),
      studentId: String(studentId),
      studentName: String(user.displayName ?? user.identity),
      studentRa: String(user.identity ?? ""),
      studentEmail: String(user.email ?? ""),
      professorId: professor.userId,
      professorName: recipientName,
      professorEmail: recipientEmail,
      subject: input.subject.trim(),
      message: input.message.trim(),
      createdAt: now,
    });

    if (this.emailService) {
      const studentLabel = `${String(user.displayName ?? user.identity)} (RA: ${String(user.identity ?? "-")})`;
      const safeClassCode = escapeHtml(classCode);
      const safeStudentLabel = escapeHtml(studentLabel);
      const safeProtocolCode = escapeHtml(protocolCode);
      const safeMessage = escapeHtml(input.message.trim());
      dispatchNotificationSafe("student-contact-professor", recipientEmail, () =>
        this.emailService!.sendRaw({
          to: recipientEmail,
          subject: `[Portal AVA • ${classCode}] ${input.subject.trim()}`,
          text: `Mensagem enviada por ${studentLabel} na disciplina ${String(classroom.subjectName ?? classCode)} (${classCode}).\nProtocolo: ${protocolCode}\n\n${input.message.trim()}`,
          html: `<div style="font-family: sans-serif; color: #18181B;">
            <h3 style="margin-bottom: 4px;">Atendimento Discente — ${safeClassCode}</h3>
            <p style="color: #71717A; font-size: 13px;">De: <strong>${safeStudentLabel}</strong> • Protocolo: <code>${safeProtocolCode}</code></p>
            <hr style="border: none; border-top: 1px solid #E5E7EB; margin: 12px 0;" />
            <p style="font-size: 14px; line-height: 1.5; white-space: pre-wrap;">${safeMessage}</p>
          </div>`,
        }),
      );
    }

    return {
      success: true,
      protocolCode,
      recipientName,
      recipientEmail,
      sentAt: formatShortDate(now),
    };
  }
}