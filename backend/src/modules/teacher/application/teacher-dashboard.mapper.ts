// Desenvolvido por Murillo Caravita - RA: 25014012
import type { Document } from "mongodb";
import { sanitizeRoomCode } from "../../video-call/application/video-call-room.service.js";
import { formatShortDate } from "../../../shared/formatting/date-formatters.js";

export function mapTeacherCourses(input: {
  classes: Document[];
  enrollmentsByClass: Map<string, Document[]>;
  materialsByClass: Map<string, Document[]>;
  forumByClass: Map<string, Document[]>;
  liveSessions: Document[];
  adminSettings: Document | null;
  user: Document;
  defaultSyllabusUnits: (subjectName: string) => Document[];
}) {
  const liveByRoom = new Map(input.liveSessions.map((session) => [String(session.roomCode).toUpperCase(), session]));

  return input.classes.map((classroom) => {
    const code = String(classroom.code);
    const roomCode = sanitizeRoomCode(code);
    const classEnrollments = input.enrollmentsByClass.get(code) ?? [];
    const classMaterials = input.materialsByClass.get(code) ?? [];
    const syllabusUnits =
      Array.isArray(classroom.syllabusUnits) && classroom.syllabusUnits.length > 0
        ? classroom.syllabusUnits
        : input.defaultSyllabusUnits(String(classroom.subjectName ?? classroom.courseName ?? code));
    const completedClassesSum = syllabusUnits.reduce(
      (total: number, unit: Document) => total + Number(unit.completedClasses ?? 0),
      0,
    );
    const totalHours = Number(classroom.totalHours ?? 80);
    const completedHours = Number(classroom.completedHours ?? Math.min(totalHours, completedClassesSum * 2));
    const live = liveByRoom.get(roomCode);

    return {
      id: code,
      classId: String(classroom._id),
      code,
      roomCode,
      courseCode: String(classroom.courseCode ?? ""),
      teacherIdentity: String(classroom.professorIdentity ?? input.user.identity ?? ""),
      title: String(classroom.subjectName ?? classroom.courseName ?? code),
      courseName: String(classroom.courseName ?? classroom.subjectName ?? code),
      term: String(classroom.semester ?? "2026/2"),
      shift: String(classroom.shift ?? "Noturno"),
      room: String(classroom.location ?? "Sala Virtual"),
      schedule: String(classroom.schedule ?? "Segundas e Quartas, 19:00 - 20:40"),
      enrolledCount: classEnrollments.length,
      completedHours,
      totalHours,
      formulaRegime: String(classroom.formulaRegime ?? "autonomia_docente"),
      evaluationFormula: String(classroom.evaluationFormula ?? "(N1 × 0.4) + (N2 × 0.6)"),
      gradeLocked: classroom.gradeLocked === true || input.adminSettings?.regimentalLockActive === true,
      classGradeLocked: classroom.gradeLocked === true,
      pautaHomologated: classroom.pautaHomologated === true,
      chancelaCode: classroom.chancelaCode ?? null,
      isLive: Boolean(live),
      syllabus: classroom.syllabus ?? `Estudo aprofundado e prática aplicada de ${classroom.subjectName ?? classroom.courseName ?? code}.`,
      bibliography: Array.isArray(classroom.bibliography) ? classroom.bibliography : [],
      syllabusUnits,
      materials: [
        ...classMaterials.map((material) => ({
          id: String(material._id),
          courseId: code,
          title: String(material.title),
          fileName: String(material.fileName ?? material.title),
          date: material.dateLabel ?? formatShortDate(new Date(material.createdAt ?? Date.now())),
          size: String(material.size ?? "1.0 MB"),
          type: String(material.type ?? "PDF"),
          unitAssociated: String(material.unitAssociated ?? "Unidade 1"),
          downloadUrl: `/api/files/materials/${String(material._id)}`,
        })),
        ...(Array.isArray(classroom.materials) ? classroom.materials : []),
      ],
      squads: Array.isArray(classroom.squads) ? classroom.squads : [],
      forumTopics: (input.forumByClass.get(code) ?? []).map((topic) => ({
        id: String(topic._id),
        classCode: code,
        title: String(topic.title),
        body: String(topic.body ?? ""),
        authorName: String(topic.authorName ?? ""),
        authorRole: String(topic.authorRole ?? "docente"),
        category: String(topic.category ?? "Geral"),
        isResolved: topic.isResolved === true,
        createdAt: topic.createdAt ? new Date(topic.createdAt).toISOString() : new Date().toISOString(),
        replies: Array.isArray(topic.replies) ? topic.replies : [],
      })),
      enrolledStudents: classEnrollments.map((enrollment) => ({
        studentId: String(enrollment.studentId),
        ra: String(enrollment.studentIdentity ?? ""),
        name: String(enrollment.displayName ?? enrollment.studentIdentity ?? ""),
      })),
    };
  });
}

export function mapTeacherEvents(teacherEvents: Document[], calendarEvents: Document[]) {
  return [
    ...teacherEvents.map((event) => ({
      id: String(event._id),
      title: String(event.title),
      date: String(event.date ?? formatShortDate(new Date(event.startsAt ?? Date.now()))),
      time: String(event.time ?? "19:00 - 20:40"),
      type: String(event.type ?? "aula"),
      location: String(event.location ?? "Campus Central"),
      isSynced: true,
    })),
    ...calendarEvents.map((event) => ({
      id: String(event._id),
      title: String(event.title),
      date: formatShortDate(new Date(event.startsAt ?? Date.now())),
      time: "Dia inteiro",
      type: event.type === "deadline" ? "entrega" : "reuniao",
      location: "Calendário Institucional",
      isSynced: true,
    })),
  ];
}

export function mapTeacherNotices(
  announcements: Document[],
  enrollments: Document[],
  enrollmentsByClass: Map<string, Document[]>,
  user: Document,
) {
  return announcements.map((announcement) => {
    const readBy = Array.isArray(announcement.readBy) ? announcement.readBy : [];
    const classEnrollments = announcement.classCode
      ? enrollmentsByClass.get(String(announcement.classCode)) ?? []
      : enrollments;
    const totalRecipients = Number(announcement.totalRecipients ?? Math.max(1, classEnrollments.length));
    return {
      id: String(announcement._id),
      author: String(announcement.authorName ?? announcement.author ?? user.displayName ?? "Secretaria Acadêmica"),
      targetCourse: String(announcement.classCode ?? announcement.targetCourse ?? "Institucional Geral"),
      targetAudience: String(announcement.audience ?? announcement.targetAudience ?? "Todos os Alunos"),
      classification: String(announcement.classification ?? (announcement.isInstitutional ? "secretaria" : "informativo")),
      publishedAt: announcement.publishedAt ?? formatShortDate(new Date(announcement.createdAt ?? Date.now())),
      title: String(announcement.title),
      message: String(announcement.body ?? announcement.message ?? ""),
      readCount: readBy.length,
      readByStudentIds: readBy,
      totalRecipients,
      isFromSecretaria: announcement.isInstitutional === true || announcement.senderRole === "admin",
    };
  });
}

export function mapTeacherProfile(
  userId: string,
  user: Document,
  activeSessions: Document[],
  auditLogs: Document[],
  currentSessionId?: string,
) {
  return {
    id: userId,
    teacherIdentity: String(user.identity),
    fullName: String(user.displayName ?? user.identity),
    socialName: String(user.socialName ?? ""),
    registrationId: String(user.identity),
    department: String(user.department ?? user.departmentOrCourse ?? "Corpo Docente Institucional"),
    semester: String(user.semester ?? "Período Vigente 2026/2"),
    campus: String(user.campus ?? "Campus Central"),
    phone: String(user.phone ?? ""),
    biography: String(user.biography ?? ""),
    status: user.active ? "VÍNCULO ATIVO" : "SUSPENSO",
    academicEmail: String(user.email ?? ""),
    personalEmail: String(user.personalEmail ?? ""),
    twoFactorEnabled: user.twoFactorRequired === true,
    preferences: user.preferences ?? {},
    activeSessions: activeSessions.map((session) => ({
      id: String(session.sessionId),
      device: String(session.userAgent ?? "Navegador / Cliente Institucional"),
      location: "Acesso Autenticado",
      ip: String(session.ipAddress ?? "127.0.0.1"),
      lastActive:
        session.sessionId === currentSessionId
          ? "Sessão Atual (Ativa agora)"
          : formatShortDate(new Date(session.createdAt ?? Date.now())),
      isCurrent: session.sessionId === currentSessionId,
    })),
    loginAudits: auditLogs.map((log) => {
      const date = new Date(log.createdAt ?? Date.now());
      return {
        date: formatShortDate(date),
        time: `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`,
        device: String(log.action ?? "Operação autenticada"),
        location: "Servidor Institucional",
        ip: String(log.ipAddress ?? "127.0.0.1"),
        status: "Registrado",
      };
    }),
  };
}

export function mapTeacherProtocols(protocols: Document[]) {
  return protocols.map((protocol) => ({
    id: String(protocol._id),
    code: String(protocol.code ?? protocol._id),
    studentName: String(protocol.studentName ?? ""),
    studentRa: String(protocol.studentRa ?? ""),
    requestType: String(protocol.requestType ?? ""),
    targetComponent: String(protocol.targetComponent ?? ""),
    status: String(protocol.status ?? "Aguardando Parecer"),
    createdAt: protocol.createdAt ? formatShortDate(new Date(protocol.createdAt)) : "",
  }));
}

export function mapTeacherAssignments(
  assignments: Document[],
  submissions: Document[],
  enrollmentsByClass: Map<string, Document[]>,
) {
  const submissionsByAssignment = new Map<string, Document[]>();
  for (const submission of submissions) {
    const assignmentId = String(submission.assignmentId);
    const list = submissionsByAssignment.get(assignmentId) ?? [];
    list.push(submission);
    submissionsByAssignment.set(assignmentId, list);
  }

  return assignments.map((assignment) => {
    const assignmentId = String(assignment._id);
    const classCode = String(assignment.classCode);
    const classEnrollments = enrollmentsByClass.get(classCode) ?? [];
    const submissionsForAssignment = submissionsByAssignment.get(assignmentId) ?? [];
    const submissionByStudent = new Map(submissionsForAssignment.map((submission) => [String(submission.studentId), submission]));

    const mappedSubmissions = classEnrollments.map((enrollment) => {
      const studentId = String(enrollment.studentId);
      const submission = submissionByStudent.get(studentId);
      if (!submission) {
        return {
          id: `pending-${assignmentId}-${studentId}`,
          studentId,
          ra: String(enrollment.studentIdentity ?? ""),
          studentName: String(enrollment.displayName ?? enrollment.studentIdentity ?? ""),
          status: "pendente",
          submittedAt: null,
          fileName: null,
          fileSize: null,
          gitUrl: null,
          comments: null,
          protocolCode: null,
          finalGrade: null,
          teacherFeedback: null,
          rubricEvaluations: [],
        };
      }
      return {
        id: String(submission._id),
        studentId,
        ra: String(submission.ra ?? enrollment.studentIdentity ?? ""),
        studentName: String(submission.studentName ?? enrollment.displayName ?? ""),
        status: submission.status === "avaliada" ? "avaliada" : "aguardandoCorrecao",
        submittedAt: submission.submittedAt ? new Date(submission.submittedAt).toISOString() : null,
        submittedAtFormatted:
          submission.submittedAtFormatted ??
          (submission.submittedAt ? formatShortDate(new Date(submission.submittedAt)) : ""),
        fileName: submission.fileName ?? null,
        fileSize: submission.fileSize ?? null,
        gitUrl: submission.gitUrl ?? null,
        comments: submission.comments ?? null,
        protocolCode: submission.protocolCode ?? null,
        sha256: submission.sha256 ?? null,
        downloadUrl: `/api/files/submissions/${String(submission._id)}`,
        finalGrade: submission.score !== undefined && submission.score !== null ? Number(submission.score) : null,
        teacherFeedback: submission.feedback ?? null,
        rubricEvaluations: Array.isArray(submission.evaluatedCriteria) ? submission.evaluatedCriteria : [],
      };
    });

    return {
      id: assignmentId,
      courseId: classCode,
      courseCode: classCode,
      title: String(assignment.title),
      description: String(assignment.description ?? ""),
      weight: Number(assignment.weight ?? 3.0),
      stage: String(assignment.stage ?? "N1"),
      maxScore: Number(assignment.maxScore ?? 10.0),
      dueDate: assignment.dueDate ? new Date(assignment.dueDate).toISOString() : null,
      dueDateFormatted: String(
        assignment.dueDateFormatted ??
          (assignment.dueDate ? formatShortDate(new Date(assignment.dueDate)) : "Sem prazo"),
      ),
      isUrgent: assignment.isUrgent === true,
      modality: String(assignment.modality ?? "Individual"),
      allowLateWithPenalty: assignment.allowLateWithPenalty !== false,
      rubricCriteria: Array.isArray(assignment.rubricCriteria) ? assignment.rubricCriteria : [],
      submissions: mappedSubmissions,
      doubts: Array.isArray(assignment.doubts) ? assignment.doubts : [],
    };
  });
}

export function mapTeacherGrades(
  classes: Document[],
  enrollmentsByClass: Map<string, Document[]>,
  grades: Document[],
  absencesByClassStudent: Map<string, number>,
) {
  const gradeByKey = new Map(grades.map((grade) => [`${grade.classCode}:${grade.studentId}`, grade]));
  const mappedGrades: Record<string, unknown>[] = [];
  for (const classroom of classes) {
    const classCode = String(classroom.code);
    const totalHours = Number(classroom.totalHours ?? 80);
    const classEnrollments = enrollmentsByClass.get(classCode) ?? [];
    for (const enrollment of classEnrollments) {
      const studentId = String(enrollment.studentId);
      const existing = gradeByKey.get(`${classCode}:${studentId}`);
      const excused = Number(enrollment.excusedAbsences ?? 0);
      const rawAbsences = Math.max(0, (absencesByClassStudent.get(`${classCode}:${studentId}`) ?? 0) - excused);
      const computedAttendance = Number(Math.max(0, ((totalHours - rawAbsences) / totalHours) * 100).toFixed(1));

      mappedGrades.push({
        id: existing ? String(existing._id) : `${classCode}-${studentId}`,
        courseId: classCode,
        classCode,
        studentId,
        ra: String(enrollment.studentIdentity ?? existing?.ra ?? ""),
        studentName: String(enrollment.displayName ?? existing?.studentName ?? ""),
        assignmentsScore: Number(existing?.assignmentsScore ?? 0),
        p1Score: Number(existing?.p1Score ?? 0),
        projectsScore: Number(existing?.projectsScore ?? 0),
        p2Score: Number(existing?.p2Score ?? 0),
        attendanceRate: existing?.attendanceRate !== undefined ? Number(existing.attendanceRate) : computedAttendance,
        absences: rawAbsences,
      });
    }
  }
  return mappedGrades;
}