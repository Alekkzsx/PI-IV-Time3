// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../entities/emoji_reaction.dart';
import '../errors/video_call_failures.dart';
import '../repositories/video_call_repository.dart';

/// Caso de uso para validação e broadcast de reações de emoji na reunião.
class SendReactionUseCase {
  final VideoCallRepository repository;

  SendReactionUseCase(this.repository);

  /// Validações defensivas executadas:
  /// - `roomId`: não vazio.
  /// - `reaction.senderId`: não vazio.
  /// - `reaction.emoji`: deve pertencer a `EmojiReaction.supportedEmojis`.
  Future<void> call({
    required String roomId,
    required EmojiReaction reaction,
  }) async {
    final cleanRoomId = roomId.trim();
    if (cleanRoomId.isEmpty) {
      throw const VideoCallValidationException('Identificador da sala não pode ser vazio.');
    }

    if (reaction.senderId.trim().isEmpty) {
      throw const VideoCallValidationException('Identificador do remetente não pode ser vazio.');
    }

    if (!EmojiReaction.isValidEmoji(reaction.emoji)) {
      throw VideoCallValidationException(
        'Reação emoji não suportada: "${reaction.emoji}". '
        'Emojis válidos: ${EmojiReaction.supportedEmojis.join(' ')}.',
      );
    }

    try {
      await repository.sendEmojiReaction(cleanRoomId, reaction);
    } catch (e) {
      if (e is VideoCallValidationException) rethrow;
      throw VideoCallException('Falha ao enviar reação emoji: $e');
    }
  }
}
