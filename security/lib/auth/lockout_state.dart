// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Modelo imutável que representa o estado de bloqueio de conta e limitação de taxa.
class LockoutState {
  /// Número de tentativas consecutivas com falha registradas.
  final int failedAttempts;

  /// Indica se a conta/identidade está atualmente bloqueada em período de espera.
  final bool isLockedOut;

  /// Segundos restantes até que o período de espera expire e os envios sejam desbloqueados.
  final int remainingLockoutSeconds;

  /// Carimbo de data/hora de quando o bloqueio termina, ou nulo caso não esteja bloqueado.
  final DateTime? lockoutEnd;

  const LockoutState({
    required this.failedAttempts,
    required this.isLockedOut,
    required this.remainingLockoutSeconds,
    this.lockoutEnd,
  });

  /// Factory que cria um estado inicial desbloqueado com zero tentativas com falha.
  factory LockoutState.unlocked() => const LockoutState(
        failedAttempts: 0,
        isLockedOut: false,
        remainingLockoutSeconds: 0,
      );
}

