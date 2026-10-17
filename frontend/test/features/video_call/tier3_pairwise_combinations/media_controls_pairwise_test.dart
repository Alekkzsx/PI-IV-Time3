// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_test_components.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 3: Pairwise Combinations - Media Controls State Matrix', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer();
    });

    tearDown(() {
      harness.dispose();
    });

    testWidgets('Pairwise: [Mic Muted, Video Off, ScreenShare Inactive, Chat Closed]',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Set states
      harness.peerA.toggleAudio(); // Muted
      harness.peerA.toggleVideo(); // Video Off

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      // Assert toolbar icons
      expect(
        find.descendant(
          of: find.byKey(const Key('toolbar_audio_button')),
          matching: find.byIcon(Icons.mic_off),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('toolbar_video_button')),
          matching: find.byIcon(Icons.videocam_off),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen_share_view')), findsNothing);
      expect(find.byKey(const Key('in_call_chat_drawer')), findsNothing);
    });

    testWidgets('Pairwise: [Mic Unmuted, Video On, ScreenShare Active, Chat Open]',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Set states
      harness.peerA.toggleScreenShare(); // Screen share active
      harness.peerA.toggleChatDrawer(); // Chat drawer open

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('toolbar_audio_button')),
          matching: find.byIcon(Icons.mic),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('toolbar_video_button')),
          matching: find.byIcon(Icons.videocam),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen_share_view')), findsOneWidget);
      expect(find.byKey(const Key('in_call_chat_drawer')), findsOneWidget);
    });

    testWidgets('Pairwise: [Mic Muted, Video On, ScreenShare Active, Chat Closed]',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      harness.peerA.toggleAudio();
      harness.peerA.toggleScreenShare();

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('toolbar_audio_button')),
          matching: find.byIcon(Icons.mic_off),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('toolbar_video_button')),
          matching: find.byIcon(Icons.videocam),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen_share_view')), findsOneWidget);
      expect(find.byKey(const Key('in_call_chat_drawer')), findsNothing);
    });

    testWidgets('Pairwise: [Mic Unmuted, Video Off, ScreenShare Inactive, Chat Open]',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      harness.peerA.toggleVideo();
      harness.peerA.toggleChatDrawer();

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('toolbar_audio_button')),
          matching: find.byIcon(Icons.mic),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('toolbar_video_button')),
          matching: find.byIcon(Icons.videocam_off),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('screen_share_view')), findsNothing);
      expect(find.byKey(const Key('in_call_chat_drawer')), findsOneWidget);
    });

    test('Toolbar actions mutate states cleanly and broadcast updates to peer',
        () async {
      // Toggle video off
      harness.peerA.toggleVideo();
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final peerAOnRemote = harness.peerB.remoteParticipants.firstWhere(
        (p) => p.id == 'peer_a_id',
      );
      expect(peerAOnRemote.isVideoOff, isTrue);

      // Toggle audio off
      harness.peerA.toggleAudio();
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final peerAOnRemote2 = harness.peerB.remoteParticipants.firstWhere(
        (p) => p.id == 'peer_a_id',
      );
      expect(peerAOnRemote2.isAudioMuted, isTrue);

      // Toggle screen share
      harness.peerA.toggleScreenShare();
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final peerAOnRemote3 = harness.peerB.remoteParticipants.firstWhere(
        (p) => p.id == 'peer_a_id',
      );
      expect(peerAOnRemote3.isScreenSharing, isTrue);
    });
  });
}
