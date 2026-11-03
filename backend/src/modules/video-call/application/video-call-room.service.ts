// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import { createHash, randomBytes } from "node:crypto";
import { ObjectId, type Db, type Document } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";

export interface AuthenticatedVideoUser {
  id: string;
  profile: string;
}

export function sanitizeRoomCode(raw: string): string {
  return raw
    .trim()
    .toUpperCase()
    .replace(/\s*-\s*/g, "-")
    .replace(/\s+/g, "-")
    .replace(/[^A-Z0-9._-]/g, "");
}

export class VideoCallRoomService {
  private readonly users;
  private readonly classes;
  private readonly enrollments;
  private readonly liveSessions;
  private readonly webSocketTickets;
  private readonly attendanceLogs;

  constructor(private readonly database: Db) {
    this.users = database.collection("auth_users");
    this.classes = database.collection("academic_classes");
    this.enrollments = database.collection("academic_enrollments");
    this.liveSessions = database.collection("academic_live_sessions");
    this.webSocketTickets = database.collection("video_call_ws_tickets");
    this.attendanceLogs = database.collection("video_call_attendance_logs");
  }

  private async findClassByRoomCode(rawRoomCode: string): Promise<Document | null> {
    const trimmed = rawRoomCode.trim();
    const sanitized = sanitizeRoomCode(trimmed);
    const direct = await this.classes.findOne({
      code: { $regex: `^${escapeRegExp(trimmed)}$`, $options: "i" },
    });
    if (direct) return direct;

    if (sanitized !== trimmed.toUpperCase()) {
      const bySanitized = await this.classes.findOne({
        code: { $regex: `^${escapeRegExp(sanitized)}$`, $options: "i" },
      });
      if (bySanitized) return bySanitized;
    }

    // Fallback: compara código sanitizado contra turmas cadastradas (ex: "218131 - APS-II" <-> "218131-APS-II")
    if (typeof this.classes.find === "function") {
      const allClasses = await this.classes.find({ active: { $ne: false } }).toArray();
      return (
        allClasses.find((item) => {
          const itemSanitized = sanitizeRoomCode(String(item.code ?? ""));
          return (
            itemSanitized === sanitized ||
            itemSanitized.endsWith(`-${sanitized}`) ||
            sanitized.endsWith(`-${itemSanitized}`)
          );
        }) ?? null
      );
    }

    return null;
  }

  async listAccessibleRooms(claims: AuthenticatedVideoUser) {
    const user = await this.users.findOne({
      _id: new ObjectId(claims.id),
      profile: claims.profile,
      active: true,
    });
    if (!user) throw new AuthError(401, "invalid_token", "Conta inativa ou inválida.");

    const identity = String(user.normalizedIdentity ?? user.identity).trim().toLowerCase();
    let classList: Document[] = [];

    if (claims.profile === "admin") {
      classList = await this.classes.find({ active: { $ne: false } }).sort({ code: 1 }).toArray();
    } else if (claims.profile === "docente") {
      classList = await this.classes
        .find({
          active: { $ne: false },
          $or: [{ professorId: String(user._id) }, { professorIdentity: identity }],
        })
        .sort({ code: 1 })
        .toArray();
    } else {
      const userEnrollments = await this.enrollments
        .find({ studentId: String(user._id), status: "active" })
        .toArray();
      const codes = userEnrollments.map((e) => e.classCode);
      if (codes.length > 0) {
        classList = await this.classes.find({ code: { $in: codes }, active: { $ne: false } }).toArray();
      }
    }

    const activeSessions = await this.liveSessions
      .find({ expiresAt: { $gt: new Date() } })
      .toArray();
    const liveByRoom = new Map(activeSessions.map((s) => [String(s.roomCode).toUpperCase(), s]));

    return classList.map((c) => {
      const roomCode = sanitizeRoomCode(String(c.code));
      const live = liveByRoom.get(roomCode);
      return {
        roomCode,
        classCode: String(c.code),
        title: String(c.subjectName ?? c.courseName ?? c.code),
        courseName: String(c.courseName ?? ""),
        semester: String(c.semester ?? ""),
        shift: String(c.shift ?? ""),
        location: String(c.location ?? ""),
        professorIdentity: c.professorIdentity ?? null,
        professorName: c.professorName ?? c.professorIdentity ?? "Docente",
        isOpen: Boolean(live),
        openedByName: live?.openedByName ?? null,
        openedAt: live?.openedAt ?? null,
      };
    });
  }

  async consumeWebSocketTicket(ticket: string, roomCode: string): Promise<void> {
    const normalizedRoom = sanitizeRoomCode(roomCode);
    const tokenDigest = createHash("sha256").update(ticket).digest("hex");
    const consumed = await this.webSocketTickets.findOneAndDelete({
      tokenDigest,
      roomCode: normalizedRoom,
      expiresAt: { $gt: new Date() },
    });
    if (!consumed) {
      throw new AuthError(401, "invalid_room_ticket", "Autorização da sala ausente ou expirada.");
    }
  }

  async enterRoom(claims: AuthenticatedVideoUser, rawRoomCode: string) {
    const user = await this.users.findOne({
      _id: new ObjectId(claims.id),
      profile: claims.profile,
      active: true,
    });
    if (!user) {
      throw new AuthError(401, "invalid_token", "Conta inativa ou inválida.");
    }

    const classRecord = await this.findClassByRoomCode(rawRoomCode);
    if (!classRecord) {
      throw new AuthError(404, "class_not_found", "Turma não encontrada.");
    }

    const roomCode = sanitizeRoomCode(String(classRecord.code));
    const identity = String(user.normalizedIdentity ?? user.identity)
      .trim()
      .toLowerCase();

    if (claims.profile === "docente" || claims.profile === "admin") {
      const isAssigned =
        claims.profile === "admin" ||
        classRecord.professorId === user._id.toString() ||
        classRecord.professorIdentity === identity;
      if (!isAssigned) {
        throw new AuthError(
          403,
          "class_access_denied",
          "Você não é o docente responsável por esta turma.",
        );
      }

      const now = new Date();
      await this.liveSessions.updateOne(
        { roomCode },
        {
          $set: {
            roomCode,
            classCode: classRecord.code,
            openedById: user._id.toString(),
            openedByIdentity: identity,
            openedByName: user.displayName ?? identity,
            openedAt: now,
            expiresAt: new Date(now.getTime() + 8 * 60 * 60 * 1000),
          },
        },
        { upsert: true },
      );
      const webSocketTicket = await this.issueWebSocketTicket(roomCode);
      return {
        roomCode,
        classCode: String(classRecord.code),
        title: String(classRecord.subjectName ?? classRecord.courseName ?? classRecord.code),
        opened: true,
        webSocketTicket,
      };
    }

    if (claims.profile !== "aluno") {
      throw new AuthError(403, "forbidden", "Perfil sem acesso à videochamada.");
    }

    const enrollment = await this.enrollments.findOne({
      classCode: classRecord.code,
      studentId: user._id.toString(),
      status: "active",
    });
    if (!enrollment) {
      throw new AuthError(403, "enrollment_required", "Você não está matriculado nesta turma.");
    }

    const activeSession = await this.liveSessions.findOne({
      roomCode,
      expiresAt: { $gt: new Date() },
    });
    if (!activeSession) {
      throw new AuthError(409, "room_not_open", "A videochamada ainda não foi aberta pelo docente.");
    }

    const webSocketTicket = await this.issueWebSocketTicket(roomCode);
    return {
      roomCode,
      classCode: String(classRecord.code),
      title: String(classRecord.subjectName ?? classRecord.courseName ?? classRecord.code),
      opened: false,
      webSocketTicket,
    };
  }

  async closeRoom(claims: AuthenticatedVideoUser, rawRoomCode: string): Promise<void> {
    if (claims.profile !== "docente" && claims.profile !== "admin") {
      throw new AuthError(403, "forbidden", "Somente o docente pode encerrar a sala.");
    }

    const user = await this.users.findOne({
      _id: new ObjectId(claims.id),
      profile: claims.profile,
      active: true,
    });
    if (!user) {
      throw new AuthError(401, "invalid_token", "Conta inativa ou inválida.");
    }

    const classRecord = await this.findClassByRoomCode(rawRoomCode);
    const roomCode = classRecord ? sanitizeRoomCode(String(classRecord.code)) : sanitizeRoomCode(rawRoomCode);
    const filter: Document =
      claims.profile === "admin"
        ? { roomCode }
        : { roomCode, openedById: user._id.toString() };
    const result = await this.liveSessions.deleteOne(filter);
    if (result.deletedCount !== 1) {
      throw new AuthError(
        404,
        "room_not_open",
        "Sala não encontrada ou aberta por outro usuário.",
      );
    }
  }

  async recordAttendanceTelemetry(
    claims: AuthenticatedVideoUser,
    rawRoomCode: string,
    event: "join" | "leave",
    connectedSeconds?: number,
  ) {
    const user = await this.users.findOne({ _id: new ObjectId(claims.id), active: true });
    if (!user) throw new AuthError(401, "invalid_token", "Conta inválida.");
    const classRecord = await this.findClassByRoomCode(rawRoomCode);
    const roomCode = classRecord ? sanitizeRoomCode(String(classRecord.code)) : sanitizeRoomCode(rawRoomCode);
    const classCode = classRecord ? String(classRecord.code) : roomCode;

    await this.attendanceLogs.insertOne({
      roomCode,
      classCode,
      userId: String(user._id),
      identity: user.identity,
      displayName: user.displayName,
      profile: user.profile,
      event,
      connectedSeconds: connectedSeconds ?? 0,
      recordedAt: new Date(),
    });

    // Atualiza indicador isConnected na última sessão de diário da turma para visibilidade docente em tempo real
    if (user.profile === "aluno") {
      const latestSession = await this.database
        .collection("academic_class_sessions")
        .findOne({ classCode }, { sort: { startsAt: -1, sessionNumber: -1 } });
      if (latestSession && Array.isArray(latestSession.attendanceList)) {
        const updatedList = latestSession.attendanceList.map((entry: Document) => {
          if (entry.studentId === String(user._id) || entry.ra === user.identity) {
            return {
              ...entry,
              isConnected: event === "join",
              ...(event === "join" || (connectedSeconds ?? 0) >= 60 ? { status: "presente" } : {}),
            };
          }
          return entry;
        });
        await this.database
          .collection("academic_class_sessions")
          .updateOne({ _id: latestSession._id }, { $set: { attendanceList: updatedList } });
      }
    }

    return { ok: true, roomCode };
  }

  private async issueWebSocketTicket(roomCode: string): Promise<string> {
    const ticket = randomBytes(32).toString("base64url");
    const tokenDigest = createHash("sha256").update(ticket).digest("hex");
    await this.webSocketTickets.insertOne({
      tokenDigest,
      roomCode,
      expiresAt: new Date(Date.now() + 60_000),
    });
    return ticket;
  }
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
