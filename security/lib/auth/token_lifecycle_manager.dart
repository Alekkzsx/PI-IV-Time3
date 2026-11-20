// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/security_constants.dart';

/// Status do ciclo de vida de uma sessão efêmera de recuperação de senha.
enum RecoverySessionStatus { active, expired, revoked, consumed }

/// Modelo que representa uma sessão de recuperação de senha ativa ou concluída.
class RecoverySession {
  final String sessionId;
  final String identifier;
  final String otpCode;
  final DateTime createdAt;
  final int ttlSeconds;
  int invalidAttempts;
  RecoverySessionStatus status;

  RecoverySession({
    required this.sessionId,
    required this.identifier,
    required this.otpCode,
    required this.createdAt,
    this.ttlSeconds = SecurityConstants.defaultTokenTtlSeconds,
    this.invalidAttempts = 0,
    this.status = RecoverySessionStatus.active,
  });

  /// Avalia se a sessão excedeu seu tempo de vida (TTL) de 5 minutos.
  bool isExpired({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    return currentTime.isAfter(createdAt.add(Duration(seconds: ttlSeconds)));
  }

  /// Calcula os segundos restantes antes da expiração.
  int remainingSeconds({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final expiry = createdAt.add(Duration(seconds: ttlSeconds));
    if (currentTime.isAfter(expiry)) return 0;
    return expiry.difference(currentTime).inSeconds;
  }
}

/// Envelope de resultado de verificação com status e mensagem de feedback ao usuário.
class VerifyResult {
  final bool isSuccess;
  final String status;
  final String message;
  final int? remainingAttempts;

  const VerifyResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.remainingAttempts,
  });

  factory VerifyResult.success(String msg) =>
      VerifyResult(isSuccess: true, status: 'SUCCESS', message: msg);

  factory VerifyResult.notFound(String msg) =>
      VerifyResult(isSuccess: false, status: 'NOT_FOUND', message: msg);

  factory VerifyResult.invalidCode(String msg, int remaining) => VerifyResult(
        isSuccess: false,
        status: 'INVALID_CODE',
        message: msg,
        remainingAttempts: remaining,
      );

  factory VerifyResult.revoked(String msg) =>
      VerifyResult(isSuccess: false, status: 'REVOKED', message: msg);

  factory VerifyResult.expired(String msg) =>
      VerifyResult(isSuccess: false, status: 'EXPIRED', message: msg);

  factory VerifyResult.consumed(String msg) =>
      VerifyResult(isSuccess: false, status: 'CONSUMED', message: msg);
}

/// Gerencia ciclos de vida de tokens efêmeros com TTL estrito de 5 minutos (300s) e invalidação de OTP após 3 tentativas.
class TokenLifecycleManager {
  static const int defaultTtlSeconds = SecurityConstants.defaultTokenTtlSeconds;
  static const int maxOtpAttempts = SecurityConstants.maxOtpVerificationAttempts;

  final Map<String, RecoverySession> _sessions = {};

  /// Cria e registra uma nova sessão de recuperação com TTL de 300s.
  RecoverySession createSession(
    String identifier, {
    String? fixedSessionId,
    String? fixedOtp,
    DateTime? now,
  }) {
    final sessionId = fixedSessionId ??
        'session_${identifier}_${DateTime.now().microsecondsSinceEpoch}';
    final otpCode = fixedOtp ?? '123456';
    final session = RecoverySession(
      sessionId: sessionId,
      identifier: identifier,
      otpCode: otpCode,
      createdAt: now ?? DateTime.now(),
      ttlSeconds: defaultTtlSeconds,
    );
    _sessions[sessionId] = session;
    return session;
  }

  /// Verifica se uma sessão está ativa e não expirada.
  bool isSessionValid(String sessionId, {DateTime? now}) {
    final session = _sessions[sessionId];
    if (session == null) return false;
    if (session.status != RecoverySessionStatus.active) return false;
    if (session.isExpired(now: now)) {
      session.status = RecoverySessionStatus.expired;
      return false;
    }
    return true;
  }

  /// Verifica um código OTP enviado em relação à sessão.
  /// Revoga a sessão automaticamente se as tentativas inválidas atingirem [maxOtpAttempts].
  VerifyResult verifyCode(
    String sessionId,
    String submittedCode, {
    DateTime? now,
  }) {
    final session = _sessions[sessionId];
    if (session == null) {
      return VerifyResult.notFound('Sessão inexistente');
    }

    if (session.status == RecoverySessionStatus.revoked) {
      return VerifyResult.revoked(
        'Sessão revogada por excesso de tentativas. Solicite um novo código.',
      );
    }

    if (session.status == RecoverySessionStatus.consumed) {
      return VerifyResult.consumed('Código já utilizado.');
    }

    if (session.isExpired(now: now)) {
      session.status = RecoverySessionStatus.expired;
      return VerifyResult.expired(
        'Código expirado. Solicite um novo código.',
      );
    }

    if (session.otpCode == submittedCode) {
      session.status = RecoverySessionStatus.consumed;
      return VerifyResult.success('Código verificado com sucesso.');
    } else {
      session.invalidAttempts++;
      if (session.invalidAttempts >= maxOtpAttempts) {
        session.status = RecoverySessionStatus.revoked;
        return VerifyResult.revoked(
          'Sessão revogada por excesso de tentativas. Solicite um novo código.',
        );
      }
      final remainingAttempts = maxOtpAttempts - session.invalidAttempts;
      return VerifyResult.invalidCode(
        'Código incorreto. $remainingAttempts tentativa(s) restante(s).',
        remainingAttempts,
      );
    }
  }

  /// Limpa todas as sessões ativas.
  void clearAll() {
    _sessions.clear();
  }
}

