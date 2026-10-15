// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/security_constants.dart';

/// Lifecycle statuses for an ephemeral password recovery session.
enum RecoverySessionStatus { active, expired, revoked, consumed }

/// Model representing an active or completed password recovery session.
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

  /// Evaluates whether the session has exceeded its 5-minute Time-To-Live.
  bool isExpired({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    return currentTime.isAfter(createdAt.add(Duration(seconds: ttlSeconds)));
  }

  /// Calculates remaining seconds before expiration.
  int remainingSeconds({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final expiry = createdAt.add(Duration(seconds: ttlSeconds));
    if (currentTime.isAfter(expiry)) return 0;
    return expiry.difference(currentTime).inSeconds;
  }
}

/// Verification result envelope with status and user feedback message.
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

/// Manages ephemeral token lifecycles with strict 5-minute (300s) TTL and 3-attempt OTP invalidation.
class TokenLifecycleManager {
  static const int defaultTtlSeconds = SecurityConstants.defaultTokenTtlSeconds;
  static const int maxOtpAttempts = SecurityConstants.maxOtpVerificationAttempts;

  final Map<String, RecoverySession> _sessions = {};

  /// Creates and registers a new recovery session with a 300s TTL.
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

  /// Verifies if a session is active and not expired.
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

  /// Verifies a submitted OTP code against the session.
  /// Automatically revokes session if invalid attempts reach [maxOtpAttempts].
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

  /// Clears all active sessions.
  void clearAll() {
    _sessions.clear();
  }
}
