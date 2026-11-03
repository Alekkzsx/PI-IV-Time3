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
    const completedHours = Math.min(
      Number(classroom.totalHours ?? 80),
      updatedUnits.reduce((total, unit) => total + Number(unit.completedClasses ?? 0) * 2, 0),
    );

    await this.database.collection("academic_classes").updateOne(
      { _id: classroom._id },
      { $set: { syllabusUnits: updatedUnits, completedHours, updatedAt: new Date() } },
    );
    return { syllabusUnits: updatedUnits, completedHours };
  }
}