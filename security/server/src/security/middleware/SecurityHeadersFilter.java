// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.middleware;

import com.sun.net.httpserver.HttpExchange;
import security.policies.SecurityConstants;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Defensive HTTP security header filter for native Java HTTP server.
 * Injects nosniff, frame rejection, CSP, and CORS policies onto outgoing responses.
 */
public class SecurityHeadersFilter {

    /**
     * Returns the standardized hardened security headers map.
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
     * Applies defensive headers directly to a native Sun {@link HttpExchange}.
     */
    public static void applyHeaders(HttpExchange exchange) {
        if (exchange == null) return;
        Map<String, String> headers = getHardenedHeaders();
        for (Map.Entry<String, String> entry : headers.entrySet()) {
            exchange.getResponseHeaders().set(entry.getKey(), entry.getValue());
        }
    }
}

