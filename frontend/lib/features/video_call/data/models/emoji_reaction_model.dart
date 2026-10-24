// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../../domain/entities/emoji_reaction.dart';

/// Modelo de dados e serialização para reações animadas de emoji na chamada.
class EmojiReactionModel {
  final String id;
  final String senderId;
  final String senderName;
  final String emoji;
  final int timestamp;
  final double startX;

  const EmojiReactionModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.emoji,
    required this.timestamp,
    this.startX = 0.5,
  });

  /// Aliases de compatibilidade.
  String get peerId => senderId;
  String get peerName => senderName;

  /// Deserializa a partir de Map JSON.
  factory EmojiReactionModel.fromJson(Map<String, dynamic> json) {
    int parsedTimestamp;
    final rawTimestamp = json['timestamp'];
    if (rawTimestamp is int) {
      parsedTimestamp = rawTimestamp;
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp)?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;
    } else {
      parsedTimestamp = DateTime.now().millisecondsSinceEpoch;
    }

    final senderId = (json['senderId'] ?? json['peerId']) as String? ?? '';
    final senderName = (json['senderName'] ?? json['peerName']) as String? ?? '';

    return EmojiReactionModel(
      id: json['id'] as String? ?? '',
      senderId: senderId,
      senderName: senderName,
      emoji: json['emoji'] as String? ?? '👍',
      timestamp: parsedTimestamp,
      startX: (json['startX'] as num?)?.toDouble() ?? 0.5,
    );
  }

  /// Serializa para Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'peerId': senderId,
      'senderName': senderName,
      'peerName': senderName,
      'emoji': emoji,
      'timestamp': timestamp,
      'startX': startX,
    };
  }

  /// Converte para a entidade de domínio [EmojiReaction].
  EmojiReaction toEntity() {
    return EmojiReaction(
      id: id,
      senderId: senderId,
      senderName: senderName,
      emoji: emoji,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      startX: startX,
    );
  }

  /// Converte da entidade de domínio [EmojiReaction] para o modelo serializável.
  factory EmojiReactionModel.fromEntity(EmojiReaction entity) {
    return EmojiReactionModel(
      id: entity.id,
      senderId: entity.senderId,
      senderName: entity.senderName,
      emoji: entity.emoji,
      timestamp: entity.timestamp.millisecondsSinceEpoch,
      startX: entity.startX,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmojiReactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          senderId == other.senderId &&
          senderName == other.senderName &&
          emoji == other.emoji &&
          timestamp == other.timestamp &&
          (other.startX - startX).abs() < 0.001;

  @override
  int get hashCode => Object.hash(
        id,
        senderId,
        senderName,
        emoji,
        timestamp,
        startX,
      );

  @override
  String toString() {
    return 'EmojiReactionModel(id: $id, emoji: $emoji, from: $senderName, timestamp: $timestamp, startX: $startX)';
  }
}
