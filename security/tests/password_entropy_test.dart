// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Tier 1 & Tier 2: Password Entropy & Complexity Evaluation Test Suite
/// Tests Features 10, 11 and Acceptance Criteria AC-09.

class PasswordEntropyValidator {
  static const int minLength = 8;
  static const int minScore = 3;

  static final RegExp _upperPattern = RegExp(r'[A-Z]');
  static final RegExp _lowerPattern = RegExp(r'[a-z]');
  static final RegExp _digitPattern = RegExp(r'[0-9]');
  static final RegExp _specialPattern = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_+=\[\]]');

  /// Calculates the 4-factor entropy score:
  /// Vector 1: Length >= 8
  /// Vector 2: Mixed case (both uppercase and lowercase)
  /// Vector 3: At least one digit
  /// Vector 4: At least one special symbol
  static int calculateScore(String password) {
    if (password.isEmpty) return 0;

    int score = 0;
    // Vector 1: Length >= 8
    if (password.length >= minLength) {
      score++;
    }

    // Vector 2: Mixed case (Upper + Lower)
    if (_upperPattern.hasMatch(password) && _lowerPattern.hasMatch(password)) {
      score++;
    }

    // Vector 3: Digit
    if (_digitPattern.hasMatch(password)) {
      score++;
    }

    // Vector 4: Special character
    if (_specialPattern.hasMatch(password)) {
      score++;
    }

    return score;
  }

  /// Feature 11: Gate submission based on score >= 3 AND length >= 8
  static bool isEligibleForSubmission(String password) {
    if (password.length < minLength) return false;
    final score = calculateScore(password);
    return score >= minScore;
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
  print('Running Password Entropy & Complexity Tests (Features 10-11)');
  print('===============================================================');

  // -------------------------------------------------------------
  // TIER 1: FEATURE COVERAGE
  // -------------------------------------------------------------
  runTest('T1-01: Empty password yields score 0 and is not eligible', () {
    assertEqual(PasswordEntropyValidator.calculateScore(''), 0, 'Empty string score must be 0');
    assertFalse(PasswordEntropyValidator.isEligibleForSubmission(''), 'Empty password cannot be submitted');
  });

  runTest('T1-02: 4-factor vector calculation (AC-09 scenarios)', () {
    // 1. "teste12" -> length 7 (<8), lower, digit -> length fails, mixed case fails. Score = 1.
    final score1 = PasswordEntropyValidator.calculateScore('teste12');
    assertEqual(score1, 1, 'teste12 score should be 1');
    assertFalse(PasswordEntropyValidator.isEligibleForSubmission('teste12'), 'Score 1 must be rejected');

    // 2. "senhaboa" -> length 8, only lower -> length passes, mixed fails, digit fails, special fails. Score = 1.
    final score2 = PasswordEntropyValidator.calculateScore('senhaboa');
    assertEqual(score2, 1, 'senhaboa score should be 1');
    assertFalse(PasswordEntropyValidator.isEligibleForSubmission('senhaboa'), 'Score 1 must be rejected');

    // 3. "Senha123" -> length 8, upper+lower, digit -> length passes, mixed passes, digit passes. Score = 3.
    final score3 = PasswordEntropyValidator.calculateScore('Senha123');
    assertEqual(score3, 3, 'Senha123 score should be 3');
    assertTrue(PasswordEntropyValidator.isEligibleForSubmission('Senha123'), 'Score 3 must be accepted');

    // 4. "S@nha#2026" -> length 10, upper+lower, digit, special -> all 4 vectors pass. Score = 4.
    final score4 = PasswordEntropyValidator.calculateScore('S@nha#2026');
    assertEqual(score4, 4, 'S@nha#2026 score should be 4');
    assertTrue(PasswordEntropyValidator.isEligibleForSubmission('S@nha#2026'), 'Score 4 must be accepted');
  });

  // -------------------------------------------------------------
  // TIER 2: BOUNDARY & CORNER CASES
  // -------------------------------------------------------------
  runTest('T2-01: Boundary length: 7 chars vs 8 chars with mixed+digit+special', () {
    // 7 characters: "Ab1!xyz" -> length fails (0), mixed passes (1), digit passes (1), special passes (1) = Score 3, but length < 8!
    final len7 = 'Ab1!xyz';
    assertEqual(len7.length, 7, 'Length is 7');
    assertFalse(PasswordEntropyValidator.isEligibleForSubmission(len7), 'Length < 8 MUST be rejected even if score is 3');

    // 8 characters: "Ab1!xyzz" -> length passes (1) + 3 vectors = Score 4
    final len8 = 'Ab1!xyzz';
    assertEqual(len8.length, 8, 'Length is 8');
    assertTrue(PasswordEntropyValidator.isEligibleForSubmission(len8), 'Length 8 with score 4 must be accepted');
  });

  runTest('T2-02: Boundary score: Score 2 vs Score 3', () {
    // "Password" -> length 8 (1), mixed case (1) = Score 2
    assertEqual(PasswordEntropyValidator.calculateScore('Password'), 2, 'Score should be 2');
    assertFalse(PasswordEntropyValidator.isEligibleForSubmission('Password'), 'Score 2 must be rejected');

    // "Pass1234" -> length 8 (1), mixed case (1), digits (1) = Score 3
    assertEqual(PasswordEntropyValidator.calculateScore('Pass1234'), 3, 'Score should be 3');
    assertTrue(PasswordEntropyValidator.isEligibleForSubmission('Pass1234'), 'Score 3 must be accepted');
  });

  runTest('T2-03: Various special characters recognition', () {
    final specials = ['@', '#', '\$', '%', '&', '*', '_', '-', '+', '!', '?'];
    for (final char in specials) {
      final pw = 'Senha12$char';
      final score = PasswordEntropyValidator.calculateScore(pw);
      assertEqual(score, 4, 'Password with special char $char should achieve score 4');
      assertTrue(PasswordEntropyValidator.isEligibleForSubmission(pw), 'Should be eligible');
    }
  });

  print('---------------------------------------------------------------');
  print('Password Entropy Tests: $passedTests / $totalTests passed.');
  if (passedTests != totalTests) {
    throw Exception('Some tests failed in password_entropy_test.dart');
  }
}
