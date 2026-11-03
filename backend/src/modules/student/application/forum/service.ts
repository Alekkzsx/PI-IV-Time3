// Desenvolvido por: Rafael Henrique dos Santos Inácio
import { randomUUID } from "node:crypto";
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";
import { formatShortDate } from "../../../../shared/formatting/date-formatters.js";

export class StudentForumService {
  constructor(private readonly database: Db) {}

  async createTopic(
    studentId: string,
    user: Document,
    classCode: string,
    input: { title: string; body: string; category?: string },
  ) {
    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode,
      studentId: String(studentId),
      status: "active",
    });
    if (!enrollment) throw new AuthError(403, "enrollment_required", "Você não está matriculado nesta turma.");
    const now = new Date();
    const doc = {
      classCode,
      title: input.title,
      body: input.body,
      category: input.category ?? "Dúvida Discente",
      authorId: String(studentId),
      authorName: user.displayName ?? user.identity,
      authorRole: "aluno",
      isResolved: false,
      replies: [],
      createdAt: now,
    };
    const inserted = await this.database.collection("academic_forum_topics").insertOne(doc);
    return {
      id: String(inserted.insertedId),
      classCode,
      title: doc.title,
      body: doc.body,
      authorName: doc.authorName,
      authorRole: doc.authorRole,
      category: doc.category,
      isResolved: false,
      createdAt: formatShortDate(now),
      replies: [],
    };
  }

  async reply(studentId: string, user: Document, classCode: string, topicId: string, body: string) {
    if (!ObjectId.isValid(topicId)) throw new AuthError(400, "invalid_id", "Tópico inválido.");
    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode,
      studentId: String(studentId),
      status: "active",
    });
    if (!enrollment) throw new AuthError(403, "enrollment_required", "Você não está matriculado nesta turma.");
    const reply = {
      id: randomUUID(),
      authorId: String(studentId),
      authorName: user.displayName ?? user.identity,
      authorRole: "aluno",
      body,
      createdAt: new Date().toISOString(),
    };
    await this.database.collection("academic_forum_topics").updateOne(
      { _id: new ObjectId(topicId) },
      { $push: { replies: reply } as unknown as Document },
    );
    return reply;
  }
}