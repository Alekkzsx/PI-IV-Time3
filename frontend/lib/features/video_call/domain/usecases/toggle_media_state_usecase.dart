// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import '../errors/video_call_failures.dart';
import '../repositories/video_call_repository.dart';

/// Caso de uso para alteração e sincronização de estados de mídia (áudio, vídeo, tela, RMS).
class ToggleMediaStateUseCase {
  final VideoCallRepository repository;

  ToggleMediaStateUseCase(this.repository);

  /// Validações defensivas executadas:
  /// - `roomId` e `peerId`: não vazios.
  /// - Pelo menos um parâmetro opcional de mídia deve ser fornecido.
  /// - `audioLevel`: caso informado, deve pertencer ao intervalo [0.0, 1.0].
  Future<void> call({
    required String roomId,
    required String peerId,
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    double? audioLevel,
  }) async {
    final cleanRoomId = roomId.trim();
    if (cleanRoomId.isEmpty) {
      throw const VideoCallValidationException('Identificador da sala não pode ser vazio.');
    }

    final cleanPeerId = peerId.trim();
    if (cleanPeerId.isEmpty) {
      throw const VideoCallValidationException('Identificador do participante não pode ser vazio.');
    }

    if (isAudioMuted == null &&
        isVideoOff == null &&
        isScreenSharing == null &&
        audioLevel == null) {
      throw const VideoCallValidationException(
        'Pelo menos um parâmetro de mídia deve ser fornecido para atualização.',
      );
    }

    if (audioLevel != null && (audioLevel < 0.0 || audioLevel > 1.0)) {
      throw const VideoCallValidationException(
        'O nível de áudio deve estar estritamente contido no intervalo entre 0.0 e 1.0.',
      );
    }

    try {
      await repository.updateMediaState(
        cleanRoomId,
        cleanPeerId,
        isAudioMuted: isAudioMuted,
        isVideoOff: isVideoOff,
        isScreenSharing: isScreenSharing,
        audioLevel: audioLevel,
      );
    } catch (e) {
      if (e is VideoCallValidationException) rethrow;
      throw VideoCallException('Falha ao atualizar estado de mídia: $e');
    }
  }
}
