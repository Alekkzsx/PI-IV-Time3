// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/student_security_limits.dart';

/// Sanitizador de textos de entrada simples (justificativas formais, notas pedagógicas).
///
/// Remove sequências de bytes nulos, neutraliza injeções HTML e aplica limites regimentais de caracteres.
abstract final class StudentTextInputSanitizer {
  StudentTextInputSanitizer._();

  static final RegExp _nullBytePattern = RegExp(r'(\x00|%00|\u0000)');
  static final RegExp _controlCharsPattern = RegExp(r'[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]');
  static final RegExp _htmlTagsPattern = RegExp(r'<[^>]*>', caseSensitive: false);

  /// Sanitiza e normaliza comentários ou notas pedagógicas enviadas ao professor.
  static String sanitizeDeliveryComments(String? rawComments) {
    if (rawComments == null || rawComments.trim().isEmpty) return '';

    var cleaned = rawComments.replaceAll(_nullBytePattern, '');
    cleaned = cleaned.replaceAll(_controlCharsPattern, '');
    // Remove tags HTML para evitar Stored XSS na visão do docente
    cleaned = cleaned.replaceAll(_htmlTagsPattern, '');
    cleaned = cleaned.trim();

    if (cleaned.length > StudentSecurityLimits.maxDeliveryCommentsLength) {
      cleaned = cleaned.substring(0, StudentSecurityLimits.maxDeliveryCommentsLength).trim();
    }

    return cleaned;
  }

  /// Valida e higieniza a justificativa regimental de requerimento para a Secretaria Geral.
  static String sanitizeProtocolJustification(String rawJustification) {
    if (rawJustification.trim().isEmpty) return '';

    var cleaned = rawJustification.replaceAll(_nullBytePattern, '');
    cleaned = cleaned.replaceAll(_controlCharsPattern, '');
    cleaned = cleaned.replaceAll(_htmlTagsPattern, '');
    cleaned = cleaned.trim();

    if (cleaned.length > StudentSecurityLimits.maxJustificationLength) {
      cleaned = cleaned.substring(0, StudentSecurityLimits.maxJustificationLength).trim();
    }

    return cleaned;
  }
}
