// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:async';
import '../entities/recording_state.dart';

/// Contrato abstrato para captura, renderização e download local da gravação da conferência.
abstract class RecordingRepository {
  /// Stream que emite o progresso e estado da gravação local.
  Stream<RecordingState> get recordingStateStream;

  /// Inicia a captura e gravação da conferência para a sala e participante iniciador informados.
  Future<void> startRecording({
    required String roomId,
    required String initiatorPeerId,
    required String initiatorName,
  });

  /// Pausa a gravação em andamento.
  Future<void> pauseRecording();

  /// Retoma uma gravação previamente pausada.
  Future<void> resumeRecording();

  /// Finaliza a gravação, empacota os dados e retorna o caminho local ou Object URL para exportação.
  Future<String?> stopRecording();

  /// Dispara o download automático do arquivo gravado no navegador ou salva no sistema de arquivos.
  Future<void> downloadRecording(String outputPath);

  /// Libera timers, instâncias de gravador e streams.
  Future<void> dispose();
}
