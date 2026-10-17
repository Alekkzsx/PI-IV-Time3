// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../entities/meeting_room.dart';
import '../entities/participant.dart';
import '../errors/video_call_failures.dart';
import '../repositories/video_call_repository.dart';

/// Caso de uso responsável pela validação e entrada em uma sala de reunião virtual.
class JoinRoomUseCase {
  final VideoCallRepository repository;

  JoinRoomUseCase(this.repository);

  /// Validações defensivas executadas:
  /// - `room.id`: não nulo, não vazio, entre 3 e 30 caracteres alfanuméricos/hífens.
  /// - `room.title`: não nulo, não vazio, entre 2 e 100 caracteres.
  /// - `localParticipant.id`: não nulo e não vazio.
  /// - `localParticipant.name`: não nulo, entre 2 e 60 caracteres.
  /// - `localParticipant.ra`: não nulo, entre 4 e 20 caracteres.
  Future<void> call({
    required MeetingRoom room,
    required Participant localParticipant,
  }) async {
    final sanitizedRoomId = room.id.trim().toUpperCase();
    if (sanitizedRoomId.isEmpty ||
        !RegExp(r'^[A-Z0-9_\-]{3,30}$').hasMatch(sanitizedRoomId)) {
      throw const VideoCallValidationException(
        'Código da sala inválido. Utilize entre 3 e 30 caracteres alfanuméricos ou hífens.',
      );
    }

    final sanitizedTitle = room.title.trim();
    if (sanitizedTitle.length < 2 || sanitizedTitle.length > 100) {
      throw const VideoCallValidationException(
        'Título da sala inválido. Deve conter entre 2 e 100 caracteres.',
      );
    }

    final sanitizedPeerId = localParticipant.id.trim();
    if (sanitizedPeerId.isEmpty) {
      throw const VideoCallValidationException(
        'Identificador do participante não pode ser vazio.',
      );
    }

    final sanitizedName = localParticipant.name.trim();
    if (sanitizedName.length < 2 || sanitizedName.length > 60) {
      throw const VideoCallValidationException(
        'Nome do participante deve conter entre 2 e 60 caracteres.',
      );
    }

    final sanitizedRa = localParticipant.ra.trim();
    if (sanitizedRa.length < 4 || sanitizedRa.length > 20) {
      throw const VideoCallValidationException(
        'Registro acadêmico (RA) deve conter entre 4 e 20 caracteres.',
      );
    }

    final validatedRoom = room.copyWith(id: sanitizedRoomId, title: sanitizedTitle);
    final validatedParticipant = localParticipant.copyWith(
      id: sanitizedPeerId,
      name: sanitizedName,
      ra: sanitizedRa,
      isLocal: true,
    );

    try {
      await repository.joinRoom(validatedRoom, validatedParticipant);
    } catch (e) {
      if (e is VideoCallValidationException) rethrow;
      throw VideoCallException('Falha ao ingressar na sala: $e');
    }
  }
}
