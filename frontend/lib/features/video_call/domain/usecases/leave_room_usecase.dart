// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import '../errors/video_call_failures.dart';
import '../repositories/video_call_repository.dart';

/// Caso de uso responsável pela saída formal de uma reunião virtual e liberação de recursos.
class LeaveRoomUseCase {
  final VideoCallRepository repository;

  LeaveRoomUseCase(this.repository);

  /// Validações defensivas executadas:
  /// - `roomId`: não vazio.
  /// - `peerId`: não vazio.
  Future<void> call({
    required String roomId,
    required String peerId,
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
      await repository.leaveRoom(cleanRoomId, cleanPeerId);
    } catch (e) {
      if (e is VideoCallValidationException) rethrow;
      throw VideoCallException('Falha ao sair da sala: $e');
    }
  }
}
