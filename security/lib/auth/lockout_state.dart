// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Immutable model representing the account lockout and rate limiting state.
class LockoutState {
  /// Number of consecutive failed attempts recorded.
  final int failedAttempts;

  /// Whether the account/identity is currently locked out in cooldown.
  final bool isLockedOut;

  /// Remaining seconds until the cooldown expires and submissions are unlocked.
  final int remainingLockoutSeconds;

  /// Timestamp when the lockout ends, or null if not locked out.
  final DateTime? lockoutEnd;

  const LockoutState({
    required this.failedAttempts,
    required this.isLockedOut,
    required this.remainingLockoutSeconds,
    this.lockoutEnd,
  });

  /// Factory creating an unlocked initial state with zero failed attempts.
  factory LockoutState.unlocked() => const LockoutState(
        failedAttempts: 0,
        isLockedOut: false,
        remainingLockoutSeconds: 0,
      );
}

