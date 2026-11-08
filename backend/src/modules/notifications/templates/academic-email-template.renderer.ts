// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import type {
  AuthOtpEmailInput,
  WelcomeUserEmailInput,
  ProtocolSubmittedEmailInput,
  ProtocolDecidedEmailInput,
  AssignmentDeadlineEmailInput,
  GradePublishedEmailInput,
  DiagnosticEmailInput,
} from "../domain/notification.types.js";

export type RenderedEmail = {
  subject: string;
  html: string;
  text: string;
};

/**
 * Motor de Renderização de Templates de E-mail do Portal Acadêmico AGM-RM.
 * Estrutura 100% responsiva baseada em tabelas XHTML e CSS inline para compatibilidade bulletproof com
 * Outlook, Gmail, Apple Mail, Thunderbird e smartphones Android/iOS.
 */
export class AcademicEmailTemplateRenderer {
  private static readonly PRIMARY_COLOR = "#0B132B"; // Navy Institucional
  private static readonly ACCENT_COLOR = "#2563EB";  // Azul Royal
  private static readonly GOLD_COLOR = "#D97706";    // Âmbar
  private static readonly BG_COLOR = "#F8FAFC";      // Slate Claro
  private static readonly CARD_BG = "#FFFFFF";       // Branco
  private static readonly TEXT_DARK = "#1E293B";     // Slate 800
  private static readonly TEXT_MUTED = "#64748B";    // Slate 500
  private static readonly BORDER_COLOR = "#E2E8F0";  // Borda suave

  /** Renderiza e-mail de código OTP para autenticação 2FA ou recuperação de senha */
  static renderAuthOtp(input: AuthOtpEmailInput): RenderedEmail {
    const isLogin = input.purpose === "login";
    const title = isLogin ? "Código de Acesso em Duas Etapas (2FA)" : "Recuperação de Senha de Acesso";
    const subject = isLogin
      ? "Portal Acadêmico AGM-RM - Código de Acesso"
      : "Portal Acadêmico AGM-RM - Código de Recuperação de Senha";
    const minutes = Math.floor(input.expiresInSeconds / 60);

    const bodyContent = `
      <p style="margin: 0 0 16px 0; font-size: 16px; color: ${this.TEXT_DARK}; line-height: 1.5;">
        Olá, <strong>${this.escape(input.displayName)}</strong>.
      </p>
      <p style="margin: 0 0 24px 0; font-size: 15px; color: ${this.TEXT_MUTED}; line-height: 1.5;">
        Recebemos uma solicitação de <strong>${isLogin ? "acesso seguro à sua conta" : "redefinição de senha"}</strong> no Portal Acadêmico. Utilize o código de verificação abaixo para prosseguir:
      </p>

      <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 24px 0;">
        <tr>
          <td align="center" style="background-color: #F1F5F9; border: 2px dashed #CBD5E1; border-radius: 12px; padding: 20px;">
            <span style="font-family: 'Courier New', Courier, monospace; font-size: 34px; font-weight: 700; letter-spacing: 8px; color: ${this.PRIMARY_COLOR}; display: inline-block;">
              ${input.code}
            </span>
            <div style="margin-top: 8px; font-size: 13px; color: ${this.TEXT_MUTED};">
              ⏳ Válido por <strong>${minutes} minuto(s)</strong>
            </div>
          </td>
        </tr>
      </table>

      <div style="background-color: #FFFBEB; border-left: 4px solid ${this.GOLD_COLOR}; padding: 12px 16px; border-radius: 6px; margin: 24px 0 0 0;">
        <p style="margin: 0; font-size: 13px; color: #92400E; line-height: 1.4;">
          <strong>Atenção de Segurança:</strong> Não compartilhe este código com ninguém. A equipe de suporte da AGM-RM nunca solicitará este código por mensagem ou telefone. Se você não solicitou este procedimento, ignore esta mensagem com segurança.
        </p>
      </div>
    `;

    const text = [
      `Olá, ${input.displayName}.`,
      "",
      `Seu código de ${isLogin ? "acesso" : "recuperação"} é: ${input.code}`,
      `Ele expira em ${minutes} minuto(s).`,
      "",
      "Se você não solicitou esta alteração, ignore esta mensagem.",
      "",
      "— Secretaria & Suporte de TI AGM-RM",
    ].join("\n");

    return {
      subject,
      html: this.wrapLayout(title, bodyContent, "Código de verificação do Portal Acadêmico"),
      text,
    };
  }

  /** Renderiza e-mail de boas-vindas com dados de acesso provisórios */
  static renderWelcomeUser(input: WelcomeUserEmailInput): RenderedEmail {
    const subject = "Bem-vindo ao Portal Acadêmico AGM-RM - Suas Credenciais de Acesso";
    const profileLabel = input.profile === "aluno" ? "Discente" : input.profile === "docente" ? "Docente" : "Administrador";

    const bodyContent = `
      <p style="margin: 0 0 16px 0; font-size: 16px; color: ${this.TEXT_DARK}; line-height: 1.5;">
        Prezado(a) <strong>${this.escape(input.displayName)}</strong>,
      </p>
      <p style="margin: 0 0 20px 0; font-size: 15px; color: ${this.TEXT_MUTED}; line-height: 1.5;">
        Sua conta institucional foi criada com sucesso no <strong>Portal Acadêmico AGM-RM</strong> com o perfil de <strong>${profileLabel}</strong>.
      </p>

      <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 20px 0; background-color: #F8FAFC; border: 1px solid ${this.BORDER_COLOR}; border-radius: 8px;">
        <tr>
          <td style="padding: 16px;">
            <p style="margin: 0 0 8px 0; font-size: 14px; color: ${this.TEXT_DARK};">
              <strong>Identificador / Login:</strong> <code>${this.escape(input.identity)}</code>
            </p>
            ${
              input.temporaryPassword
                ? `<p style="margin: 0 0 8px 0; font-size: 14px; color: ${this.TEXT_DARK};">
                     <strong>Senha Temporária:</strong> <code style="background: #E2E8F0; padding: 2px 6px; border-radius: 4px;">${this.escape(input.temporaryPassword)}</code>
                   </p>`
                : ""
            }
            <p style="margin: 0; font-size: 14px; color: ${this.TEXT_DARK};">
              <strong>Perfil:</strong> ${profileLabel}
            </p>
          </td>
        </tr>
      </table>

      ${
        input.portalUrl
          ? `<p style="margin: 24px 0; text-align: center;">
               <a href="${this.escape(input.portalUrl)}" style="background-color: ${this.ACCENT_COLOR}; color: #FFFFFF; padding: 12px 24px; border-radius: 6px; text-decoration: none; font-weight: 600; display: inline-block;">
                 Acessar Portal Acadêmico
               </a>
             </p>`
          : ""
      }

      <div style="background-color: #EFF6FF; border-left: 4px solid ${this.ACCENT_COLOR}; padding: 12px 16px; border-radius: 6px; margin-top: 20px;">
        <p style="margin: 0; font-size: 13px; color: #1E40AF; line-height: 1.4;">
          <strong>Recomendação de Acesso:</strong> No seu primeiro login, altere sua senha para uma credencial pessoal e ative a Autenticação em Duas Etapas (2FA) na aba de Segurança.
        </p>
      </div>
    `;

    const text = [
      `Prezado(a) ${input.displayName},`,
      "",
      `Sua conta institucional (${profileLabel}) foi criada no Portal Acadêmico AGM-RM.`,
      `Identificador: ${input.identity}`,
      input.temporaryPassword ? `Senha temporária: ${input.temporaryPassword}` : "",
      input.portalUrl ? `Acesso: ${input.portalUrl}` : "",
      "",
      "— Secretaria Geral Acadêmica AGM-RM",
    ].filter(Boolean).join("\n");

    return {
      subject,
      html: this.wrapLayout("Credenciais de Acesso Institucional", bodyContent, "Suas credenciais no Portal AGM-RM"),
      text,
    };
  }

  /** Renderiza confirmação de protocolo discente submetido */
  static renderProtocolSubmitted(input: ProtocolSubmittedEmailInput): RenderedEmail {
    const subject = `Protocolo Registrado [${input.protocolCode}] - Secretaria AGM-RM`;

    const bodyContent = `
      <p style="margin: 0 0 16px 0; font-size: 16px; color: ${this.TEXT_DARK}; line-height: 1.5;">
        Olá, <strong>${this.escape(input.studentName)}</strong>.
      </p>
      <p style="margin: 0 0 20px 0; font-size: 15px; color: ${this.TEXT_MUTED}; line-height: 1.5;">
        Confirmamos o recebimento do seu requerimento estudantil junto à Secretaria Acadêmica. Abaixo constam os dados de registro:
      </p>

      <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 20px 0; background-color: #F8FAFC; border: 1px solid ${this.BORDER_COLOR}; border-radius: 8px;">
        <tr>
          <td style="padding: 16px;">
            <p style="margin: 0 0 8px 0; font-size: 14px; color: ${this.TEXT_DARK};">
              <strong>Número do Protocolo:</strong> <span style="font-family: monospace; font-weight: 700; color: ${this.PRIMARY_COLOR};">${input.protocolCode}</span>
            </p>
            <p style="margin: 0 0 8px 0; font-size: 14px; color: ${this.TEXT_DARK};">
              <strong>Assunto / Requerimento:</strong> ${this.escape(input.requestType)}
            </p>
            ${
              input.targetComponent
                ? `<p style="margin: 0 0 8px 0; font-size: 14px; color: ${this.TEXT_DARK};">
                     <strong>Componente / Disciplina:</strong> ${this.escape(input.targetComponent)}
                   </p>`
                : ""
            }
            <p style="margin: 0 0 8px 0; font-size: 14px; color: ${this.TEXT_DARK};">
              <strong>Status Inicial:</strong> <span style="background-color: #FEF3C7; color: #92400E; padding: 2px 8px; border-radius: 12px; font-size: 12px; font-weight: 600;">Aguardando Parecer</span>
            </p>
            <p style="margin: 0; font-size: 14px; color: ${this.TEXT_DARK};">
              <strong>Prazo Médio de Análise:</strong> ${input.estimatedDays ?? 5} dias úteis
            </p>
          </td>
        </tr>
      </table>

      <p style="margin: 16px 0; font-size: 14px; color: ${this.TEXT_MUTED}; line-height: 1.4;">
        Você receberá uma nova notificação por e-mail assim que o parecer oficial for lavrado pela Secretaria.
      </p>
    `;

    const text = [
      `Olá, ${input.studentName}.`,
      "",
      `Seu protocolo ${input.protocolCode} foi registrado com sucesso.`,
      `Requerimento: ${input.requestType}`,
      input.targetComponent ? `Componente: ${input.targetComponent}` : "",
      "Status: Aguardando Parecer",
      `Prazo médio de análise: ${input.estimatedDays ?? 5} dias úteis.`,
      "",
      "— Secretaria Geral Acadêmica AGM-RM",
    ].filter(Boolean).join("\n");

    return {
      subject,
      html: this.wrapLayout(`Confirmação de Requerimento (${input.protocolCode})`, bodyContent, "Comprovante de protocolo acadêmico"),
      text,
    };
  }

  /** Renderiza e-mail com decisão oficial sobre protocolo */
  static renderProtocolDecided(input: ProtocolDecidedEmailInput): RenderedEmail {
    const statusLabel = input.approved ? "DEFERIDO" : "INDEFERIDO";
    const statusColor = input.approved ? "#15803D" : "#B91C1C";
    const statusBg = input.approved ? "#DCFCE7" : "#FEE2E2";
    const subject = `Resultado de Requerimento [${input.protocolCode}] - ${statusLabel}`;

    const bodyContent = `
      <p style="margin: 0 0 16px 0; font-size: 16px; color: ${this.TEXT_DARK}; line-height: 1.5;">
        Prezado(a) <strong>${this.escape(input.studentName)}</strong>,
      </p>
      <p style="margin: 0 0 20px 0; font-size: 15px; color: ${this.TEXT_MUTED}; line-height: 1.5;">
        A Secretaria Acadêmica concluiu a análise do seu requerimento <strong>${input.protocolCode}</strong>.
      </p>

      <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 20px 0;">
        <tr>
          <td align="center" style="background-color: ${statusBg}; border: 2px solid ${statusColor}; border-radius: 8px; padding: 16px;">
            <span style="font-size: 20px; font-weight: 700; color: ${statusColor};">
              PARECER: ${statusLabel}
            </span>
          </td>
        </tr>
      </table>

      <div style="background-color: #F8FAFC; border: 1px solid ${this.BORDER_COLOR}; border-radius: 8px; padding: 16px; margin: 20px 0;">
        <p style="margin: 0 0 8px 0; font-size: 13px; font-weight: 700; color: ${this.TEXT_MUTED}; text-transform: uppercase;">
          Nota Técnica / Despacho Oficial:
        </p>
        <p style="margin: 0; font-size: 15px; color: ${this.TEXT_DARK}; line-height: 1.5; font-style: italic;">
          "${this.escape(input.decisionNote)}"
        </p>
        <p style="margin: 12px 0 0 0; font-size: 13px; color: ${this.TEXT_MUTED};">
          Despachado por: <strong>${this.escape(input.signedBy)}</strong>
        </p>
      </div>

      <p style="margin: 16px 0 0 0; font-size: 13px; color: ${this.TEXT_MUTED};">
        Caso discorde do resultado, você pode entrar em contato com a Secretaria ou solicitar reconsideração regimental conforme as normas acadêmicas vigentes.
      </p>
    `;

    const text = [
      `Prezado(a) ${input.studentName},`,
      "",
      `O protocolo ${input.protocolCode} foi avaliado: ${statusLabel}.`,
      `Parecer: ${input.decisionNote}`,
      `Assinado por: ${input.signedBy}`,
      "",
      "— Secretaria Geral Acadêmica AGM-RM",
    ].join("\n");

    return {
      subject,
      html: this.wrapLayout(`Parecer do Requerimento (${input.protocolCode})`, bodyContent, `Resultado: ${statusLabel}`),
      text,
    };
  }

  /** Renderiza lembrete de prazo de entrega iminente (24h) */
  static renderAssignmentDeadline(input: AssignmentDeadlineEmailInput): RenderedEmail {
    const subject = `Lembrete de Entrega: ${input.assignmentTitle} - ${input.disciplineName}`;
    const dateFormatted = typeof input.dueDate === "string" ? input.dueDate : input.dueDate.toLocaleString("pt-BR");

    const bodyContent = `
      <p style="margin: 0 0 16px 0; font-size: 16px; color: ${this.TEXT_DARK}; line-height: 1.5;">
        Olá, <strong>${this.escape(input.studentName)}</strong>.
      </p>
      <p style="margin: 0 0 20px 0; font-size: 15px; color: ${this.TEXT_MUTED}; line-height: 1.5;">
        Este é um lembrete automático de que o prazo de submissão da atividade abaixo se encerra em breve:
      </p>

      <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 20px 0; background-color: #FEF3C7; border-left: 4px solid #D97706; border-radius: 4px;">
        <tr>
          <td style="padding: 16px;">
            <p style="margin: 0 0 6px 0; font-size: 15px; font-weight: 700; color: #92400E;">
              ${this.escape(input.assignmentTitle)}
            </p>
            <p style="margin: 0 0 6px 0; font-size: 14px; color: #78350F;">
              Disciplina: ${this.escape(input.disciplineName)}
            </p>
            <p style="margin: 0; font-size: 14px; font-weight: 700; color: #B45309;">
              Prazo Final: ${dateFormatted}
            </p>
          </td>
        </tr>
      </table>

      ${
        input.submissionUrl
          ? `<p style="margin: 24px 0; text-align: center;">
               <a href="${this.escape(input.submissionUrl)}" style="background-color: ${this.PRIMARY_COLOR}; color: #FFFFFF; padding: 12px 24px; border-radius: 6px; text-decoration: none; font-weight: 600; display: inline-block;">
                 Enviar Atividade no Portal
               </a>
             </p>`
          : ""
      }
    `;

    const text = [
      `Olá, ${input.studentName}.`,
      "",
      `Lembrete de entrega para: ${input.assignmentTitle}`,
      `Disciplina: ${input.disciplineName}`,
      `Prazo: ${dateFormatted}`,
      "",
      "— Coordenação e Corpo Docente AGM-RM",
    ].join("\n");

    return {
      subject,
      html: this.wrapLayout("Prazo de Entrega Improrrogável", bodyContent, "Lembrete de atividade acadêmica"),
      text,
    };
  }

  /** Renderiza notificação de nota e feedback */
  static renderGradePublished(input: GradePublishedEmailInput): RenderedEmail {
    const subject = `Nota Disponível: ${input.assignmentTitle} - ${input.disciplineName}`;

    const bodyContent = `
      <p style="margin: 0 0 16px 0; font-size: 16px; color: ${this.TEXT_DARK}; line-height: 1.5;">
        Olá, <strong>${this.escape(input.studentName)}</strong>.
      </p>
      <p style="margin: 0 0 20px 0; font-size: 15px; color: ${this.TEXT_MUTED}; line-height: 1.5;">
        O docente concluiu a avaliação da sua atividade <strong>${this.escape(input.assignmentTitle)}</strong> da disciplina <strong>${this.escape(input.disciplineName)}</strong>.
      </p>

      <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 20px 0;">
        <tr>
          <td align="center" style="background-color: #F1F5F9; border-radius: 8px; padding: 20px;">
            <span style="font-size: 14px; color: ${this.TEXT_MUTED}; text-transform: uppercase; font-weight: 600;">Nota Atribuída</span>
            <div style="font-size: 38px; font-weight: 700; color: ${this.PRIMARY_COLOR}; margin-top: 4px;">
              ${input.grade.toFixed(1)}
            </div>
          </td>
        </tr>
      </table>

      ${
        input.feedback
          ? `<div style="background-color: #F8FAFC; border: 1px solid ${this.BORDER_COLOR}; border-radius: 8px; padding: 16px; margin: 20px 0;">
               <p style="margin: 0 0 6px 0; font-size: 13px; font-weight: 700; color: ${this.TEXT_MUTED};">Feedback do Professor:</p>
               <p style="margin: 0; font-size: 14px; color: ${this.TEXT_DARK}; line-height: 1.5;">"${this.escape(input.feedback)}"</p>
             </div>`
          : ""
      }
    `;

    const text = [
      `Olá, ${input.studentName}.`,
      "",
      `Sua avaliação em "${input.assignmentTitle}" (${input.disciplineName}) foi publicada.`,
      `Nota: ${input.grade.toFixed(1)}`,
      input.feedback ? `Feedback: ${input.feedback}` : "",
      "",
      "— Coordenação e Docentes AGM-RM",
    ].filter(Boolean).join("\n");

    return {
      subject,
      html: this.wrapLayout("Publicação de Avaliação", bodyContent, "Nota e devolutiva de atividade"),
      text,
    };
  }

  /** Renderiza e-mail diagnóstico de verificação do sistema */
  static renderDiagnostic(input: DiagnosticEmailInput): RenderedEmail {
    const subject = `Diagnóstico do Sistema de E-mail [${input.testId}] - AGM-RM`;

    const bodyContent = `
      <p style="margin: 0 0 16px 0; font-size: 16px; color: ${this.TEXT_DARK}; line-height: 1.5;">
        Prezado Administrador <strong>${this.escape(input.adminName)}</strong>,
      </p>
      <p style="margin: 0 0 20px 0; font-size: 15px; color: ${this.TEXT_MUTED}; line-height: 1.5;">
        Este é um e-mail de teste disparado pela suíte diagnóstica do Portal Acadêmico AGM-RM para aferição de conectividade e contorno de firewalls.
      </p>

      <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 20px 0; background-color: #F8FAFC; border: 1px solid ${this.BORDER_COLOR}; border-radius: 8px;">
        <tr>
          <td style="padding: 16px;">
            <p style="margin: 0 0 8px 0; font-size: 14px; color: ${this.TEXT_DARK};">
              <strong>ID do Teste:</strong> <code>${input.testId}</code>
            </p>
            <p style="margin: 0 0 8px 0; font-size: 14px; color: ${this.TEXT_DARK};">
              <strong>Data / Hora do Servidor:</strong> ${input.timestamp.toISOString()}
            </p>
            <p style="margin: 0; font-size: 14px; color: ${this.TEXT_DARK};">
              <strong>Status:</strong> <span style="color: #15803D; font-weight: 700;">CONECTIVIDADE VERIFICADA</span>
            </p>
          </td>
        </tr>
      </table>
    `;

    const text = [
      `Teste de Diagnóstico AGM-RM [${input.testId}]`,
      `Admin: ${input.adminName}`,
      `Data: ${input.timestamp.toISOString()}`,
      "Status: Conectividade verificada com sucesso.",
    ].join("\n");

    return {
      subject,
      html: this.wrapLayout("Diagnóstico de Conectividade", bodyContent, "Teste de disparo transacional"),
      text,
    };
  }

  /** Envolve o conteúdo em layout HTML responsivo institucional */
  private static wrapLayout(heading: string, bodyContent: string, preheader: string): string {
    return `<!DOCTYPE html>
<html lang="pt-BR" xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <title>${this.escape(heading)}</title>
  <!--[if mso]>
  <style type="text/css">
    body, table, td {font-family: Arial, Helvetica, sans-serif !important;}
  </style>
  <![endif]-->
</head>
<body style="margin: 0; padding: 0; background-color: ${this.BG_COLOR}; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; -webkit-font-smoothing: antialiased;">
  <!-- Preheader oculto para clientes de e-mail -->
  <div style="display: none; font-size: 1px; color: #fff; line-height: 1px; max-height: 0px; max-width: 0px; opacity: 0; overflow: hidden;">
    ${this.escape(preheader)} &zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;
  </div>

  <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: ${this.BG_COLOR}; min-height: 100vh;">
    <tr>
      <td align="center" style="padding: 32px 16px;">
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; background-color: ${this.CARD_BG}; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -2px rgba(0, 0, 0, 0.05); overflow: hidden; border: 1px solid ${this.BORDER_COLOR};">
          
          <!-- Cabeçalho Institucional -->
          <tr>
            <td style="background-color: ${this.PRIMARY_COLOR}; padding: 24px 32px; text-align: left;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td>
                    <div style="font-size: 20px; font-weight: 800; letter-spacing: 0.5px; color: #FFFFFF; text-transform: uppercase;">
                      PORTAL ACADÊMICO
                    </div>
                    <div style="font-size: 13px; font-weight: 500; color: ${this.GOLD_COLOR}; letter-spacing: 1px; margin-top: 2px;">
                      INSTITUIÇÃO AGM-RM
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Faixa do Título -->
          <tr>
            <td style="padding: 24px 32px 8px 32px;">
              <h2 style="margin: 0; font-size: 20px; font-weight: 700; color: ${this.TEXT_DARK};">
                ${this.escape(heading)}
              </h2>
            </td>
          </tr>

          <!-- Corpo do Conteúdo -->
          <tr>
            <td style="padding: 16px 32px 32px 32px;">
              ${bodyContent}
            </td>
          </tr>

          <!-- Rodapé Institucional -->
          <tr>
            <td style="background-color: #F1F5F9; padding: 20px 32px; border-top: 1px solid ${this.BORDER_COLOR}; text-align: center;">
              <p style="margin: 0 0 6px 0; font-size: 12px; color: ${this.TEXT_MUTED}; line-height: 1.4;">
                Este é um e-mail transacional gerado automaticamente pelo Portal Acadêmico AGM-RM. Por favor, não responda diretamente a este remetente.
              </p>
              <p style="margin: 0; font-size: 11px; color: #94A3B8;">
                © 2026 AGM-RM Educação Superior. Todos os direitos reservados.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
  }

  private static escape(str: string): string {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }
}
