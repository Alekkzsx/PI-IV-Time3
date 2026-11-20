// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
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

    /** DTO imutavel da resposta HTTP do provedor (status + corpo ja lido como UTF-8). */
    protected static final class HttpResposta {
        public final int status;
        public final String body;

        public HttpResposta(int status, String body) {
            this.status = status;
            this.body = body != null ? body : "";
        }
    }

    /** Endpoint HTTPS do provedor (ex.: https://api.resend.com/emails). */
    protected abstract String getUrl();

    /** Headers de autenticacao do provedor (Authorization Bearer, x-keys, assinatura HMAC...). */
    protected abstract Map<String, String> construirHeaders();

    /** Corpo JSON no formato especifico da API do provedor. */
    protected abstract Map<String, Object> construirPayload(MensagemEmail mensagem);

    /** Gancho de timeout de conexao (default 5s - APIs de e-mail devem responder rapido). */
    protected int getConnectTimeoutMs() {
        return 5_000;
    }

    /** Gancho de timeout de leitura (default 8s). */
    protected int getReadTimeoutMs() {
        return 8_000;
    }

    /**
     * Gancho: true reenvia como GET ao receber 302/303/307/308.
     * So o webhook do cliente usa (alguns endpoints internos redirecionam); APIs
     * comerciais nao redirecionam e seguir redirect cegamente vazaria o payload.
     */
    protected boolean deveSeguirRedirectPost302() {
        return false;
    }

    /**
     * Valida a resposta HTTP do provedor; retorna null se aceito ou a mensagem de erro caso rejeitado.
     * Default: qualquer 2xx aceita; subclasses podem exigir campos no corpo (ex.: id da mensagem).
     */
    protected String validarResposta(int status, String body) {
        if (status >= 200 && status < 300) {
            return null;
        }
        return getNomeCanal() + " HTTP " + status + ": " + truncar(body, 160);
    }

    /** Fluxo fixo do tier 2: payload -> POST JSON -> validacao -> log de sucesso/rejeicao. */
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

    /**
     * Transporte POST JSON compartilhado pelos canais HTTPS.
     * Redirect automatico fica DESLIGADO (setInstanceFollowRedirects(false)) para o
     * chamador decidir; em erro (>=400) le o errorStream para incluir o motivo no errorTrail.
     */
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
            // Opt-in de redirect: repost como GET no Location (sem reenviar credenciais no corpo).
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

            // 2xx/3xx vem no inputStream; erros vem no errorStream (pode ser null em falha de rede).
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
