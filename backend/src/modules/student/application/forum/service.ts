// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
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

  async getClassChatMessages(studentId: string, classCode: string) {
    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode,
      studentId: String(studentId),
      status: "active",
    });
    if (!enrollment) throw new AuthError(403, "enrollment_required", "Você não está matriculado nesta turma.");
    const classroom = await this.database.collection("academic_classes").findOne({ code: classCode });
    return Array.isArray(classroom?.chatMessages) ? classroom.chatMessages : [];
  }

  async postClassChatMessage(studentId: string, user: Document, classCode: string, messageText: string) {
    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode,
      studentId: String(studentId),
      status: "active",
    });
    if (!enrollment) throw new AuthError(403, "enrollment_required", "Você não está matriculado nesta turma.");
    const now = new Date();
    const message = {
      id: randomUUID(),
      authorId: String(studentId),
      authorName: String(user.displayName ?? user.identity),
      authorRa: String(user.identity ?? ""),
      authorRole: "aluno",
      authorProfile: "Estudante",
      message: messageText.trim(),
      body: messageText.trim(),
      timestamp: formatShortDate(now),
      createdAt: now.toISOString(),
    };
    await this.database.collection("academic_classes").updateOne(
      { code: classCode },
      { $push: { chatMessages: message } as unknown as Document },
    );
    await this.database.collection("academic_class_chat_messages").insertOne({
      classCode,
      ...message,
    });
    return message;
  }

  async updateSquad(
    studentId: string,
    classCode: string,
    squadId: string,
    input: { repoUrl?: string; projectTitle?: string; sprintStatus?: string },
  ) {
    const enrollment = await this.database.collection("academic_enrollments").findOne({
      classCode,
      studentId: String(studentId),
      status: "active",
    });
    if (!enrollment) throw new AuthError(403, "enrollment_required", "Você não está matriculado nesta turma.");
    const classroom = await this.database.collection("academic_classes").findOne({ code: classCode });
    if (!classroom) throw new AuthError(404, "class_not_found", "Turma não encontrada.");

    const squads = Array.isArray(classroom.squads) ? [...classroom.squads] : [];
    const idx = squads.findIndex((sq: Document) => String(sq.id) === squadId);
    if (idx === -1) throw new AuthError(404, "squad_not_found", "Squad não localizado nesta turma.");

    const updated = {
      ...squads[idx],
      ...(input.repoUrl !== undefined ? { repoUrl: input.repoUrl.trim() } : {}),
      ...(input.projectTitle !== undefined ? { projectTitle: input.projectTitle.trim() } : {}),
      ...(input.sprintStatus !== undefined ? { sprintStatus: input.sprintStatus.trim() } : {}),
      updatedAt: new Date().toISOString(),
    };
    squads[idx] = updated;

    await this.database.collection("academic_classes").updateOne(
      { _id: classroom._id },
      { $set: { squads } as Document },
    );
    return updated;
  }
}