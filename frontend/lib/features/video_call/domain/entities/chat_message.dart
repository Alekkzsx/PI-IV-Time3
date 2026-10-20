// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Marcelo Zarpelon - RA: 25015323

/// Mensagem textual de chat trocada em tempo real entre os participantes da reunião.
class ChatMessage {
  /// Identificador único da mensagem (UUID).
  final String id;

  /// Peer ID de quem enviou a mensagem.
  final String senderId;

  /// Nome de exibição do remetente.
  final String senderName;

  /// Registro Acadêmico ou identidade institucional do remetente.
  final String senderRa;

  /// Conteúdo textual da mensagem.
  final String text;

  /// Carimbo de data/hora do envio.
  final DateTime timestamp;

  /// Indica se a mensagem foi enviada pelo próprio participante local.
  final bool isLocal;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRa,
    required this.text,
    required this.timestamp,
    this.isLocal = false,
  });

  /// Alias de compatibilidade para o conteúdo textual da mensagem.
  String get content => text;

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRa,
    String? text,
    String? content,
    DateTime? timestamp,
    bool? isLocal,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRa: senderRa ?? this.senderRa,
      text: text ?? content ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.senderRa == senderRa &&
        other.text == text &&
        other.timestamp == timestamp &&
        other.isLocal == isLocal;
  }

  @override
  int get hashCode => Object.hash(
        id,
        senderId,
        senderName,
        senderRa,
        text,
        timestamp,
        isLocal,
      );

  @override
  String toString() {
    return 'ChatMessage(id: $id, sender: $senderName ($senderRa), '
        'text: $text, isLocal: $isLocal, timestamp: $timestamp)';
  }
}
