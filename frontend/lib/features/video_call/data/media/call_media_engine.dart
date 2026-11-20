// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import '../../domain/entities/session_export.dart';

/// Contrato abstrato do motor de mídia real (Webcam, Microfone, WebRTC, Tela e Gravação).
abstract class ICallMediaEngine {
  /// Stream contínua de níveis RMS de áudio capturados do microfone físico (0.0 a 1.0).
  Stream<double> get onLocalAudioLevel;

  /// Stream disparada quando o compartilhamento de tela é encerrado pela barra nativa do navegador.
  Stream<void> get onScreenShareStoppedExternally;

  /// Stream de sinais WebRTC locais (SDP Offer, Answer, ICE Candidate) prontos para envio P2P.
  Stream<Map<String, dynamic>> get onOutboundWebRtcSignal;

  /// Stream notificando que o vídeo de um participante (local, remoto ou tela) está pronto para renderização.
  Stream<String> get onVideoStreamUpdated;

  /// Stream com diagnósticos de captura e reprodução de mídia para a interface.
  Stream<String> get onMediaStatus;

  /// Indica se a captura de mídia local (câmera/microfone) já está inicializada.
  bool get isInitialized;

  /// Retorna o identificador de view (`viewType`) registrado para renderizar o vídeo de [streamKey].
  ///
  /// Chaves padrão:
  /// - `'local'` para a câmera local
  /// - `'screen'` para o compartilhamento de tela
  /// - `peerId` para o stream WebRTC de um participante remoto
  String? getVideoViewType(String streamKey);

  /// Solicita permissão de câmera e microfone ao navegador e inicia a captura real.
  Future<bool> initializeLocalMedia({
    bool audioMuted = false,
    bool videoOff = false,
  });

  /// Libera a reprodução de áudio do navegador a partir de um gesto do usuário.
  Future<void> unlockAudioPlayback();

  /// Habilita ou silencia a trilha real de áudio do microfone local.
  Future<void> setMicrophoneMuted(bool muted);

  /// Liga ou desliga a trilha real de vídeo da câmera local.
  Future<void> setCameraOff(bool videoOff);

  /// Inicia a captura real de compartilhamento de tela (`getDisplayMedia`).
  /// Retorna `true` se o usuário selecionou uma tela/janela e iniciou a transmissão.
  Future<bool> startScreenShare();

  /// Encerra o compartilhamento de tela ativo.
  Future<void> stopScreenShare();

  /// Inicia uma conexão WebRTC com um participante remoto recém-descoberto.
  Future<void> connectToPeer(String remotePeerId, {required bool isInitiator});

  /// Processa um pacote de sinalização WebRTC (Offer, Answer ou ICE) recebido de [remotePeerId].
  Future<void> handleInboundWebRtcSignal(
    String remotePeerId,
    Map<String, dynamic> signalData,
  );

  /// Fecha e limpa a conexão WebRTC associada a [remotePeerId].
  Future<void> disconnectPeer(String remotePeerId);

  /// Inicia a gravação real de mídia da reunião (`MediaRecorder`).
  Future<void> startRecording();

  /// Para a gravação ativa e dispara o download real do arquivo gravado e relatório da sessão.
  Future<String?> stopRecordingAndDownload(SessionExport exportSummary);

  /// Copia texto para a área de transferência do navegador/sistema.
  Future<void> copyToClipboard(String text);

  /// Libera todas as trilhas de câmera, microfone, WebRTC e timers.
  Future<void> dispose();
}
