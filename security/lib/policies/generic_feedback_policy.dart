// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'security_constants.dart';

/// Policy governing sanitized, opaque user feedback across authentication
/// and credential recovery workflows to eliminate user enumeration, timing
/// side-channels, and information leakage.
abstract final class GenericFeedbackPolicy {
  GenericFeedbackPolicy._();

  // ─── STANDARDIZED OPAQUE STATIC MESSAGES ───

  /// Standardized generic error returned upon failed authentication.
  /// Guarantees indistinguishability between nonexistent accounts and incorrect passwords.
  static const String authFailureMessage =
      'Credenciais inválidas. Verifique seu identificador e senha.';

  /// Standardized generic success feedback returned on password recovery request.
  /// Guarantees indistinguishability between valid and nonexistent/unmapped academic identifiers.
  static const String passwordResetRequestedMessage =
      'Se o identificador informado estiver cadastrado em nosso sistema, as instruções de recuperação foram enviadas.';

  /// Standardized recovery request success message (institution format).
  static const String recoveryRequestSuccessMessage =
      'Se o identificador informado estiver cadastrado no sistema, as instruções e o código de verificação foram enviados para o e-mail institucional.';

  /// Standardized error returned when an ephemeral verification token has expired.
  static const String expiredTokenMessage =
      'Código de verificação expirado. Solicite um novo código.';

  /// Standardized token expired message (alternative wording).
  static const String tokenExpiredMessage =
      'O código de verificação expirou. Solicite um novo código para continuar.';

  /// Standardized error returned when OTP attempt limit (3 attempts) has been exceeded and session is revoked.
  static const String revokedSessionMessage =
      'Sessão de recuperação revogada por excesso de tentativas. Solicite um novo código.';

  /// Standardized token revoked message (alternative wording).
  static const String tokenRevokedMessage =
      'Número máximo de tentativas incorretas excedido. Por segurança, a sessão foi cancelada. Solicite uma nova recuperação.';

  /// Standardized error returned when password strength does not meet the minimum score.
  static const String weakPasswordMessage =
      'A nova senha não atende aos requisitos mínimos de segurança (mínimo 8 caracteres, maiúsculas, minúsculas, números e caracteres especiais).';

  /// Standardized password weak error with explicit score reference.
  static const String passwordTooWeakMessage =
      'A senha não atende aos requisitos mínimos de segurança (pontuação mínima: ${SecurityConstants.minRequiredEntropyScore}/4).';

  /// Standardized success message when password reset completes.
  static const String passwordResetSuccessMessage =
      'Senha redefinida com sucesso. Faça login com a nova senha.';

  /// Standardized client payload validation error message.
  static const String badRequestPayloadMessage =
      'Dados da requisição inválidos.';

  /// Standardized invalid payload message (alternative wording).
  static const String invalidPayloadMessage =
      'Dados de requisição inválidos ou fora do formato permitido.';

  /// Standardized payload too large error message (64 KB ceiling).
  static const String payloadTooLargeMessage =
      'Tamanho da requisição excede o limite permitido de 64 KB.';

  /// Standardized generic server error message suppressing internal stack traces.
  static const String internalErrorMessage =
      'Ocorreu um erro interno ao processar a solicitação. Tente novamente mais tarde.';

  /// Standardized generic server error message (alternative wording).
  static const String internalServerErrorMessage =
      'Ocorreu um erro no processamento da solicitação. Tente novamente mais tarde.';

  // ─── RESPONSE STRUCTURING HELPERS ───

  /// Creates a standardized auth failure response map with status 401 and generic message.
  static Map<String, dynamic> createAuthFailureResponse() {
    return <String, dynamic>{
      'statusCode': 401,
      'error': 'Unauthorized',
      'message': authFailureMessage,
    };
  }

  // ─── DYNAMIC FORMATTED MESSAGES ───

  /// Returns the standardized lockout message with the exact remaining seconds.
  static String lockoutMessage(int remainingSeconds) {
    final sanitizedSeconds = remainingSeconds > 0 ? remainingSeconds : 0;
    return 'Muitas tentativas incorretas. Tente novamente em $sanitizedSeconds segundos.';
  }

  /// Returns the standardized countdown message displayed during active lockout banner.
  static String lockoutCountdownMessage(int remainingSeconds) {
    final clamped = remainingSeconds > 0 ? remainingSeconds : 0;
    return 'Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde $clamped segundos.';
  }

  /// Returns the standardized invalid OTP code message with remaining attempts.
  static String invalidOtpCodeMessage(int remainingAttempts) {
    final sanitizedAttempts = remainingAttempts > 0 ? remainingAttempts : 0;
    return 'Código de verificação incorreto. Tentativas restantes: $sanitizedAttempts.';
  }

  /// Sanitizes an incoming error or exception object to prevent leaking
  /// internal database errors, missing user exceptions, or JVM stack traces to the UI.
  static String sanitizeErrorMessage(dynamic error) {
    if (error == null) return authFailureMessage;
    final message = error.toString().toLowerCase();

    if (message.contains('lockout') || message.contains('bloque')) {
      return 'Acesso temporariamente bloqueado por excesso de tentativas.';
    }
    if (message.contains('expir')) {
      return tokenExpiredMessage;
    }
    if (message.contains('revog') || message.contains('tentativas')) {
      return tokenRevokedMessage;
    }
    if (message.contains('senha') && (message.contains('fraca') || message.contains('entropia') || message.contains('weak'))) {
      return passwordTooWeakMessage;
    }
    if (message.contains('tamanho') || message.contains('payload') || message.contains('64') || message.contains('413')) {
      return invalidPayloadMessage;
    }

    // Default catch-all anti-enumeration fallback
    return authFailureMessage;
  }
}
