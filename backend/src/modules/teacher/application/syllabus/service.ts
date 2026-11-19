// Desenvolvido por Murillo Caravita - RA: 25014012
import type { Db, Document } from "mongodb";
import { AuthError } from "../../../../shared/auth-error.js";
import { TeacherClassAccess } from "../teacher-class-access.js";
import { createDefaultSyllabusUnits } from "./syllabus.defaults.js";

export class TeacherSyllabusService {
  constructor(
    private readonly database: Db,
    private readonly classAccess: TeacherClassAccess,
  ) {}

  async advanceUnit(userId: string, user: Document, classCode: string, unitId: string) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const units: Document[] =
      Array.isArray(classroom.syllabusUnits) && classroom.syllabusUnits.length > 0
        ? classroom.syllabusUnits
        : createDefaultSyllabusUnits(String(classroom.subjectName ?? classroom.courseName ?? classroom.code));

    const updatedUnits = units.map((unit) => {
      if (String(unit.id) !== unitId) return unit;
      const total = Number(unit.totalClasses ?? 10);
      const current = Number(unit.completedClasses ?? 0);
      return { ...unit, completedClasses: current < total ? current + 1 : total };
    });
    const totalHours = Number(classroom.totalHours ?? 80);
    const completedHours = Math.min(
      totalHours,
      updatedUnits.reduce((total, unit) => total + Number(unit.completedClasses ?? 0) * 2, 0),
    );
    const rawProgress = totalHours > 0 ? Math.min(1, Math.max(0, completedHours / totalHours)) : 0;
    const progress = Number(rawProgress.toFixed(4));
    const progressPercentage = Math.round(rawProgress * 100);
    const progressPercentageFormatted = `${progressPercentage}%`;
    const workloadCompletedLabel = `${completedHours}h`;
    const workloadTotalLabel = ` de ${totalHours}h`;

    await this.database.collection("academic_classes").updateOne(
      { _id: classroom._id },
      {
        $set: {
          syllabusUnits: updatedUnits,
          completedHours,
          progress,
          progressPercentage,
          progressPercentageFormatted,
          workloadCompletedLabel,
          workloadTotalLabel,
          updatedAt: new Date(),
        },
      },
    );
    return {
      syllabusUnits: updatedUnits,
      completedHours,
      progress,
      progressPercentage,
      progressPercentageFormatted,
      workloadCompletedLabel,
      workloadTotalLabel,
    };
  }

  async updateSyllabusPlan(
    userId: string,
    user: Document,
    classCode: string,
    input: {
      syllabus?: string;
      objectives?: string;
      methodology?: string;
      evaluationFormula?: string;
      bibliography?: Array<{ type: string; title: string; authors: string; publisher?: string; year?: string }>;
    },
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const currentFormula = String(classroom.evaluationFormula ?? "(N1 × 0.4) + (N2 × 0.6)").trim();
    if (
      classroom.formulaRegime === "admin" &&
      input.evaluationFormula !== undefined &&
      input.evaluationFormula.trim() !== currentFormula
    ) {
      throw new AuthError(
        403,
        "formula_locked_by_admin",
        "A fórmula de avaliação desta turma é imposta pela Administração e não pode ser alterada pelo docente.",
      );
    }
    const updateSet: Record<string, unknown> = { updatedAt: new Date() };
    if (input.syllabus !== undefined) {
      updateSet.syllabus = input.syllabus.trim();
      updateSet.ementa = input.syllabus.trim();
    }
    if (input.objectives !== undefined) updateSet.objectives = input.objectives.trim();
    if (input.methodology !== undefined) updateSet.methodology = input.methodology.trim();
    if (input.evaluationFormula !== undefined && classroom.formulaRegime !== "admin") {
      updateSet.evaluationFormula = input.evaluationFormula.trim();
    }
    if (input.bibliography !== undefined) updateSet.bibliography = input.bibliography;

    await this.database
      .collection("academic_classes")
      .updateOne({ _id: classroom._id }, { $set: updateSet });

    return {
      ok: true,
      classCode: classroom.code,
      syllabus: (updateSet.syllabus as string | undefined) ?? String(classroom.syllabus ?? classroom.ementa ?? ""),
      objectives: (updateSet.objectives as string | undefined) ?? String(classroom.objectives ?? ""),
      methodology: (updateSet.methodology as string | undefined) ?? String(classroom.methodology ?? ""),
      evaluationFormula:
        (updateSet.evaluationFormula as string | undefined) ??
        String(classroom.evaluationFormula ?? "(N1 × 0.4) + (N2 × 0.6)"),
      bibliography:
        (updateSet.bibliography as unknown[] | undefined) ??
        (Array.isArray(classroom.bibliography) ? classroom.bibliography : []),
    };
  }
}