// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../../../../core/errors/failures.dart';

/// Exceção lançada quando regras de validação da chamada de vídeo são violadas.
class VideoCallValidationException implements Exception {
  final String message;
  const VideoCallValidationException(this.message);

  @override
  String toString() => 'VideoCallValidationException: $message';
}

/// Exceção genérica para falhas operacionais na sinalização ou P2P.
class VideoCallException implements Exception {
  final String message;
  const VideoCallException(this.message);

  @override
  String toString() => 'VideoCallException: $message';
}

/// Exceção para falhas na captura ou controle de dispositivos de mídia.
class MediaException implements Exception {
  final String message;
  const MediaException(this.message);

  @override
  String toString() => 'MediaException: $message';
}

/// Exceção para erros na gravação da reunião.
class RecordingException implements Exception {
  final String message;
  const RecordingException(this.message);

  @override
  String toString() => 'RecordingException: $message';
}

/// Falha de validação compatível com a hierarquia de [Failure] do core.
class VideoCallValidationFailure extends Failure {
  const VideoCallValidationFailure(super.message);
}

/// Falha de sinalização/conexão P2P.
class VideoCallSignalingFailure extends Failure {
  const VideoCallSignalingFailure(super.message);
}
