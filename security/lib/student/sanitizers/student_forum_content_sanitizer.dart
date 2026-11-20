// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/student_security_limits.dart';

/// Sanitizador de conteúdo rico e colaborativo da Visão do Aluno (Fórum AVA e Caderno Pessoal).
///
/// Neutraliza vetores de Stored XSS e injeção de scripts maliciosos sem comprometer
/// a expressividade do texto do estudante.
abstract final class StudentForumContentSanitizer {
  StudentForumContentSanitizer._();

  static final RegExp _nullBytePattern = RegExp(r'(\x00|%00|\u0000)');
  static final RegExp _scriptTagsPattern = RegExp(
    r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
    caseSensitive: false,
    multiLine: true,
  );
  static final RegExp _dangerousElementsPattern = RegExp(
    r'<(iframe|object|embed|applet|meta|link|style|base|form|svg)\b[^>]*>.*?(<\/\1>)?',
    caseSensitive: false,
    multiLine: true,
  );
  static final RegExp _eventHandlersPattern = RegExp(
    r'\s+on[a-zA-Z]+\s*=\s*("[^"]*"|' r"'[^']*'|[^\s>]+)",
    caseSensitive: false,
  );
  static final RegExp _allHtmlTagsPattern = RegExp(r'<[^>]+>');

  // Detecta URLs javascript: ou vbscript: em links Markdown [texto](javascript:...)
  static final RegExp _markdownDangerousLinkPattern = RegExp(
    r'\[([^\]]*)\]\((javascript|vbscript|data):[^\)]*\)',
    caseSensitive: false,
  );

  /// Higieniza o título de uma nova dúvida no Fórum AVA.
  /// Como títulos não devem conter marcação HTML, remove qualquer tag e trunca no limite regimental.
  static String sanitizeForumTitle(String rawTitle) {
    if (rawTitle.trim().isEmpty) return '';

    var cleaned = rawTitle.replaceAll(_nullBytePattern, '');
    cleaned = cleaned.replaceAll(_allHtmlTagsPattern, '');
    cleaned = cleaned.replaceAll(RegExp(r'[\r\n\t]'), ' ');
    cleaned = cleaned.trim();

    if (cleaned.length > StudentSecurityLimits.maxForumTitleLength) {
      cleaned = cleaned.substring(0, StudentSecurityLimits.maxForumTitleLength).trim();
    }

    return cleaned;
  }

  /// Higieniza a descrição/corpo de dúvida no Fórum AVA, neutralizando scripts e manipuladores de eventos.
  static String sanitizeForumBody(String rawBody) {
    if (rawBody.trim().isEmpty) return '';

    var cleaned = rawBody.replaceAll(_nullBytePattern, '');
    cleaned = cleaned.replaceAll(_scriptTagsPattern, '');
    cleaned = cleaned.replaceAll(_dangerousElementsPattern, '');
    cleaned = cleaned.replaceAll(_eventHandlersPattern, '');
    cleaned = cleaned.trim();

    if (cleaned.length > StudentSecurityLimits.maxForumBodyLength) {
      cleaned = cleaned.substring(0, StudentSecurityLimits.maxForumBodyLength).trim();
    }

    return cleaned;
  }

  /// Sanitiza o caderno de anotações pessoais em Markdown, neutralizando exploits de links disfarçados.
  static String sanitizePersonalNotes(String rawNotes) {
    if (rawNotes.isEmpty) return '';

    var cleaned = rawNotes.replaceAll(_nullBytePattern, '');
    cleaned = cleaned.replaceAll(_scriptTagsPattern, '');
    cleaned = cleaned.replaceAll(_dangerousElementsPattern, '');
    cleaned = cleaned.replaceAll(_eventHandlersPattern, '');

    // Substitui links [Texto](javascript:alert(1)) por [Texto](#link-bloqueado)
    cleaned = cleaned.replaceAllMapped(_markdownDangerousLinkPattern, (match) {
      final label = match.group(1) ?? 'Link';
      return '[$label](#link-bloqueado-por-seguranca)';
    });

    if (cleaned.length > StudentSecurityLimits.maxPersonalNotesLength) {
      cleaned = cleaned.substring(0, StudentSecurityLimits.maxPersonalNotesLength);
    }

    return cleaned;
  }
}
