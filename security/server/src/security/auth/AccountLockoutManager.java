// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.auth;

import security.policies.SecurityConstants;

import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * Limitador de taxa (rate limiter) thread-safe no lado do servidor e gerenciador de bloqueio de conta contra força bruta.
 * Rastreia falhas consecutivas de login e bloqueia a identidade por 30 segundos após 5 falhas.
 */
public class AccountLockoutManager {

    public static class LockoutStatus {
        private final int failedAttempts;
        private final boolean isLockedOut;
        private final long remainingSeconds;

        public LockoutStatus(int failedAttempts, boolean isLockedOut, long remainingSeconds) {
            this.failedAttempts = failedAttempts;
            this.isLockedOut = isLockedOut;
            this.remainingSeconds = remainingSeconds;
        }

        public int getFailedAttempts() {
            return failedAttempts;
        }

        public boolean isLockedOut() {
            return isLockedOut;
        }

        public long getRemainingSeconds() {
            return remainingSeconds;
        }
    }

    private final ConcurrentMap<String, Integer> failureCounters = new ConcurrentHashMap<>();
    private final ConcurrentMap<String, Instant> lockoutExpirations = new ConcurrentHashMap<>();

    private final int maxAttempts;
    private final int lockoutDurationSeconds;

    public AccountLockoutManager() {
        this(SecurityConstants.MAX_FAILED_LOGIN_ATTEMPTS, SecurityConstants.LOCKOUT_DURATION_SECONDS);
    }

    public AccountLockoutManager(int maxAttempts, int lockoutDurationSeconds) {
        this.maxAttempts = maxAttempts;
        this.lockoutDurationSeconds = lockoutDurationSeconds;
    }

    /**
     * Obtém o status atual de bloqueio para uma identidade.
     * Limpa automaticamente os tempos de espera de bloqueio expirados.
     */
    public LockoutStatus getStatus(String identity) {
        Instant now = Instant.now();
        Instant expiry = lockoutExpirations.get(identity);

        if (expiry != null) {
            if (now.isBefore(expiry)) {
                long remaining = java.time.Duration.between(now, expiry).getSeconds();
                return new LockoutStatus(
                    failureCounters.getOrDefault(identity, maxAttempts),
                    true,
                    remaining > 0 ? remaining : 1
                );
            } else {
                // Expirado - limpar
                failureCounters.remove(identity);
                lockoutExpirations.remove(identity);
                return new LockoutStatus(0, false, 0);
            }
        }

        int attempts = failureCounters.getOrDefault(identity, 0);
        return new LockoutStatus(attempts, false, 0);
    }

    /**
     * Verifica se a identidade tem permissão para tentar autenticação.
     */
    public boolean checkAllowed(String identity) {
        return !getStatus(identity).isLockedOut();
    }

    /**
     * Registra uma tentativa de autenticação malsucedida.
     */
    public void recordFailure(String identity) {
        Instant now = Instant.now();
        LockoutStatus current = getStatus(identity);

        if (current.isLockedOut()) {
            return; // Já bloqueado; não estender
        }

        int newAttempts = failureCounters.compute(identity, (k, v) -> (v == null ? 1 : v + 1));
        if (newAttempts >= maxAttempts) {
            lockoutExpirations.put(identity, now.plusSeconds(lockoutDurationSeconds));
        }
    }

    /**
     * Registra uma autenticação bem-sucedida, reiniciando tentativas e bloqueios.
     */
    public void recordSuccess(String identity) {
        failureCounters.remove(identity);
        lockoutExpirations.remove(identity);
    }

    /**
     * Limpa todo o estado de rastreamento.
     */
    public void resetAll() {
        failureCounters.clear();
        lockoutExpirations.clear();
    }
}

