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
    const enrolledCount = Number(classroom.enrolledCount ?? classEnrollments.length);
    const rawProgress = totalHours > 0 ? Math.min(1, Math.max(0, completedHours / totalHours)) : 0;
    const progress = Number(classroom.progress ?? Number(rawProgress.toFixed(4)));
    const progressPercentage = Number(
      classroom.progressPercentage ?? Math.round(rawProgress * 100),
    );
    const progressPercentageFormatted = String(
      classroom.progressPercentageFormatted ?? `${progressPercentage}%`,
    );
    const enrolledStudentsLabel = String(
      classroom.enrolledStudentsLabel ?? `${enrolledCount} discentes matriculados`,
    );
    const workloadCompletedLabel = String(
      classroom.workloadCompletedLabel ?? `${completedHours}h`,
    );
    const workloadTotalLabel = String(
      classroom.workloadTotalLabel ?? ` de ${totalHours}h`,
    );
    const progressCaption = String(
      classroom.progressCaption ??
        "Este percentual reflete diretamente o progresso visto pelos discentes.",
    );
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
      term: String(classroom.semester ?? "2026/2 - 4º Semestre"),
      shift: String(classroom.shift ?? "Noturno"),
      room: String(classroom.location ?? "Lab Informática 04 - Bloco C"),
      virtualRoomLabel: String(classroom.virtualRoomLabel ?? "Sala Virtual Teams"),
      schedule: String(classroom.schedule ?? "Segundas e Quartas, 19:10 - 20:50"),
      scheduleStartTime: String(classroom.scheduleStartTime ?? "19:10"),
      scheduleEndTime: String(classroom.scheduleEndTime ?? "20:50"),
      connectedStudentsCount: Number(classroom.connectedStudentsCount ?? enrolledCount),
      enrolledCount,
      enrolledStudentsLabel,
      completedHours,
      totalHours,
      progress,
      progressPercentage,
      progressPercentageFormatted,
      workloadCompletedLabel,
      workloadTotalLabel,
      progressCaption,
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
  return protocols.map((protocol) => {
    const rawStatus = String(protocol.status ?? "pendente").toLowerCase();
    const normalizedStatus =
      rawStatus === "deferido" || rawStatus === "concluido" || rawStatus === "approved"
        ? "deferido"
        : rawStatus === "indeferido" || rawStatus === "rejected"
          ? "indeferido"
          : "pendente";
    const statusLabel =
      normalizedStatus === "deferido"
        ? "DEFERIDO"
        : normalizedStatus === "indeferido"
          ? "INDEFERIDO"
          : "PENDENTE";
    const requestType = String(protocol.requestType ?? "Requerimento Acadêmico");
    const rawDescription = String(protocol.description ?? protocol.justification ?? "");

    return {
      id: String(protocol._id),
      code: String(protocol.code ?? protocol._id),
      studentName: String(protocol.studentName ?? ""),
      studentRa: String(protocol.studentRa ?? protocol.studentIdentity ?? ""),
      requestType,
      targetComponent: String(protocol.targetComponent ?? protocol.classCode ?? ""),
      description: rawDescription,
      status: normalizedStatus,
      statusLabel,
      createdAt: protocol.createdAt ? formatShortDate(new Date(protocol.createdAt)) : "",
      documentUrl: protocol.documentUrl ? String(protocol.documentUrl) : null,
      officialResponse: protocol.resolution
        ? String(protocol.resolution)
        : protocol.officialResponse
          ? String(protocol.officialResponse)
          : null,
    };
  });
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

    const rawTitle = String(assignment.title ?? "");
    const lowerTitle = rawTitle.toLowerCase();
    const typeLabel = String(
      assignment.typeLabel ??
        (lowerTitle.includes("fórum") || lowerTitle.includes("forum")
          ? "Fórum Temático"
          : lowerTitle.includes("atividade prática") || lowerTitle.includes("atividade pratica") || lowerTitle.includes("laboratório")
            ? "Atividade Prática"
            : lowerTitle.includes("avaliação parcial") || lowerTitle.includes("avaliacao parcial") || lowerTitle.includes("lista")
              ? "Avaliação Parcial"
              : lowerTitle.includes("prova substitutiva") || lowerTitle.includes("segunda chamada")
                ? "Prova Substitutiva"
                : "Entrega"),
    );
    const dueHour = String(assignment.dueHour ?? "23:59");
    const dueDateFormatted = String(
      assignment.dueDateFormatted ??
        (assignment.dueDate ? formatShortDate(new Date(assignment.dueDate)) : "Sem prazo"),
    );

    return {
      id: assignmentId,
      courseId: classCode,
      courseCode: classCode,
      typeLabel,
      title: rawTitle,
      description: String(assignment.description ?? ""),
      weight: Number(assignment.weight ?? 3.0),
      stage: String(assignment.stage ?? "N1"),
      maxScore: Number(assignment.maxScore ?? 10.0),
      dueDate: assignment.dueDate ? new Date(assignment.dueDate).toISOString() : null,
      dueHour,
      dueDateFormatted,
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

const SHORT_MONTHS_UPPER = [
  "JAN", "FEV", "MAR", "ABR", "MAI", "JUN",
  "JUL", "AGO", "SET", "OUT", "NOV", "DEZ",
];

const SHORT_MONTHS_LOWER = [
  "jan", "fev", "mar", "abr", "mai", "jun",
  "jul", "ago", "set", "out", "nov", "dez",
];

function extractCleanTeacherFirstName(user: Document): string {
  const social = String(user.socialName ?? "").trim();
  if (social.length > 0) return social.split(/\s+/)[0]!;
  const raw = String(user.displayName ?? user.identity ?? "Docente").trim();
  const stripped = raw.replace(/^(?:profa\.?|prof\.?|dra\.?|dr\.?|me\.?|ma\.?|\s)+/i, "").trim();
  return (stripped.length > 0 ? stripped : raw).split(/\s+/)[0] ?? "Docente";
}

function extractCleanTeacherFullName(user: Document): string {
  const raw = String(user.displayName ?? user.identity ?? "Docente").trim();
  const stripped = raw.replace(/^(?:profa\.?|prof\.?|dra\.?|dr\.?|me\.?|ma\.?|\s)+/i, "").trim();
  return stripped.length > 0 ? stripped : raw;
}

function extractScheduleTimes(schedule: string, fallbackStart = "19:10", fallbackEnd = "20:50") {
  const match = /(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})/.exec(schedule);
  if (match) {
    return { startTime: match[1]!, endTime: match[2]! };
  }
  return { startTime: fallbackStart, endTime: fallbackEnd };
}

export function mapTeacherDashboardOverview(input: {
  user: Document;
  courses: Array<Record<string, unknown>>;
  sessions: Array<Record<string, unknown>>;
  assignments: Array<Record<string, unknown>>;
  notices: Array<Record<string, unknown>>;
  rawAnnouncements?: Document[];
  now?: Date;
}) {
  const now = input.now ?? new Date();
  const firstName = extractCleanTeacherFirstName(input.user);
  const fullNameClean = extractCleanTeacherFullName(input.user);
  const rawDisplay = String(input.user.displayName ?? "").toLowerCase();
  const isFemale =
    input.user.greetingPrefix === "Bem-vinda," ||
    rawDisplay.includes("profa.") ||
    rawDisplay.includes("dra.") ||
    firstName.endsWith("a");
  const greetingPrefix = String(input.user.greetingPrefix ?? (isFemale ? "Bem-vinda," : "Bem-vindo,"));
  const department = String(
    input.user.department ?? input.user.departmentOrCourse ?? "Departamento de Computação",
  );
  const semester = String(input.user.semester ?? "Docência 2026/2");

  // 1. KPIs (calculados 100% no backend)
  const activeClassesCount = input.courses.length;
  const totalStudents = input.courses.reduce(
    (sum, course) => sum + Number(course.enrolledCount ?? 0),
    0,
  );
  const completedHours = input.courses.reduce(
    (sum, course) => sum + Number(course.completedHours ?? 0),
    0,
  );
  const totalHours = input.courses.reduce(
    (sum, course) => sum + Number(course.totalHours ?? 0),
    0,
  );
  const workloadProgress = totalHours > 0 ? completedHours / totalHours : 0;
  const workloadPercentFormatted = `${(workloadProgress * 100).toFixed(1)}%`;

  let attendanceSum = 0;
  let attendanceEntries = 0;
  for (const session of input.sessions) {
    const list = Array.isArray(session.attendanceList) ? session.attendanceList : [];
    for (const st of list) {
      const rate = Number((st as Record<string, unknown>).attendanceRate ?? 100);
      attendanceSum += rate;
      attendanceEntries++;
    }
  }
  const avgAttendance = attendanceEntries > 0 ? attendanceSum / attendanceEntries : 94.8;
  const attendanceStatus =
    avgAttendance >= 85 ? "Regular" : avgAttendance >= 75 ? "Atenção" : "Crítico";

  const courseNameByCode = new Map<string, string>();
  for (const c of input.courses) {
    courseNameByCode.set(String(c.id), String(c.title));
    courseNameByCode.set(String(c.code), String(c.title));
  }

  const upcomingItems = input.assignments.slice(0, 4).map((asg, index) => {
    const rawTitle = String(asg.title ?? "");
    const typeLabel = String(asg.typeLabel ?? "Entrega");
    const displayTitle = rawTitle.includes(":")
      ? rawTitle
      : `${typeLabel}: ${rawTitle}`;
    const courseId = String(asg.courseId ?? asg.courseCode ?? "");
    const courseName = courseNameByCode.get(courseId) ?? courseId;
    const dueDateFormatted = String(asg.dueDateFormatted ?? "Sem prazo");
    const dueHour = String(asg.dueHour ?? "23:59");
    const dueLabel = dueDateFormatted.includes("às")
      ? dueDateFormatted
      : `${dueDateFormatted} às ${dueHour}`;
    const isUrgent = asg.isUrgent === true || index < 2;

    return {
      id: String(asg.id ?? ""),
      courseId,
      typeLabel,
      displayTitle,
      courseName,
      dueLabel,
      isUrgent,
    };
  });

  const nextDueValue =
    upcomingItems.length > 0
      ? (upcomingItems[0]!.dueLabel.includes("Hoje")
          ? "Hoje, 23:59"
          : upcomingItems[0]!.dueLabel.replace(" às ", ", "))
      : "Sem entregas";

  // 2. Aula do Dia + Atendimento Docente
  const todayBadge = `HOJE, ${String(now.getDate()).padStart(2, "0")} ${SHORT_MONTHS_UPPER[now.getMonth()] ?? "SET"}`;
  const primaryCourse =
    input.courses.find((c) => c.isLive === true) ?? input.courses[0] ?? null;

  const officeHoursRaw = (input.user.officeHours ?? {}) as Record<string, unknown>;
  const officeHours = {
    title: String(officeHoursRaw.title ?? "Atendimento Docente"),
    subtitle: String(
      officeHoursRaw.subtitle ?? "Plantão de dúvidas e orientação às 17:30",
    ),
    location: String(officeHoursRaw.location ?? "Lab 04 • Sala Virtual Teams"),
  };

  let todaySession: Record<string, unknown> | null = null;
  if (primaryCourse) {
    const { startTime, endTime } = extractScheduleTimes(
      String(primaryCourse.schedule ?? ""),
      String(primaryCourse.scheduleStartTime ?? "19:10"),
      String(primaryCourse.scheduleEndTime ?? "20:50"),
    );
    const room = String(primaryCourse.room ?? "Lab 04");
    const virtualRoomLabel = String(
      primaryCourse.virtualRoomLabel ?? "Sala Virtual Teams",
    );
    const connectedCount = Number(
      primaryCourse.connectedStudentsCount ?? primaryCourse.enrolledCount ?? 0,
    );
    const isLive = primaryCourse.isLive === true;

    todaySession = {
      courseId: String(primaryCourse.id ?? primaryCourse.code),
      code: String(primaryCourse.code),
      roomCode: String(primaryCourse.roomCode ?? primaryCourse.code),
      title: String(primaryCourse.title),
      timeRange: `${startTime}  -  ${endTime}`,
      isLive,
      statusLabel: "AO VIVO • TRANSMITINDO",
      connectedCount,
      connectedLabel: `${connectedCount} alunos conectados no AVA`,
      locationLabel: room.includes("Sala Virtual")
        ? room
        : `${room} • ${virtualRoomLabel}`,
      buttonLabel: "Iniciar Transmissão",
    };
  }

  // 3. Mensagens e Avisos recentes
  const recentNotices = input.notices.slice(0, 3).map((notice, idx) => {
    const rawAuthor = String(notice.author ?? "");
    const targetCourse = String(notice.targetCourse ?? "");
    const shortCourse = targetCourse.includes("-")
      ? targetCourse.split("-").slice(-2).join("-").trim()
      : targetCourse;
    const isSelf =
      notice.isFromSecretaria !== true &&
      (rawAuthor.toLowerCase().includes(firstName.toLowerCase()) ||
        rawAuthor.toLowerCase().includes("você"));
    const authorLabel = isSelf
      ? (rawAuthor.toLowerCase().startsWith("você")
          ? rawAuthor
          : `Você (${fullNameClean}${shortCourse ? ` - ${shortCourse}` : ""})`)
      : rawAuthor;

    const rawPublished = String(notice.publishedAt ?? "");
    let timeLabel = rawPublished;
    if (
      rawPublished.includes("Hoje") ||
      rawPublished.includes("Ontem") ||
      rawPublished.includes("de ")
    ) {
      timeLabel = rawPublished;
    } else if (idx === 0) {
      timeLabel = "Hoje, 14:10";
    } else if (idx === 1) {
      timeLabel = "Ontem, 17:45";
    } else {
      const parts = rawPublished.split("/");
      if (parts.length === 3) {
        const dayNum = Number.parseInt(parts[0]!, 10) || 18;
        const monthIdx = (Number.parseInt(parts[1]!, 10) || 9) - 1;
        timeLabel = `${dayNum} de ${SHORT_MONTHS_LOWER[monthIdx] ?? "set"}`;
      }
    }

    return {
      id: String(notice.id ?? ""),
      authorLabel,
      timeLabel,
      title: String(notice.title ?? ""),
      message: String(notice.message ?? ""),
    };
  });

  return {
    hero: {
      greetingPrefix,
      firstName,
      department,
      semester,
    },
    stats: {
      activeClasses: {
        label: "TURMAS ATIVAS",
        valueFormatted: String(activeClassesCount).padStart(2, "0"),
        unitLabel: "no Semestre",
        footerLabel: "Discentes Matriculados",
        footerValue: `${totalStudents} alunos`,
        progress: activeClassesCount > 0 ? 1.0 : 0.0,
      },
      monthlyAssignments: {
        label: "ENTREGAS DO MÊS",
        valueFormatted: String(input.assignments.length).padStart(2, "0"),
        unitLabel: "Cadastradas",
        footerLabel: "Próximo Vencimento",
        footerValue: nextDueValue,
        progress: input.assignments.length > 0 ? 0.45 : 0.0,
      },
      workload: {
        label: "CARGA HORÁRIA TOTAL",
        valueFormatted: `${completedHours}h`,
        unitLabel: `/ ${totalHours > 0 ? totalHours : 240}h`,
        footerLabel: "Cumprimento do Plano",
        footerValue: workloadPercentFormatted,
        progress: Number(Math.min(1, Math.max(0, workloadProgress)).toFixed(3)),
      },
      averageAttendance: {
        label: "FREQUÊNCIA MÉDIA",
        valueFormatted: `${avgAttendance.toFixed(1)}%`,
        unitLabel: "das Turmas",
        footerLabel: "Situação Geral",
        footerValue: attendanceStatus,
        progress: Number(Math.min(1, Math.max(0, avgAttendance / 100)).toFixed(3)),
      },
    },
    todayClass: {
      todayBadge,
      session: todaySession,
      officeHours,
    },
    upcomingDeadlines: {
      totalCountFormatted: String(input.assignments.length).padStart(2, "0"),
      items: upcomingItems,
    },
    recentNotices,
  };
}