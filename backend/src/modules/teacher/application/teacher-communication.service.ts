// Desenvolvido por Murillo Caravita - RA: 25014012
import { randomUUID } from "node:crypto";
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";
import { TeacherClassAccess } from "./teacher-class-access.js";
import { formatShortDate } from "../../../shared/formatting/date-formatters.js";
import type { UnifiedEmailService } from "../../notifications/domain/notification.types.js";
import {
  dispatchNotificationSafe,
  resolveActiveEnrolledRecipients,
} from "../../notifications/domain/recipient-guard.js";
import { AcademicEmailTemplateRenderer } from "../../notifications/templates/academic-email-template.renderer.js";

export class TeacherCommunicationService {
  constructor(
    private readonly database: Db,
    private readonly classAccess: TeacherClassAccess,
    private readonly emailService?: UnifiedEmailService,
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

  async resolveForumTopic(
    userId: string,
    user: Document,
    classCode: string,
    topicId: string,
    isResolved: boolean,
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    if (!ObjectId.isValid(topicId)) throw new AuthError(400, "invalid_id", "Tópico inválido.");
    const res = await this.database.collection("academic_forum_topics").updateOne(
      { _id: new ObjectId(topicId), classCode: classroom.code },
      { $set: { isResolved, updatedAt: new Date() } },
    );
    if (res.matchedCount === 0) throw new AuthError(404, "topic_not_found", "Tópico não encontrado.");
    return { ok: true, id: topicId, isResolved };
  }

  async saveClassSquads(
    userId: string,
    user: Document,
    classCode: string,
    squads: Array<{
      id?: string;
      name: string;
      projectTitle: string;
      repoUrl?: string;
      sprintStatus?: string;
      status?: string;
      members: string[];
    }>,
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const normalized = squads.map((squad, index) => ({
      id: squad.id ?? `squad-${index + 1}`,
      name: squad.name,
      projectTitle: squad.projectTitle,
      repoUrl: squad.repoUrl ?? "",
      sprintStatus: squad.sprintStatus ?? squad.status ?? "Em andamento",
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

    if (this.emailService && classroom) {
      const disciplineName = String(classroom.subjectName ?? classroom.name ?? classroom.code);
      void resolveActiveEnrolledRecipients(this.database, classroom.code)
        .then((recipients) => {
          for (const student of recipients) {
            const rendered = AcademicEmailTemplateRenderer.renderCourseNotice({
              studentName: student.displayName,
              disciplineName,
              title: doc.title,
              message: doc.body,
              authorName: String(doc.authorName),
              classification: doc.classification,
            });
            dispatchNotificationSafe("teacher-notice", student.email, () =>
              this.emailService!.sendRaw({
                to: student.email,
                subject: rendered.subject,
                html: rendered.html,
                text: rendered.text,
              }),
            );
          }
        })
        .catch((err) => {
          console.warn(`[teacher-notice] Falha ao resolver destinatários matriculados: ${err?.message}`);
        });
    }

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

  async getNoticeReads(userId: string, user: Document, noticeId: string) {
    if (!ObjectId.isValid(noticeId)) {
      throw new AuthError(400, "invalid_id", "Comunicado inválido.");
    }
    const notice = await this.database.collection("academic_announcements").findOne({
      _id: new ObjectId(noticeId),
    });
    if (!notice || !notice.classCode) {
      throw new AuthError(404, "announcement_not_found", "Comunicado não encontrado.");
    }
    const classroom = await this.classAccess.requireOwnedClass(
      userId,
      user,
      String(notice.classCode),
    );
    const readBy = new Set(
      Array.isArray(notice.readBy) ? notice.readBy.map(String) : [],
    );
    const enrollments = await this.database
      .collection("academic_enrollments")
      .find({ classCode: classroom.code, status: "active" })
      .toArray();
    const reads = enrollments
      .filter((enrollment) => readBy.has(String(enrollment.studentId)))
      .map((enrollment) => ({
        studentId: String(enrollment.studentId),
        identity: String(enrollment.studentIdentity ?? ""),
        displayName: String(enrollment.displayName ?? enrollment.studentIdentity ?? ""),
      }));
    return {
      id: String(notice._id),
      readCount: reads.length,
      totalRecipients: Number(notice.totalRecipients ?? enrollments.length),
      reads,
    };
  }
}