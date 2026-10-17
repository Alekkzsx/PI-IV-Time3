// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'in_memory_signaling_bus.dart';
import 'mock_video_call_repository.dart';
import 'video_call_contracts.dart';
import 'video_call_test_components.dart';

/// Test harness for orchestrating multi-peer P2P video call scenarios.
class VideoCallTestHarness {
  final String roomCode;
  final MeetingRoom room;
  final MockVideoCallRepository repoA;
  final MockVideoCallRepository repoB;
  final VideoCallTestController peerA;
  final VideoCallTestController peerB;

  VideoCallTestHarness._({
    required this.roomCode,
    required this.room,
    required this.repoA,
    required this.repoB,
    required this.peerA,
    required this.peerB,
  });

  /// Provisions two connected peers in the same meeting room.
  static Future<VideoCallTestHarness> createDualPeer({
    String roomCode = 'SALA-101',
    String peerAName = 'Alex Sousa',
    String peerARa = '24802449',
    String peerBName = 'Beatriz Lima',
    String peerBRa = '24801122',
  }) async {
    final room = MeetingRoom(id: roomCode, code: roomCode, title: 'Sala $roomCode');

    final repoA = MockVideoCallRepository();
    final repoB = MockVideoCallRepository();

    final participantA = Participant(
      id: 'peer_a_id',
      name: peerAName,
      ra: peerARa,
      role: 'student',
    );

    final participantB = Participant(
      id: 'peer_b_id',
      name: peerBName,
      ra: peerBRa,
      role: 'student',
    );

    final controllerA = VideoCallTestController(
      repository: repoA,
      room: room,
      localParticipant: participantA,
    );

    final controllerB = VideoCallTestController(
      repository: repoB,
      room: room,
      localParticipant: participantB,
    );

    return VideoCallTestHarness._(
      roomCode: roomCode,
      room: room,
      repoA: repoA,
      repoB: repoB,
      peerA: controllerA,
      peerB: controllerB,
    );
  }

  /// Disposes both peers, repositories, and signaling bus.
  void dispose() {
    peerA.dispose();
    peerB.dispose();
    repoA.dispose();
    repoB.dispose();
    InMemorySignalingBus.resetAll();
  }
}
