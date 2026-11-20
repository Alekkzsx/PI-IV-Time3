// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';

/// Barramento de sinalização em memória em Dart puro para testar comunicação P2P sem servidor.
///
/// Simula comunicação de canal de broadcast entre abas/janelas para
/// múltiplos pares virtuais com o mesmo código de sala.
class InMemorySignalingBus {
  static final Map<String, InMemorySignalingBus> _instances = {};

  final String roomCode;
  final StreamController<SignalingPayload> _streamController =
      StreamController<SignalingPayload>.broadcast(sync: true);

  InMemorySignalingBus._(this.roomCode);

  /// Obtém ou cria um barramento em memória para uma sala específica.
  factory InMemorySignalingBus.forRoom(String roomCode) {
    return _instances.putIfAbsent(
      roomCode.toUpperCase().trim(),
      () => InMemorySignalingBus._(roomCode.toUpperCase().trim()),
    );
  }

  /// Transmite uma mensagem para todos os pares conectados nesta sala, exceto o remetente.
  void broadcast({required String senderId, required String rawData}) {
    if (!_streamController.isClosed) {
      _streamController.add(
        SignalingPayload(
          senderId: senderId,
          rawData: rawData,
          sentAt: DateTime.now(),
        ),
      );
    }
  }

  /// Inscreve-se para receber mensagens enviadas nesta sala por outros pares.
  Stream<String> subscribe(String peerId) {
    return _streamController.stream
        .where((payload) => payload.senderId != peerId)
        .map((payload) => payload.rawData);
  }

  /// Fecha o barramento da sala e limpa os ouvintes.
  void dispose() {
    _streamController.close();
    _instances.remove(roomCode);
  }

  /// Redefine todas as salas em memória (para limpeza e isolamento entre testes).
  static void resetAll() {
    for (final bus in _instances.values) {
      bus._streamController.close();
    }
    _instances.clear();
  }
}

/// Representa uma carga bruta de sinalização trafegando pelo barramento em memória.
class SignalingPayload {
  final String senderId;
  final String rawData;
  final DateTime sentAt;

  const SignalingPayload({
    required this.senderId,
    required this.rawData,
    required this.sentAt,
  });
}
