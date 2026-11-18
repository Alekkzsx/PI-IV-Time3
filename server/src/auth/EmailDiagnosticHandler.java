// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth;

import core.HttpUtils;
import core.ManipuladorHttp;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.ConfigEnv;
import utils.Json;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

/**
 * Endpoint de diagnostico do servico de email (apenas para administradores).
 * Rota: POST /api/auth/email-diagnostic
 *
 * Envia um email de teste para o destinatario informado e retorna um relatorio
 * completo com o status de cada etapa do processo SMTP.
 *
 * Body: { "destinatarioTeste": "seu@email.com" }
 *
 * Response 200: {
 *   "status": 200,
 *   "smtpHost": "smtp.gmail.com",
 *   "smtpPorta": 465,
 *   "smtpSsl": true,
 *   "autenticacaoConfigurada": true,
 *   "remetente": "staff.notadez@gmail.com",
 *   "emailEnviado": true,
 *   "latenciaMs": 1247,
 *   "tentativas": 1,
 *   "fallbackWebhookConfigurado": true,
 *   "mensagem": "Email de diagnostico enviado com sucesso."
 * }
 *
 * Response 401: Requer autenticacao como admin.
 * Response 400: Campo 'destinatarioTeste' invalido.
 */
public class EmailDiagnosticHandler implements ManipuladorHttp {
    private final RepositorioUsuarios repositorio;

    public EmailDiagnosticHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public EmailDiagnosticHandler(RepositorioUsuarios repositorio) {
        this.repositorio = repositorio != null ? repositorio : RepositorioUsuarios.getInstance();
    }

    @Override
    public void handle(RequisicaoHttp requisicao, RespostaHttp resposta) throws IOException {
        HttpUtils.aplicarHeadersCors(requisicao, resposta);

        if ("OPTIONS".equalsIgnoreCase(requisicao.getMetodo())) {
            resposta.enviar(204, "");
            return;
        }

        if (!"POST".equalsIgnoreCase(requisicao.getMetodo())) {
            enviarErro(resposta, 405, "Utilize POST para diagnostico de email.");
            return;
        }

        try {
            // Verificar autenticacao administrativa persistida no MongoDB
            UsuarioAutenticado usuario;
            try {
                usuario = JwtAuthValidator.autenticarAdminObrigatorio(requisicao, this.repositorio);
            } catch (JwtAuthValidator.HttpSecurityException e) {
                enviarErro(resposta, e.getStatusHttp(), e.getCodigo(), e.getMessage());
                return;
            } catch (SecurityException e) {
                enviarErro(resposta, 401, "unauthorized", e.getMessage());
                return;
            }

            // Parsear body
            Map<String, Object> corpo = Json.analisarObjeto(requisicao.getCorpo());
            if (corpo == null) corpo = new LinkedHashMap<String, Object>();

            String destinatarioTeste = getString(corpo, "destinatarioTeste");
            if (destinatarioTeste == null || destinatarioTeste.trim().isEmpty()) {
                enviarErro(resposta, 400, "invalid_request", "Campo 'destinatarioTeste' e obrigatorio.");
                return;
            }

            destinatarioTeste = destinatarioTeste.trim().toLowerCase();

            // Coletar configuracoes atuais
            String smtpHost = ConfigEnv.obter("SMTP_HOST", "");
            int smtpPorta = ConfigEnv.obterInteiro("SMTP_PORT", 587);
            boolean smtpSsl = "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SECURE", "false"))
                    || "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SSL", "false"));
            String smtpUser = ConfigEnv.obter("SMTP_USER", "");
            String smtpFrom = ConfigEnv.obter("SMTP_FROM", smtpUser);
            int timeoutMs = ConfigEnv.obterInteiro("SMTP_TIMEOUT_MS", 15000);
            int maxRetries = ConfigEnv.obterInteiro("SMTP_MAX_RETRIES", 1);
            boolean sandbox = "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SANDBOX_MODE", "false"));
            String webhookUrl = ConfigEnv.obter("GMAIL_WEBHOOK_URL", "");
            String resendApiKey = ConfigEnv.obter("RESEND_API_KEY", "");
            String brevoApiKey = ConfigEnv.obter("BREVO_API_KEY", "");

            Map<String, Object> relatorio = new LinkedHashMap<String, Object>();
            relatorio.put("status", 200);
            relatorio.put("smtpHost", smtpHost);
            relatorio.put("smtpPorta", smtpPorta);
            relatorio.put("smtpSsl", smtpSsl);
            relatorio.put("autenticacaoConfigurada", !smtpUser.isEmpty());
            relatorio.put("remetente", smtpFrom);
            relatorio.put("timeoutMs", timeoutMs);
            relatorio.put("maxRetries", maxRetries);
            relatorio.put("sandboxMode", sandbox);
            relatorio.put("resendConfigurado", !resendApiKey.isEmpty());
            relatorio.put("brevoConfigurado", !brevoApiKey.isEmpty());
            relatorio.put("fallbackWebhookConfigurado", !webhookUrl.isEmpty());
            relatorio.put("circuitBreakerState", SmtpCliente.getEstadoCircuito());

            // Validar endereco de email
            if (!SmtpCliente.isEmailValido(destinatarioTeste)) {
                relatorio.put("status", 400);
                relatorio.put("code", "invalid_email");
                relatorio.put("emailEnviado", false);
                relatorio.put("deliveredExternally", false);
                relatorio.put("mensagem", "Endereco de email invalido: " + destinatarioTeste);
                resposta.enviarJson(400, Json.escrever(relatorio));
                return;
            }

            // Bloquear envios para enderecos que nao existem como conta ativa em auth_users
            UsuarioAutenticado destinatarioCadastrado = this.repositorio.buscarPorEmail(destinatarioTeste);
            if (destinatarioCadastrado == null
                    || !destinatarioCadastrado.getEmail().equalsIgnoreCase(destinatarioTeste)) {
                relatorio.put("status", 404);
                relatorio.put("code", "email_not_registered");
                relatorio.put("erro", "E-mail nao cadastrado na base de usuarios ativos (auth_users).");
                relatorio.put("message", "E-mail nao cadastrado na base de usuarios ativos (auth_users).");
                relatorio.put("emailEnviado", false);
                relatorio.put("deliveredExternally", false);
                relatorio.put("mensagem", "Destinatario nao cadastrado no sistema: " + destinatarioTeste);
                resposta.enviarJson(404, Json.escrever(relatorio));
                return;
            }

            // Enviar email de teste
            String assunto = "📧 AGMRM - Diagnóstico de Email";
            String html = construirHtmlDiagnostico(usuario.getDisplayName(), destinatarioTeste);

            if (smtpHost.isEmpty()
                    && resendApiKey.isEmpty()
                    && brevoApiKey.isEmpty()
                    && webhookUrl.isEmpty()
                    && !sandbox) {
                relatorio.put("emailEnviado", false);
                relatorio.put("deliveredExternally", false);
                relatorio.put("storedInOutbox", false);
                relatorio.put("canalUtilizado", "NENHUM");
                relatorio.put("mensagem", "Nenhum canal de envio configurado (SMTP_HOST, RESEND_API_KEY, BREVO_API_KEY e GMAIL_WEBHOOK_URL ausentes).");
                resposta.enviarJson(200, Json.escrever(relatorio));
                return;
            }

            // Enviar via metodo sincrono resiliente (SMTP -> HTTPS REST -> Outbox)
            SmtpCliente.ResultadoEnvioEmail resultado = SmtpCliente.enviarSincronoDetalhado(
                    destinatarioTeste, assunto, html, "DIAGNOSTIC");

            boolean entregueExternamente = resultado.isDeliveredExternally();
            boolean retidoEmOutbox = "OUTBOX".equals(resultado.getCanal());

            relatorio.put("emailEnviado", Boolean.valueOf(entregueExternamente));
            relatorio.put("deliveredExternally", Boolean.valueOf(entregueExternamente));
            relatorio.put("storedInOutbox", Boolean.valueOf(retidoEmOutbox));
            relatorio.put("canalUtilizado", resultado.getCanal());
            relatorio.put("latenciaMs", Long.valueOf(resultado.getLatenciaMs()));
            relatorio.put("tentativas", Integer.valueOf(1));
            relatorio.put("errorTrail", resultado.getErrorTrail());
            relatorio.put("circuitBreakerState", SmtpCliente.getEstadoCircuito());

            if (entregueExternamente) {
                relatorio.put("mensagem", "Email de diagnostico enviado externamente com sucesso via canal ["
                        + resultado.getCanal() + "] para " + destinatarioTeste);
            } else {
                relatorio.put("mensagem", "Nenhum canal externo entregou o e-mail (retido em OUTBOX local). Consulte errorTrail.");
            }

            resposta.enviarJson(200, Json.escrever(relatorio));

        } catch (DatabaseUnavailableException e) {
            HttpUtils.enviarErroJson(resposta, e.getStatusHttp(), e.getCodigo(), e.getMessage());
        } catch (Exception e) {
            System.err.println("[EMAIL-DIAG] Erro inesperado: " + e.getMessage());
            enviarErro(resposta, 500, "Erro interno no servidor: " + e.getMessage());
        }
    }

    private String getString(Map<String, Object> mapa, String chave) {
        Object valor = mapa.get(chave);
        if (valor instanceof String) return ((String) valor).trim();
        return null;
    }

    private void enviarErro(RespostaHttp resposta, int status, String mensagem) throws IOException {
        enviarErro(resposta, status, status == 401 ? "unauthorized" : "invalid_request", mensagem);
    }

    private void enviarErro(RespostaHttp resposta, int status, String codigo, String mensagem) throws IOException {
        Map<String, Object> erro = new LinkedHashMap<String, Object>();
        erro.put("status", status);
        erro.put("code", codigo);
        erro.put("message", mensagem);
        erro.put("erro", mensagem);
        resposta.enviarJson(status, Json.escrever(erro));
    }

    private String construirHtmlDiagnostico(String nomeAdmin, String destinatario) {
        String timestamp = java.time.LocalDateTime.now().toString();
        return "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"></head>"
                + "<body style=\"font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px;\">"
                + "<div style=\"max-width: 500px; margin: 0 auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);\">"
                + "<h2 style=\"color: #0d47a1; margin-top: 0;\">&#128231; Diagnóstico de Email AGMRM</h2>"
                + "<p>Olá" + (nomeAdmin != null && !nomeAdmin.isEmpty() ? ", " + nomeAdmin : "") + "!</p>"
                + "<p>Este é um email de teste enviado pelo sistema de diagnóstico.</p>"
                + "<div style=\"background: #e3f2fd; border-radius: 8px; padding: 20px; margin: 20px 0;\">"
                + "<p style=\"margin: 5px 0;\"><strong>Destinatário:</strong> " + destinatario + "</p>"
                + "<p style=\"margin: 5px 0;\"><strong>Timestamp:</strong> " + timestamp + "</p>"
                + "<p style=\"margin: 5px 0;\"><strong>Status:</strong> <span style=\"color: green;\">✓ Sucesso</span></p>"
                + "</div>"
                + "<p style=\"color: #666; font-size: 14px;\">Se você recebeu este email, o serviço SMTP está funcionando corretamente.</p>"
                + "<hr style=\"border: none; border-top: 1px solid #eee;\">"
                + "<p style=\"color: #999; font-size: 12px;\">AGMRM - Plataforma Educacional Integrada</p>"
                + "</div></body></html>";
    }
}
