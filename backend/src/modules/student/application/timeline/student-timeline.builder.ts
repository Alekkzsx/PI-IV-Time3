import type { Document } from "mongodb";

export type TimelineItemKind = "assignment" | "forum" | "material" | "reminder";

export interface TimelineItem {
  id: string;
  kind: TimelineItemKind;
  title: string;
  subtitle: string;
  completed: boolean;
  trailing: {
    type: "text" | "deadline";
    text: string;
  };
  rawDate: Date;
}

export type TimelineBlock =
  | {
      type: "day";
      label: string;
      items: TimelineItem[];
    }
  | {
      type: "gap";
      label: string;
      mascot: boolean;
      message: string;
    }
  | {
      type: "milestone";
      label: string;
      description: string;
    };

export interface StudentTimelineResponse {
  generatedAt: string;
  blocks: TimelineBlock[];
}

export interface BuildTimelineInput {
  now?: Date;
  assignments: Document[];
  submissions: Document[];
  forumTopics: Document[];
  materials: Document[];
  personalReminders: Document[];
  calendarEvents: Document[];
  classes: Document[];
  studentProgress?: Document[];
  studentId: string;
}

const MONTHS_PT = [
  "janeiro",
  "fevereiro",
  "março",
  "abril",
  "maio",
  "junho",
  "julho",
  "agosto",
  "setembro",
  "outubro",
  "novembro",
  "dezembro",
];

const WEEKDAYS_PT = [
  "Domingo",
  "Segunda-feira",
  "Terça-feira",
  "Quarta-feira",
  "Quinta-feira",
  "Sexta-feira",
  "Sábado",
];

function normalizeDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

export function formatDayHeader(date: Date, now: Date): string {
  const targetDay = normalizeDay(date);
  const nowDay = normalizeDay(now);

  const diffTime = targetDay.getTime() - nowDay.getTime();
  const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

  const dayNum = date.getDate();
  const monthName = MONTHS_PT[date.getMonth()];

  if (diffDays === 0) {
    return `Hoje, ${dayNum} de ${monthName}`;
  }
  if (diffDays === 1) {
    return `Amanhã, ${dayNum} de ${monthName}`;
  }
  if (diffDays === -1) {
    return `Ontem, ${dayNum} de ${monthName}`;
  }

  const weekday = WEEKDAYS_PT[date.getDay()];
  return `${weekday}, ${dayNum} de ${monthName}`;
}

export function formatGapRangeLabel(startDay: Date, endDay: Date): string {
  const nextStart = new Date(startDay.getTime() + 86400000);
  const prevEnd = new Date(endDay.getTime() - 86400000);

  const sMonth = MONTHS_PT[nextStart.getMonth()];
  const eMonth = MONTHS_PT[prevEnd.getMonth()];

  if (nextStart.getMonth() === prevEnd.getMonth()) {
    return `${sMonth} ${nextStart.getDate()} a ${prevEnd.getDate()}`;
  }
  return `${sMonth} ${nextStart.getDate()} a ${eMonth} ${prevEnd.getDate()}`;
}

export function buildStudentTimeline(input: BuildTimelineInput): StudentTimelineResponse {
  const now = input.now ?? new Date();
  const classMap = new Map(input.classes.map((c) => [String(c.code), c]));
  const submissionMap = new Map(
    input.submissions.map((s) => [String(s.assignmentId), s]),
  );

  const progressSet = new Set(
    (input.studentProgress ?? []).map((p) => `${p.refType}:${p.refId}`),
  );

  const rawItems: TimelineItem[] = [];

  // 1. Entregas (Assignments)
  for (const asg of input.assignments) {
    if (asg.isTimelineItem === false || !asg.dueDate) continue;
    const date = new Date(asg.dueDate);
    const id = String(asg._id);
    const sub = submissionMap.get(id);
    const isCompleted = sub?.status === "avaliada" || progressSet.has(`assignment:${id}`);
    const cls = classMap.get(String(asg.classCode));
    const subtitle = asg.customSubtitle ?? (cls
      ? `${cls.subjectName ?? cls.name} • ${cls.professorName ?? "Docente"}`
      : String(asg.classCode));

    let trailingText = "até 23:59";
    let trailingType: "text" | "deadline" = "deadline";

    if (asg.customTrailingText) {
      trailingText = String(asg.customTrailingText);
      trailingType = asg.customTrailingType ?? "text";
    } else if (isCompleted) {
      trailingText = "Concluído";
      trailingType = "text";
    } else if (asg.dueHour) {
      trailingText = `até ${asg.dueHour}`;
    }

    rawItems.push({
      id: `asg-${id}`,
      kind: "assignment",
      title: String(asg.title),
      subtitle,
      completed: isCompleted,
      trailing: {
        type: trailingType,
        text: trailingText,
      },
      rawDate: date,
    });
  }

  // 2. Fóruns (Forum Topics)
  for (const topic of input.forumTopics) {
    if (topic.isTimelineItem === false) continue;
    const date = new Date(topic.createdAt ?? topic.date ?? now);
    const id = String(topic._id);
    const cls = classMap.get(String(topic.classCode));
    const subtitle = topic.customSubtitle ?? (cls
      ? `${cls.subjectName ?? cls.name} • ${cls.professorName ?? "Docente"}`
      : String(topic.classCode));

    const repliesCount = Array.isArray(topic.replies) ? topic.replies.length : 0;
    let trailingText = topic.isClosed ? "Encerrado" : (topic.statusText ?? "Tópico aberto");
    let trailingType: "text" | "deadline" = "text";

    if (topic.customTrailingText) {
      trailingText = String(topic.customTrailingText);
      trailingType = topic.customTrailingType ?? "text";
    } else if (topic.dueHour) {
      trailingText = `até ${topic.dueHour}`;
      trailingType = "deadline";
    } else if (repliesCount > 0) {
      trailingText = `${repliesCount} participações`;
    }

    rawItems.push({
      id: `forum-${id}`,
      kind: "forum",
      title: String(topic.title),
      subtitle,
      completed: false,
      trailing: {
        type: trailingType,
        text: trailingText,
      },
      rawDate: date,
    });
  }

  // 3. Materiais Complementares
  for (const mat of input.materials) {
    if (mat.isTimelineItem !== true) continue;
    const date = new Date(mat.timelineDate ?? mat.createdAt ?? now);
    const id = String(mat._id);
    const cls = classMap.get(String(mat.classCode));
    const subtitle = mat.customSubtitle ?? (cls
      ? `${cls.subjectName ?? cls.name} • ${cls.professorName ?? "Docente"}`
      : String(mat.classCode));

    const isCompleted = mat.completed === true || progressSet.has(`material:${id}`);
    let trailingText = isCompleted ? "Concluído" : "Disponível";
    let trailingType: "text" | "deadline" = "text";

    if (mat.customTrailingText) {
      trailingText = String(mat.customTrailingText);
      trailingType = mat.customTrailingType ?? "text";
    }

    rawItems.push({
      id: `mat-${id}`,
      kind: "material",
      title: String(mat.title),
      subtitle,
      completed: isCompleted,
      trailing: {
        type: trailingType,
        text: trailingText,
      },
      rawDate: date,
    });
  }

  // 4. Lembretes Pessoais
  for (const rem of input.personalReminders) {
    if (!rem.date) continue;
    const date = new Date(rem.date);
    rawItems.push({
      id: `rem-${String(rem._id)}`,
      kind: "reminder",
      title: String(rem.title),
      subtitle: String(rem.location ?? "Lembrete Pessoal"),
      completed: rem.completed === true,
      trailing: {
        type: "text",
        text: String(rem.timeRange ?? "Lembrete"),
      },
      rawDate: date,
    });
  }

  // Ordena todas as atividades cronologicamente
  rawItems.sort((a, b) => a.rawDate.getTime() - b.rawDate.getTime());

  // Agrupa atividades por data normalizada (ano-mes-dia)
  const dayGroups = new Map<string, { date: Date; items: TimelineItem[] }>();
  for (const item of rawItems) {
    const dayKey = `${item.rawDate.getFullYear()}-${String(item.rawDate.getMonth() + 1).padStart(2, "0")}-${String(item.rawDate.getDate()).padStart(2, "0")}`;
    let g = dayGroups.get(dayKey);
    if (!g) {
      g = { date: normalizeDay(item.rawDate), items: [] };
      dayGroups.set(dayKey, g);
    }
    g.items.push(item);
  }

  // Marcos institucionais (academic_calendar)
  const milestoneItems = input.calendarEvents
    .filter((e) => e.type === "closing" || e.type === "institutional" || e.isMilestone === true)
    .map((e) => ({
      date: normalizeDay(new Date(e.startsAt ?? e.date ?? now)),
      label: e.customDateLabel ?? formatDayHeader(new Date(e.startsAt ?? e.date ?? now), now).toLowerCase(),
      description: String(e.description ?? e.title),
    }))
    .sort((a, b) => a.date.getTime() - b.date.getTime());

  const blocks: TimelineBlock[] = [];
  let hasRenderedNicolau = false;

  const sortedDays = Array.from(dayGroups.values()).sort(
    (a, b) => a.date.getTime() - b.date.getTime(),
  );

  for (let i = 0; i < sortedDays.length; i++) {
    const cur = sortedDays[i];
    if (!cur) continue;

    blocks.push({
      type: "day",
      label: formatDayHeader(cur.date, now),
      items: cur.items,
    });

    // Calcula intervalo para o próximo dia com atividade
    const nextGroup = sortedDays[i + 1];
    const nextDate = nextGroup
      ? nextGroup.date
      : milestoneItems.length > 0 && milestoneItems[0]
        ? milestoneItems[0].date
        : null;

    if (nextDate) {
      const gapDays = Math.round(
        (nextDate.getTime() - cur.date.getTime()) / (1000 * 60 * 60 * 24),
      );

      // Regra: se o hiato for >= 45 dias, exibe o Sir Nicolau NO MÁXIMO UMA VEZ
      if (gapDays >= 45 && !hasRenderedNicolau) {
        hasRenderedNicolau = true;
        blocks.push({
          type: "gap",
          label: formatGapRangeLabel(cur.date, nextDate),
          mascot: true,
          message: "Nada planejado ainda",
        });
      }
    }
  }

  // Se não houve atividades, mas há marcos ou período livre
  if (sortedDays.length === 0 && milestoneItems.length > 0 && !hasRenderedNicolau) {
    hasRenderedNicolau = true;
    blocks.push({
      type: "gap",
      label: "Sem atividades recentes",
      mascot: true,
      message: "Nada planejado ainda",
    });
  }

  // Adiciona os marcos institucionais no final
  for (const m of milestoneItems) {
    blocks.push({
      type: "milestone",
      label: m.label,
      description: m.description,
    });
  }

  return {
    generatedAt: now.toISOString(),
    blocks,
  };
}
