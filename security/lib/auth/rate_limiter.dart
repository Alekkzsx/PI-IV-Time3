// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../policies/security_constants.dart';
import 'lockout_state.dart';

/// Limitador de taxa contra força bruta em memória e gerenciador de bloqueio de conta.
/// Aplica um período de espera (cooldown) de bloqueio de 30 segundos após 5 tentativas consecutivas de autenticação com falha.
class RateLimiter {
  static const int maxFailedAttempts = SecurityConstants.maxFailedLoginAttempts;
  static const int lockoutDurationSeconds = SecurityConstants.lockoutDurationSeconds;

  final Map<String, int> _failures = {};
  final Map<String, DateTime> _lockoutEnds = {};

  /// Obtém o estado atual de bloqueio para uma determinada identidade.
  /// Redefine o estado automaticamente se o período de espera já tiver decorrido.
  LockoutState getState(String identity, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final lockoutEnd = _lockoutEnds[identity];

    if (lockoutEnd != null) {
      if (currentTime.isBefore(lockoutEnd)) {
        final remaining = lockoutEnd.difference(currentTime).inSeconds;
        return LockoutState(
          failedAttempts: _failures[identity] ?? maxFailedAttempts,
          isLockedOut: true,
          remainingLockoutSeconds: remaining > 0 ? remaining : 1,
          lockoutEnd: lockoutEnd,
        );
      } else {
        // O período de espera decorreu - redefinição automática
        _failures.remove(identity);
        _lockoutEnds.remove(identity);
        return LockoutState.unlocked();
      }
    }

    final attempts = _failures[identity] ?? 0;
    return LockoutState(
      failedAttempts: attempts,
      isLockedOut: false,
      remainingLockoutSeconds: 0,
    );
  }

  /// Verifica se uma tentativa de autenticação é atualmente permitida para a identidade.
  bool checkAllowed(String identity, {DateTime? now}) {
    final state = getState(identity, now: now);
    return !state.isLockedOut;
  }

  /// Registra uma tentativa de autenticação com falha.
  /// Se as falhas atingirem [maxFailedAttempts], inicia o período de espera de bloqueio de 30 segundos.
  void recordFailure(String identity, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final state = getState(identity, now: currentTime);
    if (state.isLockedOut) {
      return; // Já está bloqueado; não estende a janela existente
    }

    final currentAttempts = (_failures[identity] ?? 0) + 1;
    _failures[identity] = currentAttempts;

    if (currentAttempts >= maxFailedAttempts) {
      _lockoutEnds[identity] =
          currentTime.add(const Duration(seconds: lockoutDurationSeconds));
    }
  }

  /// Registra uma autenticação bem-sucedida, redefinindo as tentativas com falha e limpando bloqueios.
  void recordSuccess(String identity) {
    _failures.remove(identity);
    _lockoutEnds.remove(identity);
  }

  /// Limpa todo o estado de todas as identidades.
  void resetAll() {
    _failures.clear();
    _lockoutEnds.clear();
  }
}

