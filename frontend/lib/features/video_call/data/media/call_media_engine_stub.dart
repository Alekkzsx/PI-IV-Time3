// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter/services.dart';
import '../../domain/entities/session_export.dart';
import 'call_media_engine.dart';

/// Cria a instância de [ICallMediaEngine] para ambiente Dart VM / Testes.
ICallMediaEngine createCallMediaEngine() => StubCallMediaEngine();

/// Implementação determinística de [ICallMediaEngine] para testes e execução fora do navegador.
class StubCallMediaEngine implements ICallMediaEngine {
  final StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();
  final StreamController<void> _screenShareStoppedController =
      StreamController<void>.broadcast();
  final StreamController<Map<String, dynamic>> _outboundWebRtcController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _videoStreamUpdatedController =
      StreamController<String>.broadcast();

  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  Stream<double> get onLocalAudioLevel => _audioLevelController.stream;

  @override
  Stream<void> get onScreenShareStoppedExternally =>
      _screenShareStoppedController.stream;

  @override
  Stream<Map<String, dynamic>> get onOutboundWebRtcSignal =>
      _outboundWebRtcController.stream;

  @override
  Stream<String> get onVideoStreamUpdated =>
      _videoStreamUpdatedController.stream;

  @override
  bool get isInitialized => _isInitialized;

  @override
  String? getVideoViewType(String streamKey) => null;

  @override
  Future<bool> initializeLocalMedia({
    bool audioMuted = false,
    bool videoOff = false,
  }) async {
    if (_isDisposed) return false;
    _isInitialized = true;
    return true;
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {}

  @override
  Future<void> setCameraOff(bool videoOff) async {}

  @override
  Future<bool> startScreenShare() async => true;

  @override
  Future<void> stopScreenShare() async {}

  @override
  Future<void> connectToPeer(String remotePeerId, {required bool isInitiator}) async {}

  @override
  Future<void> handleInboundWebRtcSignal(
    String remotePeerId,
    Map<String, dynamic> signalData,
  ) async {}

  @override
  Future<void> disconnectPeer(String remotePeerId) async {}

  @override
  Future<void> startRecording() async {}

  @override
  Future<String?> stopRecordingAndDownload(SessionExport exportSummary) async {
    return 'ata_${exportSummary.roomCode}.txt';
  }

  @override
  Future<void> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _audioLevelController.close();
    await _screenShareStoppedController.close();
    await _outboundWebRtcController.close();
    await _videoStreamUpdatedController.close();
  }
}
