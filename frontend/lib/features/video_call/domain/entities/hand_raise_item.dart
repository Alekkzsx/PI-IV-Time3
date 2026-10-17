// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Elemento da fila de mãos levantadas, ordenado cronologicamente por [raisedAt].
class HandRaiseItem {
  /// Peer ID do participante com a mão levantada.
  final String peerId;

  /// Nome de exibição do participante.
  final String participantName;

  /// Registro Acadêmico ou identificador do participante.
  final String academicId;

  /// Timestamp exato em que a mão foi levantada (critério de prioridade FIFO).
  final DateTime raisedAt;

  /// Indica se a mão está ativamente levantada.
  final bool isRaised;

  const HandRaiseItem({
    required this.peerId,
    String? participantName,
    String? name,
    String? academicId,
    String? ra,
    required this.raisedAt,
    this.isRaised = true,
  })  : participantName = participantName ?? name ?? '',
        academicId = academicId ?? ra ?? '';

  /// Aliases de conveniência.
  String get name => participantName;
  String get ra => academicId;

  HandRaiseItem copyWith({
    String? peerId,
    String? participantName,
    String? name,
    String? academicId,
    String? ra,
    DateTime? raisedAt,
    bool? isRaised,
  }) {
    return HandRaiseItem(
      peerId: peerId ?? this.peerId,
      participantName: participantName ?? name ?? this.participantName,
      academicId: academicId ?? ra ?? this.academicId,
      raisedAt: raisedAt ?? this.raisedAt,
      isRaised: isRaised ?? this.isRaised,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HandRaiseItem &&
        other.peerId == peerId &&
        other.participantName == participantName &&
        other.academicId == academicId &&
        other.raisedAt == raisedAt &&
        other.isRaised == isRaised;
  }

  @override
  int get hashCode => Object.hash(peerId, participantName, academicId, raisedAt, isRaised);

  @override
  String toString() {
    return 'HandRaiseItem(peerId: $peerId, name: $participantName, '
        'academicId: $academicId, raisedAt: $raisedAt, isRaised: $isRaised)';
  }
}
