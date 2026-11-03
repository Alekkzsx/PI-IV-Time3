// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import type { Router } from "express";
import type { Db } from "mongodb";

export function registerPrivacyRoutes(router: Router, database: Db): void {
  router.get("/lgpd-export", async (_request, response) => {
    const userId = response.locals.userId as string;
    const user = response.locals.user;
    const [enrollments, classes, submissions, protocols, sessions, auditLogs] = await Promise.all([
      database.collection("academic_enrollments").find({ studentId: userId }).toArray(),
      database.collection("academic_classes").find({ professorId: userId }).toArray(),
      database.collection("academic_submissions").find({ studentId: userId }, { projection: { contentBase64: 0 } }).toArray(),
      database.collection("academic_protocols").find({ studentId: userId }, { projection: { attachmentBase64: 0 } }).toArray(),
      database.collection("auth_sessions").find({ userId }, { projection: { _id: 0, sessionId: 1, createdAt: 1, expiresAt: 1 } }).toArray(),
      database.collection("admin_audit_logs").find({ $or: [{ actorId: userId }, { target: userId }] }).limit(100).toArray(),
    ]);
    response.json({
      exportedAt: new Date().toISOString(),
      holder: {
        id: userId,
        identity: user.identity,
        displayName: user.displayName,
        email: user.email,
        profile: user.profile,
        departmentOrCourse: user.departmentOrCourse ?? user.department ?? "",
        preferences: user.preferences ?? {},
      },
      enrollments,
      teachingClasses: classes,
      submissions,
      protocols,
      activeSessions: sessions,
      auditTrail: auditLogs,
    });
  });
}