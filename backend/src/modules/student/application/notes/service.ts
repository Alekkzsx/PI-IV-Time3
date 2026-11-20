// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
import type { Db, Document } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";

export class StudentNotesService {
  constructor(private readonly database: Db) {}

  async savePersonalNote(studentId: string, classCode: string, content: string) {
    await this.database.collection("student_notes").updateOne(
      { studentId: String(studentId), classCode },
      { $set: { studentId: String(studentId), classCode, content, updatedAt: new Date() } },
      { upsert: true },
    );
    return { ok: true };
  }

  async setChecklistItem(studentId: string, classCode: string, itemId: string, completed?: boolean) {
    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode,
      studentId: String(studentId),
      status: "active",
    });
    if (!enrollment) {
      throw new AuthError(403, "enrollment_required", "Você não está matriculado nesta turma.");
    }
    const currentItems = Array.isArray(enrollment.completedChecklistItems)
      ? enrollment.completedChecklistItems.map(String)
      : [];
    const targetCompleted = completed !== undefined ? completed : !currentItems.includes(itemId);
    const nextItems = targetCompleted
      ? Array.from(new Set([...currentItems, itemId]))
      : currentItems.filter((id) => id !== itemId);

    await this.database.collection("academic_enrollments").updateOne(
      { _id: enrollment._id },
      { $set: { completedChecklistItems: nextItems, updatedAt: new Date() } as Document },
    );
    return {
      ok: true,
      classCode,
      itemId,
      completed: targetCompleted,
      completedChecklistItems: nextItems,
    };
  }
}