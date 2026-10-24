// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'signaling_channel.dart';

/// Instancia um [ISignalingChannel] conectado ao [html.BroadcastChannel] do navegador Web.
ISignalingChannel createSignalingChannel(String channelName) {
  return WebBroadcastSignalingChannel(channelName);
}

/// Implementação de [ISignalingChannel] que utiliza a API nativa [html.BroadcastChannel].
class WebBroadcastSignalingChannel implements ISignalingChannel {
  final String channelName;
  late final html.BroadcastChannel _channel;
  final StreamController<String> _controller = StreamController<String>.broadcast();
  StreamSubscription? _subscription;
  StreamSubscription? _beforeUnloadSub;
  StreamSubscription? _pageHideSub;
  bool _isClosed = false;

  WebBroadcastSignalingChannel(this.channelName) {
    _channel = html.BroadcastChannel(channelName);
    _subscription = _channel.onMessage.listen(
      (html.MessageEvent event) {
        if (!_isClosed && !_controller.isClosed) {
          final dynamic data = event.data;
          if (data is String) {
            _controller.add(data);
          } else if (data != null) {
            _controller.add(data.toString());
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_isClosed && !_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      },
    );
  }

  @override
  Stream<String> get messageStream => _controller.stream;

  @override
  Future<void> send(String data) async {
    if (_isClosed) {
      throw StateError('Cannot send message on a closed WebBroadcastSignalingChannel.');
    }
    _channel.postMessage(data);
  }

  @override
  void registerTeardownHook(void Function() onTeardown) {
    _beforeUnloadSub?.cancel();
    _pageHideSub?.cancel();

    _beforeUnloadSub = html.window.onBeforeUnload.listen((_) {
      onTeardown();
    });

    _pageHideSub = html.window.onPageHide.listen((_) {
      onTeardown();
    });
  }

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;

    await _subscription?.cancel();
    _subscription = null;

    await _beforeUnloadSub?.cancel();
    _beforeUnloadSub = null;

    await _pageHideSub?.cancel();
    _pageHideSub = null;

    _channel.close();
    await _controller.close();
  }
}
