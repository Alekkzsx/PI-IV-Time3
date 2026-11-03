// Desenvolvido por: Rafael Henrique dos Santos Inácio
import { createHash } from "node:crypto";
import type { Document } from "mongodb";
import { sanitizeRoomCode } from "../../video-call/application/video-call-room.service.js";
import { formatShortDate } from "../../../shared/formatting/date-formatters.js";

type StudentDisciplineReference = {
  name: string;
  professor: string;
};

export function mapStudentDisciplines(input: {
  classes: Document[];
  enrollments: Document[];
  grades: Document[];
  submissions: Document[];
  classSessions: Document[];
  materials: Document[];
  assignments: Document[];
  liveSessions: Document[];
  studentId: string;
  studentIdentity: unknown;
  professorById: Map<string, Document>;
}) {
  const enrollmentByClass = new Map(input.enrollments.map((enrollment) => [String(enrollment.classCode), enrollment]));
  const gradeByClass = new Map(input.grades.map((grade) => [String(grade.classCode), grade]));
  const liveByRoom = new Map(input.liveSessions.map((session) => [String(session.roomCode).toUpperCase(), session]));
  const materialsByClass = new Map<string, Document[]>();
  for (const material of input.materials) {
    const list = materialsByClass.get(String(material.classCode)) ?? [];
    list.push(material);
    materialsByClass.set(String(material.classCode), list);
  }

  const submittedAssignmentIds = new Set(input.submissions.map((submission) => String(submission.assignmentId)));
  const pendingByClass = new Set<string>();
  for (const assignment of input.assignments) {
    const key = String(assignment._id);
    if (!submittedAssignmentIds.has(key)) pendingByClass.add(String(assignment.classCode));
  }

  return input.classes.map((classroom) => {
    const code = String(classroom.code);
    const roomCode = sanitizeRoomCode(code);
    const enrollment = enrollmentByClass.get(code);
    const grade = gradeByClass.get(code);
    const professor = classroom.professorId ? input.professorById.get(String(classroom.professorId)) : undefined;
    const professorName = String(classroom.professorName ?? professor?.displayName ?? classroom.professorIdentity ?? "Docente a definir");
    const totalHours = Number(classroom.totalHours ?? 80);
    const completedHours = Number(classroom.completedHours ?? 0);
    const maxAbsenceHours = Math.round(totalHours * 0.25);

    const sessionsForClass = input.classSessions.filter((session) => String(session.classCode) === code);
    let rawAbsences = 0;
    for (const session of sessionsForClass) {
      const attendance = Array.isArray(session.attendanceList) ? session.attendanceList : [];
      const entry = attendance.find(
        (item: Document) => String(item.studentId) === String(input.studentId) || item.ra === input.studentIdentity,
      );
      if (entry?.status === "ausente") rawAbsences += Number(session.hours ?? 2);
    }
    const excused = Number(enrollment?.excusedAbsences ?? 0);
    const absences = grade?.absences !== undefined ? Number(grade.absences) : Math.max(0, rawAbsences - excused);
    const attendancePercentage =
      grade?.attendanceRate !== undefined
        ? Number(grade.attendanceRate)
        : Number(Math.max(0, ((totalHours - absences) / totalHours) * 100).toFixed(1));

    const hasGrade = Boolean(grade);
    const assignmentsScore = hasGrade ? Number(grade!.assignmentsScore ?? 0) : null;
    const p1 = hasGrade ? Number(grade!.p1Score ?? 0) : null;
    const projectsScore = hasGrade ? Number(grade!.projectsScore ?? 0) : null;
    const p2 = hasGrade ? Number(grade!.p2Score ?? 0) : null;
    const n1 = hasGrade ? Number((assignmentsScore! * 0.4 + p1! * 0.6).toFixed(1)) : null;
    const n2 = hasGrade ? Number((projectsScore! * 0.4 + p2! * 0.6).toFixed(1)) : null;
    const partialAverage = hasGrade ? Number((n1! * 0.4 + n2! * 0.6).toFixed(1)) : null;

    const scheduleString = String(classroom.schedule ?? "Segundas e Quartas, 19:00 - 20:40");
    const [scheduleDays, scheduleTime] = scheduleString.includes(",")
      ? scheduleString.split(",").map((part) => part.trim())
      : [scheduleString, "19:00 - 20:40"];
    const live = liveByRoom.get(roomCode);
    const classMaterials = materialsByClass.get(code) ?? [];

    return {
      code,
      roomCode,
      fullCode: `${code} - ${classroom.subjectName ?? classroom.courseName ?? code}`,
      name: String(classroom.subjectName ?? classroom.courseName ?? code),
      professor: professorName,
      schedule: scheduleDays ?? scheduleString,
      time: scheduleTime ?? "19:00 - 20:40",
      location: String(classroom.location ?? "Sala Virtual"),
      roomStatus: live ? "Ao Vivo" : "Sala Fechada",
      isLive: Boolean(live),
      progress: totalHours > 0 ? Number(Math.min(1, completedHours / totalHours).toFixed(2)) : 0,
      completedHours,
      totalHours,
      absences,
      maxAbsenceHours,
      attendancePercentage,
      p1,
      trab: assignmentsScore,
      p2,
      n1,
      n2,
      partialAverage,
      evaluationFormula: String(classroom.evaluationFormula ?? "(N1 × 0.4) + (N2 × 0.6)"),
      hasPendingTask: pendingByClass.has(code),
      isLab: String(classroom.location ?? "").toLowerCase().includes("lab"),
      semester: String(classroom.semester ?? "2026/2"),
      syllabusUnits: Array.isArray(classroom.syllabusUnits) ? classroom.syllabusUnits : [],
      squads: Array.isArray(classroom.squads) ? classroom.squads : [],
      materials: [
        ...classMaterials.map((material) => ({
          id: String(material._id),
          courseCode: code,
          title: String(material.title),
          fileName: String(material.fileName ?? material.title),
          date: material.dateLabel ?? formatShortDate(new Date(material.createdAt ?? Date.now())),
          size: String(material.size ?? "1.0 MB"),
          fileType: String(material.type ?? "PDF"),
          unitAssociated: String(material.unitAssociated ?? "Unidade 1"),
          downloadUrl: `/api/files/materials/${String(material._id)}`,
        })),
        ...(Array.isArray(classroom.materials) ? classroom.materials : []),
      ],
    };
  });
}

export function mapStudentDeliveries(
  assignments: Document[],
  classByCode: Map<string, StudentDisciplineReference>,
  submissionByAssignment: Map<string, Document>,
) {
  return assignments.map((assignment) => {
    const assignmentId = String(assignment._id);
    const discipline = classByCode.get(String(assignment.classCode));
    const submission = submissionByAssignment.get(assignmentId);
    const status = !submission
      ? "Pendente"
      : submission.status === "avaliada"
        ? "Avaliada"
        : "Em Análise";
    const dueDate = assignment.dueDate ? new Date(assignment.dueDate) : null;

    return {
      id: assignmentId,
      disciplineCode: String(assignment.classCode),
      disciplineName: discipline?.name ?? String(assignment.classCode),
      professor: discipline?.professor ?? String(assignment.authorName ?? "Docente"),
      title: String(assignment.title),
      description: String(assignment.description ?? ""),
      dueDate: dueDate ? formatShortDate(dueDate) : String(assignment.dueDateFormatted ?? ""),
      dueHour: "23:59",
      dueDateFormatted: String(assignment.dueDateFormatted ?? (dueDate ? formatShortDate(dueDate) : "")),
      weight: Number(assignment.weight ?? 3.0),
      stage: String(assignment.stage ?? "N1"),
      status,
      modality: String(assignment.modality ?? "Individual"),
      allowLate: assignment.allowLateWithPenalty !== false,
      protocol: submission?.protocolCode ?? null,
      submittedAt: submission?.submittedAt ? formatShortDate(new Date(submission.submittedAt)) : null,
      fileName: submission?.fileName ?? null,
      fileSize: submission?.fileSize ?? null,
      gitUrl: submission?.gitUrl ?? null,
      comments: submission?.comments ?? null,
      sha256: submission?.sha256 ?? null,
      score: submission?.score !== undefined && submission?.score !== null ? Number(submission.score) : null,
      feedback: submission?.feedback ?? null,
      evaluatedRubrics: Array.isArray(submission?.evaluatedCriteria)
        ? submission.evaluatedCriteria.map((rubric: Document) => ({
            title: String(rubric.title ?? rubric.criterio ?? ""),
            criterio: String(rubric.title ?? rubric.criterio ?? ""),
            maxPoints: Number(rubric.maxPoints ?? rubric.pontos ?? 0),
            pontos: Number(rubric.maxPoints ?? rubric.pontos ?? 0),
            assignedScore: Number(rubric.assignedScore ?? rubric.nota ?? 0),
            nota: Number(rubric.assignedScore ?? rubric.nota ?? 0),
          }))
        : [],
      doubts: Array.isArray(assignment.doubts) ? assignment.doubts : [],
    };
  });
}

export function mapStudentEvents(
  classSessions: Document[],
  assignments: Document[],
  calendarEvents: Document[],
  personalReminders: Document[],
) {
  return [
    ...classSessions.map((session) => {
      const date = new Date(session.startsAt ?? Date.now());
      return {
        id: `sess-${String(session._id)}`,
        title: String(session.title ?? `Aula ${session.classCode}`),
        date: date.toISOString(),
        timeRange: "19:00 - 20:40",
        category: "aula",
        courseCode: String(session.classCode),
        location: String(session.location ?? "Sala Virtual"),
      };
    }),
    ...assignments
      .filter((assignment) => assignment.dueDate)
      .map((assignment) => ({
        id: `asg-${String(assignment._id)}`,
        title: `Entrega: ${String(assignment.title)}`,
        date: new Date(assignment.dueDate).toISOString(),
        timeRange: "Até 23:59",
        category: "entrega",
        courseCode: String(assignment.classCode),
        location: "Portal AVA",
      })),
    ...calendarEvents.map((event) => ({
      id: `cal-${String(event._id)}`,
      title: String(event.title),
      date: new Date(event.startsAt ?? Date.now()).toISOString(),
      timeRange: "Dia inteiro",
      category: event.type === "deadline" ? "avaliacao" : "institucional",
      courseCode: "INSTITUCIONAL",
      location: "Calendário Acadêmico",
    })),
    ...personalReminders.map((reminder) => ({
      id: String(reminder._id),
      title: String(reminder.title),
      date: new Date(reminder.date ?? Date.now()).toISOString(),
      timeRange: String(reminder.timeRange ?? "Dia inteiro"),
      category: "lembrete",
      courseCode: String(reminder.courseCode ?? "PESSOAL"),
      location: String(reminder.location ?? "Lembrete Pessoal"),
    })),
  ];
}

export function mapStudentHistoricalBoletim(disciplines: Array<{
  code: string;
  semester: string;
  name: string;
  n1: number | null;
  n2: number | null;
  partialAverage: number | null;
  absences: number;
  attendancePercentage: number;
}>) {
  const periods = new Map<string, Record<string, unknown>[]>();
  for (const discipline of disciplines) {
    const period = discipline.semester || "2026/2";
    const items = periods.get(period) ?? [];
    const situation =
      discipline.partialAverage === null
        ? "Em Curso"
        : discipline.attendancePercentage < 75
          ? "Reprovado por Falta"
          : discipline.partialAverage >= 6.0
            ? "Aprovado"
            : "Em Exame / Curso";
    items.push({
      codigo: discipline.code,
      disciplina: discipline.name,
      n1: discipline.n1 !== null ? discipline.n1.toFixed(1) : "-",
      n2: discipline.n2 !== null ? discipline.n2.toFixed(1) : "-",
      media: discipline.partialAverage !== null ? discipline.partialAverage.toFixed(1) : "-",
      faltas: `${discipline.absences}h (${discipline.attendancePercentage.toFixed(0)}%)`,
      situacao: situation,
    });
    periods.set(period, items);
  }
  return Array.from(periods.entries()).map(([period, items]) => ({ period, items }));
}

export function mapStudentMessages(announcements: Document[], studentId: string) {
  return announcements.map((announcement) => {
    const readBy: string[] = Array.isArray(announcement.readBy) ? announcement.readBy.map(String) : [];
    const isInstitutional = announcement.isInstitutional === true || announcement.senderRole === "admin";
    return {
      id: String(announcement._id),
      sender: String(announcement.authorName ?? announcement.author ?? "Secretaria Geral Acadêmica"),
      category: isInstitutional ? "institutional" : "discipline",
      classCode: announcement.classCode ?? null,
      isNew: !readBy.includes(String(studentId)),
      dateLabel: String(announcement.publishedAt ?? formatShortDate(new Date(announcement.createdAt ?? Date.now()))),
      title: String(announcement.title),
      body: String(announcement.body ?? announcement.message ?? ""),
    };
  });
}

export function mapStudentProtocols(protocols: Document[]) {
  return protocols.map((protocol) => ({
    id: String(protocol._id),
    protocolCode: String(protocol.code ?? protocol._id),
    submittedAt: protocol.createdAt ? formatShortDate(new Date(protocol.createdAt)) : "",
    subjectType: String(protocol.requestType ?? ""),
    componentObject: String(protocol.targetComponent ?? "Geral"),
    status:
      protocol.status === "Deferido"
        ? "approved"
        : protocol.status === "Indeferido"
          ? "rejected"
          : "pending",
    statusLabel: String(protocol.status ?? "Aguardando Parecer"),
    officialOpinion: String(protocol.decisionNote ?? "Aguardando análise e despacho da Secretaria Acadêmica."),
    justification: String(protocol.justification ?? ""),
    attachmentName: protocol.attachmentName ? String(protocol.attachmentName) : null,
    approverName: protocol.signedBy ? String(protocol.signedBy) : null,
    responseDate: protocol.decidedAt ? formatShortDate(new Date(protocol.decidedAt)) : null,
  }));
}

export function mapStudentForumTopics(topics: Document[]) {
  return topics.map((topic) => ({
    id: String(topic._id),
    classCode: String(topic.classCode),
    title: String(topic.title),
    body: String(topic.body ?? ""),
    authorName: String(topic.authorName ?? ""),
    authorRole: String(topic.authorRole ?? ""),
    category: String(topic.category ?? "Geral"),
    isResolved: topic.isResolved === true,
    createdAt: topic.createdAt ? formatShortDate(new Date(topic.createdAt)) : "",
    replies: Array.isArray(topic.replies) ? topic.replies : [],
  }));
}

export function mapStudentSessions(sessions: Document[], currentSessionId?: string) {
  return sessions.map((session) => ({
    id: String(session.sessionId),
    device: String(session.userAgent ?? "Navegador / Cliente Institucional"),
    ipAddress: String(session.ipAddress ?? "127.0.0.1"),
    createdAt: session.createdAt,
    current: session.sessionId === currentSessionId,
  }));
}

export function mapStudentSecurityLogs(logs: Document[]) {
  return logs.map((log) => ({
    id: String(log._id),
    action: String(log.action ?? ""),
    createdAt: log.createdAt,
    ipAddress: String(log.ipAddress ?? "127.0.0.1"),
  }));
}

export function mapStudentProfileAndStats(input: {
  studentId: string;
  user: Document;
  courses: Document[];
  classes: Document[];
  disciplines: Array<{
    code: string;
    name: string;
    semester: string;
    completedHours: number;
    totalHours: number;
    partialAverage: number | null;
    attendancePercentage: number;
  }>;
}) {
  const primaryCourse = input.courses[0];
  const courseName = String(
    primaryCourse?.name ??
      input.user.departmentOrCourse ??
      (input.disciplines[0]?.name ? `Curso ${input.disciplines[0].code}` : "Matrícula Institucional"),
  );
  const courseWorkloadNumber = Number.parseInt(String(primaryCourse?.workload ?? "3200").replace(/\D/g, ""), 10) || 3200;
  const completedHoursTotal = input.disciplines.reduce((total, discipline) => total + discipline.completedHours, 0);
  const semesterHoursTotal = input.disciplines.reduce((total, discipline) => total + discipline.totalHours, 0);
  const gradedDisciplines = input.disciplines.filter((discipline) => discipline.partialAverage !== null);
  const crGlobal =
    gradedDisciplines.length > 0
      ? Number(
          (
            gradedDisciplines.reduce((total, discipline) => total + (discipline.partialAverage ?? 0), 0) /
            gradedDisciplines.length
          ).toFixed(2),
        )
      : 0.0;
  const globalFrequency =
    input.disciplines.length > 0
      ? Number(
          (
            input.disciplines.reduce((total, discipline) => total + discipline.attendancePercentage, 0) /
            input.disciplines.length
          ).toFixed(1),
        )
      : 100.0;

  return {
    studentInfo: {
      id: String(input.studentId),
      name: String(input.user.displayName ?? input.user.identity),
      socialName: String(input.user.socialName ?? ""),
      ra: String(input.user.identity),
      email: String(input.user.email ?? ""),
      phone: String(input.user.phone ?? ""),
      courseName,
      semester: String(input.user.semester ?? input.disciplines[0]?.semester ?? "2026/2"),
      shift: String(input.user.shift ?? input.classes[0]?.shift ?? "Noturno"),
      campus: String(input.user.campus ?? "Campus Central"),
      twoFactorRequired: input.user.twoFactorRequired === true,
      preferences: input.user.preferences ?? {},
      verificationKey: `AGMRM-2026-${createHash("sha256").update(String(input.studentId)).digest("hex").slice(0, 12).toUpperCase()}`,
    },
    stats: {
      activeDisciplines: input.disciplines.length,
      averageAttendance: globalFrequency,
      cr: crGlobal,
      completedHoursSemester: completedHoursTotal,
      totalHoursSemester: semesterHoursTotal,
      courseTotalWorkload: courseWorkloadNumber,
      academicStatus: input.disciplines.length > 0 ? "Regular & Apto" : "Sem Matrículas Ativas",
    },
    recordSummary: {
      ra: String(input.user.identity),
      course: `${courseName} (${input.user.semester ?? "2026/2"})`,
      academicIndex: crGlobal > 0 ? crGlobal.toFixed(2) : "—",
      completedWorkload: `${completedHoursTotal}h / ${courseWorkloadNumber}h`,
      activeEnrollmentBadge: input.user.active ? "MATRÍCULA ATIVA" : "INATIVO",
    },
  };
}