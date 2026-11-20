// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package auth.abstratas;

import auth.modules.email.MensagemEmail;
import utils.Json;
import utils.RedeUtils;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

/**
 * Especializacao abstrata para canais de e-mail baseados em APIs HTTPS REST (Tier 2).
 * Centraliza o transporte POST JSON via HttpURLConnection, tratamento de redirect 302
 * e validacao de resposta para Resend, Brevo e Webhook.
 */
public abstract class CanalHttpsEmailAbstrato extends CanalEnvioEmailAbstrato {

    protected static final class HttpResposta {
        public final int status;
        public final String body;

        public HttpResposta(int status, String body) {
            this.status = status;
            this.body = body != null ? body : "";
        }
    }

    protected abstract String getUrl();

    protected abstract Map<String, String> construirHeaders();

    protected abstract Map<String, Object> construirPayload(MensagemEmail mensagem);

    protected int getConnectTimeoutMs() {
        return 5_000;
    }

    protected int getReadTimeoutMs() {
        return 8_000;
    }

    protected boolean deveSeguirRedirectPost302() {
        return false;
    }

    /**
     * Valida a resposta HTTP do provedor; retorna null se aceito ou a mensagem de erro caso rejeitado.
     */
    protected String validarResposta(int status, String body) {
        if (status >= 200 && status < 300) {
            return null;
        }
        return getNomeCanal() + " HTTP " + status + ": " + truncar(body, 160);
    }

    @Override
    protected final boolean enviarInterno(MensagemEmail mensagem, List<String> errorTrail) throws Exception {
        String payloadJson = Json.escrever(construirPayload(mensagem));
        HttpResposta res = executarPostJsonHttp(
                getUrl(),
                construirHeaders(),
                payloadJson,
                getConnectTimeoutMs(),
                getReadTimeoutMs(),
                deveSeguirRedirectPost302()
        );
        String erro = validarResposta(res.status, res.body);
        if (erro == null) {
            log("INFO", "[FALLBACK OK] " + getNomeCanal() + " enviou com sucesso para "
                    + mensagem.getDestinatario() + " | HTTP " + res.status);
            return true;
        }
        if (errorTrail != null) {
            errorTrail.add(erro);
        }
        log("WARN", "[FALLBACK REJEITADO] " + erro);
        return false;
    }

    protected static HttpResposta executarPostJsonHttp(
            String urlDestino,
            Map<String, String> headersExtras,
            String payloadJson,
            int connectTimeoutMs,
            int readTimeoutMs,
            boolean seguirRedirectPost302) throws IOException {
        HttpURLConnection conn = null;
        try {
            URL url = new URL(urlDestino);
            conn = (HttpURLConnection) url.openConnection();
            conn.setInstanceFollowRedirects(false);
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            conn.setRequestProperty("Accept", "application/json, text/plain, */*");
            conn.setRequestProperty("User-Agent", "AGMRM-Native-Server/1.0");
            if (headersExtras != null) {
                for (Map.Entry<String, String> entry : headersExtras.entrySet()) {
                    conn.setRequestProperty(entry.getKey(), entry.getValue());
                }
            }
            conn.setDoOutput(true);
            conn.setConnectTimeout(connectTimeoutMs);
            conn.setReadTimeout(readTimeoutMs);

            OutputStream os = conn.getOutputStream();
            os.write(payloadJson.getBytes(StandardCharsets.UTF_8));
            os.flush();
            os.close();

            int status = conn.getResponseCode();
            if (seguirRedirectPost302
                    && (status == HttpURLConnection.HTTP_MOVED_TEMP
                    || status == HttpURLConnection.HTTP_SEE_OTHER
                    || status == 307
                    || status == 308)) {
                String redirectUrl = conn.getHeaderField("Location");
                if (redirectUrl != null && !redirectUrl.trim().isEmpty()) {
                    conn.disconnect();
                    conn = (HttpURLConnection) new URL(redirectUrl.trim()).openConnection();
                    conn.setInstanceFollowRedirects(true);
                    conn.setRequestMethod("GET");
                    conn.setRequestProperty("User-Agent", "AGMRM-Native-Server/1.0");
                    conn.setConnectTimeout(connectTimeoutMs);
                    conn.setReadTimeout(readTimeoutMs);
                    status = conn.getResponseCode();
                }
            }

            InputStream stream = status >= 200 && status < 400 ? conn.getInputStream() : conn.getErrorStream();
            String body = RedeUtils.lerStreamUtf8(stream);
            return new HttpResposta(status, body);
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }
    }
}
