// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Marcelo Zarpelon - RA: 25015323

/// Reação de emoji flutuante disparada durante a conferência.
class EmojiReaction {
  /// Conjunto formal de emojis suportados pelo sistema de reações.
  static const Set<String> supportedEmojis = {'❤️', '👍', '👏', '😂', '😮', '🎉'};

  /// Validador estático de emoji compatível.
  static bool isValidEmoji(String emoji) => supportedEmojis.contains(emoji);

  /// Identificador único da reação.
  final String id;

  /// Peer ID do emissor da reação.
  final String senderId;

  /// Nome de exibição do emissor da reação.
  final String senderName;

  /// Caractere do emoji (e.g. ❤️, 👍, 👏, 😂, 😮, 🎉).
  final String emoji;

  /// Data/hora de disparo da reação.
  final DateTime timestamp;

  /// Posição horizontal normalizada (0.0 a 1.0) para animação de subida na tela.
  final double startX;

  const EmojiReaction({
    required this.id,
    String? senderId,
    String? peerId,
    String? senderName,
    String? peerName,
    required this.emoji,
    required this.timestamp,
    this.startX = 0.5,
  })  : senderId = senderId ?? peerId ?? '',
        senderName = senderName ?? peerName ?? '';

  /// Aliases de conveniência para integração com controladores e widgets.
  String get peerId => senderId;
  String get peerName => senderName;

  EmojiReaction copyWith({
    String? id,
    String? senderId,
    String? peerId,
    String? senderName,
    String? peerName,
    String? emoji,
    DateTime? timestamp,
    double? startX,
  }) {
    return EmojiReaction(
      id: id ?? this.id,
      senderId: senderId ?? peerId ?? this.senderId,
      senderName: senderName ?? peerName ?? this.senderName,
      emoji: emoji ?? this.emoji,
      timestamp: timestamp ?? this.timestamp,
      startX: startX ?? this.startX,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmojiReaction &&
        other.id == id &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.emoji == emoji &&
        other.timestamp == timestamp &&
        (other.startX - startX).abs() < 0.001;
  }

  @override
  int get hashCode => Object.hash(id, senderId, senderName, emoji, timestamp, startX);

  @override
  String toString() {
    return 'EmojiReaction(id: $id, emoji: $emoji, from: $senderName, timestamp: $timestamp, startX: $startX)';
  }
}
