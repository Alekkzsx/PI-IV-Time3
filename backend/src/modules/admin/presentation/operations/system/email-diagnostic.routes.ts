// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import type { Router } from "express";
import type { Db, Document } from "mongodb";
import { z } from "zod";
import { parse } from "../../../../../shared/validation.js";
import { audit } from "../../../infrastructure/admin-support.js";
import type { UnifiedEmailService } from "../../../../notifications/domain/notification.types.js";
import type { ResilientEmailSender } from "../../../../notifications/infrastructure/resilient-email.sender.js";

export function registerAdminEmailDiagnosticRoutes(
  router: Router,
  database: Db,
  emailService?: UnifiedEmailService,
): void {
  /**
   * Dispara um e-mail de diagnóstico para validar conectividade e bypass de firewall.
   * Rota protegida: apenas administradores autenticados.
   */
  router.post("/system/test-email", async (request, response) => {
    const input = parse(
      z.object({
        recipientEmail: z.string().email().optional(),
        note: z.string().trim().max(500).optional(),
      }).strict(),
      request.body,
    );

    const adminUser = response.locals.user as Document | undefined;
    const recipient = input.recipientEmail ?? adminUser?.email ?? "staff.notadez@gmail.com";
    const testId = `DIAG-${Date.now().toString(36).toUpperCase()}`;
    const now = new Date();

    if (!emailService) {
      response.status(503).json({
        success: false,
        code: "email_service_unavailable",
        message: "Serviço de e-mail unificado não inicializado.",
      });
      return;
    }

    try {
      const result = await emailService.sendDiagnostic({
        to: recipient,
        adminName: adminUser?.displayName ?? "Administrador AGM-RM",
        testId,
        timestamp: now,
        details: {
          note: input.note,
          adminId: response.locals.adminId,
        },
      });

      await audit(
        database,
        response.locals.adminId,
        "system_email_diagnostic_sent",
        testId,
        {
          recipient,
          provider: result.provider,
          latencyMs: result.latencyMs,
          success: result.success,
        },
      );

      response.status(200).json({
        success: true,
        testId,
        recipient,
        result,
        message: "E-mail de diagnóstico despachado com sucesso.",
      });
    } catch (error: any) {
      await audit(
        database,
        response.locals.adminId,
        "system_email_diagnostic_failed",
        testId,
        {
          recipient,
          error: error?.message,
        },
      );

      response.status(502).json({
        success: false,
        testId,
        recipient,
        error: error?.message ?? "Falha no envio do teste de diagnóstico.",
      });
    }
  });

  /**
   * Consulta a telemetria do serviço de e-mail e estado do Circuit Breaker.
   */
  router.get("/system/email-status", async (_request, response) => {
    const telemetry = (emailService as ResilientEmailSender)?.getCircuitTelemetry
      ? (emailService as ResilientEmailSender).getCircuitTelemetry()
      : { status: "unknown" };

    const recentOutboxCount = await database
      .collection("email_outbox")
      .countDocuments();

    response.json({
      telemetry,
      outboxPendingOrLogged: recentOutboxCount,
      timestamp: new Date().toISOString(),
    });
  });
}
