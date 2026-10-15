// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

package security.auth;

import security.policies.SecurityConstants;

import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * Thread-safe server-side rate limiter and brute-force account lockout manager.
 * Tracks consecutive failed logins and locks the identity for 30 seconds after 5 failures.
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
     * Retrieves the current lockout status for an identity.
     * Automatically clears expired lockout cooldowns.
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
                // Expired - clean up
                failureCounters.remove(identity);
                lockoutExpirations.remove(identity);
                return new LockoutStatus(0, false, 0);
            }
        }

        int attempts = failureCounters.getOrDefault(identity, 0);
        return new LockoutStatus(attempts, false, 0);
    }

    /**
     * Checks if the identity is permitted to attempt authentication.
     */
    public boolean checkAllowed(String identity) {
        return !getStatus(identity).isLockedOut();
    }

    /**
     * Records a failed authentication attempt.
     */
    public void recordFailure(String identity) {
        Instant now = Instant.now();
        LockoutStatus current = getStatus(identity);

        if (current.isLockedOut()) {
            return; // Already locked out; do not extend
        }

        int newAttempts = failureCounters.compute(identity, (k, v) -> (v == null ? 1 : v + 1));
        if (newAttempts >= maxAttempts) {
            lockoutExpirations.put(identity, now.plusSeconds(lockoutDurationSeconds));
        }
    }

    /**
     * Records a successful authentication, resetting attempts and lockouts.
     */
    public void recordSuccess(String identity) {
        failureCounters.remove(identity);
        lockoutExpirations.remove(identity);
    }

    /**
     * Clears all tracking state.
     */
    public void resetAll() {
        failureCounters.clear();
        lockoutExpirations.clear();
    }
}
