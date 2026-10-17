// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';

/// Pure Dart in-memory signaling bus for testing serverless P2P communication.
///
/// Simulates cross-tab/cross-window broadcast channel communication across
/// multiple virtual peers within the same room code.
class InMemorySignalingBus {
  static final Map<String, InMemorySignalingBus> _instances = {};

  final String roomCode;
  final StreamController<SignalingPayload> _streamController =
      StreamController<SignalingPayload>.broadcast();

  InMemorySignalingBus._(this.roomCode);

  /// Retrieves or creates an in-memory bus for a specific room.
  factory InMemorySignalingBus.forRoom(String roomCode) {
    return _instances.putIfAbsent(
      roomCode.toUpperCase().trim(),
      () => InMemorySignalingBus._(roomCode.toUpperCase().trim()),
    );
  }

  /// Broadcasts a message to all connected peers in this room except the sender.
  void broadcast({required String senderId, required String rawData}) {
    if (!_streamController.isClosed) {
      scheduleMicrotask(() {
        if (!_streamController.isClosed) {
          _streamController.add(
            SignalingPayload(
              senderId: senderId,
              rawData: rawData,
              sentAt: DateTime.now(),
            ),
          );
        }
      });
    }
  }

  /// Subscribes to messages received in this room from other peers.
  Stream<String> subscribe(String peerId) {
    return _streamController.stream
        .where((payload) => payload.senderId != peerId)
        .map((payload) => payload.rawData);
  }

  /// Closes the room bus and cleans up listeners.
  void dispose() {
    _streamController.close();
    _instances.remove(roomCode);
  }

  /// Resets all rooms in memory (for test isolation teardown).
  static void resetAll() {
    for (final bus in _instances.values) {
      bus._streamController.close();
    }
    _instances.clear();
  }
}

/// Represents a raw signaling payload transit through the in-memory bus.
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
