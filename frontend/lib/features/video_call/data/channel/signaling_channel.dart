// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';

/// Contrato abstrato do canal de sinalização P2P para troca de mensagens em tempo real.
///
/// Fornece abstração sobre [BroadcastChannel] (Web) e [InMemorySignalingBus] (Testes/Dart VM).
abstract class ISignalingChannel {
  /// Stream assíncrono com mensagens recebidas no canal (JSON strings).
  Stream<String> get messageStream;

  /// Envia mensagem codificada em String para os demais pares inscritos no canal.
  Future<void> send(String data);

  /// Encerra o canal, remove listeners e cancela recursos abertos.
  Future<void> close();

  /// Registra um callback para despacho síncrono de encerramento (ex: onBeforeUnload/pagehide).
  void registerTeardownHook(void Function() onTeardown);
}
