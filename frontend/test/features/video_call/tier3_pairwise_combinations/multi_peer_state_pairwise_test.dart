// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_test_components.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 3: Pairwise Combinations - Multi-Peer Concurrent State Matrix', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer();
    });

    tearDown(() {
      harness.dispose();
    });

    testWidgets('Pairwise: [Peer A Speaking] x [Peer B Hand Raised] x [Recording Active]',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 1. Peer A starts speaking
      harness.peerA.setAudioLevel(0.45);
      // 2. Peer B raises hand
      harness.peerB.toggleHandRaise();
      // 3. Peer A starts recording
      harness.peerA.toggleRecording();

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      // Assert Peer A's tile shows active speaking highlight
      final peerABox = tester.widget<Container>(
        find.byKey(const Key('participant_tile_peer_a_id')),
      );
      final borderA = (peerABox.decoration as BoxDecoration).border as Border;
      expect(borderA.top.color, Colors.greenAccent);

      // Assert Peer B has raised hand badge and raised hands banner is visible
      expect(find.byKey(const Key('raised_hands_banner')), findsOneWidget);
      expect(find.text('Beatriz Lima (24801122)'), findsOneWidget);

      // Assert recording banner and badge are active
      expect(find.byKey(const Key('institutional_recording_banner')), findsOneWidget);
      expect(find.byKey(const Key('recording_timer_badge')), findsOneWidget);

      // Clean up recording timer before ending test
      harness.peerA.toggleRecording();
      await tester.pumpAndSettle();
    });

    testWidgets('Pairwise: [Peer A Silent] x [Peer B Hand Lowered] x [ScreenShare Active]',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Peer A initiates screen share while silent
      harness.peerA.toggleScreenShare();

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      // Primary presentation screen visible
      expect(find.byKey(const Key('screen_share_view')), findsOneWidget);
      // No raised hands banner
      expect(find.byKey(const Key('raised_hands_banner')), findsNothing);
      // Horizontal filmstrip contains both participants
      expect(find.byType(ListView), findsOneWidget);
    });

    test('Concurrent message and reaction dispatch during active recording', () async {
      // Start recording
      harness.peerA.toggleRecording();

      // Peer B sends chat and reaction concurrently
      harness.peerB.sendChatMessage('Pergunta importante durante a gravação');
      harness.peerB.sendReaction('❤️');

      expect(harness.peerA.chatMessages.length, 1);
      expect(harness.peerA.chatMessages.first.text, 'Pergunta importante durante a gravação');
      expect(harness.peerA.activeReactions.length, 1);
      expect(harness.peerA.activeReactions.first.emoji, '❤️');
      expect(harness.peerA.recordingState.isRecording, isTrue);

      harness.peerA.toggleRecording();
    });
  });
}
