// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import '../entities/participant.dart';
import '../entities/recording_state.dart';
import '../errors/video_call_failures.dart';
import '../repositories/recording_repository.dart';
import '../repositories/video_call_repository.dart';

/// Caso de uso responsável por alternar e sincronizar a gravação da conferência.
class ToggleRecordingUseCase {
  final VideoCallRepository videoCallRepository;
  final RecordingRepository recordingRepository;

  ToggleRecordingUseCase({
    required this.videoCallRepository,
    required this.recordingRepository,
  });

  /// Executa a transição de estado da gravação:
  /// - Se já estiver gravando: para a gravação local, obtém a mídia gravada,
  ///   atualiza o estado para `completed` e transmite via repositório de sinalização.
  /// - Se estiver parado/idle: inicia a gravação local, atualiza o estado para `recording`
  ///   e transmite via repositório de sinalização.
  Future<RecordingState> call({
    required String roomId,
    required RecordingState currentRecordingState,
    required Participant localParticipant,
  }) async {
    final cleanRoomId = roomId.trim();
    if (cleanRoomId.isEmpty) {
      throw const VideoCallValidationException('Identificador da sala não pode ser vazio.');
    }

    final cleanPeerId = localParticipant.id.trim();
    if (cleanPeerId.isEmpty) {
      throw const VideoCallValidationException('Identificador do participante não pode ser vazio.');
    }

    if (currentRecordingState.isRecording) {
      // Interromper gravação
      try {
        final outputPath = await recordingRepository.stopRecording();
        final stoppedState = currentRecordingState.copyWith(
          status: RecordingStatus.completed,
          isRecording: false,
          outputPath: outputPath,
        );
        await videoCallRepository.updateRecordingState(cleanRoomId, stoppedState);
        return stoppedState;
      } catch (e) {
        final errorState = currentRecordingState.copyWith(
          status: RecordingStatus.error,
          isRecording: false,
          errorMessage: 'Erro ao parar gravação: $e',
        );
        await videoCallRepository.updateRecordingState(cleanRoomId, errorState);
        throw RecordingException('Falha ao parar gravação: $e');
      }
    } else {
      // Iniciar gravação
      try {
        await recordingRepository.startRecording(
          roomId: cleanRoomId,
          initiatorPeerId: cleanPeerId,
          initiatorName: localParticipant.name,
        );
        final startedState = RecordingState(
          status: RecordingStatus.recording,
          isRecording: true,
          startedByPeerId: cleanPeerId,
          startedByName: localParticipant.name,
          startedAt: DateTime.now(),
          elapsedDuration: Duration.zero,
        );
        await videoCallRepository.updateRecordingState(cleanRoomId, startedState);
        return startedState;
      } catch (e) {
        final errorState = currentRecordingState.copyWith(
          status: RecordingStatus.error,
          isRecording: false,
          errorMessage: 'Erro ao iniciar gravação: $e',
        );
        await videoCallRepository.updateRecordingState(cleanRoomId, errorState);
        throw RecordingException('Falha ao iniciar gravação: $e');
      }
    }
  }
}
