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
          signal: AbortSignal.timeout(5000),
        });

        if (response.ok) {
          const data = (await response.json()) as { id?: string };
          return {
            success: true,
            provider: "resend",
            messageId: data.id ?? "resend-ok",
            latencyMs: Date.now() - startTime,
          };
        }
        console.warn(`[http-email-provider] Resend retornou HTTP ${response.status}`);
      } catch (err: any) {
        console.warn(`[http-email-provider] Falha ao enviar via Resend: ${err?.message}`);
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
          signal: AbortSignal.timeout(5000),
        });

        if (response.ok) {
          const data = (await response.json()) as { messageId?: string };
          return {
            success: true,
            provider: "brevo",
            messageId: data.messageId ?? "brevo-ok",
            latencyMs: Date.now() - startTime,
          };
        }
        console.warn(`[http-email-provider] Brevo retornou HTTP ${response.status}`);
      } catch (err: any) {
        console.warn(`[http-email-provider] Falha ao enviar via Brevo: ${err?.message}`);
      }
    }

    // 3. Tenta Webhook Relay / Google Apps Script (se configurado)
    if (this.config.gmailWebhookUrl) {
      try {
        const response = await fetch(this.config.gmailWebhookUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            to: input.to,
            subject: input.subject,
            html: input.html,
            text: input.text,
            from: fromAddress,
            sentAt: new Date().toISOString(),
          }),
          signal: AbortSignal.timeout(5000),
        });

        if (response.ok) {
          return {
            success: true,
            provider: "webhook",
            messageId: `webhook-${Date.now()}`,
            latencyMs: Date.now() - startTime,
          };
        }
        console.warn(`[http-email-provider] Webhook retornou HTTP ${response.status}`);
      } catch (err: any) {
        console.warn(`[http-email-provider] Falha ao enviar via Webhook: ${err?.message}`);
      }
    }

    throw new Error("Nenhum provedor HTTPS REST respondeu com sucesso.");
  }
}
