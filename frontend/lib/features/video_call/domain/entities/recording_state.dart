// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Estados possíveis do ciclo de vida da gravação da conferência.
enum RecordingStatus {
  idle,
  starting,
  recording,
  stopping,
  paused,
  completed,
  error,
}

/// Estado global sincronizado da gravação da conferência.
class RecordingState {
  /// Status atual do ciclo de vida da gravação.
  final RecordingStatus status;

  /// Flag indicadora de gravação ativa.
  final bool isRecording;

  /// Peer ID do participante que iniciou a gravação.
  final String? startedByPeerId;

  /// Nome do participante que iniciou a gravação.
  final String? startedByName;

  /// Timestamp de início da gravação.
  final DateTime? startedAt;

  /// Duração acumulada gravada até o momento.
  final Duration elapsedDuration;

  /// Caminho local ou URI de download da gravação finalizada.
  final String? outputPath;

  /// Mensagem de erro caso o status seja [RecordingStatus.error].
  final String? errorMessage;

  const RecordingState({
    RecordingStatus? status,
    bool? isRecording,
    this.startedByPeerId,
    this.startedByName,
    this.startedAt,
    this.elapsedDuration = Duration.zero,
    this.outputPath,
    this.errorMessage,
  })  : status = status ??
            ((isRecording ?? false) ? RecordingStatus.recording : RecordingStatus.idle),
        isRecording = isRecording ?? (status == RecordingStatus.recording);

  /// Construtor de conveniência para estado neutro inicial.
  factory RecordingState.initial() => const RecordingState();

  /// Conveniência para saber se está inativo.
  bool get isIdle => status == RecordingStatus.idle;

  /// Conveniência para saber se está pausado.
  bool get isPaused => status == RecordingStatus.paused;

  /// Aliases de compatibilidade.
  String? get recordedById => startedByPeerId;
  String? get recordedByName => startedByName;

  /// Formatação padrão `HH:mm:ss` para o badge de gravação `● REC 00:01:24`.
  String get formattedDuration {
    final hours = elapsedDuration.inHours.toString().padLeft(2, '0');
    final minutes = (elapsedDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsedDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  RecordingState copyWith({
    RecordingStatus? status,
    bool? isRecording,
    String? startedByPeerId,
    String? startedByName,
    DateTime? startedAt,
    Duration? elapsedDuration,
    String? outputPath,
    String? errorMessage,
  }) {
    return RecordingState(
      status: status ?? this.status,
      isRecording: isRecording ?? this.isRecording,
      startedByPeerId: startedByPeerId ?? this.startedByPeerId,
      startedByName: startedByName ?? this.startedByName,
      startedAt: startedAt ?? this.startedAt,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecordingState &&
        other.status == status &&
        other.isRecording == isRecording &&
        other.startedByPeerId == startedByPeerId &&
        other.startedByName == startedByName &&
        other.startedAt == startedAt &&
        other.elapsedDuration == elapsedDuration &&
        other.outputPath == outputPath &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        status,
        isRecording,
        startedByPeerId,
        startedByName,
        startedAt,
        elapsedDuration,
        outputPath,
        errorMessage,
      );

  @override
  String toString() {
    return 'RecordingState(status: $status, isRecording: $isRecording, '
        'startedBy: $startedByName ($startedByPeerId), duration: $formattedDuration, '
        'outputPath: $outputPath, error: $errorMessage)';
  }
}
