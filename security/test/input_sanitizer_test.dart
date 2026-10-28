// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Tier 1 & Tier 2: Input Sanitization & Attack Neutralization Test Suite
/// Tests Features 6, 7, 8, 9 and Acceptance Criteria AC-05.

class InputSanitizer {
  static const int maxRaLength = 32;
  static const int maxEmailLength = 254;
  static const int maxPasswordLength = 128;

  static final RegExp _scriptTagPattern = RegExp(
    r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>|<[^>]+(on\w+|javascript:)[^>]*>',
    caseSensitive: false,
  );

  static final RegExp _sqlMetaPattern = RegExp(
    r"('|--|/\*|\*/|;|xp_|union\s+select|drop\s+table)",
    caseSensitive: false,
  );

  static final RegExp _nullBytePattern = RegExp(r'(\x00|%00|\u0000)');

  static String sanitizeString(String input) {
    if (input.isEmpty) return input;
    // Strip null bytes and control chars
    var cleaned = input.replaceAll(_nullBytePattern, '');
    cleaned = cleaned.replaceAll(RegExp(r'[\x01-\x1F\x7F]'), '');
    return cleaned.trim();
  }

  static bool hasDangerousPatterns(String input) {
    if (_nullBytePattern.hasMatch(input)) return true;
    if (_scriptTagPattern.hasMatch(input)) return true;
    if (_sqlMetaPattern.hasMatch(input)) return true;
    return false;
  }

  static String sanitizeIdentity(String ra) {
    final cleaned = sanitizeString(ra);
    if (cleaned.length > maxRaLength) {
      throw ArgumentError('RA exceeds maximum length of $maxRaLength characters');
    }
    if (_scriptTagPattern.hasMatch(cleaned) || _sqlMetaPattern.hasMatch(cleaned)) {
      throw ArgumentError('Invalid characters detected in RA identifier');
    }
    return cleaned;
  }

  static String sanitizeEmail(String email) {
    final cleaned = sanitizeString(email);
    if (cleaned.length > maxEmailLength) {
      throw ArgumentError('Email exceeds maximum length of $maxEmailLength characters');
    }
    // Basic RFC email validation check
    final emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailPattern.hasMatch(cleaned)) {
      throw ArgumentError('Invalid email format');
    }
    return cleaned;
  }

  static String sanitizePassword(String password) {
    final cleaned = password.replaceAll(_nullBytePattern, '');
    if (cleaned.length > maxPasswordLength) {
      throw ArgumentError('Password exceeds maximum length of $maxPasswordLength characters');
    }
    return cleaned;
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
  print('Running Input Sanitizer & Attack Neutralization Tests (Features 6-9)');
  print('===============================================================');

  // -------------------------------------------------------------
  // TIER 1: FEATURE COVERAGE
  // -------------------------------------------------------------
  runTest('T1-01: Valid clean inputs pass through unchanged', () {
    assertEqual(InputSanitizer.sanitizeIdentity('24802449'), '24802449', 'Valid RA should pass');
    assertEqual(InputSanitizer.sanitizeEmail('aluno@escola.edu.br'), 'aluno@escola.edu.br', 'Valid email should pass');
    assertEqual(InputSanitizer.sanitizePassword('P@ssword2026'), 'P@ssword2026', 'Valid password should pass');
  });

  runTest('T1-02: XSS script tags detected as dangerous (Feature 6)', () {
    final xssPayloads = [
      '<script>alert(1)</script>',
      '<SCRIPT SRC="https://evil.com/xss.js"></SCRIPT>',
      '<img src=x onerror=alert("XSS")>',
      '<a href="javascript:alert(1)">Click</a>',
      '<iframe src="javascript:alert(1)"></iframe>',
    ];

    for (final payload in xssPayloads) {
      assertTrue(
        InputSanitizer.hasDangerousPatterns(payload),
        'Payload should be flagged as dangerous: $payload',
      );
      bool threw = false;
      try {
        InputSanitizer.sanitizeIdentity(payload);
      } catch (_) {
        threw = true;
      }
      assertTrue(threw, 'XSS payload in RA should be rejected: $payload');
    }
  });

  runTest('T1-03: SQL injection meta-characters detected as dangerous (Feature 7)', () {
    final sqliPayloads = [
      "' OR '1'='1",
      "admin' --",
      "'; DROP TABLE usuarios; --",
      "UNION SELECT * FROM senhas",
      "/* comment */ 1=1",
    ];

    for (final payload in sqliPayloads) {
      assertTrue(
        InputSanitizer.hasDangerousPatterns(payload),
        'SQLi payload should be flagged: $payload',
      );
      bool threw = false;
      try {
        InputSanitizer.sanitizeIdentity(payload);
      } catch (_) {
        threw = true;
      }
      assertTrue(threw, 'SQLi in RA should be rejected: $payload');
    }
  });

  runTest('T1-04: Null bytes stripped and detected (Feature 8)', () {
    final poisonedInput = '24802449\x00admin';
    assertTrue(InputSanitizer.hasDangerousPatterns(poisonedInput), 'Null byte should be flagged');

    final cleaned = InputSanitizer.sanitizeString(poisonedInput);
    assertEqual(cleaned, '24802449admin', 'Null byte must be stripped');
    assertFalse(cleaned.contains('\x00'), 'Cleaned string must have 0 null bytes');
  });

  // -------------------------------------------------------------
  // TIER 2: BOUNDARY & CORNER CASES
  // -------------------------------------------------------------
  runTest('T2-01: Length boundary for RA (max 32 characters)', () {
    final exactly32 = 'A' * 32;
    assertEqual(InputSanitizer.sanitizeIdentity(exactly32), exactly32, '32 chars allowed');

    final exactly33 = 'A' * 33;
    bool threw = false;
    try {
      InputSanitizer.sanitizeIdentity(exactly33);
    } catch (_) {
      threw = true;
    }
    assertTrue(threw, '33 chars must be rejected');
  });

  runTest('T2-02: Length boundary for Password (max 128 characters)', () {
    final exactly128 = 'P' * 128;
    assertEqual(InputSanitizer.sanitizePassword(exactly128), exactly128, '128 chars allowed');

    final exactly129 = 'P' * 129;
    bool threw = false;
    try {
      InputSanitizer.sanitizePassword(exactly129);
    } catch (_) {
      threw = true;
    }
    assertTrue(threw, '129 chars must be rejected');
  });

  runTest('T2-03: Empty string, whitespace, and control character edge cases', () {
    assertEqual(InputSanitizer.sanitizeString(''), '', 'Empty string allowed');
    assertEqual(InputSanitizer.sanitizeString('   '), '', 'Whitespace trimmed');
    assertEqual(InputSanitizer.sanitizeString('text\x07with\x1Bescape'), 'textwithescape', 'Control chars stripped');
  });

  print('---------------------------------------------------------------');
  print('Input Sanitizer Tests: $passedTests / $totalTests passed.');
  if (passedTests != totalTests) {
    throw Exception('Some tests failed in input_sanitizer_test.dart');
  }
}
