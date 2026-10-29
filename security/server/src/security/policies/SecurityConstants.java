// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.policies;

/**
 * Invariant security constants governing authentication, ephemeral tokens,
 * rate limiting, input bounds, and server headers for the AGMRM server.
 */
public final class SecurityConstants {

    private SecurityConstants() {
        // Prevent instantiation
    }

    // ─── EPHEMERAL TOKEN LIFECYCLE (R3) ───
    public static final int RECOVERY_TOKEN_TTL_SECONDS = 300;
    public static final int RECOVERY_TOKEN_TTL_MINUTES = 5;
    public static final int MAX_VERIFICATION_ATTEMPTS = 3;
    public static final int MAX_INVALID_VERIFICATION_ATTEMPTS = 3;
    public static final int OTP_CODE_LENGTH = 6;

    // ─── BRUTE-FORCE & LOCKOUT BOUNDARIES (R2) ───
    public static final int MAX_FAILED_LOGIN_ATTEMPTS = 5;
    public static final int LOCKOUT_DURATION_SECONDS = 30;

    // ─── PAYLOAD & REQUEST LIMITS (R4) ───
    public static final int MAX_REQUEST_BODY_SIZE_BYTES = 65536; // 64 KB
    public static final int MAX_BODY_SIZE_KB = 64;
    public static final int BUFFER_CHUNK_SIZE_BYTES = 4096;

    // ─── INPUT SANITIZATION & FIELD LENGTH BOUNDS (R2, R4) ───
    public static final int MIN_IDENTITY_LENGTH = 3;
    public static final int MAX_IDENTITY_LENGTH = 32;
    public static final int MAX_EMAIL_LENGTH = 254;
    public static final int MIN_PASSWORD_LENGTH = 8;
    public static final int MAX_PASSWORD_LENGTH = 128;

    // ─── PASSWORD ENTROPY VECTOR BOUNDS (R3) ───
    public static final int MIN_PASSWORD_ENTROPY_SCORE = 3;
    public static final int MIN_REQUIRED_ENTROPY_SCORE = 3;
    public static final int MAX_PASSWORD_ENTROPY_SCORE = 4;
    public static final int MAX_ENTROPY_SCORE = 4;

    // ─── SIDE-CHANNEL TIMING ATTACK MITIGATION (R2) ───
    public static final int STANDARDIZED_AUTH_LATENCY_MS = 1000;
    public static final int STANDARD_AUTH_LATENCY_MS = 1000;
    public static final int TIMING_JITTER_TOLERANCE_MS = 50;
    public static final int MIN_DUMMY_WORK_ITERATIONS = 10000;

    // ─── NETWORK, SERVER & CACHE DEFAULTS (R4) ───
    public static final int DEFAULT_SERVER_PORT = 8080;
    public static final String DEFAULT_SERVER_HOST = "0.0.0.0";
    public static final int DEFAULT_REQUEST_TIMEOUT_SECONDS = 30;
    public static final int CORS_MAX_AGE_SECONDS = 86400;

    // ─── DEFENSIVE HTTP SECURITY HEADERS (R4) ───
    public static final String HEADER_CONTENT_TYPE_OPTIONS = "nosniff";
    public static final String HEADER_X_CONTENT_TYPE_OPTIONS = "X-Content-Type-Options";
    public static final String HEADER_VALUE_NOSNIFF = "nosniff";

    public static final String HEADER_FRAME_OPTIONS = "DENY";
    public static final String HEADER_X_FRAME_OPTIONS = "X-Frame-Options";
    public static final String HEADER_VALUE_DENY = "DENY";

    public static final String HEADER_XSS_PROTECTION = "1; mode=block";
    public static final String HEADER_HSTS = "max-age=31536000; includeSubDomains";

    public static final String HEADER_CONTENT_SECURITY_POLICY = "Content-Security-Policy";
    public static final String HEADER_CSP =
        "default-src 'self'; script-src 'self'; object-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'self'; frame-ancestors 'none';";
    public static final String HEADER_VALUE_CSP_DEFAULT =
        "default-src 'none'; frame-ancestors 'none'; sandbox";

    public static final String HEADER_ACCESS_CONTROL_ALLOW_ORIGIN = "Access-Control-Allow-Origin";
    public static final String HEADER_VALUE_CORS_WILDCARD = "*";

    public static final String HEADER_CACHE_CONTROL = "Cache-Control";
    public static final String HEADER_VALUE_NO_STORE = "no-store, no-cache, must-revalidate, max-age=0";
    public static final String HEADER_PRAGMA = "no-cache";
}
