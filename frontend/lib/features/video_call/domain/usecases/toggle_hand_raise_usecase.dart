// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import '../errors/video_call_failures.dart';
import '../repositories/video_call_repository.dart';

/// Caso de uso para levantar ou abaixar a mão durante a conferência.
class ToggleHandRaiseUseCase {
  final VideoCallRepository repository;

  ToggleHandRaiseUseCase(this.repository);

  /// Validações defensivas executadas:
  /// - `roomId`: não vazio.
  /// - `peerId`: não vazio.
  Future<void> call({
    required String roomId,
    required String peerId,
    required bool isRaised,
  }) async {
    final cleanRoomId = roomId.trim();
    if (cleanRoomId.isEmpty) {
      throw const VideoCallValidationException('Identificador da sala não pode ser vazio.');
    }

    final cleanPeerId = peerId.trim();
    if (cleanPeerId.isEmpty) {
      throw const VideoCallValidationException('Identificador do participante não pode ser vazio.');
    }

    try {
      await repository.toggleHandRaise(cleanRoomId, cleanPeerId, isRaised);
    } catch (e) {
      if (e is VideoCallValidationException) rethrow;
      throw VideoCallException('Falha ao alternar estado de mão levantada: $e');
    }
  }
}
