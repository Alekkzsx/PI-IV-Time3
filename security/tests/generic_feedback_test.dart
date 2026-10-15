// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Tier 1 & Tier 2: Anti-Enumeration & Generic Feedback Test Suite
/// Tests Features 16, 18 and Acceptance Criteria AC-04, AC-06.

import 'dart:convert';

class GenericFeedbackPolicy {
  static const String genericAuthFailureMessage =
      'Credenciais inválidas. Verifique seu identificador e senha.';

  static const String genericRecoveryMessage =
      'Se o identificador estiver cadastrado, as instruções foram enviadas.';

  static const int recoveryTtlSeconds = 300;

  static Map<String, dynamic> createAuthFailureResponse() {
    return {
      'statusCode': 401,
      'error': 'Unauthorized',
      'message': genericAuthFailureMessage,
    };
  }

  static Map<String, dynamic> createRecoveryResponse({required String identifier}) {
    // Identity is explicitly NOT reflected back, and whether it exists is hidden
    return {
      'status': 'INSTRUCTIONS_SENT',
      'expiresInSeconds': recoveryTtlSeconds,
      'message': genericRecoveryMessage,
    };
  }
}

// Simulated Authentication Service with Anti-Enumeration
class MockAuthService {
  final Set<String> _registeredUsers = {'24802449', 'aluno123', 'admin'};

  Map<String, dynamic> handleLogin(String identity, String password) {
    // Opaque evaluation: whether user exists or not, wrong credentials yield the EXACT same error
    if (!_registeredUsers.contains(identity) || password != 'ValidPass123!') {
      return GenericFeedbackPolicy.createAuthFailureResponse();
    }
    return {'statusCode': 200, 'message': 'Authenticated'};
  }

  Map<String, dynamic> handlePasswordRecovery(String identity) {
    // Anti-enumeration: returns identical response regardless of membership in _registeredUsers
    return GenericFeedbackPolicy.createRecoveryResponse(identifier: identity);
  }
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
  print('Running Anti-Enumeration & Generic Feedback Tests (Features 16, 18)');
  print('===============================================================');

  final authService = MockAuthService();

  // -------------------------------------------------------------
  // TIER 1: FEATURE COVERAGE
  // -------------------------------------------------------------
  runTest('T1-01: Authentication failure returns generic message (Feature 16)', () {
    final response = GenericFeedbackPolicy.createAuthFailureResponse();
    assertEqual(response['statusCode'], 401, 'Status code must be 401');
    assertEqual(
      response['message'],
      'Credenciais inválidas. Verifique seu identificador e senha.',
      'Message must match generic anti-enumeration policy',
    );
  });

  runTest('T1-02: Recovery request returns generic confirmation (Feature 18)', () {
    final response = GenericFeedbackPolicy.createRecoveryResponse(identifier: 'any_user');
    assertEqual(response['status'], 'INSTRUCTIONS_SENT', 'Status must be INSTRUCTIONS_SENT');
    assertEqual(response['expiresInSeconds'], 300, 'TTL must be 300 seconds');
    assertEqual(
      response['message'],
      'Se o identificador estiver cadastrado, as instruções foram enviadas.',
      'Message must match generic recovery policy',
    );
  });

  // -------------------------------------------------------------
  // TIER 2: BOUNDARY & CORNER CASES
  // -------------------------------------------------------------
  runTest('T2-01: Login failure response is byte-identical for existing vs non-existing user (AC-04)', () {
    // Existing user with wrong password
    final resExisting = authService.handleLogin('24802449', 'wrong_pass');
    // Non-existing user
    final resMissing = authService.handleLogin('99999999', 'wrong_pass');

    final jsonExisting = jsonEncode(resExisting);
    final jsonMissing = jsonEncode(resMissing);

    assertEqual(
      jsonExisting,
      jsonMissing,
      'Login failure response MUST be byte-for-byte identical to prevent enumeration',
    );
  });

  runTest('T2-02: Recovery response is byte-identical for registered vs fictional RA (AC-06)', () {
    // Registered student
    final resRegistered = authService.handlePasswordRecovery('24802449');
    // Unmapped / fictional RA
    final resFictional = authService.handlePasswordRecovery('00000000');

    final jsonReg = jsonEncode(resRegistered);
    final jsonFic = jsonEncode(resFictional);

    assertEqual(
      jsonReg,
      jsonFic,
      'Recovery response MUST be byte-for-byte identical regardless of user existence',
    );
    assertFalse(
      jsonReg.contains('24802449'),
      'Response must never echo or leak identifier status',
    );
  });

  print('---------------------------------------------------------------');
  print('Generic Feedback Tests: $passedTests / $totalTests passed.');
  if (passedTests != totalTests) {
    throw Exception('Some tests failed in generic_feedback_test.dart');
  }
}
