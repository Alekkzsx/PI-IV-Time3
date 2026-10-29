// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
import nodemailer, { type Transporter } from "nodemailer";
import { AuthError } from "../../../shared/auth-error.js";
import type { Environment } from "../../../config/environment.js";
import type { RecoveryEmailSender } from "../domain/auth.types.js";

/** Envia códigos de recuperação usando SMTP configurado somente no backend. */
export class SmtpRecoveryEmailSender implements RecoveryEmailSender {
  private readonly transporter?: Transporter;
  private readonly senderAddress?: string;

  constructor(configuration: Environment["smtp"]) {
    if (configuration) {
      this.senderAddress = configuration.from;
      this.transporter = nodemailer.createTransport({
        host: configuration.host,
        port: configuration.port,
        secure: configuration.secure,
        auth: {
          user: configuration.user,
          pass: configuration.password,
        },
        disableFileAccess: true,
        disableUrlAccess: true,
      });
    }
  }

  async sendRecoveryCode(input: {
    to: string;
    displayName: string;
    code: string;
    expiresInSeconds: number;
  }): Promise<void> {
    if (!this.transporter) {
      throw new AuthError(
        503,
        "recovery_email_unavailable",
        "O envio de recuperação não está configurado neste ambiente.",
      );
    }

    await this.transporter.sendMail({
      from: this.senderAddress,
      to: input.to,
      subject: "Portal Acadêmico - Código de recuperação",
      text: [
        `Olá, ${input.displayName}.`,
        `Seu código de recuperação é ${input.code}.`,
        `Ele expira em ${Math.floor(input.expiresInSeconds / 60)} minuto(s).`,
        "Se você não solicitou esta alteração, ignore esta mensagem.",
      ].join("\n"),
    });
  }
}
