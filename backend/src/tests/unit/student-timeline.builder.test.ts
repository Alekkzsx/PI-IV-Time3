import test from "node:test";
import assert from "node:assert/strict";
import {
  buildStudentTimeline,
  formatDayHeader,
  formatGapRangeLabel,
} from "../../modules/student/application/timeline/student-timeline.builder.js";

test("Timeline Builder: formata cabeçalhos relativos Hoje, Amanhã, Ontem e dia da semana", () => {
  const base = new Date(2026, 8, 20); // 20 de setembro de 2026 (domingo)

  const hoje = new Date(2026, 8, 20);
  assert.equal(formatDayHeader(hoje, base), "Hoje, 20 de setembro");

  const amanha = new Date(2026, 8, 21);
  assert.equal(formatDayHeader(amanha, base), "Amanhã, 21 de setembro");

  const ontem = new Date(2026, 8, 19);
  assert.equal(formatDayHeader(ontem, base), "Ontem, 19 de setembro");

  const quinta = new Date(2026, 8, 17);
  assert.equal(formatDayHeader(quinta, base), "Quinta-feira, 17 de setembro");
});

test("Timeline Builder: calcula e formata texto do intervalo de hiato", () => {
  const d1 = new Date(2026, 8, 21); // 21 de setembro
  const d2 = new Date(2026, 11, 13); // 13 de dezembro

  const label = formatGapRangeLabel(d1, d2);
  assert.equal(label, "setembro 22 a dezembro 12");
});

test("Timeline Builder: Sir Nicolau aparece no máximo 1 vez se houver hiato >= 45 dias", () => {
  const now = new Date(2026, 8, 20);

  const res = buildStudentTimeline({
    now,
    studentId: "student-1",
    classes: [
      { code: "BD2", subjectName: "Banco de Dados II", professorName: "Profª Dra. Eliane Ramos" },
      { code: "PI4", subjectName: "Engenharia de Software", professorName: "Prof. Ricardo" },
    ],
    assignments: [
      {
        _id: "asg-1",
        classCode: "BD2",
        title: "Atividade 2 - Modelagem de Banco de Dados Relacional",
        dueDate: new Date(2026, 8, 17),
      },
      {
        _id: "asg-2",
        classCode: "PI4",
        title: "Atividade Prática 03: Implementação de API REST",
        dueDate: new Date(2026, 8, 20),
        dueHour: "23:59",
      },
    ],
    submissions: [
      { assignmentId: "asg-1", studentId: "student-1", status: "avaliada" },
    ],
    forumTopics: [
      {
        _id: "forum-1",
        classCode: "BD2",
        title: "Fórum Avaliativo: Impactos éticos da IA",
        createdAt: new Date(2026, 8, 18),
        replies: [{}, {}, {}],
      },
      {
        _id: "forum-2",
        classCode: "PI4",
        title: "Fórum de Dúvidas: Preparação A1",
        createdAt: new Date(2026, 8, 21),
        dueHour: "18:00",
      },
    ],
    materials: [
      {
        _id: "mat-1",
        classCode: "PI4",
        title: "Material Complementar: Estudo de Caso",
        isTimelineItem: true,
        timelineDate: new Date(2026, 8, 19),
        completed: true,
      },
    ],
    personalReminders: [],
    calendarEvents: [
      {
        _id: "cal-1",
        type: "closing",
        startsAt: new Date(2026, 11, 13),
        customDateLabel: "domingo, 13 de dezembro",
        description: "Término das avaliações semestrais",
      },
      {
        _id: "cal-2",
        type: "closing",
        startsAt: new Date(2026, 11, 14),
        customDateLabel: "segunda-feira, 14 de dezembro a janeiro 10",
        description: "Férias e encerramento de notas",
      },
      {
        _id: "cal-3",
        type: "institutional",
        startsAt: new Date(2027, 1, 1),
        customDateLabel: "fevereiro 2027",
        description: "Início das aulas do próximo período letivo",
      },
    ],
  });

  const gapBlocks = res.blocks.filter((b) => b.type === "gap");
  assert.equal(gapBlocks.length, 1, "Deve conter exatamente 1 bloco de hiato com Sir Nicolau");
  const gap = gapBlocks[0];
  assert.ok(gap && gap.type === "gap");
  assert.equal(gap.mascot, true);
  assert.equal(gap.label, "setembro 22 a dezembro 12");
  assert.equal(gap.message, "Nada planejado ainda");

  const milestoneBlocks = res.blocks.filter((b) => b.type === "milestone");
  assert.equal(milestoneBlocks.length, 3, "Deve conter 3 marcos institucionais ao final");
});
