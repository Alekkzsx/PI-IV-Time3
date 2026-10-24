// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:async';

/// Contrato abstrato para controle do hardware local de áudio, vídeo e compartilhamento de tela.
abstract class MediaRepository {
  /// Stream emitindo em tempo real o nível de volume RMS do microfone local (0.0 a 1.0).
  Stream<double> get localAudioLevelStream;

  /// Stream com o status de mudo do microfone local (true = silenciado).
  Stream<bool> get audioMutedStream;

  /// Stream com o status de vídeo da câmera local (true = câmera desligada).
  Stream<bool> get videoOffStream;

  /// Stream com o status de transmissão de tela local (true = compartilhando tela).
  Stream<bool> get screenSharingStream;

  /// Inicializa o stream de pré-visualização de câmera e microfone para a página de lobby.
  Future<void> initializePreview();

  /// Inicia a captura de dispositivos locais (câmera e microfone).
  Future<void> startLocalMedia({bool startAudio = true, bool startVideo = true});

  /// Encerra todas as faixas locais de mídia e libera o hardware da webcam e microfone.
  Future<void> stopLocalMedia();

  /// Alterna o estado do microfone local entre mudo e ativo.
  Future<void> toggleAudio({required bool muted});

  /// Alterna o estado da câmera local entre desligada e ativa.
  Future<void> toggleVideo({required bool videoOff});

  /// Solicita permissão do navegador e inicia o compartilhamento de tela local.
  Future<void> startScreenShare();

  /// Interrompe o compartilhamento de tela e restaura o feed padrão da câmera.
  Future<void> stopScreenShare();

  /// Libera todos os recursos, analisadores de áudio e listeners.
  Future<void> dispose();
}
