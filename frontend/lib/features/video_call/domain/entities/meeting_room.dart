// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Entidade representativa de uma sala de reunião virtual P2P.
class MeetingRoom {
  /// Código identificador da sala (e.g. "SALA-101").
  final String id;

  /// Alias de conveniência para o código da sala.
  final String code;

  /// Título ou descrição temática da sala.
  final String title;

  /// Data e hora de criação da sala.
  final DateTime createdAt;

  /// Identificador do peer que criou/iniciou a reunião como host.
  final String hostId;

  /// Indica se a sala está trancada para novos participantes.
  final bool isLocked;

  /// Capacidade máxima recomendada de participantes.
  final int maxParticipants;

  MeetingRoom({
    required this.id,
    String? code,
    required this.title,
    DateTime? createdAt,
    this.hostId = '',
    this.isLocked = false,
    this.maxParticipants = 50,
  })  : code = code ?? id,
        createdAt = createdAt ?? DateTime.now();

  MeetingRoom copyWith({
    String? id,
    String? code,
    String? title,
    DateTime? createdAt,
    String? hostId,
    bool? isLocked,
    int? maxParticipants,
  }) {
    return MeetingRoom(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      hostId: hostId ?? this.hostId,
      isLocked: isLocked ?? this.isLocked,
      maxParticipants: maxParticipants ?? this.maxParticipants,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeetingRoom &&
        other.id == id &&
        other.code == code &&
        other.title == title &&
        other.hostId == hostId &&
        other.isLocked == isLocked &&
        other.maxParticipants == maxParticipants;
  }

  @override
  int get hashCode => Object.hash(
        id,
        code,
        title,
        hostId,
        isLocked,
        maxParticipants,
      );

  @override
  String toString() {
    return 'MeetingRoom(id: $id, code: $code, title: $title, hostId: $hostId, '
        'isLocked: $isLocked, maxParticipants: $maxParticipants, createdAt: $createdAt)';
  }
}
