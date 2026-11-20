// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.modules.email;

import auth.abstratas.CanalHttpsEmailAbstrato;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Canal Tier 2a: Provedor HTTPS REST Resend (https://api.resend.com/emails).
 */
public class CanalResendEmail extends CanalHttpsEmailAbstrato {
    private final String apiKey;
    private final String remetente;

    /** @param apiKey chave RESEND_API_KEY (vazia = canal desabilitado). */
    public CanalResendEmail(String apiKey, String remetente) {
        this.apiKey = apiKey != null ? apiKey.trim() : "";
        this.remetente = remetente != null ? remetente.trim() : "";
    }

    @Override
    public String getNomeCanal() {
        return "RESEND";
    }

    @Override
    public boolean estaConfigurado() {
        return !apiKey.isEmpty();
    }

    @Override
    protected String getUrl() {
        return "https://api.resend.com/emails";
    }

    /** Autenticacao da API Resend: Authorization Bearer <apiKey>. */
    @Override
    protected Map<String, String> construirHeaders() {
        Map<String, String> headers = new LinkedHashMap<String, String>();
        headers.put("Authorization", "Bearer " + apiKey);
        return headers;
    }

    /** Payload da API Resend: to e uma LISTA; html + text como alternativas MIME. */
    @Override
    protected Map<String, Object> construirPayload(MensagemEmail mensagem) {
        Map<String, Object> body = new LinkedHashMap<String, Object>();
        body.put("from", remetente);
        body.put("to", Collections.singletonList(mensagem.getDestinatario()));
        body.put("subject", mensagem.getAssunto());
        body.put("html", mensagem.getCorpoHtml());
        body.put("text", mensagem.getTextoPlano());
        return body;
    }
}
