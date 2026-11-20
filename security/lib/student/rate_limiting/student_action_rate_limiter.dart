// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/student_security_limits.dart';
import 'student_action_type.dart';

/// Controlador de vazão (Rate Limiter) com janelas deslizantes em memória para a Visão do Aluno.
///
/// Previne ataques de negação de serviço (DoS), abusos por cliques múltiplos (double-click burst)
/// e inundação automatizada de protocolos, declarações e entregas.
class StudentActionRateLimiter {
  /// Instância singleton para preservação de estado em memória durante a sessão discente.
  static final StudentActionRateLimiter instance = StudentActionRateLimiter._();

  StudentActionRateLimiter._();

  // Histórico de timestamps por ação discente
  final Map<StudentActionType, List<DateTime>> _actionTimestamps = {};

  /// Retorna o limite máximo de ações permitidas na janela de 60s para o tipo informado.
  int getMaxAllowed(StudentActionType action) {
    switch (action) {
      case StudentActionType.submitDelivery:
        return StudentSecurityLimits.maxDeliverySubmissionsPerWindow;
      case StudentActionType.issueProtocol:
        return StudentSecurityLimits.maxProtocolSubmissionsPerWindow;
      case StudentActionType.issueEnrollmentDeclaration:
        return StudentSecurityLimits.maxEnrollmentDeclarationsPerWindow;
      case StudentActionType.createForumTopic:
        return StudentSecurityLimits.maxForumTopicsPerWindow;
      case StudentActionType.changePassword:
        return StudentSecurityLimits.maxPasswordChangesPerWindow;
    }
  }

  /// Limpa registros mais antigos do que a janela deslizante de 60 segundos.
  void _pruneOldTimestamps(StudentActionType action, DateTime currentTime) {
    final timestamps = _actionTimestamps[action];
    if (timestamps == null || timestamps.isEmpty) return;

    final cutoff = currentTime.subtract(StudentSecurityLimits.slidingWindowDuration);
    timestamps.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }

  /// Verifica se o aluno pode executar a ação especificada no momento.
  bool canExecute(StudentActionType action, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    _pruneOldTimestamps(action, currentTime);

    final currentCount = _actionTimestamps[action]?.length ?? 0;
    return currentCount < getMaxAllowed(action);
  }

  /// Registra a ocorrência de uma ação e consome uma cota da janela.
  ///
  /// Retorna `true` se a ação foi permitida e registrada, ou `false` se foi bloqueada por esgotamento de cota.
  bool recordAction(StudentActionType action, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    _pruneOldTimestamps(action, currentTime);

    final timestamps = _actionTimestamps.putIfAbsent(action, () => []);
    if (timestamps.length >= getMaxAllowed(action)) {
      return false; // Bloqueado
    }

    timestamps.add(currentTime);
    return true;
  }

  /// Retorna a quantidade de segundos restantes para que a ação seja liberada após um bloqueio.
  /// Retorna `0` se a ação já estiver permitida.
  int getRemainingCooldownSeconds(StudentActionType action, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    _pruneOldTimestamps(action, currentTime);

    final timestamps = _actionTimestamps[action];
    if (timestamps == null || timestamps.length < getMaxAllowed(action)) {
      return 0;
    }

    // O próximo slot liberará quando o evento mais antigo da janela atual expirar
    final oldestInWindow = timestamps.first;
    final expiresAt = oldestInWindow.add(StudentSecurityLimits.slidingWindowDuration);
    final diffMs = expiresAt.difference(currentTime).inMilliseconds;

    if (diffMs <= 0) return 0;
    return (diffMs / 1000).ceil();
  }

  /// Limpa todos os contadores em memória (utilizado em testes ou encerramento de sessão).
  void resetAll() {
    _actionTimestamps.clear();
  }
}
