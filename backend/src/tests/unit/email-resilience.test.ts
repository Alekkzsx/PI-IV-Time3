// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import assert from "node:assert/strict";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { describe, it, beforeEach } from "node:test";
import {
  AcademicEmailTemplateRenderer,
  HttpEmailProvider,
  LocalOutboxEmailProvider,
  ResilientEmailSender,
} from "../../modules/notifications/index.js";
import type { Environment } from "../../config/environment.js";

const mockEnvironment: Environment = {
  nodeEnv: "test",
  port: 3001,
  corsOrigins: ["http://localhost:5000"],
  allowLanCors: false,
  mongoUri: "mongodb://127.0.0.1:27017",
  mongoDatabase: "test_db",
  jwtSecret: "test_jwt_secret_with_minimum_length_32_characters",
  internalServiceSecret: "test_internal_secret_with_minimum_length_32_chars",
  otpSecret: "test_otp_secret_with_minimum_length_32_characters",
  jwtTtl: "15m",
  otpTtlSeconds: 300,
  otpMaxAttempts: 3,
  emailProviders: {
    fallbackMode: "outbox",
  },
  smtp: undefined,
};

describe("AcademicEmailTemplateRenderer", () => {
  it("renders Auth OTP email with HTML layout, security badge and plain text", () => {
    const rendered = AcademicEmailTemplateRenderer.renderAuthOtp({
      to: "aluno@agmrm.edu.br",
      displayName: "Lucas Prado",
      code: "749201",
      expiresInSeconds: 300,
      purpose: "recovery",
    });

    assert.ok(rendered.subject.includes("Código de Recuperação"));
    assert.ok(rendered.html.includes("749201"));
    assert.ok(rendered.html.includes("Lucas Prado"));
    assert.ok(rendered.html.includes("5 minuto(s)"));
    assert.ok(rendered.text.includes("749201"));
  });

  it("renders Welcome User email with temporary credentials and CTA", () => {
    const rendered = AcademicEmailTemplateRenderer.renderWelcomeUser({
      to: "novo.aluno@agmrm.edu.br",
      displayName: "Helena Bittencourt",
      identity: "RA-2026-999",
      profile: "aluno",
      temporaryPassword: "temp-pass-1234",
      portalUrl: "http://localhost:5000",
    });

    assert.ok(rendered.subject.includes("Bem-vindo ao Portal Acadêmico"));
    assert.ok(rendered.html.includes("temp-pass-1234"));
    assert.ok(rendered.html.includes("RA-2026-999"));
    assert.ok(rendered.html.includes("Discente"));
    assert.ok(rendered.text.includes("RA-2026-999"));
  });

  it("renders Protocol Submitted confirmation with official code and SLA", () => {
    const rendered = AcademicEmailTemplateRenderer.renderProtocolSubmitted({
      to: "discente@agmrm.edu.br",
      studentName: "Mariana Ferreira",
      protocolCode: "PROT-2026/A94F",
      requestType: "Abono de Faltas",
      targetComponent: "Engenharia de Software IV",
      justification: "Atestado médico anexo.",
      estimatedDays: 5,
    });

    assert.ok(rendered.subject.includes("PROT-2026/A94F"));
    assert.ok(rendered.html.includes("PROT-2026/A94F"));
    assert.ok(rendered.html.includes("Abono de Faltas"));
    assert.ok(rendered.html.includes("5 dias úteis"));
  });

  it("renders Protocol Decided notice with approval badge and technical opinion", () => {
    const renderedApproved = AcademicEmailTemplateRenderer.renderProtocolDecided({
      to: "discente@agmrm.edu.br",
      studentName: "Mariana Ferreira",
      protocolCode: "PROT-2026/A94F",
      approved: true,
      decisionNote: "Atestado validado e faltas abonadas conforme regimento.",
      signedBy: "Secretaria Acadêmica Central",
    });

    assert.ok(renderedApproved.subject.includes("DEFERIDO"));
    assert.ok(renderedApproved.html.includes("DEFERIDO"));
    assert.ok(renderedApproved.html.includes("Atestado validado"));

    const renderedRejected = AcademicEmailTemplateRenderer.renderProtocolDecided({
      to: "discente@agmrm.edu.br",
      studentName: "Mariana Ferreira",
      protocolCode: "PROT-2026/B12C",
      approved: false,
      decisionNote: "Prazo regimental de entrega do atestado excedido (máx 48h).",
      signedBy: "Coordenação de Curso",
    });

    assert.ok(renderedRejected.subject.includes("INDEFERIDO"));
    assert.ok(renderedRejected.html.includes("INDEFERIDO"));
  });

  it("renders Assignment Deadline and Grade Published templates", () => {
    const deadline = AcademicEmailTemplateRenderer.renderAssignmentDeadline({
      to: "aluno@agmrm.edu.br",
      studentName: "Lucas Prado",
      assignmentTitle: "Projeto Integrador Sprint 3",
      disciplineName: "Desenvolvimento Mobile",
      dueDate: new Date("2026-11-15T23:59:00Z"),
    });
    assert.ok(deadline.subject.includes("Lembrete de Entrega"));
    assert.ok(deadline.html.includes("Projeto Integrador Sprint 3"));

    const grade = AcademicEmailTemplateRenderer.renderGradePublished({
      to: "aluno@agmrm.edu.br",
      studentName: "Lucas Prado",
      assignmentTitle: "Atividade Prática 2",
      disciplineName: "Banco de Dados",
      grade: 9.5,
      feedback: "Excelente modelagem e normalização.",
    });
    assert.ok(grade.subject.includes("Nota Disponível"));
    assert.ok(grade.html.includes("9.5"));
    assert.ok(grade.html.includes("Excelente modelagem"));
  });
});

describe("LocalOutboxEmailProvider & Resilience", () => {
  beforeEach(() => {
    LocalOutboxEmailProvider.clear();
  });

  it("saves sent email into the in-memory ring buffer without throwing", async () => {
    const outbox = new LocalOutboxEmailProvider();
    const result = await outbox.save(
      {
        to: "offline@example.com",
        subject: "Teste Offline",
        html: "<p>Conteudo</p>",
        text: "Conteudo",
      },
      { code: "123456", purpose: "login" },
    );

    assert.equal(result.success, true);
    assert.equal(result.provider, "outbox");

    const sent = LocalOutboxEmailProvider.getSentEmails();
    assert.equal(sent.length, 1);
    assert.equal(sent[0]?.to, "offline@example.com");
    assert.equal(sent[0]?.code, "123456");
  });

  it("ResilientEmailSender safely falls back to Outbox when SMTP is unconfigured", async () => {
    const sender = new ResilientEmailSender(mockEnvironment);

    // ensureAvailable passa em modo outbox
    assert.doesNotThrow(() => sender.ensureAvailable());

    const result = await sender.sendAuthOtp({
      to: "usuario@exemplo.com",
      displayName: "Usuario Demo",
      code: "894201",
      expiresInSeconds: 300,
      purpose: "recovery",
    });

    assert.equal(result.success, true);
    assert.equal(result.provider, "outbox");

    const last = LocalOutboxEmailProvider.getLastEmail();
    assert.equal(last?.to, "usuario@exemplo.com");
    assert.equal(last?.code, "894201");
  });

  it("throws 503 when configured in strict mode without any mail provider", () => {
    const strictEnv: Environment = {
      ...mockEnvironment,
      emailProviders: {
        fallbackMode: "strict",
      },
    };

    const sender = new ResilientEmailSender(strictEnv);
    assert.throws(
      () => sender.ensureAvailable(),
      (err: any) => err.code === "recovery_email_unavailable",
    );
  });

  it("HttpEmailProvider rejects HTTP 200 Apps Script error payloads and accepts valid JSON", async () => {
    assert.equal(
      HttpEmailProvider.validateWebhookResponse(200, JSON.stringify({ status: 200, success: true })),
      null,
    );
    assert.match(
      HttpEmailProvider.validateWebhookResponse(200, JSON.stringify({ status: 500, error: "Quota exceeded" })) ?? "",
      /Quota exceeded/,
    );
    assert.match(
      HttpEmailProvider.validateWebhookResponse(200, "<!DOCTYPE html><html><body>Erro</body></html>") ?? "",
      /página\/erro inválido/,
    );

    const server = createServer((req, res) => {
      if (req.url === "/exec-ok") {
        res.writeHead(302, { Location: "/echo-ok" });
        res.end();
        return;
      }
      if (req.url === "/echo-ok") {
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ status: 200, success: true }));
        return;
      }
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ status: 500, error: "GmailApp limit reached" }));
    });
    await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
    const { port } = server.address() as AddressInfo;

    try {
      const okProvider = new HttpEmailProvider({
        gmailWebhookUrl: `http://127.0.0.1:${port}/exec-ok`,
        defaultSender: "noreply@agmrm.test",
      });
      const okResult = await okProvider.send({
        to: "aluno@agmrm.test",
        subject: "Teste",
        html: "<p>Oi</p>",
        text: "Oi",
      });
      assert.equal(okResult.success, true);
      assert.equal(okResult.provider, "webhook");
      assert.equal(okResult.deliveredExternally, true);

      const errSender = new ResilientEmailSender({
        ...mockEnvironment,
        emailProviders: {
          fallbackMode: "outbox",
          gmailWebhookUrl: `http://127.0.0.1:${port}/exec-fail`,
        },
      });
      const fallbackResult = await errSender.sendAuthOtp({
        to: "aluno@agmrm.test",
        displayName: "Aluno Teste",
        code: "654321",
        expiresInSeconds: 300,
        purpose: "recovery",
      });
      assert.equal(fallbackResult.success, true);
      assert.equal(fallbackResult.provider, "outbox");
      assert.equal(fallbackResult.deliveredExternally, false);
      assert.ok(
        fallbackResult.errorTrail?.some((entry) => entry.includes("GmailApp limit reached")),
      );
    } finally {
      await new Promise<void>((resolve) => server.close(() => resolve()));
    }
  });
});
