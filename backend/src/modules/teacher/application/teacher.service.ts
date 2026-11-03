// Desenvolvido por Murillo Caravita - RA: 25014012
import { ObjectId, type Db, type Document } from "mongodb";
import { TeacherClassAccess } from "./teacher-class-access.js";
import { TeacherCommunicationService } from "./teacher-communication.service.js";
import { TeacherDashboardRepository } from "./teacher-dashboard.repository.js";
import { formatPtBrLongDate, formatShortDate } from "../../../shared/formatting/date-formatters.js";
import {
  mapTeacherEvents,
  mapTeacherCourses,
  mapTeacherNotices,
  mapTeacherProfile,
  mapTeacherProtocols,
  mapTeacherAssignments,
  mapTeacherGrades,
} from "./teacher-dashboard.mapper.js";
import { TeacherMaterialService } from "./teacher-material.service.js";
import { TeacherSessionService, type SessionAttendanceUpdate } from "./teacher-session.service.js";
import { TeacherGradebookService } from "./gradebook/index.js";
import { TeacherAssignmentService } from "./assignments/index.js";
import { createDefaultSyllabusUnits, TeacherSyllabusService } from "./syllabus/index.js";

export { formatPtBrLongDate, formatShortDate } from "../../../shared/formatting/date-formatters.js";

export class TeacherService {
  private readonly classAccess: TeacherClassAccess;
  private readonly communicationService: TeacherCommunicationService;
  private readonly dashboardRepository: TeacherDashboardRepository;
  private readonly materialService: TeacherMaterialService;
  private readonly sessionService: TeacherSessionService;
  private readonly gradebookService: TeacherGradebookService;
  private readonly assignmentService: TeacherAssignmentService;
  private readonly syllabusService: TeacherSyllabusService;

  constructor(private readonly database: Db) {
    this.classAccess = new TeacherClassAccess(database);
    this.communicationService = new TeacherCommunicationService(database, this.classAccess);
    this.dashboardRepository = new TeacherDashboardRepository(database, this.classAccess);
    this.materialService = new TeacherMaterialService(database, this.classAccess);
    this.sessionService = new TeacherSessionService(database, this.classAccess);
    this.gradebookService = new TeacherGradebookService(database, this.classAccess);
    this.assignmentService = new TeacherAssignmentService(database, this.classAccess);
    this.syllabusService = new TeacherSyllabusService(database, this.classAccess);
  }

  private defaultSyllabusUnits(subjectName: string) {
    return createDefaultSyllabusUnits(subjectName);
  }

  async getBootstrap(userId: string, user: Document, currentSessionId?: string) {
    const {
      classes,
      classCodes,
      enrollments,
      rawSessions,
      rawAssignments,
      rawSubmissions,
      rawGrades,
      rawMaterials,
      rawForumTopics,
      teacherEvents,
      calendarEvents,
      announcements,
      protocols,
      liveSessions,
      activeSessions,
      auditLogs,
      adminSettings,
    } = await this.dashboardRepository.load(userId, user);

    const enrollmentsByClass = new Map<string, Document[]>();
    for (const e of enrollments) {
      const list = enrollmentsByClass.get(e.classCode) ?? [];
      list.push(e);
      enrollmentsByClass.set(e.classCode, list);
    }

    const materialsByClass = new Map<string, Document[]>();
    for (const material of rawMaterials) {
      const list = materialsByClass.get(material.classCode) ?? [];
      list.push(material);
      materialsByClass.set(material.classCode, list);
    }

    const forumByClass = new Map<string, Document[]>();
    for (const topic of rawForumTopics) {
      const list = forumByClass.get(topic.classCode) ?? [];
      list.push(topic);
      forumByClass.set(topic.classCode, list);
    }

    const mappedCourses = mapTeacherCourses({
      classes,
      enrollmentsByClass,
      materialsByClass,
      forumByClass,
      liveSessions,
      adminSettings,
      user,
      defaultSyllabusUnits: (subjectName) => this.defaultSyllabusUnits(subjectName),
    });

    // Calcula faltas acumuladas por aluno em cada turma
    const absencesByClassStudent = new Map<string, number>();
    for (const s of rawSessions) {
      const list = Array.isArray(s.attendanceList) ? s.attendanceList : [];
      const hours = Number(s.hours ?? 2);
      for (const item of list) {
        if (item.status === "ausente") {
          const key = `${s.classCode}:${item.studentId}`;
          absencesByClassStudent.set(key, (absencesByClassStudent.get(key) ?? 0) + hours);
        }
      }
    }

    // 2. Sessions / Diário de Classe (garante ao menos 1 sessão inicial por turma ativa para chamada imediata)
    const mappedSessions: Record<string, unknown>[] = [];
    for (const c of classes) {
      const code = String(c.code);
      const classEnrollments = enrollmentsByClass.get(code) ?? [];
      const totalHours = Number(c.totalHours ?? 80);
      const maxAbsences = Math.round(totalHours * 0.25);
      const classSessions = rawSessions.filter((s) => s.classCode === code);

      if (classSessions.length === 0) {
        const now = new Date();
        const seeded = {
          classCode: code,
          courseCode: c.courseCode,
          sessionNumber: 1,
          hours: 2,
          startsAt: now,
          endsAt: new Date(now.getTime() + 90 * 60 * 1000),
          title: `Aula 01 - ${c.subjectName ?? c.courseName ?? code}`,
          contentProgram: `Apresentação do plano de ensino, critérios de avaliação e introdução a ${c.subjectName ?? c.courseName ?? code}.`,
          methodology: "Aula expositiva dialogada e alinhamento prático.",
          location: String(c.location ?? "Sala Virtual"),
          isHomologated: false,
          attendanceList: classEnrollments.map((e) => ({
            studentId: String(e.studentId),
            ra: String(e.studentIdentity ?? ""),
            name: String(e.displayName ?? e.studentIdentity ?? ""),
            status: "presente",
            accumulatedAbsences: 0,
            maxAbsences,
            attendanceRate: 100,
            riskLevel: "regular",
            isConnected: false,
          })),
          cancelled: false,
          createdAt: now,
          createdBy: userId,
        };
        const inserted = await this.database.collection("academic_class_sessions").insertOne(seeded);
        classSessions.push({ _id: inserted.insertedId, ...seeded });
      }

      classSessions.forEach((s, idx) => {
        const startDate = s.startsAt ? new Date(s.startsAt) : new Date();
        const existingList = Array.isArray(s.attendanceList) ? s.attendanceList : [];
        const byStudent = new Map(existingList.map((a: Document) => [String(a.studentId), a]));

        const mergedAttendance = classEnrollments.map((e) => {
          const sid = String(e.studentId);
          const prev = byStudent.get(sid);
          const excused = Number(e.excusedAbsences ?? 0);
          const rawAbs = Math.max(0, (absencesByClassStudent.get(`${code}:${sid}`) ?? 0) - excused);
          const rate = Number(Math.max(0, ((totalHours - rawAbs) / totalHours) * 100).toFixed(1));
          const riskLevel = rate < 75 ? "critico" : rate < 82 ? "atencao" : "regular";
          return {
            studentId: sid,
            ra: String(e.studentIdentity ?? prev?.ra ?? ""),
            name: String(e.displayName ?? prev?.name ?? e.studentIdentity ?? ""),
            status: String(prev?.status ?? "presente"),
            accumulatedAbsences: rawAbs,
            maxAbsences,
            attendanceRate: rate,
            riskLevel,
            observation: prev?.observation ?? "",
            isConnected: prev?.isConnected === true,
          };
        });

        mappedSessions.push({
          id: String(s._id),
          courseId: code,
          classCode: code,
          sessionNumber: Number(s.sessionNumber ?? idx + 1),
          hours: Number(s.hours ?? 2),
          date: startDate.toISOString(),
          dateFormatted: s.dateFormatted ?? formatPtBrLongDate(startDate),
          contentProgram: String(s.contentProgram ?? s.title ?? ""),
          methodology: String(s.methodology ?? "Aula expositiva dialogada e prática supervisionada."),
          location: String(s.location ?? c.location ?? "Sala Virtual"),
          isHomologated: s.isHomologated === true,
          attendanceList: mergedAttendance,
        });
      });
    }

    const mappedAssignments = mapTeacherAssignments(rawAssignments, rawSubmissions, enrollmentsByClass);
    const mappedGrades = mapTeacherGrades(classes, enrollmentsByClass, rawGrades, absencesByClassStudent);

    const mappedEvents = mapTeacherEvents(teacherEvents, calendarEvents);
    const mappedNotices = mapTeacherNotices(announcements, enrollments, enrollmentsByClass, user);
    const profile = mapTeacherProfile(userId, user, activeSessions, auditLogs, currentSessionId);

    return {
      profile,
      regimentalLockActive: adminSettings?.regimentalLockActive === true,
      courses: mappedCourses,
      sessions: mappedSessions,
      assignments: mappedAssignments,
      grades: mappedGrades,
      events: mappedEvents,
      notices: mappedNotices,
      protocols: mapTeacherProtocols(protocols),
    };
  }

  async createOrSelectSessionByDate(
    userId: string,
    user: Document,
    classCode: string,
    isoDate: string,
    hours = 2,
  ) {
    return this.sessionService.createOrSelectSessionByDate(userId, user, classCode, isoDate, hours);
  }

  async updateSessionAttendance(
    userId: string,
    user: Document,
    sessionId: string,
    payload: SessionAttendanceUpdate,
  ) {
    return this.sessionService.updateSessionAttendance(userId, user, sessionId, payload);
  }

  async advanceSyllabusUnit(userId: string, user: Document, classCode: string, unitId: string) {
    return this.syllabusService.advanceUnit(userId, user, classCode, unitId);
  }

  async publishMaterial(
    userId: string,
    user: Document,
    classCode: string,
    input: {
      title: string;
      fileName?: string;
      size?: string;
      type?: string;
      unitAssociated?: string;
      contentBase64?: string;
    },
  ) {
    return this.materialService.publishMaterial(userId, user, classCode, input);
  }

  async createAssignment(
    userId: string,
    user: Document,
    classCode: string,
    input: {
      title: string;
      description?: string;
      weight: number;
      stage: string;
      dueDate?: string;
      dueDateFormatted: string;
      modality: string;
      allowLateWithPenalty: boolean;
      rubricCriteria: Array<{ id?: string; title: string; maxPoints: number; description?: string }>;
    },
  ) {
    return this.assignmentService.createAssignment(userId, user, classCode, input);
  }

  async evaluateSubmission(
    userId: string,
    user: Document,
    assignmentId: string,
    input: {
      studentId: string;
      calculatedGrade: number;
      feedback: string;
      evaluatedCriteria: Array<{ id: string; title: string; maxPoints: number; assignedScore: number; description?: string }>;
    },
  ) {
    return this.assignmentService.evaluateSubmission(userId, user, assignmentId, input);
  }

  async replyAssignmentDoubt(
    userId: string,
    user: Document,
    assignmentId: string,
    doubtId: string,
    replyText: string,
  ) {
    return this.assignmentService.replyAssignmentDoubt(userId, user, assignmentId, doubtId, replyText);
  }

  async updateStudentGrade(
    userId: string,
    user: Document,
    classCode: string,
    studentId: string,
    scores: {
      assignmentsScore?: number;
      p1Score?: number;
      projectsScore?: number;
      p2Score?: number;
    },
  ) {
    return this.gradebookService.updateStudentGrade(userId, user, classCode, studentId, scores);
  }

  async homologateClassGrades(userId: string, user: Document, classCode: string) {
    return this.gradebookService.homologateClassGrades(userId, user, classCode);
  }

  async requestGradeRectification(
    userId: string,
    user: Document,
    classCode: string,
    input: { studentId: string; stage: string; newScore: number; justification: string },
  ) {
    return this.gradebookService.requestGradeRectification(userId, user, classCode, input);
  }

  async createForumTopic(
    userId: string,
    user: Document,
    classCode: string,
    input: { title: string; body: string; category?: string },
  ) {
    return this.communicationService.createForumTopic(userId, user, classCode, input);
  }

  async replyForumTopic(
    userId: string,
    user: Document,
    classCode: string,
    topicId: string,
    body: string,
  ) {
    return this.communicationService.replyForumTopic(userId, user, classCode, topicId, body);
  }

  async saveClassSquads(
    userId: string,
    user: Document,
    classCode: string,
    squads: Array<{ id?: string; name: string; projectTitle: string; repoUrl?: string; members: string[] }>,
  ) {
    return this.communicationService.saveClassSquads(userId, user, classCode, squads);
  }

  async createEvent(
    userId: string,
    input: { title: string; date: string; time: string; type: string; location: string },
  ) {
    return this.communicationService.createEvent(userId, input);
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
    return this.communicationService.publishNotice(userId, user, input);
  }
}

