// Desenvolvido por: Rafael Henrique dos Santos Inácio
import { randomBytes } from "node:crypto";
import type { Db, Document } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";
import { formatShortDate } from "../../../../shared/formatting/date-formatters.js";

export class StudentProtocolService {
  constructor(private readonly database: Db) {}

  async submit(
    studentId: string,
    user: Document,
    input: {
      requestType: string;
      targetComponent: string;
      justification: string;
      attachmentName?: string;
      attachmentBase64?: string;
    },
  ) {
    if (user.profile !== "aluno") {
      throw new AuthError(403, "forbidden", "Apenas discentes podem abrir requerimentos estudantis por este canal.");
    }
    const now = new Date();
    const code = `PROT-2026/${randomBytes(2).toString("hex").toUpperCase()}`;
    const doc = {
      code,
      studentId: String(studentId),
      studentIdentity: user.normalizedIdentity,
      studentRa: user.identity,
      studentName: user.displayName,
      requestType: input.requestType,
      targetComponent: input.targetComponent,
      justification: input.justification,
      attachmentName: input.attachmentName ?? "",
      attachmentBase64: input.attachmentBase64 ?? null,
      status: "Aguardando Parecer",
      createdAt: now,
      createdBy: String(studentId),
    };
    const inserted = await this.database.collection("academic_protocols").insertOne(doc);
    await this.database.collection("admin_audit_logs").insertOne({
      actorId: String(studentId),
      actorName: user.displayName,
      actorRole: "aluno",
      action: "protocol_submitted",
      target: code,
      details: { requestType: input.requestType, targetComponent: input.targetComponent },
      createdAt: now,
    });
    return {
      id: String(inserted.insertedId),
      protocolCode: code,
      submittedAt: formatShortDate(now),
      subjectType: doc.requestType,
      componentObject: doc.targetComponent,
      status: "pending",
      statusLabel: doc.status,
      officialOpinion: "Aguardando análise e despacho da Secretaria Acadêmica.",
      justification: doc.justification,
      attachmentName: doc.attachmentName || null,
    };
  }
}