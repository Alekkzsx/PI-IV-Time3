// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import "../config/local-environment.js";
import net from "node:net";
import { loadEnvironment } from "../config/environment.js";
import { ResilientEmailSender } from "../modules/notifications/index.js";

type PortProbeResult = {
  host: string;
  port: number;
  status: "OPEN" | "BLOCKED" | "TIMEOUT";
  latencyMs: number;
  error?: string;
};

/** Testa abertura de socket TCP com timeout rigoroso */
function probeTcpPort(host: string, port: number, timeoutMs = 4000): Promise<PortProbeResult> {
  const start = Date.now();
  return new Promise((resolve) => {
    const socket = new net.Socket();
    let resolved = false;

    const finish = (status: "OPEN" | "BLOCKED" | "TIMEOUT", error?: string) => {
      if (resolved) return;
      resolved = true;
      socket.destroy();
      resolve({
        host,
        port,
        status,
        latencyMs: Date.now() - start,
        error,
      });
    };

    socket.setTimeout(timeoutMs);
    socket.once("connect", () => finish("OPEN"));
    socket.once("timeout", () => finish("TIMEOUT", `Timeout após ${timeoutMs}ms`));
    socket.once("error", (err: any) => finish("BLOCKED", err.code || err.message));

    try {
      socket.connect(port, host);
    } catch (e: any) {
      finish("BLOCKED", e.message);
    }
  });
}

async function runEmailResilienceDiagnostic(): Promise<void> {
  console.info("════════════════════════════════════════════════════════════════════════");
  console.info(" 🛰️  SUÍTE DE DIAGNÓSTICO DE REDE, FIREWALL E E-MAIL RESILIENTE AGM-RM");
  console.info("════════════════════════════════════════════════════════════════════════\n");

  const environment = loadEnvironment();
  const smtpHost = environment.smtp?.host || "smtp.gmail.com";

  console.info(`[1/3] Aferindo conectividade de portas de saída em ${smtpHost}...`);

  const probes = await Promise.all([
    probeTcpPort(smtpHost, 465, 4000),
    probeTcpPort(smtpHost, 587, 4000),
    probeTcpPort("api.resend.com", 443, 3000),
  ]);

  console.info("\n┌──────────┬────────────────────────────┬──────────┬────────────┬────────────────────────┐");
  console.info("│ Porta    │ Destino / Protocolo        │ Status   │ Latência   │ Observação             │");
  console.info("├──────────┼────────────────────────────┼──────────┼────────────┼────────────────────────┤");

  for (const p of probes) {
    const portStr = String(p.port).padEnd(8);
    const hostStr = `${p.host}`.padEnd(26);
    const statusStr = (p.status === "OPEN" ? "🟢 OPEN" : p.status === "TIMEOUT" ? "🟡 TIMEOUT" : "🔴 BLOCKED").padEnd(8);
    const latStr = `${p.latencyMs}ms`.padEnd(10);
    const obsStr = (p.error ? p.error.substring(0, 22) : p.port === 443 ? "HTTPS (Imune Firewall)" : "SMTP Padrão").padEnd(22);
    console.info(`│ ${portStr} │ ${hostStr} │ ${statusStr} │ ${latStr} │ ${obsStr} │`);
  }
  console.info("└──────────┴────────────────────────────┴──────────┴────────────┴────────────────────────┘\n");

  // Diagnóstico de Firewall
  const smtpBlocked = probes[0].status !== "OPEN" && probes[1].status !== "OPEN";
  const httpsOpen = probes[2].status === "OPEN";

  if (smtpBlocked && httpsOpen) {
    console.warn("⚠️  DIAGNÓSTICO: Portas SMTP (465/587) estão bloqueadas nesta rede/firewall.");
    console.warn("🛡️  AÇÃO RESILIENTE: O tráfego de e-mail será roteado automaticamente via Porta 443 (HTTPS REST)!");
  } else if (!smtpBlocked) {
    console.info("✅ DIAGNÓSTICO: Conexão direta SMTP disponível com saída liberada.");
  }

  console.info("\n[2/3] Instanciando ResilientEmailSender com suporte multitransporte...");
  const sender = new ResilientEmailSender(environment);

  console.info("\n[3/3] Disparando teste de OTP via ResilientEmailSender...");
  const testEmail = environment.smtp?.user || "staff.notadez@gmail.com";
  const testOtp = String(Math.floor(100000 + Math.random() * 900000));

  try {
    const result = await sender.sendAuthOtp({
      to: testEmail,
      displayName: "Administrador / Teste de Rede",
      code: testOtp,
      expiresInSeconds: 300,
      purpose: "recovery",
    });

    console.info("\n✅ RESULTADO DO DISPARO:");
    console.info(`• Sucesso:      ${result.success}`);
    console.info(`• Provedor:     ${result.provider.toUpperCase()}`);
    console.info(`• Latência:     ${result.latencyMs}ms`);
    console.info(`• Message ID:   ${result.messageId}`);
    console.info(`• Destinatário: ${testEmail}`);
  } catch (err: any) {
    console.error(`\n❌ Falha no disparo do teste: ${err.message}`);
    process.exitCode = 1;
    return;
  }

  console.info("\n════════════════════════════════════════════════════════════════════════");
  console.info(" 🎉 SISTEMA DE E-MAIL 100% OPERACIONAL E RESILIENTE A FIREWALLS!");
  console.info("════════════════════════════════════════════════════════════════════════\n");
}

void runEmailResilienceDiagnostic();
