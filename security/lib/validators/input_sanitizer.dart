// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/security_constants.dart';

/// Utilitário de sanitização de entrada no lado do cliente que neutraliza XSS, injeção de SQL,
/// envenenamento por null byte e impõe limites estritos de comprimento de payload.
class InputSanitizer {
  InputSanitizer._();

  static const int maxRaLength = SecurityConstants.maxRaLength;
  static const int maxEmailLength = SecurityConstants.maxEmailLength;
  static const int maxPasswordLength = SecurityConstants.maxPasswordLength;

  static final RegExp _scriptTagPattern = RegExp(
    r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>|<[^>]+(on\w+|javascript:)[^>]*>',
    caseSensitive: false,
  );

  static final RegExp _sqlMetaPattern = RegExp(
    r"('|--|/\*|\*/|;|xp_|union\s+select|drop\s+table)",
    caseSensitive: false,
  );

  static final RegExp _nullBytePattern = RegExp(r'(\x00|%00|\u0000)');

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Remove null bytes, caracteres de controle ASCII não imprimíveis e espaços em branco no início e no fim.
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;
    var cleaned = input.replaceAll(_nullBytePattern, '');
    cleaned = cleaned.replaceAll(RegExp(r'[\x01-\x1F\x7F]'), '');
    return cleaned.trim();
  }

  /// Determina se uma string de entrada contém payloads de exploração de alto risco (null bytes, tags XSS, metadados SQL).
  static bool hasDangerousPatterns(String input) {
    if (_nullBytePattern.hasMatch(input)) return true;
    if (_scriptTagPattern.hasMatch(input)) return true;
    if (_sqlMetaPattern.hasMatch(input)) return true;
    return false;
  }

  /// Valida e sanitiza identificadores de registro acadêmico (RA/Matrícula).
  /// Lança [ArgumentError] se as restrições ou sequências de caracteres perigosas forem violadas.
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

  /// Valida e sanitiza endereços de e-mail institucionais de acordo com os limites do padrão RFC.
  static String sanitizeEmail(String email) {
    final cleaned = sanitizeString(email);
    if (cleaned.length > maxEmailLength) {
      throw ArgumentError('Email exceeds maximum length of $maxEmailLength characters');
    }
    if (!_emailPattern.hasMatch(cleaned)) {
      throw ArgumentError('Invalid email format');
    }
    return cleaned;
  }

  /// Remove null bytes de senhas e garante os limites de comprimento.
  static String sanitizePassword(String password) {
    final cleaned = password.replaceAll(_nullBytePattern, '');
    if (cleaned.length > maxPasswordLength) {
      throw ArgumentError('Password exceeds maximum length of $maxPasswordLength characters');
    }
    return cleaned;
  }
}

