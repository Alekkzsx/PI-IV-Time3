// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import assert from "node:assert/strict";
import { describe, it } from "node:test";
import type { Document } from "mongodb";
import {
  mapStudentDeliveries,
  mapStudentHistoricalBoletim,
} from "../../modules/student/application/dashboard/index.js";
import {
  mapTeacherAssignments,
  mapTeacherCourses,
  mapTeacherDashboardOverview,
  mapTeacherGrades,
  mapTeacherProtocols,
} from "../../modules/teacher/application/dashboard/index.js";

const documents = (records: Record<string, unknown>[]) => records as Document[];

describe("dashboard mappers", () => {
  it("preserves pending delivery status and its linked discipline display values", () => {
    const [delivery] = mapStudentDeliveries(
      documents([{ _id: "assignment-1", classCode: "CS101", title: "Projeto" }]),
      new Map([["CS101", { name: "Algoritmos", professor: "Docente" }]]),
      new Map(),
    );

    assert.equal(delivery?.status, "Pendente");
    assert.equal(delivery?.disciplineName, "Algoritmos");
    assert.equal(delivery?.professor, "Docente");
    assert.equal(delivery?.score, null);
  });

  it("keeps the existing academic outcome rules in historical records", () => {
    const [period] = mapStudentHistoricalBoletim([
      {
        code: "CS101",
        semester: "2026/2",
        name: "Algoritmos",
        n1: 8,
        n2: 7,
        partialAverage: 7.6,
        absences: 2,
        attendancePercentage: 90,
      },
    ]);

    assert.equal(period?.period, "2026/2");
    assert.deepEqual(period?.items[0], {
      codigo: "CS101",
      disciplina: "Algoritmos",
      n1: "8.0",
      n2: "7.0",
      media: "7.6",
      faltas: "2h (90%)",
      situacao: "Aprovado",
    });
  });

  it("creates a pending row for each enrolled student in teacher assignments", () => {
    const [assignment] = mapTeacherAssignments(
      documents([{ _id: "assignment-1", classCode: "CS101", title: "Projeto" }]),
      [],
      new Map([["CS101", documents([{ studentId: "student-1", studentIdentity: "RA-1", displayName: "Estudante" }])]]),
    );

    assert.equal(assignment?.submissions.length, 1);
    assert.equal(assignment?.submissions[0]?.status, "pendente");
    assert.equal(assignment?.submissions[0]?.studentId, "student-1");
  });

  it("recalculates attendance while preserving recorded grade values", () => {
    const [grade] = mapTeacherGrades(
      documents([{ code: "CS101", totalHours: 40 }]),
      new Map([["CS101", documents([{ studentId: "student-1", studentIdentity: "RA-1", displayName: "Estudante" }])]]),
      documents([{ _id: "grade-1", classCode: "CS101", studentId: "student-1", p1Score: 8, attendanceRate: 90 }]),
      new Map([["CS101:student-1", 4]]),
    );

    assert.equal(grade?.id, "grade-1");
    assert.equal(grade?.p1Score, 8);
    assert.equal(grade?.attendanceRate, 90);
    assert.equal(grade?.absences, 4);
  });

  it("maps teacher protocols with normalized status, description, and requestType", () => {
    const [deferido, pendente] = mapTeacherProtocols(
      documents([
        {
          _id: "p1",
          code: "PROT - 2026/0541",
          studentName: "Camila Duarte Fagundes",
          studentRa: "2024.1.00982",
          requestType: "Atestado Médico",
          targetComponent: "218131 - APS-II",
          description: "APS-II e BD-II (Afastamento 29 a 30/09)",
          status: "deferido",
        },
        {
          _id: "p2",
          code: "PROT - 2026/0850",
          studentName: "Rodrigo Antunes Nogueira",
          studentRa: "2024.1.00938",
          requestType: "Segunda Chamada",
          targetComponent: "218131 - APS-II",
          justification: "APS-II - Prova Substitutiva",
          status: "pendente",
        },
      ]),
    );

    assert.equal(deferido?.status, "deferido");
    assert.equal(deferido?.statusLabel, "DEFERIDO");
    assert.equal(deferido?.description, "APS-II e BD-II (Afastamento 29 a 30/09)");
    assert.equal(pendente?.status, "pendente");
    assert.equal(pendente?.statusLabel, "PENDENTE");
    assert.equal(pendente?.description, "APS-II - Prova Substitutiva");
  });

  it("computes teacher dashboard overview KPIs, today class, deadlines, and notices in backend", () => {
    const overview = mapTeacherDashboardOverview({
      user: {
        displayName: "Profa. Dra. Helena Bittencourt",
        greetingPrefix: "Bem-vinda,",
        department: "Departamento de Computação",
        semester: "Docência 2026/2",
        officeHours: {
          title: "Atendimento Docente",
          subtitle: "Plantão de dúvidas e orientação às 17:30",
          location: "Lab 04 • Sala Virtual Teams",
        },
      } as unknown as Document,
      courses: [
        {
          id: "218131 - APS-II",
          code: "218131 - APS-II",
          roomCode: "218131-APS-II",
          title: "Análise e Projeto de Sistemas II",
          schedule: "Segundas e Quartas, 19:10 - 20:50",
          room: "Lab 04",
          virtualRoomLabel: "Sala Virtual Teams",
          enrolledCount: 34,
          connectedStudentsCount: 43,
          completedHours: 54,
          totalHours: 80,
          isLive: true,
        },
        {
          id: "218131 - BD-II",
          code: "218131 - BD-II",
          roomCode: "218131-BD-II",
          title: "Estudos de Banco de Dados II",
          schedule: "Terças e Quintas, 19:10 - 20:50",
          room: "Lab 02",
          enrolledCount: 31,
          completedHours: 60,
          totalHours: 80,
          isLive: false,
        },
        {
          id: "218131 - FSO",
          code: "218131 - FSO",
          roomCode: "218131-FSO",
          title: "Fundamentos de Sistemas Operacionais",
          schedule: "Sextas, 19:10 - 20:50",
          room: "Lab 01",
          enrolledCount: 36,
          completedHours: 44,
          totalHours: 80,
          isLive: false,
        },
      ],
      sessions: [
        {
          attendanceList: [
            { attendanceRate: 94.8 },
            { attendanceRate: 94.8 },
          ],
        },
      ],
      assignments: [
        {
          id: "asg-1",
          courseId: "218131 - APS-II",
          typeLabel: "Entrega",
          title: "Diagrama de Classes e Sequência",
          dueDateFormatted: "Hoje, 20/09",
          dueHour: "23:59",
          isUrgent: true,
        },
      ],
      notices: [
        {
          id: "n-1",
          author: "Profa. Dra. Helena Bittencourt",
          targetCourse: "218131 - APS-II",
          publishedAt: "Hoje, 14:10",
          title: "Feedback da Sprint 1 e Orientações para o Diagrama UML",
          message: "Prezados alunos...",
          isFromSecretaria: false,
        },
      ],
      now: new Date(2026, 8, 20, 14, 10, 0),
    });

    assert.equal(overview.hero.greetingPrefix, "Bem-vinda,");
    assert.equal(overview.hero.firstName, "Helena");
    assert.equal(overview.stats.activeClasses.valueFormatted, "03");
    assert.equal(overview.stats.activeClasses.footerValue, "101 alunos");
    assert.equal(overview.stats.workload.valueFormatted, "158h");
    assert.equal(overview.stats.workload.unitLabel, "/ 240h");
    assert.equal(overview.stats.workload.footerValue, "65.8%");
    assert.equal(overview.stats.averageAttendance.valueFormatted, "94.8%");
    assert.equal(overview.todayClass.todayBadge, "HOJE, 20 SET");
    assert.equal(overview.todayClass.session?.title, "Análise e Projeto de Sistemas II");
    assert.equal(overview.todayClass.session?.connectedLabel, "43 alunos conectados no AVA");
    assert.equal(overview.upcomingDeadlines.items[0]?.displayTitle, "Entrega: Diagrama de Classes e Sequência");
    assert.equal(overview.recentNotices[0]?.authorLabel, "Você (Helena Bittencourt - APS-II)");
  });

  it("computes teacher course card progress and formatted workload/enrollment labels in backend", () => {
    const [course] = mapTeacherCourses({
      classes: documents([
        {
          _id: "c1",
          code: "218131 - APS-II",
          subjectName: "Análise e Projeto de Sistemas II",
          semester: "2026/2 - 4º Semestre",
          shift: "Noturno",
          location: "Lab Informática 04 - Bloco C",
          schedule: "Segundas e Quartas, 19:10 - 20:50",
          completedHours: 54,
          totalHours: 80,
          enrolledCount: 34,
        },
      ]),
      enrollmentsByClass: new Map(),
      materialsByClass: new Map(),
      forumByClass: new Map(),
      liveSessions: [],
      adminSettings: null,
      user: { identity: "DOC-88410" } as unknown as Document,
      defaultSyllabusUnits: () => [],
    });

    assert.equal(course?.code, "218131 - APS-II");
    assert.equal(course?.enrolledCount, 34);
    assert.equal(course?.enrolledStudentsLabel, "34 discentes matriculados");
    assert.equal(course?.completedHours, 54);
    assert.equal(course?.totalHours, 80);
    assert.equal(course?.progress, 0.675);
    assert.equal(course?.progressPercentage, 68);
    assert.equal(course?.progressPercentageFormatted, "68%");
    assert.equal(course?.workloadCompletedLabel, "54h");
    assert.equal(course?.workloadTotalLabel, " de 80h");
    assert.equal(
      course?.progressCaption,
      "Este percentual reflete diretamente o progresso visto pelos discentes.",
    );
  });

  it("exposes planned rubricCriteria, maxScore, and deduplicated dueDate in student deliveries", () => {
    const [pending, graded] = mapStudentDeliveries(
      documents([
        {
          _id: "a1",
          classCode: "IHC-305",
          title: "Protótipo Figma",
          dueDateFormatted: "25/11/2026 às 19:30",
          maxScore: 10.0,
          rubricCriteria: [
            { id: "r1", title: "Usabilidade", maxPoints: 5, description: "Heurísticas" },
            { id: "r2", title: "Fluxo", maxPoints: 5, description: "Clareza" },
          ],
        },
        {
          _id: "a2",
          classCode: "IHC-305",
          title: "Avaliação Heurística",
          dueDateFormatted: "30/11/2026",
          dueHour: "22:00",
          maxScore: 10.0,
          rubricCriteria: [{ id: "r1", title: "Critério", maxPoints: 10 }],
        },
      ]),
      new Map([["IHC-305", { name: "IHC", professor: "Prof. Ricardo" }]]),
      new Map([
        [
          "a2",
          {
            _id: "s2",
            assignmentId: "a2",
            status: "avaliada",
            score: 9.0,
            feedback: "Muito bom",
            evaluatedCriteria: [{ id: "r1", title: "Critério", maxPoints: 10, assignedScore: 9 }],
          } as unknown as Document,
        ],
      ]),
    );

    assert.equal(pending?.dueDate, "25/11/2026");
    assert.equal(pending?.dueHour, "19:30");
    assert.equal(pending?.maxScore, 10);
    assert.equal(pending?.rubrics.length, 2);
    assert.equal(pending?.rubrics[0]?.title, "Usabilidade");
    assert.equal(pending?.rubrics[0]?.assignedScore, null);

    assert.equal(graded?.dueDate, "30/11/2026");
    assert.equal(graded?.dueHour, "22:00");
    assert.equal(graded?.rubrics.length, 1);
    assert.equal(graded?.rubrics[0]?.nota, 9);
    assert.equal(graded?.evaluatedRubrics.length, 1);
  });

  it("distinguishes attendance-only gradebook records from actual entered grades", () => {
    const [attendanceOnly, explicitZero] = mapTeacherGrades(
      documents([
        { code: "IHC-305", totalHours: 80 },
      ]),
      new Map([
        [
          "IHC-305",
          documents([
            { studentId: "st-1", studentIdentity: "RA-1", displayName: "Aluno Sem Nota" },
            { studentId: "st-2", studentIdentity: "RA-2", displayName: "Aluno Nota Zero" },
          ]),
        ],
      ]),
      documents([
        { _id: "g1", classCode: "IHC-305", studentId: "st-1", assignmentsScore: 0, p1Score: 0, projectsScore: 0, p2Score: 0, attendanceRate: 95 },
        { _id: "g2", classCode: "IHC-305", studentId: "st-2", assignmentsScore: 0, p1Score: 0, projectsScore: 0, p2Score: 0, attendanceRate: 100, hasEnteredGrades: true },
      ]),
      new Map(),
    );

    assert.equal(attendanceOnly?.hasGrades, false);
    assert.equal(explicitZero?.hasGrades, true);
  });
});