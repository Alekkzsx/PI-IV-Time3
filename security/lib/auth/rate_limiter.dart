// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/security_constants.dart';
import 'lockout_state.dart';

/// In-memory brute-force rate limiter and account lockout manager.
/// Enforces a 30-second lockout cooldown after 5 consecutive failed authentication attempts.
class RateLimiter {
  static const int maxFailedAttempts = SecurityConstants.maxFailedLoginAttempts;
  static const int lockoutDurationSeconds = SecurityConstants.lockoutDurationSeconds;

  final Map<String, int> _failures = {};
  final Map<String, DateTime> _lockoutEnds = {};

  /// Retrieves the current lockout state for a given identity.
  /// Automatically resets the state if the cooldown period has elapsed.
  LockoutState getState(String identity, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final lockoutEnd = _lockoutEnds[identity];

    if (lockoutEnd != null) {
      if (currentTime.isBefore(lockoutEnd)) {
        final remaining = lockoutEnd.difference(currentTime).inSeconds;
        return LockoutState(
          failedAttempts: _failures[identity] ?? maxFailedAttempts,
          isLockedOut: true,
          remainingLockoutSeconds: remaining > 0 ? remaining : 1,
          lockoutEnd: lockoutEnd,
        );
      } else {
        // Cooldown has elapsed - automatically reset
        _failures.remove(identity);
        _lockoutEnds.remove(identity);
        return LockoutState.unlocked();
      }
    }

    final attempts = _failures[identity] ?? 0;
    return LockoutState(
      failedAttempts: attempts,
      isLockedOut: false,
      remainingLockoutSeconds: 0,
    );
  }

  /// Checks if an authentication attempt is currently allowed for the identity.
  bool checkAllowed(String identity, {DateTime? now}) {
    final state = getState(identity, now: now);
    return !state.isLockedOut;
  }

  /// Records a failed authentication attempt.
  /// If failures reach [maxFailedAttempts], initiates the 30-second lockout cooldown.
  void recordFailure(String identity, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final state = getState(identity, now: currentTime);
    if (state.isLockedOut) {
      return; // Already locked out; do not extend existing window
    }

    final currentAttempts = (_failures[identity] ?? 0) + 1;
    _failures[identity] = currentAttempts;

    if (currentAttempts >= maxFailedAttempts) {
      _lockoutEnds[identity] =
          currentTime.add(const Duration(seconds: lockoutDurationSeconds));
    }
  }

  /// Records a successful authentication, resetting failed attempts and clearing lockouts.
  void recordSuccess(String identity) {
    _failures.remove(identity);
    _lockoutEnds.remove(identity);
  }

  /// Clears all state across all identities.
  void resetAll() {
    _failures.clear();
    _lockoutEnds.clear();
  }
}
