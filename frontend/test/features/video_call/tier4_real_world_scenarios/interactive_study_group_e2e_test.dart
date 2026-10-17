// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/in_memory_signaling_bus.dart';
import '../helpers/video_call_test_components.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 4: Real-World Scenarios - Interactive Study Group E2E', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer(
        roomCode: 'GRUPO-ESTUDOS',
        peerAName: 'Alex Sousa',
        peerARa: '24802449',
        peerBName: 'Beatriz Lima',
        peerBRa: '24801122',
      );
    });

    tearDown(() {
      harness.dispose();
      InMemorySignalingBus.resetAll();
    });

    testWidgets('E2E: Interactive turn-taking discussion, active speaker highlight, and emoji banter',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Alex starts speaking
      harness.peerA.setAudioLevel(0.40);
      await tester.pump();

      final boxA = tester.widget<Container>(
        find.byKey(const Key('participant_tile_peer_a_id')),
      );
      expect((boxA.decoration as BoxDecoration).border?.top.color, Colors.greenAccent);

      // 2. Alex stops speaking, Beatriz takes the floor and speaks
      harness.peerA.setAudioLevel(0.02);
      harness.peerB.setAudioLevel(0.55);
      await tester.pump();

      final boxB = tester.widget<Container>(
        find.byKey(const Key('participant_tile_peer_b_id')),
      );
      expect((boxB.decoration as BoxDecoration).border?.top.color, Colors.greenAccent);

      // 3. Multi-peer emoji celebration burst
      harness.peerA.sendReaction('🎉');
      harness.peerB.sendReaction('❤️');
      await tester.pump();

      expect(harness.peerA.activeReactions.length, 2);
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('❤️'), findsOneWidget);

      // 4. Collaborative chat study notes exchange
      harness.peerA.sendChatMessage('Resumo do capítulo 3 finalizado');
      harness.peerB.sendChatMessage('Perfeito, vou anexar o diagrama');
      await tester.pump();

      harness.peerA.toggleChatDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Resumo do capítulo 3 finalizado'), findsOneWidget);
      expect(find.text('Perfeito, vou anexar o diagrama'), findsOneWidget);
    });
  });
}
