// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:convert';

/// Constantes oficiais dos tipos de envelope de sinalização P2P.
class SignalingEnvelopeType {
  static const String join = 'join';
  static const String presenceSync = 'presence_sync';
  static const String heartbeat = 'heartbeat';
  static const String leave = 'leave';
  static const String chat = 'chat';
  static const String emoji = 'emoji';
  static const String handRaise = 'hand_raise';
  static const String mediaState = 'media_state';
  static const String recordingState = 'recording_state';

  static const List<String> values = [
    join,
    presenceSync,
    heartbeat,
    leave,
    chat,
    emoji,
    handRaise,
    mediaState,
    recordingState,
  ];

  /// Normaliza strings de tipo para comparação case-insensitive.
  static bool matches(String rawType, String expectedType) {
    return rawType.trim().toLowerCase() == expectedType.trim().toLowerCase();
  }
}

/// Modelo de envelope universal para sinalização P2P entre navegadores.
///
/// Schema JSON:
/// {
///   "protocol": "p2p_videocall_v1",
///   "type": "join" | "presence_sync" | "heartbeat" | "leave" | "chat" | "emoji" | "hand_raise" | "media_state" | "recording_state",
///   "roomId": "SALA-101",
///   "senderId": "peer_12345",
///   "senderName": "Alex Gabriel (RA: 24802449)",
///   "timestamp": 1729169480000,
///   "payload": { ... }
/// }
class SignalingEnvelopeModel {
  static const String defaultProtocol = 'p2p_videocall_v1';

  final String protocol;
  final String type;
  final String roomId;
  final String senderId;
  final String senderName;
  final int timestamp;
  final Map<String, dynamic> payload;

  const SignalingEnvelopeModel({
    this.protocol = defaultProtocol,
    required this.type,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.payload,
  });

  /// Factory auxiliar para criação de envelopes com timestamp atual e protocolo padronizado.
  factory SignalingEnvelopeModel.create({
    required String type,
    required String roomId,
    required String senderId,
    required String senderName,
    required Map<String, dynamic> payload,
    String protocol = defaultProtocol,
    int? timestamp,
  }) {
    return SignalingEnvelopeModel(
      protocol: protocol,
      type: type,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      payload: payload,
    );
  }

  /// Deserializa envelope a partir de Map JSON decodificado com validações de segurança.
  factory SignalingEnvelopeModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final roomId = json['roomId'] as String? ?? '';
    final senderId = json['senderId'] as String? ?? '';
    final senderName = json['senderName'] as String? ?? '';
    final timestamp = json['timestamp'] as int? ?? 0;
    final protocol = json['protocol'] as String? ?? defaultProtocol;
    final payloadRaw = json['payload'];

    Map<String, dynamic> payload;
    if (payloadRaw is Map<String, dynamic>) {
      payload = payloadRaw;
    } else if (payloadRaw is Map) {
      payload = Map<String, dynamic>.from(payloadRaw);
    } else {
      payload = <String, dynamic>{};
    }

    return SignalingEnvelopeModel(
      protocol: protocol,
      type: type,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      timestamp: timestamp,
      payload: payload,
    );
  }

  /// Serializa envelope em Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'protocol': protocol,
      'type': type,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp,
      'payload': payload,
    };
  }

  /// Serializa para string JSON bruta para envio no canal de sinalização.
  String toRawJson() => jsonEncode(toJson());

  /// Deserializa diretamente de string JSON bruta.
  factory SignalingEnvelopeModel.fromRawJson(String str) {
    final dynamic decoded = jsonDecode(str);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object for SignalingEnvelopeModel');
    }
    return SignalingEnvelopeModel.fromJson(decoded);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignalingEnvelopeModel &&
          runtimeType == other.runtimeType &&
          protocol == other.protocol &&
          type == other.type &&
          roomId == other.roomId &&
          senderId == other.senderId &&
          senderName == other.senderName &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      protocol.hashCode ^
      type.hashCode ^
      roomId.hashCode ^
      senderId.hashCode ^
      senderName.hashCode ^
      timestamp.hashCode;

  @override
  String toString() {
    return 'SignalingEnvelopeModel(type: $type, roomId: $roomId, senderId: $senderId, timestamp: $timestamp)';
  }
}
