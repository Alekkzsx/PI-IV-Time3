// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../../domain/entities/participant.dart';

/// Modelo de dados e serialização para participante da videoconferência.
class ParticipantModel {
  final String id;
  final String name;
  final String ra;
  final bool isAudioMuted;
  final bool isVideoOff;
  final bool isScreenSharing;
  final bool isHandRaised;
  final double audioLevel;
  final bool isSpeaking;
  final int lastHeartbeat;
  final String role;

  const ParticipantModel({
    required this.id,
    required this.name,
    required this.ra,
    this.isAudioMuted = false,
    this.isVideoOff = false,
    this.isScreenSharing = false,
    this.isHandRaised = false,
    this.audioLevel = 0.0,
    this.isSpeaking = false,
    required this.lastHeartbeat,
    this.role = 'participant',
  });

  /// Deserializa a partir de Map JSON.
  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    final audioLevel = (json['audioLevel'] as num?)?.toDouble() ?? 0.0;
    final isAudioMuted = json['isAudioMuted'] as bool? ?? false;
    final explicitSpeaking = json['isSpeaking'] as bool?;

    return ParticipantModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ra: json['ra'] as String? ?? '',
      isAudioMuted: isAudioMuted,
      isVideoOff: json['isVideoOff'] as bool? ?? false,
      isScreenSharing: json['isScreenSharing'] as bool? ?? false,
      isHandRaised: json['isHandRaised'] as bool? ?? false,
      audioLevel: audioLevel,
      isSpeaking: explicitSpeaking ?? (!isAudioMuted && audioLevel > 0.15),
      lastHeartbeat: json['lastHeartbeat'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      role: json['role'] as String? ?? 'participant',
    );
  }

  /// Serializa para Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ra': ra,
      'isAudioMuted': isAudioMuted,
      'isVideoOff': isVideoOff,
      'isScreenSharing': isScreenSharing,
      'isHandRaised': isHandRaised,
      'audioLevel': audioLevel,
      'isSpeaking': isSpeaking,
      'lastHeartbeat': lastHeartbeat,
      'role': role,
    };
  }

  /// Converte para a entidade pura de domínio [Participant].
  Participant toEntity({bool isLocal = false}) {
    return Participant(
      id: id,
      name: name,
      ra: ra,
      role: role,
      isLocal: isLocal,
      isAudioMuted: isAudioMuted,
      isVideoOff: isVideoOff,
      isScreenSharing: isScreenSharing,
      isHandRaised: isHandRaised,
      audioLevel: audioLevel,
      isSpeaking: isSpeaking,
      lastHeartbeat: DateTime.fromMillisecondsSinceEpoch(lastHeartbeat),
      joinedAt: DateTime.fromMillisecondsSinceEpoch(lastHeartbeat),
    );
  }

  /// Converte da entidade pura de domínio [Participant] para o modelo serializável.
  factory ParticipantModel.fromEntity(Participant entity) {
    return ParticipantModel(
      id: entity.id,
      name: entity.name,
      ra: entity.ra,
      role: entity.role,
      isAudioMuted: entity.isAudioMuted,
      isVideoOff: entity.isVideoOff,
      isScreenSharing: entity.isScreenSharing,
      isHandRaised: entity.isHandRaised,
      audioLevel: entity.audioLevel,
      isSpeaking: entity.isSpeaking,
      lastHeartbeat: entity.lastHeartbeat.millisecondsSinceEpoch,
    );
  }

  ParticipantModel copyWith({
    String? id,
    String? name,
    String? ra,
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    bool? isHandRaised,
    double? audioLevel,
    bool? isSpeaking,
    int? lastHeartbeat,
    String? role,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ra: ra ?? this.ra,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      audioLevel: audioLevel ?? this.audioLevel,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          ra == other.ra &&
          isAudioMuted == other.isAudioMuted &&
          isVideoOff == other.isVideoOff &&
          isScreenSharing == other.isScreenSharing &&
          isHandRaised == other.isHandRaised &&
          (other.audioLevel - audioLevel).abs() < 0.001 &&
          isSpeaking == other.isSpeaking &&
          role == other.role;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        ra,
        isAudioMuted,
        isVideoOff,
        isScreenSharing,
        isHandRaised,
        audioLevel,
        isSpeaking,
        role,
      );

  @override
  String toString() {
    return 'ParticipantModel(id: $id, name: $name, ra: $ra, role: $role, '
        'muted: $isAudioMuted, videoOff: $isVideoOff, level: ${audioLevel.toStringAsFixed(2)}, speaking: $isSpeaking)';
  }
}
