// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'signaling_channel.dart';

/// Barramento em memória de sinalização para execução na Dart VM e testes automatizados.
///
/// Replica com exatidão o comportamento do W3C [BroadcastChannel]:
/// - Mensagens enviadas por um canal são entregues a todos os outros canais registrados
///   sob o mesmo [channelName], mas NUNCA ao próprio emissor.
class InMemorySignalingBus {
  static final InMemorySignalingBus _instance = InMemorySignalingBus._internal();
  factory InMemorySignalingBus() => _instance;
  InMemorySignalingBus._internal();

  final Map<String, Set<InMemorySignalingChannel>> _channels = {};

  /// Registra uma nova instância de canal no barramento.
  void register(String channelName, InMemorySignalingChannel channel) {
    _channels.putIfAbsent(channelName, () => <InMemorySignalingChannel>{}).add(channel);
  }

  /// Remove uma instância de canal do barramento.
  void unregister(String channelName, InMemorySignalingChannel channel) {
    final set = _channels[channelName];
    if (set != null) {
      set.remove(channel);
      if (set.isEmpty) {
        _channels.remove(channelName);
      }
    }
  }

  /// Despacha uma mensagem para todos os canais inscritos em [channelName], exceto o [sender].
  void postMessage(String channelName, InMemorySignalingChannel sender, String data) {
    final subscribers = _channels[channelName];
    if (subscribers == null) return;

    for (final recipient in List<InMemorySignalingChannel>.from(subscribers)) {
      if (recipient != sender && !recipient.isClosed) {
        recipient.dispatchIncoming(data);
      }
    }
  }

  /// Limpa todos os canais registrados nesta instância do barramento.
  void reset() {
    _channels.clear();
  }

  /// Limpa o singleton global do barramento.
  static void resetAll() {
    _instance.reset();
  }
}

/// Implementação de [ISignalingChannel] operando sobre o [InMemorySignalingBus].
class InMemorySignalingChannel implements ISignalingChannel {
  final String channelName;
  final InMemorySignalingBus _bus;
  final StreamController<String> _controller = StreamController<String>.broadcast();
  bool _isClosed = false;
  void Function()? _teardownHook;

  InMemorySignalingChannel(this.channelName, [InMemorySignalingBus? bus])
      : _bus = bus ?? InMemorySignalingBus() {
    _bus.register(channelName, this);
  }

  bool get isClosed => _isClosed;

  @override
  Stream<String> get messageStream => _controller.stream;

  @override
  Future<void> send(String data) async {
    if (_isClosed) {
      throw StateError('Cannot send message on a closed InMemorySignalingChannel.');
    }
    _bus.postMessage(channelName, this, data);
  }

  /// Método interno chamado pelo bus para injetar mensagens recebidas de outros pares.
  void dispatchIncoming(String data) {
    if (!_isClosed && !_controller.isClosed) {
      _controller.add(data);
    }
  }

  @override
  void registerTeardownHook(void Function() onTeardown) {
    _teardownHook = onTeardown;
  }

  /// Permite testes simularem o fechamento abrupto de aba/janela do navegador.
  void simulateTeardown() {
    _teardownHook?.call();
  }

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    _bus.unregister(channelName, this);
    await _controller.close();
  }
}
