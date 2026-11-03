// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'signaling_channel.dart';

/// Conecta a sinalizacao WebRTC ao servidor Java por WebSocket.
ISignalingChannel createSignalingChannel(
  String channelName, {
  String? ticket,
}) {
  return WebSocketSignalingChannel(channelName, ticket: ticket);
}

class WebSocketSignalingChannel implements ISignalingChannel {
  static const String _baseUrl = String.fromEnvironment(
    'VIDEO_CALL_WS_BASE_URL',
    defaultValue: 'ws://127.0.0.1:8080',
  );

  final String channelName;
  late final html.WebSocket _channel;
  final StreamController<String> _controller = StreamController<String>.broadcast();
  final Completer<void> _connected = Completer<void>();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _isClosed = false;

  WebSocketSignalingChannel(this.channelName, {String? ticket}) {
    const prefix = 'p2p_videocall_';
    final roomCode = channelName.startsWith(prefix)
        ? channelName.substring(prefix.length)
        : channelName;
    final baseUri = Uri.parse(_baseUrl);
    final socketUri = baseUri
        .replace(scheme: baseUri.scheme == 'https' ? 'wss' : 'ws')
        .resolve('/ws/video-call/${Uri.encodeComponent(roomCode)}')
        .replace(queryParameters: ticket == null ? null : {'ticket': ticket});
    _channel = html.WebSocket(socketUri.toString());

    _subscriptions.add(_channel.onOpen.listen((_) {
      if (!_connected.isCompleted) _connected.complete();
    }));
    _subscriptions.add(_channel.onMessage.listen(
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
        if (!_connected.isCompleted) _connected.completeError(error, stackTrace);
        if (!_isClosed && !_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      },
    ));
    _subscriptions.add(_channel.onClose.listen((_) {
      if (!_connected.isCompleted) {
        _connected.completeError(StateError('WebSocket fechado antes da conexão.'));
      }
      if (!_controller.isClosed) unawaited(_controller.close());
    }));
    _subscriptions.add(_channel.onError.listen((_) {
      if (!_connected.isCompleted) {
        _connected.completeError(StateError('Não foi possível conectar à sala.'));
      }
    }));
  }

  @override
  Stream<String> get messageStream => _controller.stream;

  @override
  Future<void> send(String data) async {
    if (_isClosed) {
      throw StateError('Cannot send message on a closed WebSocketSignalingChannel.');
    }
    await _connected.future.timeout(const Duration(seconds: 8));
    if (_channel.readyState != html.WebSocket.OPEN) {
      throw StateError('WebSocket is not open.');
    }
    _channel.send(data);
  }

  @override
  void registerTeardownHook(void Function() onTeardown) {
    _subscriptions.add(html.window.onBeforeUnload.listen((_) => onTeardown()));
    _subscriptions.add(html.window.onPageHide.listen((_) => onTeardown()));
  }

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    if (_channel.readyState == html.WebSocket.OPEN ||
        _channel.readyState == html.WebSocket.CONNECTING) {
      _channel.close();
    }
    await _controller.close();
  }
}
