// Desenvolvido por: Rafael Henrique dos Santos Inácio
import { randomBytes } from "node:crypto";
import type { Db, Document } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";
import { formatShortDate } from "../../../shared/formatting/date-formatters.js";
import {
  mapStudentDeliveries,
  mapStudentDisciplines,
  mapStudentEvents,
  mapStudentForumTopics,
  mapStudentHistoricalBoletim,
  mapStudentMessages,
  mapStudentProfileAndStats,
  mapStudentProtocols,
  mapStudentSecurityLogs,
  mapStudentSessions,
} from "./student-dashboard.mapper.js";
import { StudentDashboardRepository } from "./student-dashboard.repository.js";
import { StudentPortalOperationsService } from "./student-portal-operations.service.js";
import { buildStudentTimeline } from "./timeline/student-timeline.builder.js";

export class StudentDashboardService {
  private readonly repository: StudentDashboardRepository;
  private readonly operations: StudentPortalOperationsService;

  constructor(private readonly database: Db) {
    this.repository = new StudentDashboardRepository(database);
    this.operations = new StudentPortalOperationsService(database);
  }

  async getBootstrap(studentId: string, user: Document, currentSessionId?: string) {
    const {
      enrollments,
      classCodes,
      courseCodes,
      classes,
      courses,
      classSessions,
      assignments,
      submissions,
      grades,
      materials,
      forumTopics,
      personalNotes,
      personalReminders,
      calendarEvents,
      announcements,
      protocols,
      liveSessions,
      activeSessions,
      auditLogs,
      profMap,
    } = await this.repository.load(studentId);

    const submissionByAssignment = new Map(submissions.map((s) => [String(s.assignmentId), s]));
    const notesMap: Record<string, string> = {};
    for (const n of personalNotes) {
      notesMap[String(n.classCode)] = String(n.content ?? "");
    }

    // 1. Disciplinas matriculadas
    const mappedDisciplines = mapStudentDisciplines({
      classes,
      enrollments,
      grades,
      submissions,
      classSessions,
      materials,
      assignments,
      liveSessions,
      studentId,
      studentIdentity: user.identity,
      professorById: profMap,
    });

    // 2. Entregas / Atividades
    const classByCode = new Map(mappedDisciplines.map((d) => [d.code, d]));
    const mappedDeliveries = mapStudentDeliveries(assignments, classByCode, submissionByAssignment);

    // 3. Eventos do Calendário do Aluno
    const mappedEvents = mapStudentEvents(classSessions, assignments, calendarEvents, personalReminders);

    const historicalBoletim = mapStudentHistoricalBoletim(mappedDisciplines);
    const mappedMessages = mapStudentMessages(announcements, studentId);
    const mappedProtocols = mapStudentProtocols(protocols);

    const { studentInfo, stats, recordSummary } = mapStudentProfileAndStats({
      studentId,
      user,
      courses,
      classes,
      disciplines: mappedDisciplines,
    });

    return {
      studentInfo,
      stats,
      recordSummary,
      disciplines: mappedDisciplines,
      deliveries: mappedDeliveries,
      events: mappedEvents,
      historicalBoletim,
      messages: mappedMessages,
      protocols: mappedProtocols,
      forumTopics: mapStudentForumTopics(forumTopics),
      personalNotes: notesMap,
      activeSessions: mapStudentSessions(activeSessions, currentSessionId),
      securityLogs: mapStudentSecurityLogs(auditLogs),
    };
  }

  async getDashboardOverview(studentId: string, user: Document) {
    const boot = await this.getBootstrap(studentId, user);
    const liveDisc = boot.disciplines.find((d) => d.isLive) ?? boot.disciplines[0] ?? null;
    return {
      studentInfo: boot.studentInfo,
      stats: boot.stats,
      todayClass: liveDisc
        ? {
            time: liveDisc.time,
            isLive: liveDisc.isLive,
            discipline: liveDisc.code,
            disciplineName: liveDisc.name,
            roomCode: liveDisc.roomCode,
            teacher: liveDisc.professor,
            location: liveDisc.location,
            linkType: "Sala Virtual",
          }
        : null,
      freeSchedule: !liveDisc
        ? {
            hasFreeSchedule: true,
            message: "Nenhuma aula agendada no momento.",
          }
        : null,
      disciplines: boot.disciplines,
      deliveries: boot.deliveries.slice(0, 6),
      notices: boot.messages.slice(0, 5),
    };
  }

  async getStudentDisciplines(studentId: string, user: Document) {
    const boot = await this.getBootstrap(studentId, user);
    return {
      totalHours: {
        current: boot.stats.completedHoursSemester,
        max: boot.stats.totalHoursSemester,
        percentage:
          boot.stats.totalHoursSemester > 0
            ? Math.round((boot.stats.completedHoursSemester / boot.stats.totalHoursSemester) * 100)
            : 0,
      },
      status: {
        text: boot.stats.academicStatus,
        subtext: `${boot.disciplines.length} disciplinas em andamento`,
      },
      disciplinesList: boot.disciplines,
      historicalBoletim: boot.historicalBoletim,
    };
  }

  async getStudentBoletim(studentId: string, user: Document) {
    const boot = await this.getBootstrap(studentId, user);
    return boot.historicalBoletim;
  }

  async getTimeline(studentId: string, customNow?: Date) {
    const data = await this.repository.load(studentId);
    const now =
      customNow ??
      (process.env.TIMELINE_SIMULATED_NOW
        ? new Date(process.env.TIMELINE_SIMULATED_NOW)
        : new Date("2026-09-20T12:00:00.000Z"));
    return buildStudentTimeline({
      now,
      studentId,
      assignments: data.assignments,
      submissions: data.submissions,
      forumTopics: data.forumTopics,
      materials: data.materials,
      personalReminders: data.personalReminders,
      calendarEvents: data.calendarEvents,
      classes: data.classes,
    });
  }

  async issueEnrollmentDeclaration(studentId: string, user: Document) {
    const enrollments = await this.database
      .collection("academic_enrollments")
      .find({ studentId, status: "active" })
      .toArray();
    if (enrollments.length === 0) {
      throw new AuthError(
        409,
        "active_enrollment_required",
        "É necessário possuir matrícula ativa para emitir a declaração.",
      );
    }

    const classCodes = enrollments.map((enrollment) => String(enrollment.classCode));
    const classes = await this.database
      .collection("academic_classes")
      .find({ code: { $in: classCodes }, active: { $ne: false } })
      .toArray();
    const issuedAt = new Date();
    const declaration = {
      studentId,
      studentIdentity: String(user.identity),
      studentName: String(user.displayName ?? user.identity),
      course: String(user.departmentOrCourse ?? user.department ?? ""),
      enrollmentCount: enrollments.length,
      classCodes,
      classes: classes.map((classroom) => ({
        code: String(classroom.code),
        name: String(classroom.subjectName ?? classroom.courseName ?? classroom.code),
        semester: String(classroom.semester ?? ""),
      })),
      verificationKey: `AGMRM-${randomBytes(16).toString("hex").toUpperCase()}`,
      issuedAt,
    };
    const inserted = await this.database
      .collection("academic_enrollment_declarations")
      .insertOne(declaration);
    return {
      id: String(inserted.insertedId),
      ...declaration,
      issuedAt: issuedAt.toISOString(),
    };
  }

  async getStudentDeliveries(studentId: string, user: Document) {
    const boot = await this.getBootstrap(studentId, user);
    const pending = boot.deliveries.filter((d) => d.status === "Pendente").length;
    const inAnalysis = boot.deliveries.filter((d) => d.status === "Em Análise").length;
    const evaluatedList = boot.deliveries.filter((d) => d.status === "Avaliada" && d.score !== null);
    const media =
      evaluatedList.length > 0
        ? Number(
            (evaluatedList.reduce((acc, d) => acc + (d.score ?? 0), 0) / evaluatedList.length).toFixed(1),
          )
        : 0.0;
    return {
      stats: { pending, inAnalysis, evaluated: evaluatedList.length, media },
      tasks: boot.deliveries,
    };
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
    return this.operations.submitDelivery(studentId, user, assignmentId, input);
  }

  async postAssignmentDoubt(studentId: string, user: Document, assignmentId: string, question: string) {
    return this.operations.postAssignmentDoubt(studentId, user, assignmentId, question);
  }

  async addReminder(
    studentId: string,
    input: { title: string; date: string; timeRange?: string; courseCode?: string; location?: string },
  ) {
    return this.operations.addReminder(studentId, input);
  }

  async markMessageRead(studentId: string, messageId: string) {
    return this.operations.markMessageRead(studentId, messageId);
  }

  async markAllMessagesRead(studentId: string) {
    return this.operations.markAllMessagesRead(studentId);
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
    return this.operations.submitProtocol(studentId, user, input);
  }

  async savePersonalNote(studentId: string, classCode: string, content: string) {
    return this.operations.savePersonalNote(studentId, classCode, content);
  }

  async createForumTopic(
    studentId: string,
    user: Document,
    classCode: string,
    input: { title: string; body: string; category?: string },
  ) {
    return this.operations.createForumTopic(studentId, user, classCode, input);
  }

  async replyForumTopic(studentId: string, user: Document, classCode: string, topicId: string, body: string) {
    return this.operations.replyForumTopic(studentId, user, classCode, topicId, body);
  }
}
