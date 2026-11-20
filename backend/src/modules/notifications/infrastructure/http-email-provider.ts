// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import type { BaseEmailInput, EmailDeliveryResult } from "../domain/notification.types.js";

export type HttpEmailProviderConfig = {
  resendApiKey?: string;
  brevoApiKey?: string;
  gmailWebhookUrl?: string;
  defaultSender: string;
};

/**
 * Provedor de E-mail via HTTPS REST (Porta 443).
 * Opera em camada HTTP de aplicação, sendo 100% imune a bloqueios de portas SMTP (25, 465, 587)
 * impostos por firewalls institucionais (eduroam, campus labs, proxies ou cloud egress filters).
 */
export class HttpEmailProvider {
  constructor(private readonly config: HttpEmailProviderConfig) {}

  isConfigured(): boolean {
    return Boolean(
      this.config.resendApiKey ||
      this.config.brevoApiKey ||
      this.config.gmailWebhookUrl
    );
  }

  async send(input: BaseEmailInput): Promise<EmailDeliveryResult> {
    const startTime = Date.now();
    const fromAddress = input.from || this.config.defaultSender;
    const errors: string[] = [];

    // 1. Tenta Resend API (se configurado)
    if (this.config.resendApiKey) {
      try {
        const response = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${this.config.resendApiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: fromAddress,
            to: [input.to],
            subject: input.subject,
            html: input.html,
            text: input.text,
          }),
          signal: AbortSignal.timeout(8000),
        });

        if (response.ok) {
          const data = (await response.json()) as { id?: string };
          return {
            success: true,
            provider: "resend",
            deliveredExternally: true,
            messageId: data.id ?? "resend-ok",
            latencyMs: Date.now() - startTime,
          };
        }
        const errBody = await response.text().catch(() => "");
        const msg = `Resend retornou HTTP ${response.status}${errBody ? `: ${errBody.slice(0, 160)}` : ""}`;
        errors.push(msg);
        console.warn(`[http-email-provider] ${msg}`);
      } catch (err: any) {
        const msg = `Falha ao enviar via Resend: ${err?.message ?? "erro desconhecido"}`;
        errors.push(msg);
        console.warn(`[http-email-provider] ${msg}`);
      }
    }

    // 2. Tenta Brevo API (se configurado)
    if (this.config.brevoApiKey) {
      try {
        const response = await fetch("https://api.brevo.com/v3/smtp/email", {
          method: "POST",
          headers: {
            "api-key": this.config.brevoApiKey,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            sender: { email: fromAddress, name: "Portal Acadêmico AGM-RM" },
            to: [{ email: input.to }],
            subject: input.subject,
            htmlContent: input.html,
            textContent: input.text,
          }),
          signal: AbortSignal.timeout(8000),
        });

        if (response.ok) {
          const data = (await response.json()) as { messageId?: string };
          return {
            success: true,
            provider: "brevo",
            deliveredExternally: true,
            messageId: data.messageId ?? "brevo-ok",
            latencyMs: Date.now() - startTime,
          };
        }
        const errBody = await response.text().catch(() => "");
        const msg = `Brevo retornou HTTP ${response.status}${errBody ? `: ${errBody.slice(0, 160)}` : ""}`;
        errors.push(msg);
        console.warn(`[http-email-provider] ${msg}`);
      } catch (err: any) {
        const msg = `Falha ao enviar via Brevo: ${err?.message ?? "erro desconhecido"}`;
        errors.push(msg);
        console.warn(`[http-email-provider] ${msg}`);
      }
    }

    // 3. Tenta Webhook Relay / Google Apps Script (se configurado)
    if (this.config.gmailWebhookUrl) {
      try {
        const response = await fetch(this.config.gmailWebhookUrl, {
          method: "POST",
          redirect: "follow",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            to: input.to,
            subject: input.subject,
            html: input.html,
            text: input.text,
            from: fromAddress,
            sentAt: new Date().toISOString(),
          }),
          signal: AbortSignal.timeout(12000),
        });

        const rawBody = await response.text().catch(() => "");
        const validationError = HttpEmailProvider.validateWebhookResponse(response.status, rawBody);
        if (!validationError) {
          return {
            success: true,
            provider: "webhook",
            deliveredExternally: true,
            messageId: `webhook-${Date.now()}`,
            latencyMs: Date.now() - startTime,
          };
        }
        errors.push(validationError);
        console.warn(`[http-email-provider] ${validationError}`);
      } catch (err: any) {
        const msg = `Falha ao enviar via Webhook: ${err?.message ?? "erro desconhecido"}`;
        errors.push(msg);
        console.warn(`[http-email-provider] ${msg}`);
      }
    }

    throw new Error(
      errors.length > 0
        ? `Nenhum provedor HTTPS REST respondeu com sucesso (${errors.join(" | ")})`
        : "Nenhum provedor HTTPS REST configurado.",
    );
  }

  /** Valida HTTP status e corpo da resposta (Google Apps Script retorna HTTP 200 mesmo em erros). */
  static validateWebhookResponse(status: number, rawBody: string): string | null {
    const trimmed = rawBody.trim();
    if (status < 200 || status >= 300) {
      return `Webhook retornou HTTP ${status}${trimmed ? `: ${trimmed.slice(0, 160)}` : ""}`;
    }

    const lower = trimmed.toLowerCase();
    if (
      lower.includes("<!doctype") ||
      lower.includes("<html") ||
      lower.includes("accounts.google.com") ||
      lower.includes("não foi possível abrir o arquivo") ||
      lower.includes("função de script não encontrada") ||
      lower.includes("script function not found") ||
      lower.includes("errormessage")
    ) {
      return `Webhook retornou página/erro inválido em HTTP ${status}: ${trimmed.slice(0, 160)}`;
    }

    if (trimmed.startsWith("{")) {
      try {
        const parsed = JSON.parse(trimmed) as Record<string, unknown>;
        const errField = parsed.error ?? parsed.errorMessage;
        if (errField !== undefined && errField !== null && String(errField).trim() !== "") {
          return `Webhook reportou erro no corpo: ${String(errField)}`;
        }
        if (parsed.ok === false || parsed.success === false) {
          return `Webhook retornou success=false: ${trimmed.slice(0, 160)}`;
        }
        if (typeof parsed.status === "number" && parsed.status >= 400) {
          return `Webhook retornou status interno ${parsed.status}: ${trimmed.slice(0, 160)}`;
        }
      } catch {
        // Ignora texto que começa com '{' mas não é JSON válido caso não tenha marcadores HTML de erro
      }
    }

    return null;
  }
}
