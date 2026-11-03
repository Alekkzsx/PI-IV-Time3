// Desenvolvido por Murillo Caravita - RA: 25014012
import { ObjectId, type Db, type Document } from "mongodb";
import { TeacherClassAccess } from "./teacher-class-access.js";

export class TeacherDashboardRepository {
  constructor(
    private readonly database: Db,
    private readonly classAccess: TeacherClassAccess,
  ) {}

  async load(userId: string, user: Document) {
    const classes = await this.classAccess.listClasses(userId, user);
    const classCodes = classes.map((classroom) => String(classroom.code));

    const [
      enrollments,
      rawSessions,
      rawAssignments,
      rawSubmissions,
      rawGrades,
      rawMaterials,
      rawForumTopics,
      teacherEvents,
      calendarEvents,
      announcements,
      protocols,
      liveSessions,
      activeSessions,
      auditLogs,
      adminSettings,
    ] = await Promise.all([
      classCodes.length > 0
        ? this.database.collection("academic_enrollments").find({ classCode: { $in: classCodes }, status: "active" }).toArray()
        : Promise.resolve([]),
      classCodes.length > 0
        ? this.database.collection("academic_class_sessions").find({ classCode: { $in: classCodes }, cancelled: { $ne: true } }).sort({ startsAt: 1, sessionNumber: 1 }).toArray()
        : Promise.resolve([]),
      classCodes.length > 0
        ? this.database.collection("academic_assignments").find({ classCode: { $in: classCodes } }).sort({ createdAt: -1 }).toArray()
        : Promise.resolve([]),
      classCodes.length > 0
        ? this.database.collection("academic_submissions").find({ classCode: { $in: classCodes } }, { projection: { contentBase64: 0 } }).toArray()
        : Promise.resolve([]),
      classCodes.length > 0
        ? this.database.collection("academic_grades").find({ classCode: { $in: classCodes } }).toArray()
        : Promise.resolve([]),
      classCodes.length > 0
        ? this.database.collection("academic_materials").find({ classCode: { $in: classCodes } }, { projection: { contentBase64: 0 } }).sort({ createdAt: -1 }).toArray()
        : Promise.resolve([]),
      classCodes.length > 0
        ? this.database.collection("academic_forum_topics").find({ classCode: { $in: classCodes } }).sort({ createdAt: -1 }).toArray()
        : Promise.resolve([]),
      this.database.collection("academic_events").find({ ownerId: userId }).sort({ createdAt: -1 }).toArray(),
      this.database.collection("academic_calendar").find({}).sort({ startsAt: 1 }).limit(50).toArray(),
      this.database
        .collection("academic_announcements")
        .find({
          $or: [
            { isInstitutional: true },
            { classCode: { $in: classCodes } },
            { createdBy: userId },
          ],
        })
        .sort({ createdAt: -1 })
        .limit(100)
        .toArray(),
      classCodes.length > 0
        ? this.database
            .collection("academic_protocols")
            .find({ targetComponent: { $in: classCodes } }, { projection: { attachmentBase64: 0 } })
            .sort({ createdAt: -1 })
            .limit(50)
            .toArray()
        : Promise.resolve([]),
      this.database.collection("academic_live_sessions").find({ expiresAt: { $gt: new Date() } }).toArray(),
      this.database
        .collection("auth_sessions")
        .find({ userId, expiresAt: { $gt: new Date() } })
        .sort({ createdAt: -1 })
        .toArray(),
      this.database
        .collection("admin_audit_logs")
        .find({ $or: [{ actorId: userId }, { target: userId }] })
        .sort({ createdAt: -1 })
        .limit(20)
        .toArray(),
      this.database.collection("admin_settings").findOne({ _id: "institutional" as unknown as ObjectId }),
    ]);

    return {
      classes,
      classCodes,
      enrollments,
      rawSessions,
      rawAssignments,
      rawSubmissions,
      rawGrades,
      rawMaterials,
      rawForumTopics,
      teacherEvents,
      calendarEvents,
      announcements,
      protocols,
      liveSessions,
      activeSessions,
      auditLogs,
      adminSettings,
    };
  }
}