// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.middleware;

/**
 * Server-side error sanitizer preventing information disclosure and stack trace leakage.
 * Converts raw Java runtime exceptions into opaque, standardized JSON payloads.
 */
public class ServerErrorSanitizer {

    /**
     * Sanitizes client-side input errors and malformed requests into RFC compliant JSON.
     * Never exposes JVM stack traces, file paths, or internal class names.
     */
    public static String sanitizeException(Throwable t) {
        return "{\"status\": 400, \"error\": \"Bad Request\", \"message\": \"Dados invalidos\"}";
    }

    /**
     * Sanitizes unhandled internal exceptions into opaque HTTP 500 JSON payloads.
     */
    public static String sanitizeInternalError(Throwable t) {
        return "{\"status\": 500, \"error\": \"Internal Server Error\", \"message\": \"Ocorreu um erro interno\"}";
    }
}

