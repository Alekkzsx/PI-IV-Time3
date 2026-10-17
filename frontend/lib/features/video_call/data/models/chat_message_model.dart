// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Marcelo Zarpelon - RA: 25015323

import '../../domain/entities/chat_message.dart';

/// Modelo de dados e serialização para mensagens do chat da videoconferência.
class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRa;
  final String text;
  final int timestamp;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRa,
    required this.text,
    required this.timestamp,
  });

  /// Alias de compatibilidade.
  String get content => text;

  /// Deserializa a partir de Map JSON.
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
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

    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderRa: json['senderRa'] as String? ?? '',
      text: (json['text'] ?? json['content']) as String? ?? '',
      timestamp: parsedTimestamp,
    );
  }

  /// Serializa para Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderRa': senderRa,
      'text': text,
      'content': text,
      'timestamp': timestamp,
    };
  }

  /// Converte para a entidade de domínio [ChatMessage].
  ChatMessage toEntity({bool isLocal = false}) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderRa: senderRa,
      text: text,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      isLocal: isLocal,
    );
  }

  /// Converte da entidade de domínio [ChatMessage] para o modelo serializável.
  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      senderId: entity.senderId,
      senderName: entity.senderName,
      senderRa: entity.senderRa,
      text: entity.text,
      timestamp: entity.timestamp.millisecondsSinceEpoch,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          senderId == other.senderId &&
          senderName == other.senderName &&
          senderRa == other.senderRa &&
          text == other.text &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        id,
        senderId,
        senderName,
        senderRa,
        text,
        timestamp,
      );

  @override
  String toString() {
    return 'ChatMessageModel(id: $id, sender: $senderName ($senderRa), text: $text, timestamp: $timestamp)';
  }
}
