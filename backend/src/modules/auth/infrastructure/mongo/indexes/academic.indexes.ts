import type { Db } from "mongodb";

export async function ensureAcademicIndexes(database: Db): Promise<void> {
  await database.collection("academic_protocols").createIndex({ code: 1 }, { unique: true });
  await database.collection("academic_courses").createIndex({ code: 1 }, { unique: true });
  await database.collection("academic_classes").createIndex({ code: 1 }, { unique: true });
  await database.collection("academic_enrollments").createIndex({ classCode: 1, studentId: 1 }, { unique: true });
  await database.collection("academic_enrollments").createIndex({ studentId: 1, status: 1 });
  await database.collection("academic_enrollment_declarations").createIndex({ verificationKey: 1 }, { unique: true });
  await database.collection("academic_class_sessions").createIndex({ classCode: 1, startsAt: 1 });
  await database.collection("academic_live_sessions").createIndex({ roomCode: 1 }, { unique: true });
  await database.collection("academic_live_sessions").createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
}