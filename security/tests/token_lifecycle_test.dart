// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Tier 1 & Tier 2: Ephemeral Token Lifecycle & OTP Invalidation Test Suite
/// Tests Features 19, 20, 21 and Acceptance Criteria AC-07, AC-08.

enum RecoverySessionStatus { active, expired, revoked, consumed }

class RecoverySession {
  final String sessionId;
  final String identifier;
  final String otpCode;
  final DateTime createdAt;
  final int ttlSeconds;
  int invalidAttempts;
  RecoverySessionStatus status;

  RecoverySession({
    required this.sessionId,
    required this.identifier,
    required this.otpCode,
    required this.createdAt,
    this.ttlSeconds = 300,
    this.invalidAttempts = 0,
    this.status = RecoverySessionStatus.active,
  });

  bool isExpired({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    return currentTime.isAfter(createdAt.add(Duration(seconds: ttlSeconds)));
  }

  int remainingSeconds({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final expiry = createdAt.add(Duration(seconds: ttlSeconds));
    if (currentTime.isAfter(expiry)) return 0;
    return expiry.difference(currentTime).inSeconds;
  }
}

class TokenLifecycleManager {
  static const int defaultTtlSeconds = 300; // 5 minutes
  static const int maxOtpAttempts = 3;

  final Map<String, RecoverySession> _sessions = {};

  RecoverySession createSession(
    String identifier, {
    String? fixedSessionId,
    String? fixedOtp,
    DateTime? now,
  }) {
    final sessionId = fixedSessionId ??
        'session_${identifier}_${DateTime.now().microsecondsSinceEpoch}';
    final otpCode = fixedOtp ?? '123456';
    final session = RecoverySession(
      sessionId: sessionId,
      identifier: identifier,
      otpCode: otpCode,
      createdAt: now ?? DateTime.now(),
      ttlSeconds: defaultTtlSeconds,
    );
    _sessions[sessionId] = session;
    return session;
  }

  bool isSessionValid(String sessionId, {DateTime? now}) {
    final session = _sessions[sessionId];
    if (session == null) return false;
    if (session.status != RecoverySessionStatus.active) return false;
    if (session.isExpired(now: now)) {
      session.status = RecoverySessionStatus.expired;
      return false;
    }
    return true;
  }

  VerifyResult verifyCode(
    String sessionId,
    String submittedCode, {
    DateTime? now,
  }) {
    final session = _sessions[sessionId];
    if (session == null) {
      return VerifyResult.notFound('Sessão inexistente');
    }

    if (session.status == RecoverySessionStatus.revoked) {
      return VerifyResult.revoked(
        'Sessão revogada por excesso de tentativas. Solicite um novo código.',
      );
    }

    if (session.status == RecoverySessionStatus.consumed) {
      return VerifyResult.consumed('Código já utilizado.');
    }

    if (session.isExpired(now: now)) {
      session.status = RecoverySessionStatus.expired;
      return VerifyResult.expired(
        'Código expirado. Solicite um novo código.',
      );
    }

    if (session.otpCode == submittedCode) {
      session.status = RecoverySessionStatus.consumed;
      return VerifyResult.success('Código verificado com sucesso.');
    } else {
      session.invalidAttempts++;
      if (session.invalidAttempts >= maxOtpAttempts) {
        session.status = RecoverySessionStatus.revoked;
        return VerifyResult.revoked(
          'Sessão revogada por excesso de tentativas. Solicite um novo código.',
        );
      }
      final remainingAttempts = maxOtpAttempts - session.invalidAttempts;
      return VerifyResult.invalidCode(
        'Código incorreto. $remainingAttempts tentativa(s) restante(s).',
        remainingAttempts,
      );
    }
  }

  void clearAll() {
    _sessions.clear();
  }
}

class VerifyResult {
  final bool isSuccess;
  final String status;
  final String message;
  final int? remainingAttempts;

  const VerifyResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.remainingAttempts,
  });

  factory VerifyResult.success(String msg) =>
      VerifyResult(isSuccess: true, status: 'SUCCESS', message: msg);

  factory VerifyResult.notFound(String msg) =>
      VerifyResult(isSuccess: false, status: 'NOT_FOUND', message: msg);

  factory VerifyResult.invalidCode(String msg, int remaining) => VerifyResult(
        isSuccess: false,
        status: 'INVALID_CODE',
        message: msg,
        remainingAttempts: remaining,
      );

  factory VerifyResult.revoked(String msg) =>
      VerifyResult(isSuccess: false, status: 'REVOKED', message: msg);

  factory VerifyResult.expired(String msg) =>
      VerifyResult(isSuccess: false, status: 'EXPIRED', message: msg);

  factory VerifyResult.consumed(String msg) =>
      VerifyResult(isSuccess: false, status: 'CONSUMED', message: msg);
}

// Assertion Helpers
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

void main() {
  print('===============================================================');
  print('Running Token Lifecycle & Expiration Tests (Features 19-21)');
  print('===============================================================');

  final manager = TokenLifecycleManager();

  // -------------------------------------------------------------
  // TIER 1: FEATURE COVERAGE
  // -------------------------------------------------------------
  runTest('T1-01: Session creation generates 300s TTL token', () {
    manager.clearAll();
    final t0 = DateTime(2026, 10, 15, 12, 0, 0);
    final session = manager.createSession(
      'student_24802449',
      fixedSessionId: 'sess_01',
      fixedOtp: '654321',
      now: t0,
    );

    assertEqual(session.ttlSeconds, 300, 'TTL must be exactly 300 seconds');
    assertEqual(session.status, RecoverySessionStatus.active, 'Must be active');
    assertEqual(session.remainingSeconds(now: t0), 300, 'Initial remaining: 300s');
    assertTrue(manager.isSessionValid('sess_01', now: t0), 'Session must be valid at creation');
  });

  runTest('T1-02: Correct OTP within TTL successfully verifies and consumes token', () {
    manager.clearAll();
    final t0 = DateTime(2026, 10, 15, 12, 0, 0);
    manager.createSession(
      'student_24802449',
      fixedSessionId: 'sess_02',
      fixedOtp: '789123',
      now: t0,
    );

    final t50 = t0.add(const Duration(seconds: 50));
    final result = manager.verifyCode('sess_02', '789123', now: t50);

    assertTrue(result.isSuccess, 'Correct code must succeed');
    assertEqual(result.status, 'SUCCESS', 'Status must be SUCCESS');
    assertFalse(manager.isSessionValid('sess_02', now: t50), 'Consumed session is no longer active');
  });

  runTest('T1-03: Re-submitting code to consumed token is rejected', () {
    final t51 = DateTime(2026, 10, 15, 12, 0, 51);
    final replayResult = manager.verifyCode('sess_02', '789123', now: t51);
    assertFalse(replayResult.isSuccess, 'Replay of consumed token must fail');
    assertEqual(replayResult.status, 'CONSUMED', 'Must indicate already consumed');
  });

  // -------------------------------------------------------------
  // TIER 2: BOUNDARY & CORNER CASES
  // -------------------------------------------------------------
  runTest('T2-01: Boundary TTL: 299s (valid) vs 300s vs 301s (expired) (AC-07)', () {
    manager.clearAll();
    final t0 = DateTime(2026, 10, 15, 12, 0, 0);
    manager.createSession(
      'student_ttl_test',
      fixedSessionId: 'sess_ttl',
      fixedOtp: '112233',
      now: t0,
    );

    // At 299 seconds: valid
    final t299 = t0.add(const Duration(seconds: 299));
    assertTrue(manager.isSessionValid('sess_ttl', now: t299), 'Must be valid at 299s');

    // At 301 seconds: expired
    final t301 = t0.add(const Duration(seconds: 301));
    assertFalse(manager.isSessionValid('sess_ttl', now: t301), 'Must be expired at 301s');

    final result = manager.verifyCode('sess_ttl', '112233', now: t301);
    assertFalse(result.isSuccess, 'Expired token verification must fail');
    assertEqual(result.status, 'EXPIRED', 'Must return EXPIRED status');
  });

  runTest('T2-02: 3-Attempt OTP invalidation threshold (AC-08)', () {
    manager.clearAll();
    final t0 = DateTime(2026, 10, 15, 12, 0, 0);
    manager.createSession(
      'student_attempts_test',
      fixedSessionId: 'sess_attempts',
      fixedOtp: '998877',
      now: t0,
    );

    // Attempt 1: wrong code
    final res1 = manager.verifyCode('sess_attempts', '000001', now: t0);
    assertFalse(res1.isSuccess, 'Attempt 1 should fail');
    assertEqual(res1.status, 'INVALID_CODE', 'Status should be INVALID_CODE');
    assertEqual(res1.remainingAttempts, 2, '2 attempts remaining');
    assertTrue(manager.isSessionValid('sess_attempts', now: t0), 'Session still valid');

    // Attempt 2: wrong code
    final res2 = manager.verifyCode('sess_attempts', '000002', now: t0);
    assertFalse(res2.isSuccess, 'Attempt 2 should fail');
    assertEqual(res2.remainingAttempts, 1, '1 attempt remaining');
    assertTrue(manager.isSessionValid('sess_attempts', now: t0), 'Session still valid');

    // Attempt 3: wrong code -> Permanent REVOCATION
    final res3 = manager.verifyCode('sess_attempts', '000003', now: t0);
    assertFalse(res3.isSuccess, 'Attempt 3 should fail');
    assertEqual(res3.status, 'REVOKED', 'Session must transition to REVOKED on 3rd failure');
    assertFalse(manager.isSessionValid('sess_attempts', now: t0), 'Revoked session is invalid');

    // Attempt 4: submitting the CORRECT code after revocation
    final res4 = manager.verifyCode('sess_attempts', '998877', now: t0);
    assertFalse(res4.isSuccess, 'Correct code on revoked session MUST be rejected');
    assertEqual(res4.status, 'REVOKED', 'Must remain permanently revoked');
  });

  runTest('T2-03: Correct code on 3rd attempt succeeds if attempts < 3', () {
    manager.clearAll();
    final t0 = DateTime(2026, 10, 15, 12, 0, 0);
    manager.createSession(
      'student_3rd_success',
      fixedSessionId: 'sess_3rd',
      fixedOtp: '445566',
      now: t0,
    );

    // 2 failures
    manager.verifyCode('sess_3rd', '000000', now: t0);
    manager.verifyCode('sess_3rd', '111111', now: t0);

    // 3rd attempt is correct code
    final res3 = manager.verifyCode('sess_3rd', '445566', now: t0);
    assertTrue(res3.isSuccess, '3rd attempt with correct code must succeed');
  });

  print('---------------------------------------------------------------');
  print('Token Lifecycle Tests: $passedTests / $totalTests passed.');
  if (passedTests != totalTests) {
    throw Exception('Some tests failed in token_lifecycle_test.dart');
  }
}
