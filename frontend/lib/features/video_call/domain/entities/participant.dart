// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Papéis de usuário suportados na conferência P2P.
enum ParticipantRole {
  host,
  presenter,
  participant,
}

/// Entidade representativa de um participante real conectado na reunião.
///
/// Invariante Zero Bots: representa estritamente um usuário humano real conectado.
class Participant {
  /// Identificador exclusivo da sessão do peer (UUID/peerId).
  final String id;

  /// Nome de exibição do participante (e.g. "Alex Sousa").
  final String name;

  /// Registro Acadêmico ou identificador institucional (e.g. "24802449").
  final String ra;

  /// Papel descritivo do participante na sala.
  final String role;

  /// Indica se o microfone está silenciado.
  final bool isAudioMuted;

  /// Indica se a câmera de vídeo está desligada.
  final bool isVideoOff;

  /// Indica se o participante está compartilhando a tela.
  final bool isScreenSharing;

  /// Indica se o participante está com a mão levantada.
  final bool isHandRaised;

  /// Indica se o participante é o anfitrião da sala.
  final bool isHost;

  /// Indica se este participante corresponde ao usuário deste cliente local.
  final bool isLocal;

  /// Nível de volume em tempo real (0.0 a 1.0) para detecção de voz.
  final double audioLevel;

  /// Data e hora em que o participante entrou na reunião.
  final DateTime joinedAt;

  /// Data e hora da última recepção de sinalização de presença/heartbeat.
  final DateTime lastHeartbeat;

  final bool? _isSpeakingExplicit;

  Participant({
    required this.id,
    required this.name,
    required this.ra,
    dynamic role = 'participant',
    this.isAudioMuted = false,
    this.isVideoOff = false,
    this.isScreenSharing = false,
    this.isHandRaised = false,
    bool? isHost,
    this.isLocal = false,
    this.audioLevel = 0.0,
    bool? isSpeaking,
    DateTime? joinedAt,
    DateTime? lastHeartbeat,
  })  : role = role is ParticipantRole ? role.name : (role?.toString() ?? 'participant'),
        isHost = isHost ?? (role == 'host' || role == ParticipantRole.host),
        joinedAt = joinedAt ?? DateTime.now(),
        lastHeartbeat = lastHeartbeat ?? joinedAt ?? DateTime.now(),
        _isSpeakingExplicit = isSpeaking;

  /// Determina dinamicamente se o participante está falando (nível RMS > 0.15 e não mutado).
  bool get isSpeaking => _isSpeakingExplicit ?? (!isAudioMuted && audioLevel > 0.15);

  /// Retorna o [ParticipantRole] tipado correspondente ao [role].
  ParticipantRole get participantRole {
    return ParticipantRole.values.firstWhere(
      (r) => r.name.toLowerCase() == role.toLowerCase(),
      orElse: () => isHost ? ParticipantRole.host : ParticipantRole.participant,
    );
  }

  Participant copyWith({
    String? id,
    String? name,
    String? ra,
    dynamic role,
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    bool? isHandRaised,
    bool? isHost,
    bool? isLocal,
    double? audioLevel,
    bool? isSpeaking,
    DateTime? joinedAt,
    DateTime? lastHeartbeat,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      ra: ra ?? this.ra,
      role: role ?? this.role,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      isHost: isHost ?? this.isHost,
      isLocal: isLocal ?? this.isLocal,
      audioLevel: audioLevel ?? this.audioLevel,
      isSpeaking: isSpeaking ?? _isSpeakingExplicit,
      joinedAt: joinedAt ?? this.joinedAt,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Participant &&
        other.id == id &&
        other.name == name &&
        other.ra == ra &&
        other.role == role &&
        other.isAudioMuted == isAudioMuted &&
        other.isVideoOff == isVideoOff &&
        other.isScreenSharing == isScreenSharing &&
        other.isHandRaised == isHandRaised &&
        other.isHost == isHost &&
        other.isLocal == isLocal &&
        (other.audioLevel - audioLevel).abs() < 0.001;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        ra,
        role,
        isAudioMuted,
        isVideoOff,
        isScreenSharing,
        isHandRaised,
        isHost,
        isLocal,
        audioLevel,
      );

  @override
  String toString() {
    return 'Participant(id: $id, name: $name, ra: $ra, role: $role, '
        'audioMuted: $isAudioMuted, videoOff: $isVideoOff, sharing: $isScreenSharing, '
        'handRaised: $isHandRaised, host: $isHost, local: $isLocal, '
        'audioLevel: ${audioLevel.toStringAsFixed(2)}, speaking: $isSpeaking)';
  }
}
