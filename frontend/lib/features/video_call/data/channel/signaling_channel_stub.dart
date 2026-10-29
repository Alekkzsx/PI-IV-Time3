// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'in_memory_signaling_bus.dart';
import 'signaling_channel.dart';

/// Instancia um [ISignalingChannel] para o ambiente Dart VM (testes de unidade e widgets).
ISignalingChannel createSignalingChannel(String channelName) {
  return InMemorySignalingChannel(channelName);
}
