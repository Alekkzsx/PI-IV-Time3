// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
import type { Db, Document } from "mongodb";
import { createSeedHelpers, SEED_TAG } from "../shared/seed.runner.js";
import type { SeedModule, SeedSummary } from "../shared/seed.types.js";
import { curriculumComponents } from "./02-courses.seed.js";

export async function seedClasses(
  database: Db,
  _password: string,
  context?: Record<string, any>,
): Promise<SeedSummary> {
  const summary: SeedSummary = {};
  const { now, upsertSync, upsertOnInsert } = createSeedHelpers(database, summary);

  const adminActor = context?.users?.get("coord.agmrm") ??
    (await database.collection("auth_users").findOne({ normalizedIdentity: "coord.agmrm" }));

  const adminId = adminActor ? String(adminActor._id) : "admin";

  // Busca todos os docentes disponíveis
  const teachers = await database.collection("auth_users").find({ profile: "docente" }).toArray();
  const defaultTeacher = teachers[0]!;

  // 30 Turmas cobrindo 30 disciplinas do currículo
  const classesToCreate = curriculumComponents.slice(0, 30).map((comp, idx) => {
    const teacher = teachers[idx % teachers.length] ?? defaultTeacher;
    const isCurrentSemester = comp.semester === 4;

    const totalHours = comp.workloadHours;
    const completedHours = isCurrentSemester ? Math.round(comp.workloadHours * 0.68) : comp.workloadHours;
    const rawProgress = totalHours > 0 ? Math.min(1, Math.max(0, completedHours / totalHours)) : 0;
    const progress = Number(rawProgress.toFixed(4));
    const progressPercentage = Math.round(rawProgress * 100);

    return {
      code: comp.code === "PI-IV" ? "PI4-2026-4N" : comp.code,
      subjectName: comp.name,
      courseCode: "ES-2026",
      courseName: "Engenharia de Software",
      professorId: String(teacher._id),
      professorIdentity: teacher.identity,
      professorName: teacher.displayName,
      semester: `2026/${comp.semester % 2 === 0 ? "2" : "1"} - ${comp.semester}º Semestre`,
      shift: "Noturno",
      schedule: isCurrentSemester
        ? (idx % 2 === 0 ? "Segundas e Quartas, 19:10 - 20:50" : "Terças e Quintas, 19:10 - 20:50")
        : "Segundas e Quartas, 19:10 - 20:50",
      scheduleStartTime: "19:10",
      scheduleEndTime: "20:50",
      scheduleDays: isCurrentSemester ? (idx % 2 === 0 ? [1, 3] : [2, 4]) : [1, 2, 3, 4, 5],
      location: `Lab Informática ${String((idx % 6) + 1).padStart(2, "0")} - Bloco C`,
      virtualRoomLabel: "Sala Virtual Teams",
      connectedStudentsCount: 34 + (idx % 12),
      totalHours,
      credits: Math.round(totalHours / 20),
      completedHours,
      progress,
      progressPercentage,
      progressPercentageFormatted: `${progressPercentage}%`,
      workloadCompletedLabel: `${completedHours}h`,
      workloadTotalLabel: ` de ${totalHours}h`,
      progressCaption: "Este percentual reflete diretamente o progresso visto pelos discentes.",
      active: true,
      maxCapacity: 50,
      formulaRegime: "autonomia_docente",
    };
  });

  const classesMap = new Map<string, Document>();

  for (const cls of classesToCreate) {
    const doc = await upsertSync(
      "academic_classes",
      { code: cls.code },
      {
        ...cls,
        createdBy: adminId,
        createdAt: now,
        updatedAt: now,
        seedTag: SEED_TAG,
      },
    );
    classesMap.set(cls.code, doc);
  }

  // 2. MATRÍCULAS DOS ALUNOS
  // Busca todos os alunos cadastrados (36 alunos reais)
  const allStudents = await database.collection("auth_users").find({ profile: "aluno" }).toArray();

  // Matricula todos os alunos nas turmas do 4º semestre (ativas) e uma coorte nas demais turmas
  const activeSemesterCodes = new Set(
    classesToCreate
      .filter((c) => c.code.includes("4N") || c.code.includes("APS-II") || c.code === "PI4-2026-4N")
      .map((c) => c.code),
  );
  const cohortStudents = allStudents.slice(Math.min(20, allStudents.length), Math.min(32, allStudents.length));

  for (const classroom of classesToCreate) {
    const enrolledList = activeSemesterCodes.has(classroom.code) ? allStudents : cohortStudents;
    for (const st of enrolledList) {
      await upsertOnInsert(
        "academic_enrollments",
        { classCode: classroom.code, studentId: String(st._id) },
        {
          classCode: classroom.code,
          courseCode: "ES-2026",
          studentId: String(st._id),
          studentIdentity: st.identity,
          displayName: st.displayName,
          status: "active",
          enrolledAt: now,
          createdBy: adminId,
          seedTag: SEED_TAG,
        },
      );
    }
  }

  await database.collection("academic_classes").createIndex({ code: 1 }, { unique: true });
  await database.collection("academic_enrollments").createIndex(
    { classCode: 1, studentId: 1 },
    { unique: true },
  );

  if (context) {
    context.classes = classesMap;
  }

  return summary;
}

export const classesSeed: SeedModule = {
  id: "classes",
  name: "03-classes",
  description: "Provisiona 30 turmas acadêmicas completas com mais de 30 matrículas ativas por turma",
  execute: seedClasses,
};
