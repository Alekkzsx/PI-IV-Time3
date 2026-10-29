// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../../domain/entities/recording_state.dart';

/// Modelo de dados e serialização do estado de gravação sincronizado entre os participantes.
class RecordingStateModel {
  final bool isRecording;
  final String status;
  final int? startedAt;
  final String? recordedById;
  final String? recordedByName;
  final int? stoppedAt;
  final int elapsedDurationMs;
  final String? outputPath;
  final String? errorMessage;

  const RecordingStateModel({
    required this.isRecording,
    this.status = 'idle',
    this.startedAt,
    this.recordedById,
    this.recordedByName,
    this.stoppedAt,
    this.elapsedDurationMs = 0,
    this.outputPath,
    this.errorMessage,
  });

  /// Factory para estado inativo inicial.
  factory RecordingStateModel.initial() {
    return const RecordingStateModel(
      isRecording: false,
      status: 'idle',
      startedAt: null,
      recordedById: null,
      recordedByName: null,
      stoppedAt: null,
      elapsedDurationMs: 0,
    );
  }

  /// Deserializa a partir de Map JSON.
  factory RecordingStateModel.fromJson(Map<String, dynamic> json) {
    int? parsedStartedAt;
    final rawStarted = json['startedAt'];
    if (rawStarted is int) {
      parsedStartedAt = rawStarted;
    } else if (rawStarted is String) {
      parsedStartedAt = DateTime.tryParse(rawStarted)?.millisecondsSinceEpoch;
    }

    int? parsedStoppedAt;
    final rawStopped = json['stoppedAt'];
    if (rawStopped is int) {
      parsedStoppedAt = rawStopped;
    } else if (rawStopped is String) {
      parsedStoppedAt = DateTime.tryParse(rawStopped)?.millisecondsSinceEpoch;
    }

    final isRecording = json['isRecording'] as bool? ?? false;
    final status = json['status'] as String? ?? (isRecording ? 'recording' : 'idle');
    final recordedById = (json['recordedById'] ?? json['startedByPeerId']) as String?;
    final recordedByName = (json['recordedByName'] ?? json['startedByName']) as String?;
    final elapsedMs = (json['elapsedDurationMs'] as num?)?.toInt() ?? 0;

    return RecordingStateModel(
      isRecording: isRecording,
      status: status,
      startedAt: parsedStartedAt,
      recordedById: recordedById,
      recordedByName: recordedByName,
      stoppedAt: parsedStoppedAt,
      elapsedDurationMs: elapsedMs,
      outputPath: json['outputPath'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Serializa para Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'isRecording': isRecording,
      'status': status,
      'startedAt': startedAt,
      'recordedById': recordedById,
      'startedByPeerId': recordedById,
      'recordedByName': recordedByName,
      'startedByName': recordedByName,
      'stoppedAt': stoppedAt,
      'elapsedDurationMs': elapsedDurationMs,
      'outputPath': outputPath,
      'errorMessage': errorMessage,
    };
  }

  /// Converte para a entidade pura de domínio [RecordingState].
  RecordingState toEntity() {
    RecordingStatus recordingStatus;
    try {
      recordingStatus = RecordingStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == status.toLowerCase(),
        orElse: () => isRecording ? RecordingStatus.recording : RecordingStatus.idle,
      );
    } catch (_) {
      recordingStatus = isRecording ? RecordingStatus.recording : RecordingStatus.idle;
    }

    return RecordingState(
      status: recordingStatus,
      isRecording: isRecording,
      startedAt: startedAt != null ? DateTime.fromMillisecondsSinceEpoch(startedAt!) : null,
      startedByPeerId: recordedById,
      startedByName: recordedByName,
      elapsedDuration: Duration(milliseconds: elapsedDurationMs),
      outputPath: outputPath,
      errorMessage: errorMessage,
    );
  }

  /// Converte da entidade de domínio [RecordingState] para o modelo serializável.
  factory RecordingStateModel.fromEntity(RecordingState entity) {
    return RecordingStateModel(
      isRecording: entity.isRecording,
      status: entity.status.name,
      startedAt: entity.startedAt?.millisecondsSinceEpoch,
      recordedById: entity.startedByPeerId,
      recordedByName: entity.startedByName,
      elapsedDurationMs: entity.elapsedDuration.inMilliseconds,
      outputPath: entity.outputPath,
      errorMessage: entity.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingStateModel &&
          runtimeType == other.runtimeType &&
          isRecording == other.isRecording &&
          status == other.status &&
          startedAt == other.startedAt &&
          recordedById == other.recordedById &&
          recordedByName == other.recordedByName &&
          stoppedAt == other.stoppedAt &&
          elapsedDurationMs == other.elapsedDurationMs &&
          outputPath == other.outputPath &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        isRecording,
        status,
        startedAt,
        recordedById,
        recordedByName,
        stoppedAt,
        elapsedDurationMs,
        outputPath,
        errorMessage,
      );

  @override
  String toString() {
    return 'RecordingStateModel(status: $status, isRecording: $isRecording, '
        'startedBy: $recordedByName, durationMs: $elapsedDurationMs)';
  }
}
