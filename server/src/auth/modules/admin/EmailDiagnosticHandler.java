// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.admin;

import auth.abstratas.HandlerAutenticadoAbstrato;
import auth.model.UsuarioAutenticado;
import auth.modules.email.SmtpCliente;
import auth.modules.email.TemplateEmailDiagnostico;
import auth.modules.persistencia.RepositorioUsuarios;
import core.RequisicaoHttp;
import core.RespostaHttp;
import utils.ConfigEnv;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Endpoint administrativo de diagnostico real de entrega de e-mail (SMTP -> HTTPS -> Outbox).
 * Rota: POST /api/auth/email-diagnostic
 */
public class EmailDiagnosticHandler extends HandlerAutenticadoAbstrato {

    public EmailDiagnosticHandler() {
        this(RepositorioUsuarios.getInstance());
    }

    public EmailDiagnosticHandler(RepositorioUsuarios repositorio) {
        super(repositorio);
    }

    @Override
    protected boolean deveAplicarHeadersAuth() {
        return false;
    }

    @Override
    protected boolean exigirAdmin() {
        return true;
    }

    @Override
    protected String metodoPermitido() {
        return "POST";
    }

    @Override
    protected String mensagemMetodoNaoPermitido() {
        return "Utilize POST para diagnostico de email.";
    }

    @Override
    protected String tagLog() {
        return "EMAIL-DIAG";
    }

    @Override
    protected void processarAutenticado(
            RequisicaoHttp requisicao, RespostaHttp resposta, UsuarioAutenticado admin) throws Exception {
        Map<String, Object> corpo = lerJsonObjeto(requisicao);
        String destinatarioTeste = getString(corpo, "destinatarioTeste");
        if (destinatarioTeste == null || destinatarioTeste.isEmpty()) {
            responderErro(resposta, 400, "invalid_request", "Campo 'destinatarioTeste' e obrigatorio.");
            return;
        }
        destinatarioTeste = destinatarioTeste.toLowerCase();

        Map<String, Object> relatorio = coletarConfiguracoesAtuais();

        if (!SmtpCliente.isEmailValido(destinatarioTeste)) {
            relatorio.put("status", Integer.valueOf(400));
            relatorio.put("code", "invalid_email");
            relatorio.put("emailEnviado", Boolean.FALSE);
            relatorio.put("deliveredExternally", Boolean.FALSE);
            relatorio.put("mensagem", "Endereco de email invalido: " + destinatarioTeste);
            enviarJson(resposta, 400, relatorio);
            return;
        }

        UsuarioAutenticado cadastrado = repositorio.buscarPorEmail(destinatarioTeste);
        if (cadastrado == null || !cadastrado.getEmail().equalsIgnoreCase(destinatarioTeste)) {
            relatorio.put("status", Integer.valueOf(404));
            relatorio.put("code", "email_not_registered");
            relatorio.put("erro", "E-mail nao cadastrado na base de usuarios ativos (auth_users).");
            relatorio.put("message", "E-mail nao cadastrado na base de usuarios ativos (auth_users).");
            relatorio.put("emailEnviado", Boolean.FALSE);
            relatorio.put("deliveredExternally", Boolean.FALSE);
            relatorio.put("mensagem", "Destinatario nao cadastrado no sistema: " + destinatarioTeste);
            enviarJson(resposta, 404, relatorio);
            return;
        }

        if (!algumCanalConfigurado(relatorio)) {
            relatorio.put("emailEnviado", Boolean.FALSE);
            relatorio.put("deliveredExternally", Boolean.FALSE);
            relatorio.put("storedInOutbox", Boolean.FALSE);
            relatorio.put("canalUtilizado", "NENHUM");
            relatorio.put("mensagem", "Nenhum canal de envio configurado (SMTP_HOST, RESEND_API_KEY, BREVO_API_KEY e GMAIL_WEBHOOK_URL ausentes).");
            enviarJson(resposta, 200, relatorio);
            return;
        }

        String html = new TemplateEmailDiagnostico(admin.getDisplayName(), destinatarioTeste).renderizar();
        SmtpCliente.ResultadoEnvioEmail resultado = SmtpCliente.enviarSincronoDetalhado(
                destinatarioTeste, "📧 AGMRM - Diagnóstico de Email", html, "DIAGNOSTIC");

        boolean entregueExternamente = resultado.isDeliveredExternally();
        relatorio.put("emailEnviado", Boolean.valueOf(entregueExternamente));
        relatorio.put("deliveredExternally", Boolean.valueOf(entregueExternamente));
        relatorio.put("storedInOutbox", Boolean.valueOf("OUTBOX".equals(resultado.getCanal())));
        relatorio.put("canalUtilizado", resultado.getCanal());
        relatorio.put("latenciaMs", Long.valueOf(resultado.getLatenciaMs()));
        relatorio.put("tentativas", Integer.valueOf(1));
        relatorio.put("errorTrail", resultado.getErrorTrail());
        relatorio.put("circuitBreakerState", SmtpCliente.getEstadoCircuito());
        relatorio.put("mensagem", entregueExternamente
                ? "Email de diagnostico enviado externamente com sucesso via canal ["
                        + resultado.getCanal() + "] para " + destinatarioTeste
                : "Nenhum canal externo entregou o e-mail (retido em OUTBOX local). Consulte errorTrail.");
        enviarJson(resposta, 200, relatorio);
    }

    private static Map<String, Object> coletarConfiguracoesAtuais() {
        String smtpHost = ConfigEnv.obter("SMTP_HOST", "");
        String smtpUser = ConfigEnv.obter("SMTP_USER", "");
        boolean smtpSsl = "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SECURE", "false"))
                || "true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SSL", "false"));

        Map<String, Object> relatorio = new LinkedHashMap<String, Object>();
        relatorio.put("status", Integer.valueOf(200));
        relatorio.put("smtpHost", smtpHost);
        relatorio.put("smtpPorta", Integer.valueOf(ConfigEnv.obterInteiro("SMTP_PORT", 587)));
        relatorio.put("smtpSsl", Boolean.valueOf(smtpSsl));
        relatorio.put("autenticacaoConfigurada", Boolean.valueOf(!smtpUser.isEmpty()));
        relatorio.put("remetente", ConfigEnv.obter("SMTP_FROM", smtpUser));
        relatorio.put("timeoutMs", Integer.valueOf(ConfigEnv.obterInteiro("SMTP_TIMEOUT_MS", 15000)));
        relatorio.put("maxRetries", Integer.valueOf(ConfigEnv.obterInteiro("SMTP_MAX_RETRIES", 1)));
        relatorio.put("sandboxMode", Boolean.valueOf("true".equalsIgnoreCase(ConfigEnv.obter("SMTP_SANDBOX_MODE", "false"))));
        relatorio.put("resendConfigurado", Boolean.valueOf(!ConfigEnv.obter("RESEND_API_KEY", "").isEmpty()));
        relatorio.put("brevoConfigurado", Boolean.valueOf(!ConfigEnv.obter("BREVO_API_KEY", "").isEmpty()));
        relatorio.put("fallbackWebhookConfigurado", Boolean.valueOf(!ConfigEnv.obter("GMAIL_WEBHOOK_URL", "").isEmpty()));
        relatorio.put("circuitBreakerState", SmtpCliente.getEstadoCircuito());
        return relatorio;
    }

    private static boolean algumCanalConfigurado(Map<String, Object> relatorio) {
        String host = (String) relatorio.get("smtpHost");
        return (host != null && !host.isEmpty())
                || Boolean.TRUE.equals(relatorio.get("resendConfigurado"))
                || Boolean.TRUE.equals(relatorio.get("brevoConfigurado"))
                || Boolean.TRUE.equals(relatorio.get("fallbackWebhookConfigurado"))
                || Boolean.TRUE.equals(relatorio.get("sandboxMode"));
    }
}
