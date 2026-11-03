// Desenvolvido por: Rafael Henrique dos Santos Inácio
import { ObjectId, type Db } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";

export class StudentCommunicationsService {
  constructor(private readonly database: Db) {}

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
}