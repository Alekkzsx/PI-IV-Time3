// Desenvolvido por Murillo Caravita - RA: 25014012
import type { Db, Document } from "mongodb";
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
}