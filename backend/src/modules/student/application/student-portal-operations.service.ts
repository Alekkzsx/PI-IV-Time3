// Desenvolvido por: Rafael Henrique dos Santos Inácio
import type { Db, Document } from "mongodb";
import { StudentProtocolService } from "./protocols/index.js";
import { StudentForumService } from "./forum/index.js";
import { StudentCalendarService } from "./calendar/index.js";
import { StudentCommunicationsService } from "./communications/index.js";
import { StudentNotesService } from "./notes/index.js";
import { StudentDeliveryService } from "./deliveries/index.js";

export class StudentPortalOperationsService {
  private readonly protocolService: StudentProtocolService;
  private readonly forumService: StudentForumService;
  private readonly calendarService: StudentCalendarService;
  private readonly communicationsService: StudentCommunicationsService;
  private readonly notesService: StudentNotesService;
  private readonly deliveryService: StudentDeliveryService;

  constructor(database: Db) {
    this.protocolService = new StudentProtocolService(database);
    this.forumService = new StudentForumService(database);
    this.calendarService = new StudentCalendarService(database);
    this.communicationsService = new StudentCommunicationsService(database);
    this.notesService = new StudentNotesService(database);
    this.deliveryService = new StudentDeliveryService(database);
  }

  async submitDelivery(
    studentId: string,
    user: Document,
    assignmentId: string,
    input: {
      fileName: string;
      fileSize?: string;
      contentBase64?: string;
      gitUrl?: string;
      comments?: string;
    },
  ) {
    return this.deliveryService.submit(studentId, user, assignmentId, input);
  }

  async postAssignmentDoubt(studentId: string, user: Document, assignmentId: string, question: string) {
    return this.deliveryService.postAssignmentDoubt(studentId, user, assignmentId, question);
  }

  async addReminder(
    studentId: string,
    input: { title: string; date: string; timeRange?: string; courseCode?: string; location?: string },
  ) {
    return this.calendarService.addReminder(studentId, input);
  }

  async markMessageRead(studentId: string, messageId: string) {
    return this.communicationsService.markMessageRead(studentId, messageId);
  }

  async markAllMessagesRead(studentId: string) {
    return this.communicationsService.markAllMessagesRead(studentId);
  }

  async submitProtocol(
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
    return this.protocolService.submit(studentId, user, input);
  }

  async savePersonalNote(studentId: string, classCode: string, content: string) {
    return this.notesService.savePersonalNote(studentId, classCode, content);
  }

  async createForumTopic(
    studentId: string,
    user: Document,
    classCode: string,
    input: { title: string; body: string; category?: string },
  ) {
    return this.forumService.createTopic(studentId, user, classCode, input);
  }

  async replyForumTopic(studentId: string, user: Document, classCode: string, topicId: string, body: string) {
    return this.forumService.reply(studentId, user, classCode, topicId, body);
  }
}