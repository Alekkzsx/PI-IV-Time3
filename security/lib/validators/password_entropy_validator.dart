// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/security_constants.dart';

/// Avaliador de entropia e complexidade de senha no lado do cliente.
/// Calcula uma pontuação de entropia de 4 fatores (0 a 4) e libera envios de redefinição de senha (pontuação >= 3).
class PasswordEntropyValidator {
  PasswordEntropyValidator._();

  static const int minLength = SecurityConstants.minPasswordLength;
  static const int minScore = SecurityConstants.minRequiredEntropyScore;

  static final RegExp _upperPattern = RegExp(r'[A-Z]');
  static final RegExp _lowerPattern = RegExp(r'[a-z]');
  static final RegExp _digitPattern = RegExp(r'[0-9]');
  static final RegExp _specialPattern = RegExp(r'[!@#$%^&*(),.?":{}|<>\-_+=\[\]]');

  /// Calcula a pontuação de entropia de 4 fatores:
  /// - Vetor 1: Comprimento >= 8
  /// - Vetor 2: Letras maiúsculas e minúsculas
  /// - Vetor 3: Pelo menos um dígito numérico (0-9)
  /// - Vetor 4: Pelo menos um símbolo especial
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

  /// Avalia se uma senha satisfaz os requisitos mínimos de complexidade institucional.
  /// Exige comprimento >= 8 e pontuação de entropia >= 3.
  static bool isEligibleForSubmission(String password) {
    if (password.length < minLength) return false;
    final score = calculateScore(password);
    return score >= minScore;
  }
}

