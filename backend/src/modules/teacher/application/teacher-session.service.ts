// Desenvolvido por Murillo Caravita - RA: 25014012
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";
import { TeacherClassAccess } from "./teacher-class-access.js";
import { formatPtBrLongDate } from "../../../shared/formatting/date-formatters.js";

export interface SessionAttendanceUpdate {
  contentProgram?: string;
  methodology?: string;
  location?: string;
  isHomologated?: boolean;
  attendanceList?: Array<{
    studentId: string;
    ra: string;
    name: string;
    status: "presente" | "ausente" | "justificada";
    observation?: string;
  }>;
}

export class TeacherSessionService {
  constructor(
    private readonly database: Db,
    private readonly classAccess: TeacherClassAccess,
  ) {}

  async createOrSelectSessionByDate(
    userId: string,
    user: Document,
    classCode: string,
    isoDate: string,
    hours = 2,
  ) {
    const classroom = await this.classAccess.requireOwnedClass(userId, user, classCode);
    const targetDate = new Date(isoDate);
    if (Number.isNaN(targetDate.getTime())) throw new AuthError(400, "invalid_date", "Data da aula inválida.");

    const dayStart = new Date(targetDate);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(targetDate);
    dayEnd.setHours(23, 59, 59, 999);

    const existing = await this.database.collection("academic_class_sessions").findOne({
      classCode: classroom.code,
      startsAt: { $gte: dayStart, $lte: dayEnd },
      cancelled: { $ne: true },
    });
    if (existing) {
      return { id: String(existing._id), created: false };
    }

    const count = await this.database.collection("academic_class_sessions").countDocuments({
      classCode: classroom.code,
      cancelled: { $ne: true },
    });
    const enrollments = await this.database
      .collection("academic_enrollments")
      .find({ classCode: classroom.code, status: "active" })
      .sort({ displayName: 1 })
      .toArray();
    const totalHours = Number(classroom.totalHours ?? 80);
    const maxAbsences = Math.round(totalHours * 0.25);

    const doc = {
      classCode: classroom.code,
      courseCode: classroom.courseCode,
      sessionNumber: count + 1,
      hours,
      startsAt: targetDate,
      endsAt: new Date(targetDate.getTime() + hours * 45 * 60 * 1000),
      dateFormatted: formatPtBrLongDate(targetDate),
      title: `Aula ${String(count + 1).padStart(2, "0")} - ${classroom.subjectName ?? classroom.courseName ?? classroom.code}`,
      contentProgram: "",
      methodology: "Aula expositiva dialogada e atividades práticas.",
      location: String(classroom.location ?? "Sala Virtual"),
      isHomologated: false,
      attendanceList: enrollments.map((e) => ({
        studentId: String(e.studentId),
        ra: String(e.studentIdentity ?? ""),
        name: String(e.displayName ?? e.studentIdentity ?? ""),
        status: "presente",
        accumulatedAbsences: 0,
        maxAbsences,
        attendanceRate: 100,
        riskLevel: "regular",
        isConnected: false,
      })),
      cancelled: false,
      createdAt: new Date(),
      createdBy: userId,
    };
    const inserted = await this.database.collection("academic_class_sessions").insertOne(doc);
    return { id: String(inserted.insertedId), created: true };
  }

  async updateSessionAttendance(
    userId: string,
    user: Document,
    sessionId: string,
    payload: SessionAttendanceUpdate,
  ) {
    if (!ObjectId.isValid(sessionId)) throw new AuthError(400, "invalid_id", "Identificador de aula inválido.");
    const sessionDoc = await this.database
      .collection("academic_class_sessions")
      .findOne({ _id: new ObjectId(sessionId) });
    if (!sessionDoc) throw new AuthError(404, "session_not_found", "Aula não encontrada.");
    const classroom = await this.classAccess.requireOwnedClass(userId, user, String(sessionDoc.classCode));

    const updateSet: Record<string, unknown> = { updatedAt: new Date() };
    if (payload.contentProgram !== undefined) updateSet.contentProgram = payload.contentProgram;
    if (payload.methodology !== undefined) updateSet.methodology = payload.methodology;
    if (payload.location !== undefined) updateSet.location = payload.location;
    if (payload.isHomologated !== undefined) updateSet.isHomologated = payload.isHomologated;
    if (payload.attendanceList !== undefined) {
      const prevMap = new Map(
        (Array.isArray(sessionDoc.attendanceList) ? sessionDoc.attendanceList : []).map((a: Document) => [
          String(a.studentId),
          a,
        ]),
      );
      updateSet.attendanceList = payload.attendanceList.map((item) => ({
        ...(prevMap.get(item.studentId) ?? {}),
        studentId: item.studentId,
        ra: item.ra,
        name: item.name,
        status: item.status,
        observation: item.observation ?? "",
      }));
    }

    await this.database
      .collection("academic_class_sessions")
      .updateOne({ _id: new ObjectId(sessionId) }, { $set: updateSet });

    const allClassSessions = await this.database
      .collection("academic_class_sessions")
      .find({ classCode: classroom.code, cancelled: { $ne: true } })
      .toArray();
    const homologatedHours = allClassSessions
      .filter((s) => s.isHomologated === true)
      .reduce((acc, s) => acc + Number(s.hours ?? 2), 0);
    if (homologatedHours > 0) {
      await this.database
        .collection("academic_classes")
        .updateOne({ _id: classroom._id }, { $set: { completedHours: homologatedHours } });
    }

    const totalHours = Number(classroom.totalHours ?? 80);
    const enrollments = await this.database
      .collection("academic_enrollments")
      .find({ classCode: classroom.code, status: "active" })
      .toArray();

    for (const enrollment of enrollments) {
      const sid = String(enrollment.studentId);
      let rawAbsences = 0;
      for (const session of allClassSessions) {
        const list = Array.isArray(session.attendanceList) ? session.attendanceList : [];
        const entry = list.find((a: Document) => String(a.studentId) === sid || a.ra === enrollment.studentIdentity);
        if (entry?.status === "ausente") {
          rawAbsences += Number(session.hours ?? 2);
        }
      }
      const netAbsences = Math.max(0, rawAbsences - Number(enrollment.excusedAbsences ?? 0));
      const attendanceRate = Number(Math.max(0, ((totalHours - netAbsences) / totalHours) * 100).toFixed(1));
      await this.database.collection("academic_grades").updateOne(
        { classCode: classroom.code, studentId: sid },
        {
          $set: {
            ra: enrollment.studentIdentity,
            studentName: enrollment.displayName,
            absences: netAbsences,
            attendanceRate,
            updatedAt: new Date(),
          },
          $setOnInsert: {
            classCode: classroom.code,
            studentId: sid,
            assignmentsScore: 0,
            p1Score: 0,
            projectsScore: 0,
            p2Score: 0,
            createdAt: new Date(),
          },
        },
        { upsert: true },
      );
    }

    if (payload.isHomologated) {
      await this.database.collection("admin_audit_logs").insertOne({
        actorId: userId,
        actorName: user.displayName,
        actorRole: user.profile,
        action: "attendance_homologated",
        target: classroom.code,
        details: { sessionId, sessionNumber: sessionDoc.sessionNumber },
        createdAt: new Date(),
      });
    }

    return { ok: true, sessionId };
  }
}