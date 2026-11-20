// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
package core;

import bridge.ClientePonteAcademica;
import utils.ConfigEnv;
import utils.RedeUtils;

import java.net.HttpURLConnection;
import java.net.Proxy;
import java.net.URL;

/**
 * Monitor leve (com cache curto) da disponibilidade do Backend Academico TypeScript (:3001).
 *
 * Implementa politica Fail-Closed simetrica no servidor Java (:8080):
 * quando ativado em runtime (Main.java), se o Backend Academico (:3001) cair ou for desligado,
 * todas as rotas funcionais passam a retornar HTTP 503 (academic_service_unavailable),
 * preservando apenas /health e /health/ready livres para diagnostico.
 */
public final class MonitorBackendAcademico {
    private static final int PROBE_TIMEOUT_MS = 2_000;
    private static final long CACHE_OK_MS = 3_000L;
    private static final long CACHE_FALHA_MS = 1_000L;

    private static volatile boolean ativo = false;
    private static volatile String baseUrlConfigurada = resolverBaseUrl();
    private static volatile long ultimoCheckMs = 0L;
    private static volatile boolean ultimoResultadoOnline = false;

    private MonitorBackendAcademico() {}

    private static String resolverBaseUrl() {
        String env = ConfigEnv.obter("ACADEMIC_API_BASE_URL", null);
        if (env == null || env.trim().isEmpty()) {
            env = ConfigEnv.obter("API_BASE_URL", "http://127.0.0.1:3001");
        }
        String limpa = RedeUtils.limparBarraFinal(env);
        return limpa.isEmpty() ? "http://127.0.0.1:3001" : limpa;
    }

    /**
     * Ativa o monitor em runtime caso REQUIRE_ACADEMIC_BACKEND_ONLINE nao seja "false".
     */
    public static void ativarSeConfigurado() {
        String flag = ConfigEnv.obter("REQUIRE_ACADEMIC_BACKEND_ONLINE", "true");
        boolean habilitar = !"false".equalsIgnoreCase(flag);
        configurar(habilitar, resolverBaseUrl());
    }

    /**
     * Configura explicitamente o estado e URL do monitor (util em runtime e testes).
     */
    public static void configurar(boolean habilitar, String baseUrl) {
        ativo = habilitar;
        String limpa = RedeUtils.limparBarraFinal(baseUrl);
        baseUrlConfigurada = limpa.isEmpty() ? "http://127.0.0.1:3001" : limpa;
        ultimoCheckMs = 0L;
        ultimoResultadoOnline = false;
    }

    public static void desativar() {
        ativo = false;
        ultimoCheckMs = 0L;
        ultimoResultadoOnline = false;
    }

    public static boolean estaAtivo() {
        return ativo;
    }

    /**
     * Verifica (com cache curto) se o Backend Academico (:3001) responde HTTP 200 em /health.
     */
    public static boolean verificarOnline() {
        long agora = System.currentTimeMillis();
        long ttl = ultimoResultadoOnline ? CACHE_OK_MS : CACHE_FALHA_MS;
        if (ultimoCheckMs > 0L && (agora - ultimoCheckMs) < ttl) {
            return ultimoResultadoOnline;
        }
        boolean ok = executarProbeHealth(baseUrlConfigurada);
        ultimoResultadoOnline = ok;
        ultimoCheckMs = System.currentTimeMillis();
        return ok;
    }

    /**
     * Quando ativo, exige que o Backend Academico (:3001) esteja online; caso contrario lanca HTTP 503.
     */
    public static void garantirOnlineSeAtivo() {
        if (!ativo) {
            return;
        }
        if (!verificarOnline()) {
            throw new ClientePonteAcademica.ExcecaoPonteAcademica(
                    503,
                    "academic_service_unavailable",
                    "Backend Academico (:3001) desligado ou fora do ar. Operacao bloqueada."
            );
        }
    }

    private static boolean executarProbeHealth(String baseUrl) {
        HttpURLConnection conn = null;
        try {
            URL url = new URL(baseUrl + "/health");
            conn = RedeUtils.isLoopbackHost(url.getHost())
                    ? (HttpURLConnection) url.openConnection(Proxy.NO_PROXY)
                    : (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setRequestProperty("Accept", "application/json");
            conn.setConnectTimeout(PROBE_TIMEOUT_MS);
            conn.setReadTimeout(PROBE_TIMEOUT_MS);
            int status = conn.getResponseCode();
            return status >= 200 && status < 300;
        } catch (Exception e) {
            return false;
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }
    }
}
