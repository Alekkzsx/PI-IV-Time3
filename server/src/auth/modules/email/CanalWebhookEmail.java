// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
package auth.modules.email;

import auth.abstratas.CanalHttpsEmailAbstrato;
import utils.Json;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

/**
 * Canal Tier 2c: Webhook HTTP (ex.: Google Apps Script) com suporte a redirect 302
 * e validacao rigorosa contra paginas HTML de erro ou respostas JSON com erro logico.
 */
public class CanalWebhookEmail extends CanalHttpsEmailAbstrato {
    // Timeouts maiores que os provedores comerciais: Apps Script pode demorar a acordar.
    private static final int WEBHOOK_CONNECT_TIMEOUT_MS = 6_000;
    private static final int WEBHOOK_READ_TIMEOUT_MS = 12_000;

    private final String webhookUrl;
    private final String remetente;

    /** @param webhookUrl URL do endpoint (GMAIL_WEBHOOK_URL); vazia = canal desabilitado. */
    public CanalWebhookEmail(String webhookUrl, String remetente) {
        this.webhookUrl = webhookUrl != null ? webhookUrl.trim() : "";
        this.remetente = remetente != null ? remetente.trim() : "";
    }

    @Override
    public String getNomeCanal() {
        return "WEBHOOK";
    }

    @Override
    public boolean estaConfigurado() {
        return !webhookUrl.isEmpty();
    }

    @Override
    protected String getUrl() {
        return webhookUrl;
    }

    @Override
    protected int getConnectTimeoutMs() {
        return WEBHOOK_CONNECT_TIMEOUT_MS;
    }

    @Override
    protected int getReadTimeoutMs() {
        return WEBHOOK_READ_TIMEOUT_MS;
    }

    /** Apps Script responde 302 para o googleusercontent: seguir o redirect e obrigatorio aqui. */
    @Override
    protected boolean deveSeguirRedirectPost302() {
        return true;
    }

    /** Sem headers de auth: a propria URL secreta do webhook e a credencial. */
    @Override
    protected Map<String, String> construirHeaders() {
        return Collections.emptyMap();
    }

    /** Payload generico do webhook (to/from/subject/html/text/type). */
    @Override
    protected Map<String, Object> construirPayload(MensagemEmail mensagem) {
        Map<String, Object> body = new LinkedHashMap<String, Object>();
        body.put("to", mensagem.getDestinatario());
        body.put("from", remetente);
        body.put("subject", mensagem.getAssunto());
        body.put("html", mensagem.getCorpoHtml());
        body.put("text", mensagem.getTextoPlano());
        body.put("type", mensagem.getTipo());
        return body;
    }

    @Override
    protected String validarResposta(int status, String body) {
        return validarRespostaWebhook(status, body);
    }

    /**
     * Validacao RIGOROSA: HTTP 2xx nao basta para webhooks caseiros.
     * Rejeita (1) paginas HTML de erro/login do Google (o script "respondeu" mas nao enviou)
     * e (2) JSON com erro logico: error/errorMessage preenchidos, ok/success=false ou
     * status interno >= 400. So passa quem realmente aceitou a mensagem.
     *
     * @return null se aceito; mensagem de erro caso contrario
     */
    public static String validarRespostaWebhook(int status, String body) {
        if (status < 200 || status >= 300) {
            return "Webhook retornou HTTP " + status + (body != null && !body.trim().isEmpty()
                    ? ": " + truncar(body.trim(), 160) : "");
        }
        String limpo = body != null ? body.trim() : "";
        String lower = limpo.toLowerCase(Locale.ROOT);
        // Marcadores de pagina de erro/login do Apps Script (HTML em vez do JSON esperado).
        if (lower.contains("<!doctype")
                || lower.contains("<html")
                || lower.contains("accounts.google.com")
                || lower.contains("não foi possível abrir o arquivo")
                || lower.contains("função de script não encontrada")
                || lower.contains("script function not found")
                || lower.contains("errormessage")) {
            return "Webhook retornou pagina/erro invalido em HTTP " + status + ": " + truncar(limpo, 160);
        }
        if (limpo.startsWith("{")) {
            // Corpo JSON: procura erros LOGICOS mesmo com HTTP 200.
            try {
                Map<String, Object> json = Json.analisarObjeto(limpo);
                Object erro = json.get("error");
                if (erro == null) erro = json.get("errorMessage");
                if (erro != null && !String.valueOf(erro).trim().isEmpty()) {
                    return "Webhook reportou erro no corpo: " + erro;
                }
                if (Boolean.FALSE.equals(json.get("ok")) || Boolean.FALSE.equals(json.get("success"))) {
                    return "Webhook retornou success=false: " + truncar(limpo, 160);
                }
                Object statusJson = json.get("status");
                if (statusJson instanceof Number && ((Number) statusJson).intValue() >= 400) {
                    return "Webhook retornou status interno " + statusJson + ": " + truncar(limpo, 160);
                }
            } catch (IllegalArgumentException ignored) { }
        }
        return null;
    }
}
