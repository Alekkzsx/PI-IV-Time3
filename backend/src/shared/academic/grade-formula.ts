import type { Document } from "mongodb";

export type GradeCalculationMode = "ponderada" | "equitativa" | "aritmetica";

export interface GradeWeightsSpec {
  mode: GradeCalculationMode;
  n1Weight: number;
  n2Weight: number;
  formulaLabel: string;
}

export interface InstitutionalThresholds {
  minimumGrade: number;
  minimumAttendance: number;
  specialExamGrade: number;
  evaluationFormula: string;
  resolutionCode: string;
  currentSemesterLabel: string;
  currentWeekLabel: string;
}

/** Interpreta uma expressão ou nome de fórmula avaliativa em pesos concretos. */
export function parseGradeFormula(rawFormula?: unknown): GradeWeightsSpec {
  const raw = typeof rawFormula === "string" ? rawFormula.trim() : "";
  const lower = raw.toLowerCase();

  if (
    lower.includes("aritm") ||
    lower.includes("contínu") ||
    lower.includes("continu") ||
    lower.includes("/ 4") ||
    lower.includes("/4")
  ) {
    return {
      mode: "aritmetica",
      n1Weight: 0.5,
      n2Weight: 0.5,
      formulaLabel: raw || "Média aritmética de instrumentos contínuos",
    };
  }

  if (
    lower.includes("equitativa") ||
    lower.includes("/ 2") ||
    lower.includes("/2")
  ) {
    return {
      mode: "equitativa",
      n1Weight: 0.5,
      n2Weight: 0.5,
      formulaLabel: raw || "(N1 + N2) / 2",
    };
  }

  const normalized = raw.replace(/,/g, ".");
  const n1Match = /N1\s*[×*x]\s*([0-9]+(?:\.[0-9]+)?)/i.exec(normalized);
  const n2Match = /N2\s*[×*x]\s*([0-9]+(?:\.[0-9]+)?)/i.exec(normalized);
  if (n1Match && n2Match) {
    const w1 = Number(n1Match[1]);
    const w2 = Number(n2Match[1]);
    const total = w1 + w2;
    if (Number.isFinite(w1) && Number.isFinite(w2) && total > 0) {
      const n1Weight = Number((w1 / total).toFixed(4));
      const n2Weight = Number((w2 / total).toFixed(4));
      return {
        mode: Math.abs(n1Weight - 0.5) < 0.001 ? "equitativa" : "ponderada",
        n1Weight,
        n2Weight,
        formulaLabel: raw,
      };
    }
  }

  if (lower.includes("50%") && lower.includes("n1") && lower.includes("n2")) {
    return {
      mode: "equitativa",
      n1Weight: 0.5,
      n2Weight: 0.5,
      formulaLabel: raw || "(N1 + N2) / 2",
    };
  }

  return {
    mode: "ponderada",
    n1Weight: 0.4,
    n2Weight: 0.6,
    formulaLabel: raw || "(N1 × 0.4) + (N2 × 0.6)",
  };
}

/** Calcula N1, N2 e média final respeitando o modo e pesos configurados para a turma. */
export function computeSemesterGrades(input: {
  assignmentsScore: number;
  p1Score: number;
  projectsScore: number;
  p2Score: number;
  evaluationFormula?: unknown;
}) {
  const spec = parseGradeFormula(input.evaluationFormula);
  const round1 = (value: number) => Number(value.toFixed(1));

  if (spec.mode === "aritmetica") {
    const n1 = round1((input.assignmentsScore + input.p1Score) / 2);
    const n2 = round1((input.projectsScore + input.p2Score) / 2);
    const finalAverage = round1(
      (input.assignmentsScore + input.p1Score + input.projectsScore + input.p2Score) / 4,
    );
    return { n1, n2, finalAverage, spec };
  }

  const n1 = round1(input.assignmentsScore * 0.4 + input.p1Score * 0.6);
  const n2 = round1(input.projectsScore * 0.4 + input.p2Score * 0.6);
  const finalAverage = round1(n1 * spec.n1Weight + n2 * spec.n2Weight);
  return { n1, n2, finalAverage, spec };
}

/** Extrai limites regimentais efetivos a partir de `admin_settings`, com fallbacks seguros. */
export function resolveInstitutionalThresholds(
  adminSettings?: Document | null,
): InstitutionalThresholds {
  const num = (val: unknown, fallback: number) => {
    const n = Number(val);
    return Number.isFinite(n) ? n : fallback;
  };
  return {
    minimumGrade: num(adminSettings?.minimumGrade ?? adminSettings?.passingGrade, 6),
    minimumAttendance: num(adminSettings?.minimumAttendance, 75),
    specialExamGrade: num(adminSettings?.specialExamGrade, 4),
    evaluationFormula: String(
      adminSettings?.evaluationFormula ??
        adminSettings?.defaultFormula ??
        "(N1 × 0.4) + (N2 × 0.6)",
    ),
    resolutionCode: String(
      adminSettings?.resolutionCode ?? "RESOLUÇÃO CONSEPE 2026/04",
    ),
    currentSemesterLabel: String(
      adminSettings?.currentSemesterLabel ??
        adminSettings?.academicPeriod ??
        "2026/2",
    ),
    currentWeekLabel: String(
      adminSettings?.currentWeekLabel ?? "Calendário Vigente 2026/2",
    ),
  };
}

/** Determina a situação acadêmica conforme média e frequência regimentais configuradas. */
export function evaluateAcademicSituation(input: {
  partialAverage: number | null;
  attendancePercentage: number;
  thresholds: Pick<
    InstitutionalThresholds,
    "minimumGrade" | "minimumAttendance" | "specialExamGrade"
  >;
}): string {
  if (input.partialAverage === null) return "Em Curso";
  if (input.attendancePercentage < input.thresholds.minimumAttendance) {
    return "Reprovado por Falta";
  }
  if (input.partialAverage >= input.thresholds.minimumGrade) {
    return "Aprovado";
  }
  if (input.partialAverage >= input.thresholds.specialExamGrade) {
    return "Em Exame / Curso";
  }
  return "Reprovado por Nota";
}

/**
 * Gera candidatos de `classCode` a partir de `targetComponent`
 * (ex.: `"IHC-305 - Interação..."` -> `["IHC-305 - Interação...", "IHC-305"]`,
 * preservando códigos compostos como `"218131 - APS-II"`).
 */
export function extractClassCodeCandidates(targetComponent: unknown): string[] {
  if (typeof targetComponent !== "string") return [];
  const full = targetComponent.trim();
  if (!full || full.toLowerCase() === "geral") return [];

  const candidates = new Set<string>([full]);
  const parts = full.split(" - ");
  for (let i = 1; i < parts.length; i++) {
    const prefix = parts.slice(0, i).join(" - ").trim();
    if (prefix.length >= 2) candidates.add(prefix);
  }
  return Array.from(candidates);
}

/** Verifica se um comunicado institucional deve ser exibido ao perfil informado. */
export function isAnnouncementVisibleToRole(
  announcement: Document,
  profile: "aluno" | "docente",
): boolean {
  const isInst =
    announcement.isInstitutional === true || announcement.senderRole === "admin";
  if (!isInst) return true;

  const rawAudience = String(announcement.audience ?? "").trim().toLowerCase();
  if (!rawAudience || rawAudience.includes("comunidade") || rawAudience.includes("todos")) {
    return true;
  }

  const mentionsDiscente =
    rawAudience.includes("discent") || rawAudience.includes("alun");
  const mentionsDocente =
    rawAudience.includes("docent") || rawAudience.includes("prof");

  if (mentionsDiscente && mentionsDocente) return true;
  if (profile === "aluno") return mentionsDiscente || !mentionsDocente;
  return mentionsDocente || !mentionsDiscente;
}
