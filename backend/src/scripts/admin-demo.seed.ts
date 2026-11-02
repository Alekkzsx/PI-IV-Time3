// Desenvolvido por Guilherme Henrique Moreira

import bcrypt from "bcryptjs";
import { ObjectId, type Db, type Document } from "mongodb";

const COURSE_CODE = "ES-DEMO";
const CLASS_CODE = "ES-DEMO-4N";
const SESSION_TITLE = "Aula de apresentação (Demo)";
const SEED_TAG = "admin-demo-v1";

export const demoUsers = [
  { identity: "admin.demo", displayName: "Administrador Demonstração", email: "admin.demo@example.com", profile: "admin" },
  { identity: "prof.demo", displayName: "Professor Demonstração", email: "prof.demo@example.com", profile: "docente" },
  { identity: "aluno.demo1", displayName: "Aluno Demonstração Um", email: "aluno.demo1@example.com", profile: "aluno" },
  { identity: "aluno.demo2", displayName: "Aluno Demonstração Dois", email: "aluno.demo2@example.com", profile: "aluno" },
] as const;

export type SeedSummary = Record<string, { created: number; reused: number }>;

export class SeedValidationError extends Error {}

export function validateSeedPassword(password: string | undefined): asserts password is string {
  if (!password || password.trim().length < 8 || Buffer.byteLength(password, "utf8") > 72) {
    throw new SeedValidationError("Defina SEED_DEMO_PASSWORD com pelo menos 8 caracteres e no máximo 72 bytes (limite do bcrypt).");
  }
}

interface PlannedRecord {
  collection: string;
  filter: Document;
  document: Document & { _id: ObjectId };
  existing: boolean;
}

function checkFields(record: Document, expected: Document, label: string): void {
  for (const [field, value] of Object.entries(expected)) {
    const actual = record[field];
    const matches = value instanceof Date
      ? actual instanceof Date && actual.getTime() === value.getTime()
      : actual === value;
    if (!matches) {
      throw new SeedValidationError(`Registro incompatível em ${label}, campo ${field}. Nenhum dado existente será sobrescrito.`);
    }
  }
}

function exactText(value: string): RegExp {
  return new RegExp("^" + value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$", "i");
}

async function findExisting(database: Db, collection: string, filter: Document): Promise<Document | null> {
  const records = await database.collection(collection).find(filter).limit(2).toArray();
  if (records.length > 1) {
    throw new SeedValidationError(`Há registros duplicados ou conflitantes em ${collection}. Revise-os antes do seed.`);
  }
  return records[0] ?? null;
}

// A preparação inteira é somente leitura: conflitos interrompem antes das inserções.
export async function seedAdminDemo(database: Db, password: string): Promise<SeedSummary> {
  validateSeedPassword(password);
  const plans: PlannedRecord[] = [];
  const accounts: Document[] = [];
  const now = new Date();

  for (const demo of demoUsers) {
    const filter = { normalizedIdentity: demo.identity };
    const existing = await findExisting(database, "auth_users", {
      $or: [filter, { identity: exactText(demo.identity) }, { email: exactText(demo.email) }],
    });
    if (existing) {
      checkFields(existing, {
        normalizedIdentity: demo.identity, profile: demo.profile, active: true,
      }, demo.identity);
      if (typeof existing.email !== "string" || existing.email.trim().toLowerCase() !== demo.email ||
          typeof existing.identity !== "string" || existing.identity.trim().toLowerCase() !== demo.identity ||
          typeof existing.passwordHash !== "string" || !/^\$2[aby]\$\d{2}\$/.test(existing.passwordHash)) {
        throw new SeedValidationError(`Conta ${demo.identity} incompatível com os dados demonstrativos.`);
      }
      if (!await bcrypt.compare(password, existing.passwordHash)) {
        throw new SeedValidationError(`A senha de ${demo.identity} difere de SEED_DEMO_PASSWORD. A senha existente foi preservada.`);
      }
    }
    const document = existing
      ? existing as Document & { _id: ObjectId }
      : {
          _id: new ObjectId(), ...demo, normalizedIdentity: demo.identity,
          passwordHash: await bcrypt.hash(password, 12), active: true, createdAt: now, updatedAt: now, seedTag: SEED_TAG,
        };
    plans.push({ collection: "auth_users", filter, document, existing: !!existing });
    accounts.push(document);
  }

  const admin = accounts[0]!;
  const professor = accounts[1]!;
  const students = accounts.slice(2);
  const courseFilter = { code: COURSE_CODE };
  const existingCourse = await findExisting(database, "academic_courses", courseFilter);
  if (existingCourse) {
    checkFields(existingCourse, { name: "Engenharia de Software (Demo)" }, COURSE_CODE);
  }
  const course = existingCourse ?? {
    _id: new ObjectId(), code: COURSE_CODE, name: "Engenharia de Software (Demo)",
    matrix: "2026", workload: "3200h", studentsCount: 2,
    formula: "P1 * 0.4 + P2 * 0.4 + T * 0.2", department: "Computação",
    modality: "Presencial", components: [], createdBy: String(admin._id),
    createdAt: now, updatedAt: now, seedTag: SEED_TAG,
  };
  plans.push({ collection: "academic_courses", filter: courseFilter,
    document: course as PlannedRecord["document"], existing: !!existingCourse });

  const classFilter = { code: CLASS_CODE };
  const existingClass = await findExisting(database, "academic_classes", classFilter);
  const classLinks = {
    courseCode: COURSE_CODE, courseName: course.name,
    professorId: String(professor._id), professorIdentity: professor.normalizedIdentity,
  };
  if (existingClass) checkFields(existingClass, classLinks, CLASS_CODE);
  const classroom = existingClass ?? {
    _id: new ObjectId(), code: CLASS_CODE, ...classLinks,
    semester: "2026/2 - 4º Semestre", shift: "Noturno", location: "Sala Demo",
    maxCapacity: 40, formulaRegime: "autonomia_docente",
    createdBy: String(admin._id), createdAt: now, updatedAt: now, seedTag: SEED_TAG,
  };
  if (!Number.isInteger(classroom.maxCapacity) || classroom.maxCapacity < 2) {
    throw new SeedValidationError("A turma demonstrativa precisa comportar os dois alunos.");
  }
  plans.push({ collection: "academic_classes", filter: classFilter,
    document: classroom as PlannedRecord["document"], existing: !!existingClass });

  let missingEnrollments = 0;
  for (const student of students) {
    const filter = { classCode: CLASS_CODE, studentId: String(student._id) };
    const existing = await findExisting(database, "academic_enrollments", filter);
    const links = {
      courseCode: COURSE_CODE, studentIdentity: student.normalizedIdentity, status: "active",
    };
    if (existing) checkFields(existing, links, "matrícula demonstrativa");
    else missingEnrollments++;
    plans.push({
      collection: "academic_enrollments", filter, existing: !!existing,
      document: (existing ?? {
        _id: new ObjectId(), ...filter, ...links, displayName: student.displayName,
        enrolledAt: now, createdBy: String(admin._id), seedTag: SEED_TAG,
      }) as PlannedRecord["document"],
    });
  }
  const enrolled = await database.collection("academic_enrollments")
    .countDocuments({ classCode: CLASS_CODE, status: "active" });
  if (enrolled + missingEnrollments > classroom.maxCapacity) {
    throw new SeedValidationError("A turma não tem vagas suficientes para as matrículas demonstrativas.");
  }

  const sessionFilter = { classCode: CLASS_CODE, title: SESSION_TITLE };
  const existingSession = await findExisting(database, "academic_class_sessions", sessionFilter);
  const start = new Date("2026-11-09T22:00:00.000Z");
  const sessionFields = {
    courseCode: COURSE_CODE, startsAt: start,
    endsAt: new Date(start.getTime() + 90 * 60 * 1000),
  };
  if (existingSession) checkFields(existingSession, sessionFields, "aula demonstrativa");
  plans.push({
    collection: "academic_class_sessions", filter: sessionFilter, existing: !!existingSession,
    document: (existingSession ?? {
      _id: new ObjectId(), ...sessionFilter, ...sessionFields,
      createdBy: String(admin._id), createdAt: now, seedTag: SEED_TAG,
    }) as PlannedRecord["document"],
  });

  await database.collection("auth_users").createIndex({ normalizedIdentity: 1 }, { unique: true });
  await database.collection("academic_courses").createIndex({ code: 1 }, { unique: true });
  await database.collection("academic_classes").createIndex({ code: 1 }, { unique: true });
  await database.collection("academic_enrollments")
    .createIndex({ classCode: 1, studentId: 1 }, { unique: true });
  // A unicidade da aula vale somente para dados deste seed.
  await database.collection("academic_class_sessions").createIndex(
    { classCode: 1, title: 1 },
    { unique: true, partialFilterExpression: { seedTag: SEED_TAG } },
  );

  const summary: SeedSummary = {};
  for (const plan of plans) {
    const counts = summary[plan.collection] ??= { created: 0, reused: 0 };
    if (plan.existing) {
      counts.reused++;
      continue;
    }
    const result = await database.collection(plan.collection).updateOne(
      plan.filter, { $setOnInsert: plan.document }, { upsert: true },
    );
    if (result.upsertedCount === 1) {
      counts.created++;
    } else {
      // Outro processo pode ter inserido a mesma chave após a preparação.
      throw new SeedValidationError("Dados alterados durante o seed. Execute novamente para validar os vínculos antes de continuar.");
    }
  }
  return summary;
}
