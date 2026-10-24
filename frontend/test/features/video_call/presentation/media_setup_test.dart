// Desenvolvido por Marcelo Zarpelon - RA: 25015323
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/data/media/call_media_engine_stub.dart';
import 'package:pi_iv_time3/features/video_call/presentation/controllers/video_call_lobby_controller.dart';

void main() {
  test(
    'retries local media initialization before joining after initial failure',
    () async {
      final mediaEngine = _RetryableMediaEngine();
      final controller = VideoCallLobbyController(mediaEngine: mediaEngine);

      expect(await controller.ensureMediaReady(), isTrue);
      expect(mediaEngine.initializationAttempts, 2);
      expect(controller.isMediaReady, isTrue);
      expect(controller.isInitializingMedia, isFalse);

      controller.dispose();
      await mediaEngine.dispose();
    },
  );
}

class _RetryableMediaEngine extends StubCallMediaEngine {
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  int initializationAttempts = 0;

  @override
  Stream<String> get onMediaStatus => _statusController.stream;

  @override
  Future<bool> initializeLocalMedia({
    bool audioMuted = false,
    bool videoOff = false,
  }) async {
    initializationAttempts++;
    return initializationAttempts > 1;
  }

  @override
  Future<void> dispose() async {
    if (!_statusController.isClosed) await _statusController.close();
    await super.dispose();
  }
}
