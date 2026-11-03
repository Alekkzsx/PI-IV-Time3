// Desenvolvido por Guilherme Henrique Moreira
import { Router } from "express";
import { ObjectId, type Db, type Document } from "mongodb";
import { z } from "zod";
import { adminOnly } from "../infrastructure/admin-auth.middleware.js";
import { adminWrite, audit, publicRecord, publicUser } from "../infrastructure/admin-support.js";
import { parse, objectId } from "../../../shared/validation.js";
import { AuthError } from "../../../shared/auth-error.js";
import { registerAdminCalendarRoutes } from "./operations/calendar/routes.js";
import { registerAdminProtocolRoutes } from "./operations/protocols/routes.js";
import { registerAdminAnnouncementRoutes } from "./operations/announcements/routes.js";
import { registerAdminSettingsRoutes } from "./operations/settings/routes.js";

export function createAdminOperationsRouter(database: Db, secret: string): Router {
  const router = Router();
  router.use(adminOnly(secret, database));
  registerAdminCalendarRoutes(router, database);
  registerAdminProtocolRoutes(router, database);
  registerAdminAnnouncementRoutes(router, database);
  registerAdminSettingsRoutes(router, database);
  const protocols = database.collection("academic_protocols");

  router.get("/dashboard", async (_request, response) => {
    const users = database.collection("auth_users");
    const [
      students,
      professors,
      administrators,
      courses,
      allClasses,
      pendingProtocols,
      decidedProtocols,
      gradesList,
      calendarMilestones,
    ] = await Promise.all([
      users.countDocuments({ profile: "aluno", active: true }),
      users.countDocuments({ profile: "docente", active: true }),
      users.countDocuments({ profile: "admin", active: true }),
      database.collection("academic_courses").countDocuments({ active: { $ne: false } }),
      database.collection("academic_classes").find({ active: { $ne: false } }).toArray(),
      protocols.countDocuments({ status: "Aguardando Parecer" }),
      protocols.countDocuments({ status: { $in: ["Deferido", "Indeferido"] } }),
      database.collection("academic_grades").find({}).toArray(),
      database.collection("academic_calendar").find({}).sort({ startsAt: 1 }).limit(10).toArray(),
    ]);

    const classes = allClasses.length;
    const homologatedCount = allClasses.filter((c) => c.pautaHomologated === true || c.gradeLocked === true).length;
    const homologatedPercentage = classes > 0 ? Math.round((homologatedCount / classes) * 100) : 0;
    const attendanceAverage =
      gradesList.length > 0
        ? Number(
            (
              gradesList.reduce((acc, g) => acc + Number(g.attendanceRate ?? 100), 0) /
              gradesList.length
            ).toFixed(1),
          )
        : 100;

    response.json({
      students,
      professors,
      administrators,
      courses,
      classes,
      pendingProtocols,
      decidedProtocols,
      homologatedCount,
      homologatedPercentage,
      attendanceAverage,
      calendarMilestones: calendarMilestones.map(publicRecord),
    });
  });

  router.get("/audit-logs", async (request, response) => {
    const query = parse(
      z.object({
        target: z.string().max(100).optional(),
        limit: z.coerce.number().int().min(1).max(500).default(100),
        offset: z.coerce.number().int().min(0).max(100000).default(0),
      }).strict(),
      request.query,
    );
    const records = await database
      .collection("admin_audit_logs")
      .find(query.target ? { target: query.target } : {})
      .sort({ createdAt: -1, _id: -1 })
      .skip(query.offset)
      .limit(query.limit)
      .toArray();

    const actorIds = Array.from(
      new Set(
        records
          .map((r) => (typeof r.actorId === "string" && ObjectId.isValid(r.actorId) ? r.actorId : null))
          .filter(Boolean) as string[],
      ),
    );
    const actors =
      actorIds.length > 0
        ? await database
            .collection("auth_users")
            .find({ _id: { $in: actorIds.map((id) => new ObjectId(id)) } })
            .toArray()
        : [];
    const actorMap = new Map(actors.map((a) => [String(a._id), a]));

    response.json(
      records.map((entry) => {
        const actorDoc = typeof entry.actorId === "string" ? actorMap.get(entry.actorId) : undefined;
        const actionStr = String(entry.action ?? "");
        const severity =
          entry.severity ??
          (actionStr.includes("suspended") || actionStr.includes("revoked") || actionStr.includes("locked")
            ? "CRITICO"
            : actionStr.includes("updated") || actionStr.includes("decision") || actionStr.includes("rectif")
              ? "ATENCAO"
              : "INFO");
        return {
          ...publicRecord(entry),
          actorName: entry.actorName ?? actorDoc?.displayName ?? "Sistema Institucional",
          actorIdentity: entry.actorIdentity ?? actorDoc?.identity ?? entry.actorId ?? "SISTEMA",
          actorRole: entry.actorRole ?? actorDoc?.profile ?? "admin",
          ipAddress: entry.ipAddress ?? "127.0.0.1",
          severity,
          diffBefore: entry.diffBefore ?? null,
          diffAfter: entry.diffAfter ?? (entry.details ? JSON.stringify(entry.details) : null),
        };
      }),
    );
  });

  router.get("/users/:id/dossier", async (request, response) => {
    const id = objectId(request.params.id);
    const user = await database.collection("auth_users").findOne({ _id: id });
    if (!user) throw new AuthError(404, "user_not_found", "Usuário não encontrado.");
    const [classes, enrollments, logs, protocolsList, gradesList] = await Promise.all([
      database.collection("academic_classes").find({ professorId: String(id) }).toArray(),
      database.collection("academic_enrollments").find({ studentId: String(id) }).toArray(),
      database
        .collection("admin_audit_logs")
        .find({ $or: [{ target: String(id) }, { actorId: String(id) }] })
        .sort({ createdAt: -1 })
        .limit(100)
        .toArray(),
      protocols.find({ studentId: String(id) }, { projection: { attachmentBase64: 0 } }).sort({ createdAt: -1 }).toArray(),
      database.collection("academic_grades").find({ studentId: String(id) }).toArray(),
    ]);
    await audit(database, response.locals.adminId, "dossier_viewed", String(id));
    response.json({
      user: publicUser(user),
      classes: classes.map(publicRecord),
      enrollments: enrollments.map(publicRecord),
      protocols: protocolsList.map(publicRecord),
      grades: gradesList.map(publicRecord),
      auditLogs: logs.map(publicRecord),
    });
  });

  return router;
}
