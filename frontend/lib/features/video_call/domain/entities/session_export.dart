// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Snapshot e registro contábil da sessão gravada da reunião para fins de auditoria acadêmica.
class SessionExport {
  /// Código identificador da sala de reunião.
  final String roomCode;

  /// Timestamp exato de início da gravação.
  final DateTime startedAt;

  /// Timestamp exato de término da gravação.
  final DateTime endedAt;

  /// Duração total acumulada da sessão gravada.
  final Duration totalDuration;

  /// Quantidade total de participantes presentes durante a sessão.
  final int totalParticipants;

  /// Lista dos nomes de todos os participantes presentes na conferência.
  final List<String> attendeeNames;

  /// Quantidade total de mensagens textuais trocadas no chat durante a reunião.
  final int chatMessageCount;

  /// Quantidade total de reações de emojis disparadas durante a reunião.
  final int reactionCount;

  const SessionExport({
    required this.roomCode,
    required this.startedAt,
    required this.endedAt,
    required this.totalDuration,
    required this.totalParticipants,
    required this.attendeeNames,
    required this.chatMessageCount,
    required this.reactionCount,
  });

  /// Serialização para JSON no padrão de auditoria institucional `academic_session_ledger_v1`.
  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'totalDurationSeconds': totalDuration.inSeconds,
        'totalParticipants': totalParticipants,
        'attendeeNames': attendeeNames,
        'chatMessageCount': chatMessageCount,
        'reactionCount': reactionCount,
        'exportFormat': 'academic_session_ledger_v1',
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionExport &&
        other.roomCode == roomCode &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt &&
        other.totalDuration == totalDuration &&
        other.totalParticipants == totalParticipants &&
        other.chatMessageCount == chatMessageCount &&
        other.reactionCount == reactionCount;
  }

  @override
  int get hashCode => Object.hash(
        roomCode,
        startedAt,
        endedAt,
        totalDuration,
        totalParticipants,
        chatMessageCount,
        reactionCount,
      );

  @override
  String toString() {
    return 'SessionExport(room: $roomCode, duration: ${totalDuration.inSeconds}s, '
        'participants: $totalParticipants, messages: $chatMessageCount, reactions: $reactionCount)';
  }
}
