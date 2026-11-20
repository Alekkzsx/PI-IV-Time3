// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
package auth.modules.email;

import auth.abstratas.CanalHttpsEmailAbstrato;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Canal Tier 2b: Provedor HTTPS REST Brevo (https://api.brevo.com/v3/smtp/email).
 */
public class CanalBrevoEmail extends CanalHttpsEmailAbstrato {
    private final String apiKey;
    private final String remetente;

    /** @param apiKey chave BREVO_API_KEY (vazia = canal desabilitado). */
    public CanalBrevoEmail(String apiKey, String remetente) {
        this.apiKey = apiKey != null ? apiKey.trim() : "";
        this.remetente = remetente != null ? remetente.trim() : "";
    }

    @Override
    public String getNomeCanal() {
        return "BREVO";
    }

    @Override
    public boolean estaConfigurado() {
        return !apiKey.isEmpty();
    }

    @Override
    protected String getUrl() {
        return "https://api.brevo.com/v3/smtp/email";
    }

    /** Autenticacao da API Brevo: header proprio "api-key" (nao usa Bearer). */
    @Override
    protected Map<String, String> construirHeaders() {
        Map<String, String> headers = new LinkedHashMap<String, String>();
        headers.put("api-key", apiKey);
        return headers;
    }

    /** Payload da API Brevo v3: sender/to sao OBJETOS {email,name}; campos htmlContent/textContent. */
    @Override
    protected Map<String, Object> construirPayload(MensagemEmail mensagem) {
        Map<String, Object> sender = new LinkedHashMap<String, Object>();
        sender.put("email", remetente);
        sender.put("name", "Portal Acadêmico AGM-RM");

        Map<String, Object> recipient = new LinkedHashMap<String, Object>();
        recipient.put("email", mensagem.getDestinatario());

        Map<String, Object> body = new LinkedHashMap<String, Object>();
        body.put("sender", sender);
        body.put("to", Collections.singletonList(recipient));
        body.put("subject", mensagem.getAssunto());
        body.put("htmlContent", mensagem.getCorpoHtml());
        body.put("textContent", mensagem.getTextoPlano());
        return body;
    }
}
