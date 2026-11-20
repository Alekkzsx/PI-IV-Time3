// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package bridge;

import auth.utils.OtpService;
import core.abstratas.ExcecaoHttpAbstrata;
import utils.ConfigEnv;
import utils.Json;
import utils.RedeUtils;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.Proxy;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Cliente HTTP da Ponte Interna entre o servidor Java (:8080) e o backend academico TypeScript (:3001).
 * Todas as chamadas sao autenticadas via header X-Internal-Service-Secret.
 */
public class ClientePonteAcademica {
    private static final int TIMEOUT_MS = 6000;

    public static final class ExcecaoPonteAcademica extends ExcecaoHttpAbstrata {
        public ExcecaoPonteAcademica(int statusHttp, String codigo, String message) {
            super(statusHttp, codigo, message);
        }
    }

    private final String baseUrl;
    private final String internalSecret;

    public ClientePonteAcademica() {
        this(resolverBaseUrl(), resolverSegredoInterno());
    }

    public ClientePonteAcademica(String baseUrl, String internalSecret) {
        String limpa = RedeUtils.limparBarraFinal(baseUrl);
        this.baseUrl = limpa.isEmpty() ? "http://127.0.0.1:3001" : limpa;
        this.internalSecret = internalSecret != null ? internalSecret : "";
    }

    private static String resolverBaseUrl() {
        String env = ConfigEnv.obter("ACADEMIC_API_BASE_URL", null);
        if (env == null || env.trim().isEmpty()) {
            env = ConfigEnv.obter("API_BASE_URL", "http://127.0.0.1:3001");
        }
        return RedeUtils.limparBarraFinal(env);
    }

    public static String resolverSegredoInterno() {
        String explicito = ConfigEnv.obter("INTERNAL_SERVICE_SECRET", null);
        if (explicito != null && !explicito.trim().isEmpty()) {
            return explicito.trim();
        }
        String jwtSecret = ConfigEnv.obter("AUTH_JWT_SECRET", null);
        if (jwtSecret == null || jwtSecret.isEmpty()) {
            jwtSecret = ConfigEnv.obter("JWT_SECRET", "");
        }
        if (jwtSecret.isEmpty()) {
            return "";
        }
        return OtpService.sha256Hex("agmrm-internal-bridge:" + jwtSecret);
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> consultarVinculosUsuario(String userId) {
        Object res = requisicao("GET", "/api/internal/academic/users/" + RedeUtils.urlEncode(userId) + "/links", null);
        return res instanceof Map ? (Map<String, Object>) res : Collections.<String, Object>emptyMap();
    }

    public void sincronizarUsuario(String userId, String identity, String displayName) {
        Map<String, Object> body = new LinkedHashMap<String, Object>();
        if (identity != null && !identity.trim().isEmpty()) {
            body.put("identity", identity.trim());
        }
        if (displayName != null && !displayName.trim().isEmpty()) {
            body.put("displayName", displayName.trim());
        }
        if (body.isEmpty()) {
            return;
        }
        requisicao("POST", "/api/internal/academic/users/" + RedeUtils.urlEncode(userId) + "/sync", body);
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> obterDadosLgpdUsuario(String userId) {
        Object res = requisicao("GET", "/api/internal/academic/users/" + RedeUtils.urlEncode(userId) + "/lgpd-data", null);
        return res instanceof Map ? (Map<String, Object>) res : Collections.<String, Object>emptyMap();
    }

    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> listarSalasUsuario(String userId, String profile, String identity) {
        String path = "/api/internal/academic/video-call/rooms?userId=" + RedeUtils.urlEncode(userId)
                + "&profile=" + RedeUtils.urlEncode(profile)
                + "&identity=" + RedeUtils.urlEncode(identity != null ? identity : "");
        Object res = requisicao("GET", path, null);
        List<Map<String, Object>> lista = new ArrayList<Map<String, Object>>();
        if (res instanceof List) {
            for (Object item : (List<?>) res) {
                if (item instanceof Map) {
                    lista.add((Map<String, Object>) item);
                }
            }
        }
        return lista;
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> autorizarSala(String userId, String profile, String identity, String roomCode) {
        String path = "/api/internal/academic/video-call/authorize?userId=" + RedeUtils.urlEncode(userId)
                + "&profile=" + RedeUtils.urlEncode(profile)
                + "&identity=" + RedeUtils.urlEncode(identity != null ? identity : "")
                + "&roomCode=" + RedeUtils.urlEncode(roomCode);
        Object res = requisicao("GET", path, null);
        return res instanceof Map ? (Map<String, Object>) res : Collections.<String, Object>emptyMap();
    }

    public void registrarPresencaSala(String classCode, String userId, String identity, boolean isConnected) {
        Map<String, Object> body = new LinkedHashMap<String, Object>();
        body.put("classCode", classCode);
        body.put("userId", userId);
        if (identity != null && !identity.trim().isEmpty()) {
            body.put("identity", identity.trim());
        }
        body.put("isConnected", Boolean.valueOf(isConnected));
        requisicao("POST", "/api/internal/academic/video-call/presence", body);
    }

    private Object requisicao(String metodo, String path, Map<String, Object> body) {
        HttpURLConnection conn = null;
        try {
            URL url = new URL(baseUrl + path);
            conn = RedeUtils.isLoopbackHost(url.getHost())
                    ? (HttpURLConnection) url.openConnection(Proxy.NO_PROXY)
                    : (HttpURLConnection) url.openConnection();
            conn.setRequestMethod(metodo);
            conn.setRequestProperty("Accept", "application/json");
            conn.setRequestProperty("X-Internal-Service-Secret", internalSecret);
            conn.setConnectTimeout(TIMEOUT_MS);
            conn.setReadTimeout(TIMEOUT_MS);

            if (body != null) {
                conn.setDoOutput(true);
                conn.setRequestProperty("Content-Type", "application/json; charset=utf-8");
                byte[] bytes = Json.escrever(body).getBytes(StandardCharsets.UTF_8);
                OutputStream os = conn.getOutputStream();
                os.write(bytes);
                os.flush();
                os.close();
            }

            int status = conn.getResponseCode();
            InputStream stream = status >= 200 && status < 400 ? conn.getInputStream() : conn.getErrorStream();
            String payload = RedeUtils.lerStreamUtf8(stream);

            if (status >= 200 && status < 300) {
                if (payload.trim().isEmpty()) {
                    return Collections.emptyMap();
                }
                return Json.analisar(payload);
            }

            throw construirExcecaoErro(status, payload);
        } catch (ExcecaoPonteAcademica e) {
            throw e;
        } catch (IOException e) {
            throw new ExcecaoPonteAcademica(503, "academic_service_unavailable",
                    "Servico academico (:3001) indisponivel para concluir esta operacao.");
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }
    }

    private static ExcecaoPonteAcademica construirExcecaoErro(int status, String payload) {
        String codigo = "academic_bridge_error";
        String mensagem = "Erro na comunicacao com o servico academico (HTTP " + status + ").";
        try {
            if (!payload.trim().isEmpty()) {
                Object decoded = Json.analisar(payload);
                if (decoded instanceof Map) {
                    Map<?, ?> mapa = (Map<?, ?>) decoded;
                    if (mapa.get("code") instanceof String) {
                        codigo = (String) mapa.get("code");
                    }
                    if (mapa.get("message") instanceof String) {
                        mensagem = (String) mapa.get("message");
                    } else if (mapa.get("erro") instanceof String) {
                        mensagem = (String) mapa.get("erro");
                    }
                }
            }
        } catch (Exception ignored) { }
        return new ExcecaoPonteAcademica(status, codigo, mensagem);
    }
}
