// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import type { Router } from "express";
import type { Db, Document } from "mongodb";
import { z } from "zod";
import { AuthError } from "../../../../../shared/auth-error.js";
import { objectId, parse } from "../../../../../shared/validation.js";
import { adminWrite, audit, publicRecord } from "../../../infrastructure/admin-support.js";
import type { UnifiedEmailService } from "../../../../notifications/domain/notification.types.js";
import {
  dispatchNotificationSafe,
  resolveActiveRegisteredRecipientById,
} from "../../../../notifications/domain/recipient-guard.js";

const STAGE_FIELD_MAP: Record<string, string> = {
  P1: "p1Score",
  N1: "p1Score",
  P2: "p2Score",
  N2: "p2Score",
  ATIVIDADES: "assignmentsScore",
  TRAB: "assignmentsScore",
  PROJETOS: "projectsScore",
  PROJ: "projectsScore",
};

/** Rotas administrativas para fila de retificações de notas solicitadas após lacração da pauta. */
export function registerAdminRectificationRoutes(
  router: Router,
  database: Db,
  emailService?: UnifiedEmailService,
): void {
  const rectifications = database.collection("academic_rectifications");

  router.get("/rectifications", async (request, response) => {
    const query: Document = {};
    if (typeof request.query.classCode === "string" && request.query.classCode.trim().length > 0) {
      query.classCode = request.query.classCode.trim();
    }
    if (typeof request.query.status === "string" && request.query.status.trim().length > 0) {
      query.status = request.query.status.trim();
    }
    const list = await rectifications
      .find(query)
      .sort({ createdAt: -1 })
      .limit(200)
      .toArray();
    response.json(list.map(publicRecord));
  });

  router.patch("/rectifications/:id/decision", async (request, response) => {
    const id = objectId(request.params.id);
    const input = parse(
      z.object({
        approved: z.boolean(),
        decisionNote: z.string().trim().min(5).max(3000),
      }).strict(),
      request.body,
    );
    const adminUser = response.locals.user as Document | undefined;
    const signedBy = String(adminUser?.displayName ?? "Secretaria Geral Acadêmica");

    const decided = await adminWrite(database, response.locals.adminId, async (session) => {
      const updated = await rectifications.findOneAndUpdate(
        { _id: id, status: { $regex: /^(pendente|aguardando|aguardando parecer)$/i } },
        {
          $set: {
            status: input.approved ? "Deferido" : "Indeferido",
            decisionNote: input.decisionNote,
            decidedBy: response.locals.adminId,
            signedBy,
            decidedAt: new Date(),
            updatedAt: new Date(),
          },
        },
        { session, returnDocument: "after" },
      );
      if (!updated) {
        throw new AuthError(409, "rectification_unavailable", "Solicitação de retificação inexistente ou já decidida.");
      }

      if (input.approved) {
        const stageKey = String(updated.stage ?? "P1").trim().toUpperCase();
        const targetField = STAGE_FIELD_MAP[stageKey] ?? "p1Score";
        const newScore = Number(updated.newScore ?? 0);
        const now = new Date();
        await database.collection("academic_grades").updateOne(
          { classCode: String(updated.classCode), studentId: String(updated.studentId) },
          {
            $set: {
              [targetField]: newScore,
              hasEnteredGrades: true,
              updatedAt: now,
            },
            $setOnInsert: {
              classCode: String(updated.classCode),
              studentId: String(updated.studentId),
              ra: String(updated.studentRa ?? ""),
              studentName: String(updated.studentName ?? ""),
              assignmentsScore: 0,
              p1Score: 0,
              projectsScore: 0,
              p2Score: 0,
              attendanceRate: 100,
              absences: 0,
              createdAt: now,
            },
          },
          { upsert: true, session },
        );
      }

      await audit(
        database,
        response.locals.adminId,
        "rectification_decided",
        String(updated.classCode ?? id),
        {
          rectificationId: String(id),
          approved: input.approved,
          studentId: updated.studentId,
          stage: updated.stage,
          newScore: updated.newScore,
        },
        session,
      );

      return publicRecord(updated);
    });

    if (emailService && decided) {
      const code = String(decided.code ?? decided.id);
      if (input.approved && decided.studentId) {
        void resolveActiveRegisteredRecipientById(database, String(decided.studentId))
          .then((student) => {
            if (!student) return;
            dispatchNotificationSafe("admin-rectification-student", student.email, () =>
              emailService.sendGradePublished({
                to: student.email,
                studentName: student.displayName || String(decided.studentName ?? "Discente"),
                assignmentTitle: `Retificação Homologada (${String(decided.stage ?? "Avaliação")})`,
                disciplineName: String(decided.classCode ?? ""),
                grade: Number(decided.newScore ?? 0),
                feedback: `Despacho administrativo (${signedBy}): ${input.decisionNote}`,
              }),
            );
          })
          .catch(() => {});
      }

      if (decided.teacherId) {
        void resolveActiveRegisteredRecipientById(database, String(decided.teacherId))
          .then((teacher) => {
            if (!teacher) return;
            dispatchNotificationSafe("admin-rectification-teacher", teacher.email, () =>
              emailService.sendProtocolDecided({
                to: teacher.email,
                studentName: teacher.displayName || String(decided.teacherName ?? "Docente"),
                protocolCode: code,
                requestType: `Retificação de Nota (${String(decided.stage ?? "")} • ${String(decided.classCode ?? "")})`,
                approved: input.approved,
                decisionNote: input.decisionNote,
                signedBy,
              }),
            );
          })
          .catch(() => {});
      }
    }

    response.json(decided);
  });
}
