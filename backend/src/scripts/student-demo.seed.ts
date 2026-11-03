//Desenvolvido por Rafael Henrique dos Santos Inácio - RA: 25009719

 // Seed demonstrativa do portal do aluno

import bcrypt from "bcryptjs";
import { ObjectId, type Db, type Document } from "mongodb";

const SEED_TAG = "student-demo-v1";
const COURSE_CODE = "ES-STUDENT-DEMO";
const CLASS_CODE = "ES-STUDENT-4N";

export const studentDemoUsers = [
  {
    identity: "prof.student.demo",
    email: "prof.student.demo@example.com",
    displayName: "Professor de Demonstração",
    profile: "docente",
  },
  {
    identity: "aluno.student1",
    email: "aluno.student1@example.com",
    displayName: "Aluno Demonstração Um",
    profile: "aluno",
  },
  {
    identity: "aluno.student2",
    email: "aluno.student2@example.com",
    displayName: "Aluno Demonstração Dois",
    profile: "aluno",
  },
] as const;

export type StudentSeedSummary = Record<
  string,
  { created: number; reused: number }
>;

export class StudentSeedError extends Error {}

// Verifica se a senha atende aos limites do bcrypt.
export function validateStudentPassword(
  password: string | undefined,
): asserts password is string {
  if (
    !password ||
    password.trim().length < 8 ||
    Buffer.byteLength(password, "utf8") > 72
  ) {
    throw new StudentSeedError(
      "SEED_DEMO_PASSWORD deve ter pelo menos 8 caracteres e no máximo 72 bytes.",
    );
  }
}

interface PlannedRecord {
  collection: string;
  filter: Document;
  document: Document;
  existing: boolean;
}

// Procura registros já existentes.
async function findExisting(
  database: Db,
  collection: string,
  filter: Document,
): Promise<Document | null> {
  const records = await database
    .collection(collection)
    .find(filter)
    .limit(2)
    .toArray();

  if (records.length > 1) {
    throw new StudentSeedError(
      `Registros duplicados em ${collection}.`,
    );
  }

  return records[0] ?? null;
}

// Compara os vínculos sem modificar dados existentes.
function checkFields(
  existing: Document,
  expected: Document,
  label: string,
): void {
  for (const [field, value] of Object.entries(expected)) {
    const actual = existing[field];

    const matches =
      value instanceof Date
        ? actual instanceof Date &&
          actual.getTime() === value.getTime()
        : actual === value;

    if (!matches) {
      throw new StudentSeedError(
        `Registro incompatível em ${label}, campo ${field}.`,
      );
    }
  }
}

// Executa a lógica da seed.
export async function seedStudentDemo(
  database: Db,
  password: string,
): Promise<StudentSeedSummary> {
  validateStudentPassword(password);

  const plans: PlannedRecord[] = [];
  const accounts: Document[] = [];
  const now = new Date();

  // 1. Planejamento dos usuários.
  for (const demo of studentDemoUsers) {
    const existing = await findExisting(
      database,
      "auth_users",
      {
        $or: [
          { normalizedIdentity: demo.identity },
          { identity: demo.identity },
          { email: demo.email },
        ],
      },
    );

    if (existing) {
      checkFields(
        existing,
        {
          normalizedIdentity: demo.identity,
          profile: demo.profile,
          active: true,
        },
        demo.identity,
      );

      if (
        existing.identity !== demo.identity ||
        typeof existing.email !== "string" ||
        existing.email.toLowerCase() !== demo.email ||
        typeof existing.passwordHash !== "string" ||
        !await bcrypt.compare(password, existing.passwordHash)
      ) {
        throw new StudentSeedError(
          `Conta ${demo.identity} incompatível. A senha existente foi preservada.`,
        );
      }
    }

    const document = existing ?? {
      _id: new ObjectId(),
      ...demo,
      normalizedIdentity: demo.identity,
      passwordHash: await bcrypt.hash(password, 12),
      active: true,
      sessionVersion: 0,
      twoFactorRequired: false,
      createdAt: now,
      updatedAt: now,
      seedTag: SEED_TAG,
    };

    plans.push({
      collection: "auth_users",
      filter: { normalizedIdentity: demo.identity },
      document,
      existing: !!existing,
    });

    accounts.push(document);
  }

  const professor = accounts[0]!;
  const students = accounts.slice(1);

  // 2. Curso demonstrativo.
  const courseFilter = { code: COURSE_CODE };

  const existingCourse = await findExisting(
    database,
    "academic_courses",
    courseFilter,
  );

  if (existingCourse) {
    checkFields(
      existingCourse,
      {
        code: COURSE_CODE,
        name: "Engenharia de Software (Aluno Demo)",
      },
      COURSE_CODE,
    );
  }

  const course = existingCourse ?? {
    _id: new ObjectId(),
    code: COURSE_CODE,
    name: "Engenharia de Software (Aluno Demo)",
    matrix: "2026",
    workload: "3200h",
    studentsCount: 2,
    department: "Computação",
    modality: "Presencial",
    formula: "P1 * 0.4 + P2 * 0.4 + T * 0.2",
    components: [],
    createdAt: now,
    updatedAt: now,
    seedTag: SEED_TAG,
  };

  plans.push({
    collection: "academic_courses",
    filter: courseFilter,
    document: course,
    existing: !!existingCourse,
  });

  // 3. Turma vinculada ao curso e professor.
  const classFilter = { code: CLASS_CODE };

  const classLinks = {
    courseCode: COURSE_CODE,
    courseName: course.name,
    professorId: String(professor._id),
    professorIdentity: professor.normalizedIdentity,
  };

  const existingClass = await findExisting(
    database,
    "academic_classes",
    classFilter,
  );

  if (existingClass) {
    checkFields(existingClass, classLinks, CLASS_CODE);
  }

  const classroom = existingClass ?? {
    _id: new ObjectId(),
    code: CLASS_CODE,
    ...classLinks,
    semester: "2026/2 - 4º Semestre",
    shift: "Noturno",
    location: "Sala de Demonstração",
    maxCapacity: 40,
    formulaRegime: "autonomia_docente",
    createdAt: now,
    updatedAt: now,
    seedTag: SEED_TAG,
  };

  plans.push({
    collection: "academic_classes",
    filter: classFilter,
    document: classroom,
    existing: !!existingClass,
  });

  // 4. Matrículas dos alunos na turma.
  for (const student of students) {
    const filter = {
      classCode: CLASS_CODE,
      studentId: String(student._id),
    };

    const links = {
      courseCode: COURSE_CODE,
      studentIdentity: student.normalizedIdentity,
      status: "active",
    };

    const existing = await findExisting(
      database,
      "academic_enrollments",
      filter,
    );

    if (existing) {
      checkFields(existing, links, "matrícula");
    }

    plans.push({
      collection: "academic_enrollments",
      filter,
      document: existing ?? {
        _id: new ObjectId(),
        ...filter,
        ...links,
        displayName: student.displayName,
        enrolledAt: now,
        seedTag: SEED_TAG,
      },
      existing: !!existing,
    });
  }

  // Confere a capacidade antes das inserções.
  const enrolled = await database
    .collection("academic_enrollments")
    .countDocuments({
      classCode: CLASS_CODE,
      status: "active",
    });

  const missing = plans.filter(
    (plan) =>
      plan.collection === "academic_enrollments" &&
      !plan.existing,
  ).length;

  if (
    !Number.isInteger(classroom.maxCapacity) ||
    enrolled + missing > classroom.maxCapacity
  ) {
    throw new StudentSeedError(
      "A turma não possui capacidade suficiente.",
    );
  }

  // 5. Aulas demonstrativas.
  const sessions = [
    {
      title: "Engenharia de Software - Introdução",
      startsAt: new Date("2026-11-09T22:00:00.000Z"),
    },
    {
      title: "Engenharia de Software - Projeto Prático",
      startsAt: new Date("2026-11-11T22:00:00.000Z"),
    },
  ];

  for (const session of sessions) {
    const filter = {
      classCode: CLASS_CODE,
      title: session.title,
    };

    const fields = {
      courseCode: COURSE_CODE,
      startsAt: session.startsAt,
      endsAt: new Date(
        session.startsAt.getTime() + 90 * 60 * 1000,
      ),
    };

    const existing = await findExisting(
      database,
      "academic_class_sessions",
      filter,
    );

    if (existing) {
      checkFields(existing, fields, session.title);
    }

    plans.push({
      collection: "academic_class_sessions",
      filter,
      document: existing ?? {
        _id: new ObjectId(),
        ...filter,
        ...fields,
        createdAt: now,
        seedTag: SEED_TAG,
      },
      existing: !!existing,
    });
  }

  // 6. Cria índices para evitar duplicações.
  await database.collection("auth_users").createIndex(
    { normalizedIdentity: 1 },
    { unique: true },
  );

  await database.collection("academic_courses").createIndex(
    { code: 1 },
    { unique: true },
  );

  await database.collection("academic_classes").createIndex(
    { code: 1 },
    { unique: true },
  );

  await database.collection("academic_enrollments").createIndex(
    { classCode: 1, studentId: 1 },
    { unique: true },
  );

  await database.collection("academic_class_sessions").createIndex(
  { classCode: 1, title: 1 },
    {
      name: "student_demo_class_session_unique",
      unique: true,
      partialFilterExpression: { seedTag: SEED_TAG },
    },
  );

  // 7. Insere apenas os registros que faltam.
  const summary: StudentSeedSummary = {};

  for (const plan of plans) {
    const counts = summary[plan.collection] ??= {
      created: 0,
      reused: 0,
    };

    if (plan.existing) {
      counts.reused++;
      continue;
    }

    const result = await database
      .collection(plan.collection)
      .updateOne(
        plan.filter,
        { $setOnInsert: plan.document },
        { upsert: true },
      );

    if (result.upsertedCount !== 1) {
      throw new StudentSeedError(
        "Os dados foram alterados durante a execução. Revise e execute novamente.",
      );
    }

    counts.created++;
  }

  return summary;
}
