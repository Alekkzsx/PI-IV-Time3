// Desenvolvido por: Rafael Henrique dos Santos Inácio
import type { Db } from "mongodb";

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
}