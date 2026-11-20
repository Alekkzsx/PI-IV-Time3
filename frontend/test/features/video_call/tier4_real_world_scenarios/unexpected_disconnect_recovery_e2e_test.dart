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

      // 1. Conexão inicial com 2 pares
      expect(harness.peerA.allParticipants.length, 2);
      expect(find.byType(ParticipantVideoTile), findsNWidgets(2));

      // 2. O par B sai abruptamente / fecha a aba
      harness.peerB.leaveCall();
      await tester.pumpAndSettle();

      // 3. A grade do par A remove imediatamente o bloco do par B sem erros
      expect(harness.peerA.allParticipants.length, 1);
      expect(harness.peerA.remoteParticipants, isEmpty);
      expect(find.byType(ParticipantVideoTile), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_peer_a_id')), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_peer_b_id')), findsNothing);

      // 4. O usuário restante mantém todas as funcionalidades interativas
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
