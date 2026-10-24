// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/security_constants.dart';

/// Client-side input sanitization utility neutralizing XSS, SQL injection,
/// null byte poisoning, and enforcing strict payload length boundaries.
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

  /// Strips null bytes, non-printable ASCII control characters, and leading/trailing whitespace.
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;
    var cleaned = input.replaceAll(_nullBytePattern, '');
    cleaned = cleaned.replaceAll(RegExp(r'[\x01-\x1F\x7F]'), '');
    return cleaned.trim();
  }

  /// Determines if an input string contains high-risk exploit payloads (null bytes, XSS tags, SQL meta).
  static bool hasDangerousPatterns(String input) {
    if (_nullBytePattern.hasMatch(input)) return true;
    if (_scriptTagPattern.hasMatch(input)) return true;
    if (_sqlMetaPattern.hasMatch(input)) return true;
    return false;
  }

  /// Validates and sanitizes academic registration (RA/Matrícula) identifiers.
  /// Throws [ArgumentError] if constraints or dangerous character sequences are violated.
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

  /// Validates and sanitizes institutional email addresses according to RFC pattern bounds.
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

  /// Strips null bytes from passwords and ensures length bounds.
  static String sanitizePassword(String password) {
    final cleaned = password.replaceAll(_nullBytePattern, '');
    if (cleaned.length > maxPasswordLength) {
      throw ArgumentError('Password exceeds maximum length of $maxPasswordLength characters');
    }
    return cleaned;
  }
}

