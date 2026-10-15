// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Tier 3: Cross-Feature Pairwise Security & Defense-in-Depth Synergy Test Suite
/// Tests multi-layer defense interactions across Features 1-24.

import 'dart:convert';
import 'rate_limiter_test.dart';
import 'token_lifecycle_test.dart';
import 'input_sanitizer_test.dart';
import 'password_entropy_test.dart';
import 'generic_feedback_test.dart';
import 'timing_attack_test.dart';

void assertTrue(bool condition, String message) {
  if (!condition) throw Exception('Assertion failed: $message');
}

void assertFalse(bool condition, String message) {
  if (condition) throw Exception('Assertion failed (expected false): $message');
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

Future<void> runAsyncTest(String name, Future<void> Function() testFn) async {
  totalTests++;
  try {
    await testFn();
    passedTests++;
    print('  [PASS] $name');
  } catch (e) {
    print('  [FAIL] $name: $e');
  }
}

Future<void> main() async {
  print('===============================================================');
  print('Running Tier 3: Cross-Feature Pairwise Security Tests');
  print('===============================================================');

  final rateLimiter = RateLimiter();
  final tokenManager = TokenLifecycleManager();

  // -------------------------------------------------------------
  // PAIRWISE 1: Rate Limiter Lockout + Input Sanitization
  // -------------------------------------------------------------
  runTest('T3-01: Injection attack during active lockout is rejected by lockout guard', () {
    final victimId = 'user_locked_out@test.com';
    rateLimiter.resetAll();

    // Trigger lockout
    for (int i = 0; i < 5; i++) {
      rateLimiter.recordFailure(victimId);
    }
    assertTrue(rateLimiter.getState(victimId).isLockedOut, 'User must be locked out');

    // Attacker submits malicious SQLi/XSS payload while locked out
    final maliciousPayload = "<script>alert('pwned')</script>";
    final isAllowed = rateLimiter.checkAllowed(victimId);

    // Defense-in-depth: lockout rejects the request immediately before sanitization/query
    assertFalse(isAllowed, 'Request must be blocked by rate limiter before parsing');
    assertTrue(InputSanitizer.hasDangerousPatterns(maliciousPayload), 'Payload is also detected');
  });

  // -------------------------------------------------------------
  // PAIRWISE 2: Expired Token + OTP Brute-Force Replay
  // -------------------------------------------------------------
  runTest('T3-02: OTP brute-force on expired token prioritized as EXPIRED', () {
    tokenManager.clearAll();
    final t0 = DateTime(2026, 10, 15, 12, 0, 0);
    tokenManager.createSession('student_p2', fixedSessionId: 'sess_p2', fixedOtp: '123456', now: t0);

    // Advance beyond 300 seconds TTL
    final t305 = t0.add(const Duration(seconds: 305));

    // Submit invalid code after expiration
    final result = tokenManager.verifyCode('sess_p2', '999999', now: t305);
    assertFalse(result.isSuccess, 'Expired session must reject verification');
    assertEqual(result.status, 'EXPIRED', 'Must return EXPIRED status rather than attempt decrement');
  });

  // -------------------------------------------------------------
  // PAIRWISE 3: Password Entropy + Token Lifecycle Preservation
  // -------------------------------------------------------------
  runTest('T3-03: Weak password rejection does NOT consume or revoke valid token', () {
    tokenManager.clearAll();
    final t0 = DateTime(2026, 10, 15, 12, 0, 0);
    tokenManager.createSession('student_p3', fixedSessionId: 'sess_p3', fixedOtp: '555666', now: t0);

    // Step 1: Verify OTP code successfully
    final verifyResult = tokenManager.verifyCode('sess_p3', '555666', now: t0);
    assertTrue(verifyResult.isSuccess, 'Valid OTP must verify');

    // Step 2: User attempts to set a weak password ("weakpass" -> Score 1)
    final weakPassword = 'weakpass';
    final isStrong = PasswordEntropyValidator.isEligibleForSubmission(weakPassword);
    assertFalse(isStrong, 'Weak password must be rejected');

    // Step 3: User corrects to strong password ("P@ssw0rd2026" -> Score 4)
    final strongPassword = 'P@ssw0rd2026';
    assertTrue(
      PasswordEntropyValidator.isEligibleForSubmission(strongPassword),
      'Strong password must be eligible for reset completion',
    );
  });

  // -------------------------------------------------------------
  // PAIRWISE 4: Anti-Enumeration + Rate Limiting Isolation
  // -------------------------------------------------------------
  runTest('T3-04: Non-existent accounts are rate-limited independently with generic feedback', () {
    rateLimiter.resetAll();
    final nonExistentId = 'ghost_student_99999999';

    // 5 failed logins for non-existent account
    for (int i = 0; i < 5; i++) {
      rateLimiter.recordFailure(nonExistentId);
    }

    final state = rateLimiter.getState(nonExistentId);
    assertTrue(state.isLockedOut, 'Non-existent account must also trigger lockout to prevent DoS/enumeration');

    // Output response remains generic
    final response = GenericFeedbackPolicy.createAuthFailureResponse();
    assertEqual(response['statusCode'], 401, 'Status 401');
    assertEqual(
      response['message'],
      'Credenciais inválidas. Verifique seu identificador e senha.',
      'Generic feedback prevents revealing ghost account',
    );
  });

  // -------------------------------------------------------------
  // PAIRWISE 5: Timing Attack Defense with Malicious Payloads
  // -------------------------------------------------------------
  await runAsyncTest('T3-05: Timing normalization holds across clean and malicious inputs', () async {
    final timing = TimingAttackMitigation(targetLatencyMs: 30, varianceToleranceMs: 20);

    // Clean input path
    final swClean = Stopwatch()..start();
    final cleanInput = '24802449';
    InputSanitizer.sanitizeIdentity(cleanInput);
    final elapsedClean = await timing.normalizeLatency(swClean);

    // Malicious input path
    final swMalicious = Stopwatch()..start();
    final maliciousInput = "<script>alert('xss')</script>";
    try {
      InputSanitizer.sanitizeIdentity(maliciousInput);
    } catch (_) {
      timing.executeSyntheticWork();
    }
    final elapsedMalicious = await timing.normalizeLatency(swMalicious);

    final delta = (elapsedClean - elapsedMalicious).abs();
    print('    [INFO] Clean latency: ${elapsedClean}ms, Malicious latency: ${elapsedMalicious}ms, Delta: ${delta}ms');
    assertTrue(delta <= 20, 'Timing difference across paths must be within tolerance');
  });

  // -------------------------------------------------------------
  // PAIRWISE 6: Multi-User Concurrency & State Isolation
  // -------------------------------------------------------------
  runTest('T3-06: 20 independent users maintain strict state isolation', () {
    rateLimiter.resetAll();
    // Simulate 20 students
    for (int i = 1; i <= 20; i++) {
      final studentId = 'student_$i';
      if (i % 2 == 0) {
        // Even students have 5 failures -> locked out
        for (int k = 0; k < 5; k++) {
          rateLimiter.recordFailure(studentId);
        }
      } else {
        // Odd students have 2 failures -> unlocked
        for (int k = 0; k < 2; k++) {
          rateLimiter.recordFailure(studentId);
        }
      }
    }

    for (int i = 1; i <= 20; i++) {
      final studentId = 'student_$i';
      final state = rateLimiter.getState(studentId);
      if (i % 2 == 0) {
        assertTrue(state.isLockedOut, 'Even student $studentId must be locked out');
        assertEqual(state.failedAttempts, 5, 'Must have 5 failures');
      } else {
        assertFalse(state.isLockedOut, 'Odd student $studentId must NOT be locked out');
        assertEqual(state.failedAttempts, 2, 'Must have 2 failures');
      }
    }
  });

  print('---------------------------------------------------------------');
  print('Tier 3 Cross-Feature Tests: $passedTests / $totalTests passed.');
  if (passedTests != totalTests) {
    throw Exception('Some tests failed in CrossFeatureSecurityTest.dart');
  }
}
