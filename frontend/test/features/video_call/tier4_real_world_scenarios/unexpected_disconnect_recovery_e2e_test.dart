// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/in_memory_signaling_bus.dart';
import '../helpers/video_call_test_components.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 4: Real-World Scenarios - Unexpected Disconnect & Peer Lifecycle Resilience', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer(
        roomCode: 'SALA-RESILIENCE',
      );
    });

    tearDown(() {
      harness.dispose();
      InMemorySignalingBus.resetAll();
    });

    testWidgets('E2E: Peer abruptly disconnects, grid resizes to 1 tile, remaining user keeps full functionality',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial 2-peer connection
      expect(harness.peerA.allParticipants.length, 2);
      expect(find.byType(ParticipantVideoTile), findsNWidgets(2));

      // 2. Peer B abruptly leaves / closes tab
      harness.peerB.leaveCall();
      await tester.pumpAndSettle();

      // 3. Peer A's grid immediately prunes Peer B's tile without errors
      expect(harness.peerA.allParticipants.length, 1);
      expect(harness.peerA.remoteParticipants, isEmpty);
      expect(find.byType(ParticipantVideoTile), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_peer_a_id')), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_peer_b_id')), findsNothing);

      // 4. Remaining user maintains full interactive capabilities
      harness.peerA.toggleAudio();
      harness.peerA.toggleVideo();
      harness.peerA.sendChatMessage('Permaneço conectado na sala com sucesso');
      await tester.pumpAndSettle();

      expect(harness.peerA.localParticipant.isAudioMuted, isTrue);
      expect(harness.peerA.localParticipant.isVideoOff, isTrue);
      expect(harness.peerA.chatMessages.length, 1);
      expect(harness.peerA.chatMessages.first.text, 'Permaneço conectado na sala com sucesso');
    });
  });
}
