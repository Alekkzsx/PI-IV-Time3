// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Tier 1 & Tier 2: Brute-Force Rate Limiting & Cooldown Test Suite
/// Tests Features 12, 13, 14, 15 and Acceptance Criteria AC-01, AC-02, AC-03.

import 'dart:async';

// Reference Contract Implementation for Progressive Testability
class LockoutState {
  final int failedAttempts;
  final bool isLockedOut;
  final int remainingLockoutSeconds;
  final DateTime? lockoutEnd;

  const LockoutState({
    required this.failedAttempts,
    required this.isLockedOut,
    required this.remainingLockoutSeconds,
    this.lockoutEnd,
  });

  factory LockoutState.unlocked() => const LockoutState(
        failedAttempts: 0,
        isLockedOut: false,
        remainingLockoutSeconds: 0,
      );
}

class RateLimiter {
  static const int maxFailedAttempts = 5;
  static const int lockoutDurationSeconds = 30;

  final Map<String, int> _failures = {};
  final Map<String, DateTime> _lockoutEnds = {};

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
        // Cooldown has elapsed - auto reset
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

  bool checkAllowed(String identity, {DateTime? now}) {
    final state = getState(identity, now: now);
    return !state.isLockedOut;
  }

  void recordFailure(String identity, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final state = getState(identity, now: currentTime);
    if (state.isLockedOut) {
      return; // Already locked out
    }

    final currentAttempts = (_failures[identity] ?? 0) + 1;
    _failures[identity] = currentAttempts;

    if (currentAttempts >= maxFailedAttempts) {
      _lockoutEnds[identity] =
          currentTime.add(const Duration(seconds: lockoutDurationSeconds));
    }
  }

  void recordSuccess(String identity) {
    _failures.remove(identity);
    _lockoutEnds.remove(identity);
  }

  void resetAll() {
    _failures.clear;
    _lockoutEnds.clear();
  }
}

// Lightweight Test Assertion Harness
void assertTrue(bool condition, String message) {
  if (!condition) {
    throw Exception('Assertion failed: $message');
  }
}

void assertFalse(bool condition, String message) {
  if (condition) {
    throw Exception('Assertion failed (expected false): $message');
  }
}

void assertEqual(dynamic actual, dynamic expected, String message) {
  if (actual != expected) {
    throw Exception('$message — expected: $expected, got: $actual');
  }
}

int passedTests = 0;
int totalTests = 0;

void runTest(String name, void Function() testFn) {
  totalTests++;
  try {
    testFn();
    passedTests++;
    print('  [PASS] $name');
  } catch (e) {
    print('  [FAIL] $name: $e');
  }
}

void main() {
  print('===============================================================');
  print('Running Rate Limiter & Brute-Force Tests (Features 12-15)');
  print('===============================================================');

  final rateLimiter = RateLimiter();

  // -------------------------------------------------------------
  // TIER 1: FEATURE COVERAGE
  // -------------------------------------------------------------
  runTest('T1-01: Initial state is unlocked with 0 failed attempts', () {
    final state = rateLimiter.getState('user1@example.com');
    assertFalse(state.isLockedOut, 'Should not be locked out initially');
    assertEqual(state.failedAttempts, 0, 'Initial attempts must be 0');
    assertEqual(state.remainingLockoutSeconds, 0, 'Remaining seconds must be 0');
    assertTrue(rateLimiter.checkAllowed('user1@example.com'), 'Initial login must be allowed');
  });

  runTest('T1-02: Consecutive failures increment attempt counter correctly', () {
    final id = 'student_24802449';
    rateLimiter.resetAll();

    for (int i = 1; i <= 4; i++) {
      rateLimiter.recordFailure(id);
      final state = rateLimiter.getState(id);
      assertEqual(state.failedAttempts, i, 'Attempts should be $i');
      assertFalse(state.isLockedOut, 'Should not be locked out at $i attempts');
      assertTrue(rateLimiter.checkAllowed(id), 'Should still be allowed at $i attempts');
    }
  });

  runTest('T1-03: 5th consecutive failure triggers 30-second lockout (AC-01)', () {
    final id = 'student_lockout_test';
    rateLimiter.resetAll();
    final t0 = DateTime(2026, 10, 15, 12, 0, 0);

    for (int i = 1; i <= 4; i++) {
      rateLimiter.recordFailure(id, now: t0);
    }
    // 5th failure
    rateLimiter.recordFailure(id, now: t0);

    final state = rateLimiter.getState(id, now: t0);
    assertTrue(state.isLockedOut, '5th attempt must trigger lockout');
    assertEqual(state.failedAttempts, 5, 'Failed attempts must be 5');
    assertEqual(state.remainingLockoutSeconds, 30, 'Initial countdown must be 30 seconds');
    assertFalse(rateLimiter.checkAllowed(id, now: t0), 'Login must be blocked');
  });

  runTest('T1-04: Successful authentication resets failed attempt counter (AC-03)', () {
    final id = 'student_reset_counter';
    rateLimiter.resetAll();

    // 3 failed attempts
    for (int i = 0; i < 3; i++) {
      rateLimiter.recordFailure(id);
    }
    assertEqual(rateLimiter.getState(id).failedAttempts, 3, 'Should have 3 failures');

    // Successful login
    rateLimiter.recordSuccess(id);
    final state = rateLimiter.getState(id);
    assertEqual(state.failedAttempts, 0, 'Counter must reset to 0 upon success');
    assertFalse(state.isLockedOut, 'Account must remain unlocked');
    assertTrue(rateLimiter.checkAllowed(id), 'Login must be allowed');
  });

  // -------------------------------------------------------------
  // TIER 2: BOUNDARY & CORNER CASES
  // -------------------------------------------------------------
  runTest('T2-01: Boundary attempt 4 vs 5', () {
    final id = 'boundary_test';
    rateLimiter.resetAll();

    for (int i = 1; i <= 4; i++) {
      rateLimiter.recordFailure(id);
    }
    assertTrue(rateLimiter.checkAllowed(id), 'Attempt 4 must remain allowed');

    rateLimiter.recordFailure(id);
    assertFalse(rateLimiter.checkAllowed(id), 'Attempt 5 must be rejected');
  });

  runTest('T2-02: Lockout cooldown timeline: 0s, 15s, 29.9s (blocked) vs 30.1s (cleared) (AC-02)', () {
    final id = 'timeline_test';
    rateLimiter.resetAll();
    final t0 = DateTime(2026, 10, 15, 12, 0, 0);

    for (int i = 0; i < 5; i++) {
      rateLimiter.recordFailure(id, now: t0);
    }

    // At t0 + 15 seconds: still locked out, 15s remaining
    final t15 = t0.add(const Duration(seconds: 15));
    final state15 = rateLimiter.getState(id, now: t15);
    assertTrue(state15.isLockedOut, 'Should still be locked out at 15s');
    assertEqual(state15.remainingLockoutSeconds, 15, 'Should have 15s remaining');
    assertFalse(rateLimiter.checkAllowed(id, now: t15), 'Attempt at 15s must be rejected');

    // At t0 + 29s: still locked out, 1s remaining
    final t29 = t0.add(const Duration(seconds: 29));
    final state29 = rateLimiter.getState(id, now: t29);
    assertTrue(state29.isLockedOut, 'Should be locked out at 29s');
    assertEqual(state29.remainingLockoutSeconds, 1, 'Should have 1s remaining');

    // At t0 + 30.1s: lockout auto-clears
    final t31 = t0.add(const Duration(seconds: 31));
    final state31 = rateLimiter.getState(id, now: t31);
    assertFalse(state31.isLockedOut, 'Lockout must auto-clear after 30s');
    assertEqual(state31.failedAttempts, 0, 'Counter must be reset to 0');
    assertTrue(rateLimiter.checkAllowed(id, now: t31), 'Login must be permitted after cooldown');
  });

  runTest('T2-03: Multi-identity isolation (attacking user A does not lock out user B)', () {
    rateLimiter.resetAll();
    final userA = 'victim@example.com';
    final userB = 'innocent@example.com';

    for (int i = 0; i < 5; i++) {
      rateLimiter.recordFailure(userA);
    }

    assertTrue(rateLimiter.getState(userA).isLockedOut, 'User A must be locked out');
    assertFalse(rateLimiter.getState(userB).isLockedOut, 'User B must NOT be locked out');
    assertTrue(rateLimiter.checkAllowed(userB), 'User B must be allowed to login');
  });

  print('---------------------------------------------------------------');
  print('Rate Limiter Tests: $passedTests / $totalTests passed.');
  if (passedTests != totalTests) {
    throw Exception('Some tests failed in rate_limiter_test.dart');
  }
}
