// Desenvolvido por: Rafael Henrique dos Santos Inácio
import { ObjectId, type Db, type Document } from "mongodb";

export interface StudentDashboardData {
  enrollments: Document[];
  classCodes: string[];
  courseCodes: string[];
  classes: Document[];
  courses: Document[];
  classSessions: Document[];
  assignments: Document[];
  submissions: Document[];
  grades: Document[];
  materials: Document[];
  forumTopics: Document[];
  personalNotes: Document[];
  personalReminders: Document[];
  calendarEvents: Document[];
  announcements: Document[];
  protocols: Document[];
  liveSessions: Document[];
  activeSessions: Document[];
  auditLogs: Document[];
  profMap: Map<string, Document>;
}

export class StudentDashboardRepository {
  constructor(private readonly database: Db) {}

  async load(studentId: string): Promise<StudentDashboardData> {
    const enrollments = await this.database
      .collection("academic_enrollments")
      .find({ studentId: String(studentId), status: "active" })
      .toArray();
    const classCodes = enrollments.map((enrollment) => String(enrollment.classCode));
    const courseCodes = Array.from(new Set(enrollments.map((enrollment) => String(enrollment.courseCode)).filter(Boolean)));

    const [
      classes,
      courses,
      classSessions,
      assignments,
      submissions,
      grades,
      materials,
      forumTopics,
      personalNotes,
      personalReminders,
      calendarEvents,
      announcements,
      protocols,
      liveSessions,
      activeSessions,
      auditLogs,
    ] = await Promise.all([
      classCodes.length > 0
        ? this.database.collection("academic_classes").find({ code: { $in: classCodes } }).toArray()
        : Promise.resolve([]),
      courseCodes.length > 0
        ? this.database.collection("academic_courses").find({ code: { $in: courseCodes } }).toArray()
        : Promise.resolve([]),
      classCodes.length > 0
        ? this.database
            .collection("academic_class_sessions")
            .find({ classCode: { $in: classCodes }, cancelled: { $ne: true } })
            .sort({ startsAt: 1 })
            .toArray()
        : Promise.resolve([]),
      classCodes.length > 0
        ? this.database
            .collection("academic_assignments")
            .find({ classCode: { $in: classCodes } })
            .sort({ dueDate: 1, createdAt: -1 })
            .toArray()
        : Promise.resolve([]),
      this.database
        .collection("academic_submissions")
        .find({ studentId: String(studentId) }, { projection: { contentBase64: 0 } })
        .toArray(),
      this.database.collection("academic_grades").find({ studentId: String(studentId) }).toArray(),
      classCodes.length > 0
        ? this.database
            .collection("academic_materials")
            .find({ classCode: { $in: classCodes } }, { projection: { contentBase64: 0 } })
            .sort({ createdAt: -1 })
            .toArray()
        : Promise.resolve([]),
      classCodes.length > 0
        ? this.database
            .collection("academic_forum_topics")
            .find({ classCode: { $in: classCodes } })
            .sort({ createdAt: -1 })
            .toArray()
        : Promise.resolve([]),
      this.database.collection("student_notes").find({ studentId: String(studentId) }).toArray(),
      this.database
        .collection("student_reminders")
        .find({ studentId: String(studentId) })
        .sort({ date: 1 })
        .toArray(),
      this.database.collection("academic_calendar").find({}).sort({ startsAt: 1 }).limit(100).toArray(),
      this.database
        .collection("academic_announcements")
        .find({ $or: [{ isInstitutional: true }, { classCode: { $in: classCodes } }] })
        .sort({ createdAt: -1 })
        .limit(100)
        .toArray(),
      this.database
        .collection("academic_protocols")
        .find({ studentId: String(studentId) }, { projection: { attachmentBase64: 0 } })
        .sort({ createdAt: -1 })
        .toArray(),
      this.database.collection("academic_live_sessions").find({ expiresAt: { $gt: new Date() } }).toArray(),
      this.database
        .collection("auth_sessions")
        .find({ userId: String(studentId), expiresAt: { $gt: new Date() } })
        .sort({ createdAt: -1 })
        .toArray(),
      this.database
        .collection("admin_audit_logs")
        .find({ $or: [{ actorId: String(studentId) }, { target: String(studentId) }] })
        .sort({ createdAt: -1 })
        .limit(20)
        .toArray(),
    ]);

    const professorIds = Array.from(
      new Set(
        classes
          .map((classroom) =>
            typeof classroom.professorId === "string" && ObjectId.isValid(classroom.professorId)
              ? classroom.professorId
              : null,
          )
          .filter(Boolean) as string[],
      ),
    );
    const professors =
      professorIds.length > 0
        ? await this.database
            .collection("auth_users")
            .find({ _id: { $in: professorIds.map((id) => new ObjectId(id)) } })
            .toArray()
        : [];

    return {
      enrollments,
      classCodes,
      courseCodes,
      classes,
      courses,
      classSessions,
      assignments,
      submissions,
      grades,
      materials,
      forumTopics,
      personalNotes,
      personalReminders,
      calendarEvents,
      announcements,
      protocols,
      liveSessions,
      activeSessions,
      auditLogs,
      profMap: new Map(professors.map((professor) => [String(professor._id), professor])),
    };
  }
}