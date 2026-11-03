// Desenvolvido por: Rafael Henrique dos Santos Inácio
import type { Db } from "mongodb";

export class StudentCalendarService {
  constructor(private readonly database: Db) {}

  async addReminder(
    studentId: string,
    input: { title: string; date: string; timeRange?: string; courseCode?: string; location?: string },
  ) {
    const parsedDate = new Date(input.date);
    const doc = {
      studentId: String(studentId),
      title: input.title,
      date: Number.isNaN(parsedDate.getTime()) ? new Date() : parsedDate,
      timeRange: input.timeRange ?? "Dia inteiro",
      courseCode: input.courseCode ?? "PESSOAL",
      location: input.location ?? "Lembrete Pessoal",
      createdAt: new Date(),
    };
    const inserted = await this.database.collection("student_reminders").insertOne(doc);
    return {
      id: String(inserted.insertedId),
      ...doc,
      date: doc.date.toISOString(),
      category: "lembrete",
    };
  }
}