// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/in_memory_signaling_bus.dart';
import '../helpers/video_call_test_components.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 4: Real-World Scenarios - Full Academic Classroom Lecture E2E', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer(
        roomCode: 'SALA-204',
        peerAName: 'Prof. Carlos',
        peerARa: 'DOC-1020',
        peerBName: 'Alex Sousa',
        peerBRa: '24802449',
      );
    });

    tearDown(() {
      harness.dispose();
      InMemorySignalingBus.resetAll();
    });

    testWidgets(
        'E2E: Professor starts lecture, shares screen, student raises hand, chat question, recording, and export',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 1. Mount Professor Carlos's room UI
      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sala SALA-204 (SALA-204)'), findsOneWidget);
      expect(find.text('Prof. Carlos (DOC-1020)'), findsOneWidget);
      expect(find.text('Alex Sousa (24802449)'), findsOneWidget);

      // 2. Professor Carlos starts Screen Sharing (spotlight presentation mode)
      harness.peerA.toggleScreenShare();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('screen_share_view')), findsOneWidget);
      expect(find.text('Apresentação de Tela Ativa'), findsOneWidget);

      // 3. Student Alex raises hand in the class
      harness.peerB.toggleHandRaise();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('raised_hands_banner')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('raised_hands_banner')),
          matching: find.text('Alex Sousa (24802449)'),
        ),
        findsOneWidget,
      );

      // 4. Professor Carlos begins meeting recording
      harness.peerA.toggleRecording();
      await tester.pump();

      expect(find.byKey(const Key('institutional_recording_banner')), findsOneWidget);
      expect(find.byKey(const Key('recording_timer_badge')), findsOneWidget);

      // 5. Student Alex sends a question in the in-call chat
      harness.peerB.sendChatMessage('Professor, haverá revisão para a prova final?');
      await tester.pump();

      // Professor's toolbar displays unread chat badge
      expect(find.byKey(const Key('unread_chat_badge')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // 6. Professor opens chat drawer to review question
      harness.peerA.toggleChatDrawer();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('in_call_chat_drawer')), findsOneWidget);
      expect(find.text('Professor, haverá revisão para a prova final?'), findsOneWidget);
      expect(harness.peerA.unreadChatCount, 0);

      // 7. Student sends applause reaction
      harness.peerB.sendReaction('👏');
      await tester.pump();

      expect(harness.peerA.activeReactions.any((r) => r.emoji == '👏'), isTrue);

      // Allow reaction 2500ms duration to expire cleanly
      await tester.pump(const Duration(milliseconds: 2600));

      // 8. Professor stops recording and concludes session
      harness.peerA.toggleRecording();
      await tester.pump();

      final export = harness.peerA.lastSessionExport;
      expect(export, isNotNull);
      expect(export!.roomCode, 'SALA-204');
      expect(export.chatMessageCount, 1);
      expect(export.totalParticipants, 2);
    });
  });
}
