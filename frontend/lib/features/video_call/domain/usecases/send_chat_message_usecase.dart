// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import '../entities/chat_message.dart';
import '../errors/video_call_failures.dart';
import '../repositories/video_call_repository.dart';

/// Caso de uso para validação e broadcast de mensagens de chat na reunião.
class SendChatMessageUseCase {
  final VideoCallRepository repository;

  SendChatMessageUseCase(this.repository);

  /// Validações defensivas executadas:
  /// - `roomId`: não vazio.
  /// - `message.text`: não vazio, até 1000 caracteres.
  /// - `message.senderId`: não vazio.
  /// - `message.senderName`: não vazio.
  Future<void> call({
    required String roomId,
    required ChatMessage message,
  }) async {
    final cleanRoomId = roomId.trim();
    if (cleanRoomId.isEmpty) {
      throw const VideoCallValidationException('Identificador da sala não pode ser vazio.');
    }

    final cleanText = message.text.trim();
    if (cleanText.isEmpty) {
      throw const VideoCallValidationException('A mensagem não pode ser vazia.');
    }

    if (cleanText.length > 1000) {
      throw const VideoCallValidationException(
        'A mensagem excede o limite máximo permitido de 1000 caracteres.',
      );
    }

    if (message.senderId.trim().isEmpty) {
      throw const VideoCallValidationException('Identificador do remetente não pode ser vazio.');
    }

    if (message.senderName.trim().isEmpty) {
      throw const VideoCallValidationException('Nome do remetente não pode ser vazio.');
    }

    final validatedMessage = message.copyWith(text: cleanText);

    try {
      await repository.sendChatMessage(cleanRoomId, validatedMessage);
    } catch (e) {
      if (e is VideoCallValidationException) rethrow;
      throw VideoCallException('Falha ao enviar mensagem de chat: $e');
    }
  }
}
