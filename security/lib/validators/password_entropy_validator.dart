// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/security_constants.dart';

/// Client-side password entropy and complexity evaluator.
/// Calculates a 4-factor entropy score (0 to 4) and gates password reset submissions (score >= 3).
class PasswordEntropyValidator {
  PasswordEntropyValidator._();

  static const int minLength = SecurityConstants.minPasswordLength;
  static const int minScore = SecurityConstants.minRequiredEntropyScore;

  static final RegExp _upperPattern = RegExp(r'[A-Z]');
  static final RegExp _lowerPattern = RegExp(r'[a-z]');
  static final RegExp _digitPattern = RegExp(r'[0-9]');
  static final RegExp _specialPattern = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_+=\[\]]');

  /// Calculates the 4-factor entropy score:
  /// - Vector 1: Length >= 8
  /// - Vector 2: Mixed case (Upper + Lower)
  /// - Vector 3: At least one numeric digit (0-9)
  /// - Vector 4: At least one special symbol
  static int calculateScore(String password) {
    if (password.isEmpty) return 0;

    int score = 0;
    if (password.length >= minLength) {
      score++;
    }
    if (_upperPattern.hasMatch(password) && _lowerPattern.hasMatch(password)) {
      score++;
    }
    if (_digitPattern.hasMatch(password)) {
      score++;
    }
    if (_specialPattern.hasMatch(password)) {
      score++;
    }

    return score;
  }

  /// Evaluates whether a password satisfies the minimum institutional complexity requirements.
  /// Requires length >= 8 and entropy score >= 3.
  static bool isEligibleForSubmission(String password) {
    if (password.length < minLength) return false;
    final score = calculateScore(password);
    return score >= minScore;
  }
}
