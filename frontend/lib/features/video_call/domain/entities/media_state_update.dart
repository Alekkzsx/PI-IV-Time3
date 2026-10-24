// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Atualização atômica do estado de mídia de um participante no canal P2P.
class MediaStateUpdate {
  /// Peer ID cujo estado de mídia foi alterado.
  final String peerId;

  /// Novo estado do microfone (nulo se inalterado).
  final bool? isAudioMuted;

  /// Novo estado da câmera (nulo se inalterado).
  final bool? isVideoOff;

  /// Novo estado de compartilhamento de tela (nulo se inalterado).
  final bool? isScreenSharing;

  /// Nível de áudio RMS aferido (nulo se inalterado).
  final double? audioLevel;

  /// Carimbo de data/hora da emissão da atualização.
  final DateTime timestamp;

  const MediaStateUpdate({
    required this.peerId,
    this.isAudioMuted,
    this.isVideoOff,
    this.isScreenSharing,
    this.audioLevel,
    required this.timestamp,
  });

  MediaStateUpdate copyWith({
    String? peerId,
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    double? audioLevel,
    DateTime? timestamp,
  }) {
    return MediaStateUpdate(
      peerId: peerId ?? this.peerId,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      audioLevel: audioLevel ?? this.audioLevel,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaStateUpdate &&
        other.peerId == peerId &&
        other.isAudioMuted == isAudioMuted &&
        other.isVideoOff == isVideoOff &&
        other.isScreenSharing == isScreenSharing &&
        ((other.audioLevel == null && audioLevel == null) ||
            (other.audioLevel != null &&
                audioLevel != null &&
                (other.audioLevel! - audioLevel!).abs() < 0.001)) &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(
        peerId,
        isAudioMuted,
        isVideoOff,
        isScreenSharing,
        audioLevel,
        timestamp,
      );

  @override
  String toString() {
    return 'MediaStateUpdate(peerId: $peerId, audioMuted: $isAudioMuted, '
        'videoOff: $isVideoOff, screenSharing: $isScreenSharing, '
        'audioLevel: $audioLevel, timestamp: $timestamp)';
  }
}
