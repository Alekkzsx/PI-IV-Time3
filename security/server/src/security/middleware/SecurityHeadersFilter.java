// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.middleware;

import com.sun.net.httpserver.HttpExchange;
import security.policies.SecurityConstants;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Filtro defensivo de cabeçalhos de segurança HTTP para o servidor HTTP Java nativo.
 * Injeta políticas de nosniff, bloqueio de frames, CSP e CORS nas respostas enviadas.
 */
public class SecurityHeadersFilter {

    /**
     * Retorna o mapa padronizado de cabeçalhos de segurança reforçados.
     */
    public static Map<String, String> getHardenedHeaders() {
        Map<String, String> headers = new LinkedHashMap<>();
        headers.put("X-Content-Type-Options", "nosniff");
        headers.put("X-Frame-Options", "DENY");
        headers.put("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'; sandbox");
        headers.put("Access-Control-Allow-Origin", "*");
        headers.put("Cache-Control", "no-store, no-cache, must-revalidate");
        return headers;
    }

    /**
     * Aplica cabeçalhos defensivos diretamente a um {@link HttpExchange} nativo da Sun.
     */
    public static void applyHeaders(HttpExchange exchange) {
        if (exchange == null) return;
        Map<String, String> headers = getHardenedHeaders();
        for (Map.Entry<String, String> entry : headers.entrySet()) {
            exchange.getResponseHeaders().set(entry.getKey(), entry.getValue());
        }
    }
}

