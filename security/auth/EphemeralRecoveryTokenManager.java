// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.auth;

import security.policies.SecurityConstants;

import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * Server-side ephemeral recovery token and OTP session manager.
 * Enforces a strict 300-second (5-minute) TTL and revokes sessions after 3 invalid code attempts.
 */
public class EphemeralRecoveryTokenManager {

    public enum SessionStatus {
        ACTIVE,
        EXPIRED,
        REVOKED,
        CONSUMED
    }

    public static class RecoverySession {
        private final String sessionId;
        private final String identifier;
        private final String otpCode;
        private final Instant createdAt;
        private final long ttlSeconds;
        private int invalidAttempts;
        private SessionStatus status;

        public RecoverySession(String sessionId, String identifier, String otpCode, Instant createdAt, long ttlSeconds) {
            this.sessionId = sessionId;
            this.identifier = identifier;
            this.otpCode = otpCode;
            this.createdAt = createdAt;
            this.ttlSeconds = ttlSeconds;
            this.invalidAttempts = 0;
            this.status = SessionStatus.ACTIVE;
        }

        public String getSessionId() { return sessionId; }
        public String getIdentifier() { return identifier; }
        public String getOtpCode() { return otpCode; }
        public Instant getCreatedAt() { return createdAt; }
        public long getTtlSeconds() { return ttlSeconds; }
        public int getInvalidAttempts() { return invalidAttempts; }
        public SessionStatus getStatus() { return status; }

        public boolean isExpired() {
            return Instant.now().isAfter(createdAt.plusSeconds(ttlSeconds));
        }

        public long getRemainingSeconds() {
            Instant now = Instant.now();
            Instant expiry = createdAt.plusSeconds(ttlSeconds);
            if (now.isAfter(expiry)) return 0;
            return java.time.Duration.between(now, expiry).getSeconds();
        }
    }

    public static class VerificationResult {
        private final boolean success;
        private final String status;
        private final String message;
        private final int remainingAttempts;

        public VerificationResult(boolean success, String status, String message, int remainingAttempts) {
            this.success = success;
            this.status = status;
            this.message = message;
            this.remainingAttempts = remainingAttempts;
        }

        public boolean isSuccess() { return success; }
        public String getStatus() { return status; }
        public String getMessage() { return message; }
        public int getRemainingAttempts() { return remainingAttempts; }
    }

    private final ConcurrentMap<String, RecoverySession> sessions = new ConcurrentHashMap<>();
    private final int maxAttempts;
    private final long ttlSeconds;

    public EphemeralRecoveryTokenManager() {
        this(SecurityConstants.MAX_VERIFICATION_ATTEMPTS, SecurityConstants.RECOVERY_TOKEN_TTL_SECONDS);
    }

    public EphemeralRecoveryTokenManager(int maxAttempts, long ttlSeconds) {
        this.maxAttempts = maxAttempts;
        this.ttlSeconds = ttlSeconds;
    }

    /**
     * Creates and registers a new recovery session with 300s TTL.
     */
    public RecoverySession createSession(String identifier, String otpCode) {
        String sessionId = UUID.randomUUID().toString();
        RecoverySession session = new RecoverySession(sessionId, identifier, otpCode, Instant.now(), ttlSeconds);
        sessions.put(sessionId, session);
        return session;
    }

    /**
     * Checks if a session is currently active and within its TTL.
     */
    public boolean isSessionValid(String sessionId) {
        RecoverySession session = sessions.get(sessionId);
        if (session == null) return false;
        if (session.status != SessionStatus.ACTIVE) return false;
        if (session.isExpired()) {
            session.status = SessionStatus.EXPIRED;
            return false;
        }
        return true;
    }

    /**
     * Verifies the submitted OTP code using constant-time comparison.
     */
    public VerificationResult verifyCode(String sessionId, String submittedCode) {
        RecoverySession session = sessions.get(sessionId);
        if (session == null) {
            return new VerificationResult(false, "NOT_FOUND", "Sessao inexistente", 0);
        }

        if (session.status == SessionStatus.REVOKED) {
            return new VerificationResult(false, "REVOKED", "Sessao revogada por excesso de tentativas.", 0);
        }

        if (session.status == SessionStatus.CONSUMED) {
            return new VerificationResult(false, "CONSUMED", "Codigo ja utilizado.", 0);
        }

        if (session.isExpired()) {
            session.status = SessionStatus.EXPIRED;
            return new VerificationResult(false, "EXPIRED", "Codigo expirado. Solicite um novo codigo.", 0);
        }

        if (ConstantTimeComparator.isEqual(session.otpCode, submittedCode)) {
            session.status = SessionStatus.CONSUMED;
            return new VerificationResult(true, "SUCCESS", "Codigo verificado com sucesso.", maxAttempts - session.invalidAttempts);
        } else {
            session.invalidAttempts++;
            if (session.invalidAttempts >= maxAttempts) {
                session.status = SessionStatus.REVOKED;
                return new VerificationResult(false, "REVOKED", "Sessao revogada por excesso de tentativas.", 0);
            }
            int remaining = maxAttempts - session.invalidAttempts;
            return new VerificationResult(false, "INVALID_CODE", "Codigo incorreto. " + remaining + " tentativa(s) restante(s).", remaining);
        }
    }

    public void clearAll() {
        sessions.clear();
    }
}
