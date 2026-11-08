// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import nodemailer, { type Transporter } from "nodemailer";
import type { Db } from "mongodb";
import { AuthError } from "../../../shared/auth-error.js";
import type { Environment } from "../../../config/environment.js";
import type { RecoveryEmailSender } from "../../auth/domain/auth.types.js";
import type {
  AuthOtpEmailInput,
  WelcomeUserEmailInput,
  ProtocolSubmittedEmailInput,
  ProtocolDecidedEmailInput,
  AssignmentDeadlineEmailInput,
  GradePublishedEmailInput,
  DiagnosticEmailInput,
  BaseEmailInput,
  EmailDeliveryResult,
  UnifiedEmailService,
} from "../domain/notification.types.js";
import { AcademicEmailTemplateRenderer } from "../templates/academic-email-template.renderer.js";
import { HttpEmailProvider } from "./http-email-provider.js";
import { LocalOutboxEmailProvider } from "./local-outbox-email-provider.js";

export type CircuitBreakerState = "CLOSED" | "OPEN" | "HALF_OPEN";

/**
 * Disparador de e-mails resiliente e independente de redes e firewalls.
 * Implementa RecoveryEmailSender (para 100% de retrocompatibilidade com o módulo de autenticação)
 * e UnifiedEmailService (para abranger todos os serviços acadêmicos do portal).
 */
export class ResilientEmailSender implements RecoveryEmailSender, UnifiedEmailService {
  private readonly smtpTransporter?: Transporter;
  private readonly senderAddress: string;
  private readonly httpProvider: HttpEmailProvider;
  private readonly outboxFallback: LocalOutboxEmailProvider;
  private readonly fallbackMode: "outbox" | "strict";

  // Circuit Breaker para evitar hangs em redes com portas bloqueadas
  private circuitState: CircuitBreakerState = "CLOSED";
  private consecutiveFailures = 0;
  private nextAttemptTimestamp = 0;
  private static readonly MAX_FAILURES_BEFORE_OPEN = 3;
  private static readonly CIRCUIT_COOLDOWN_MS = 60_000; // 60 segundos

  constructor(environment: Environment, database?: Db) {
    this.fallbackMode = environment.emailProviders.fallbackMode;
    this.senderAddress = environment.smtp?.from || "portal.academico@agmrm.edu.br";

    // Tier 1: Configuração do Nodemailer com guardas rigorosas de timeout
    if (environment.smtp) {
      this.smtpTransporter = nodemailer.createTransport({
        host: environment.smtp.host,
        port: environment.smtp.port,
        secure: environment.smtp.secure,
        auth: {
          user: environment.smtp.user,
          pass: environment.smtp.password,
        },
        connectionTimeout: 4000, // Máx 4s para handshake TCP (evita silent drop em firewalls)
        greetingTimeout: 4000,   // Máx 4s para banner SMTP 220
        socketTimeout: 5000,     // Máx 5s de inatividade
        dnsTimeout: 3000,        // Máx 3s para resolução DNS
        disableFileAccess: true,
        disableUrlAccess: true,
      } as any);
    }

    // Tier 2: Provedor HTTPS REST (Porta 443 — Imune a bloqueios de firewall)
    this.httpProvider = new HttpEmailProvider({
      resendApiKey: environment.emailProviders.resendApiKey,
      brevoApiKey: environment.emailProviders.brevoApiKey,
      gmailWebhookUrl: environment.emailProviders.gmailWebhookUrl,
      defaultSender: this.senderAddress,
    });

    // Tier 3: Provedor Outbox Local & Visualizador no Terminal (Zero Crash)
    this.outboxFallback = new LocalOutboxEmailProvider(database);
  }

  /**
   * Verifica se o serviço de e-mail está disponível.
   * Se configurado modo 'strict' e nenhum provedor existir, lança 503.
   * No modo padrão 'outbox', o serviço está sempre disponível (resiliência garantida).
   */
  ensureAvailable(): void {
    const hasSmtp = Boolean(this.smtpTransporter);
    const hasHttp = this.httpProvider.isConfigured();
    if (this.fallbackMode === "strict" && !hasSmtp && !hasHttp) {
      throw new AuthError(
        503,
        "recovery_email_unavailable",
        "O envio de códigos não está configurado neste ambiente.",
      );
    }
  }

  /**
   * Implementação do contrato clássico de autenticação (RecoveryEmailSender).
   * Mantém compatibilidade integral com AuthService e PasswordRecoveryService.
   */
  async sendRecoveryCode(input: {
    to: string;
    displayName: string;
    code: string;
    expiresInSeconds: number;
    purpose?: "login" | "recovery";
  }): Promise<void> {
    const rendered = AcademicEmailTemplateRenderer.renderAuthOtp(input);
    const result = await this.dispatchResilient(
      {
        to: input.to,
        subject: rendered.subject,
        html: rendered.html,
        text: rendered.text,
        from: this.senderAddress,
      },
      { code: input.code, purpose: input.purpose ?? "recovery" },
    );

    if (!result.success) {
      throw new AuthError(
        503,
        "recovery_email_failed",
        "Falha ao despachar código de segurança.",
      );
    }
  }

  // ─── IMPLEMENTAÇÃO DOS SERVIÇOS ACADÊMICOS UNIFICADOS ──────────────────────

  async sendAuthOtp(input: AuthOtpEmailInput): Promise<EmailDeliveryResult> {
    const rendered = AcademicEmailTemplateRenderer.renderAuthOtp(input);
    return this.dispatchResilient(
      {
        to: input.to,
        subject: rendered.subject,
        html: rendered.html,
        text: rendered.text,
        from: this.senderAddress,
      },
      { code: input.code, purpose: input.purpose },
    );
  }

  async sendWelcomeUser(input: WelcomeUserEmailInput): Promise<EmailDeliveryResult> {
    const rendered = AcademicEmailTemplateRenderer.renderWelcomeUser(input);
    return this.dispatchResilient({
      to: input.to,
      subject: rendered.subject,
      html: rendered.html,
      text: rendered.text,
      from: this.senderAddress,
    });
  }

  async sendProtocolSubmitted(input: ProtocolSubmittedEmailInput): Promise<EmailDeliveryResult> {
    const rendered = AcademicEmailTemplateRenderer.renderProtocolSubmitted(input);
    return this.dispatchResilient({
      to: input.to,
      subject: rendered.subject,
      html: rendered.html,
      text: rendered.text,
      from: this.senderAddress,
    });
  }

  async sendProtocolDecided(input: ProtocolDecidedEmailInput): Promise<EmailDeliveryResult> {
    const rendered = AcademicEmailTemplateRenderer.renderProtocolDecided(input);
    return this.dispatchResilient({
      to: input.to,
      subject: rendered.subject,
      html: rendered.html,
      text: rendered.text,
      from: this.senderAddress,
    });
  }

  async sendAssignmentDeadline(input: AssignmentDeadlineEmailInput): Promise<EmailDeliveryResult> {
    const rendered = AcademicEmailTemplateRenderer.renderAssignmentDeadline(input);
    return this.dispatchResilient({
      to: input.to,
      subject: rendered.subject,
      html: rendered.html,
      text: rendered.text,
      from: this.senderAddress,
    });
  }

  async sendGradePublished(input: GradePublishedEmailInput): Promise<EmailDeliveryResult> {
    const rendered = AcademicEmailTemplateRenderer.renderGradePublished(input);
    return this.dispatchResilient({
      to: input.to,
      subject: rendered.subject,
      html: rendered.html,
      text: rendered.text,
      from: this.senderAddress,
    });
  }

  async sendDiagnostic(input: DiagnosticEmailInput): Promise<EmailDeliveryResult> {
    const rendered = AcademicEmailTemplateRenderer.renderDiagnostic(input);
    return this.dispatchResilient({
      to: input.to,
      subject: rendered.subject,
      html: rendered.html,
      text: rendered.text,
      from: this.senderAddress,
    });
  }

  async sendRaw(input: BaseEmailInput): Promise<EmailDeliveryResult> {
    return this.dispatchResilient(input);
  }

  // ─── NÚCLEO DE RESILIÊNCIA E FAILOVER MULTITRANSPORTE ──────────────────────

  private async dispatchResilient(
    input: BaseEmailInput,
    meta?: { code?: string; purpose?: string },
  ): Promise<EmailDeliveryResult> {
    const errorTrail: string[] = [];
    const startTime = Date.now();

    // 1. TIER 1: SMTP Transporter (Portas 465 / 587)
    if (this.canAttemptSmtp()) {
      try {
        const info = await this.smtpTransporter!.sendMail({
          from: input.from || this.senderAddress,
          to: input.to,
          subject: input.subject,
          text: input.text,
          html: input.html,
        });

        this.recordSmtpSuccess();
        return {
          success: true,
          provider: "smtp",
          messageId: info.messageId,
          latencyMs: Date.now() - startTime,
        };
      } catch (err: any) {
        const errorMsg = `SMTP [${err?.code ?? "UNKNOWN"}]: ${err?.message ?? "Falha de envio"}`;
        errorTrail.push(errorMsg);
        this.recordSmtpFailure(errorMsg);
        console.warn(`[resilient-email] SMTP falhou (${errorMsg}). Acionando Tier 2 (HTTPS REST)...`);
      }
    } else if (this.circuitState === "OPEN") {
      errorTrail.push(`Circuit Breaker OPEN: SMTP ignorado temporariamente (cooldown até ${new Date(this.nextAttemptTimestamp).toISOString()})`);
    }

    // 2. TIER 2: HTTPS REST Provider (Porta 443 — Imune a restrições de firewall)
    if (this.httpProvider.isConfigured()) {
      try {
        const httpResult = await this.httpProvider.send(input);
        return {
          ...httpResult,
          latencyMs: Date.now() - startTime,
        };
      } catch (err: any) {
        const errorMsg = `HTTPS REST: ${err?.message ?? "Falha de envio"}`;
        errorTrail.push(errorMsg);
        console.warn(`[resilient-email] HTTPS falhou (${errorMsg}). Acionando Tier 3 (Outbox)...`);
      }
    }

    // 3. TIER 3: Local Outbox & Console Banner (Zero Crash garantido)
    return this.outboxFallback.save(input, {
      code: meta?.code,
      purpose: meta?.purpose,
      errorTrail,
    });
  }

  // ─── GERENCIAMENTO DO CIRCUIT BREAKER ─────────────────────────────────────

  private canAttemptSmtp(): boolean {
    if (!this.smtpTransporter) return false;
    const now = Date.now();

    if (this.circuitState === "CLOSED") return true;

    if (this.circuitState === "OPEN") {
      if (now >= this.nextAttemptTimestamp) {
        this.circuitState = "HALF_OPEN";
        return true;
      }
      return false;
    }

    // HALF_OPEN: permite 1 tentativa de teste
    return true;
  }

  private recordSmtpSuccess(): void {
    this.consecutiveFailures = 0;
    this.circuitState = "CLOSED";
  }

  private recordSmtpFailure(reason: string): void {
    this.consecutiveFailures++;
    if (this.consecutiveFailures >= ResilientEmailSender.MAX_FAILURES_BEFORE_OPEN) {
      this.circuitState = "OPEN";
      this.nextAttemptTimestamp = Date.now() + ResilientEmailSender.CIRCUIT_COOLDOWN_MS;
      console.warn(`[resilient-email] Circuit Breaker SMTP ABERTO após ${this.consecutiveFailures} falhas consecutivas. Motivo: ${reason}`);
    }
  }

  /** Retorna a telemetria do Circuit Breaker para a rota de diagnóstico */
  getCircuitTelemetry() {
    return {
      state: this.circuitState,
      consecutiveFailures: this.consecutiveFailures,
      smtpConfigured: Boolean(this.smtpTransporter),
      httpConfigured: this.httpProvider.isConfigured(),
      nextAttemptAt: this.nextAttemptTimestamp > 0 ? new Date(this.nextAttemptTimestamp).toISOString() : null,
    };
  }
}
