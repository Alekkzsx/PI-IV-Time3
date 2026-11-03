// Desenvolvido por Murillo Caravita - RA: 25014012
import { randomUUID } from "node:crypto";
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";
import { TeacherClassAccess } from "./teacher-class-access.js";
import { formatShortDate } from "../../../shared/formatting/date-formatters.js";

export class TeacherCommunicationService {
  constructor(
    private readonly database: Db,
    private readonly classAccess: TeacherClassAccess,
  ) {}

  async createForumTopic(
    userId: string,
    user: Document,
    classCode: string,
    input: { title: string; body: string; category?: string },
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const now = new Date();
    const doc = {
      classCode: classroom.code,
      title: input.title,
      body: input.body,
      category: input.category ?? "Discussão Acadêmica",
      authorId: userId,
      authorName: user.displayName ?? user.identity,
      authorRole: user.profile,
      isResolved: false,
      replies: [],
      createdAt: now,
    };
    const inserted = await this.database.collection("academic_forum_topics").insertOne(doc);
    return { id: String(inserted.insertedId), ...doc };
  }

  async replyForumTopic(userId: string, user: Document, classCode: string, topicId: string, body: string) {
    await this.classAccess.requireOwnedClass(userId, user, classCode);
    if (!ObjectId.isValid(topicId)) throw new AuthError(400, "invalid_id", "Tópico inválido.");
    const reply = {
      id: randomUUID(),
      authorId: userId,
      authorName: user.displayName ?? user.identity,
      authorRole: user.profile,
      body,
      createdAt: new Date().toISOString(),
    };
    await this.database.collection("academic_forum_topics").updateOne(
      { _id: new ObjectId(topicId) },
      { $push: { replies: reply } as unknown as Document },
    );
    return reply;
  }

  async saveClassSquads(
    userId: string,
    user: Document,
    classCode: string,
    squads: Array<{ id?: string; name: string; projectTitle: string; repoUrl?: string; members: string[] }>,
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const normalized = squads.map((squad, index) => ({
      id: squad.id ?? `squad-${index + 1}`,
      name: squad.name,
      projectTitle: squad.projectTitle,
      repoUrl: squad.repoUrl ?? "",
      members: squad.members,
    }));
    await this.database
      .collection("academic_classes")
      .updateOne({ _id: classroom._id }, { $set: { squads: normalized, updatedAt: new Date() } });
    return normalized;
  }

  async createEvent(
    userId: string,
    input: { title: string; date: string; time: string; type: string; location: string },
  ) {
    const now = new Date();
    const doc = {
      ownerId: userId,
      title: input.title,
      date: input.date,
      time: input.time,
      type: input.type,
      location: input.location,
      isSynced: true,
      createdAt: now,
    };
    const inserted = await this.database.collection("academic_events").insertOne(doc);
    return { id: String(inserted.insertedId), ...doc };
  }

  async publishNotice(
    userId: string,
    user: Document,
    input: {
      targetCourse: string;
      targetAudience: string;
      classification: string;
      title: string;
      message: string;
    },
  ) {
    const classroom = await this.database.collection("academic_classes").findOne({ code: input.targetCourse });
    const enrolledCount = classroom
      ? await this.database
          .collection("academic_enrollments")
          .countDocuments({ classCode: classroom.code, status: "active" })
      : 0;
    const now = new Date();
    const doc = {
      title: input.title,
      body: input.message,
      audience: input.targetAudience,
      category: "Disciplina",
      classification: input.classification,
      classCode: classroom ? classroom.code : input.targetCourse,
      isInstitutional: false,
      authorName: user.displayName ?? user.identity,
      senderRole: "docente",
      readBy: [],
      totalRecipients: Math.max(1, enrolledCount),
      publishedAt: formatShortDate(now),
      createdBy: userId,
      createdAt: now,
    };
    const inserted = await this.database.collection("academic_announcements").insertOne(doc);
    return {
      id: String(inserted.insertedId),
      author: doc.authorName,
      targetCourse: doc.classCode,
      targetAudience: doc.audience,
      classification: doc.classification,
      publishedAt: doc.publishedAt,
      title: doc.title,
      message: doc.body,
      readCount: 0,
      totalRecipients: doc.totalRecipients,
      isFromSecretaria: false,
    };
  }
}