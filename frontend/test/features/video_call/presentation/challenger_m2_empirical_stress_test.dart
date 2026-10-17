// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/data/channel/in_memory_signaling_bus.dart';
import 'package:pi_iv_time3/features/video_call/data/datasources/video_call_signaling_datasource.dart';
import 'package:pi_iv_time3/features/video_call/data/repositories/video_call_repository_impl.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/chat_message.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/emoji_reaction.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/meeting_room.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/participant.dart';
import 'package:pi_iv_time3/features/video_call/presentation/controllers/video_call_controller.dart';
import 'package:pi_iv_time3/features/video_call/presentation/pages/video_call_room_page.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/dynamic_video_grid.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/floating_reactions_overlay.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/in_call_chat_drawer.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/meeting_controls_toolbar.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/participant_video_tile.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/raised_hands_banner.dart';

void main() {
  group('Empirical Challenger M2-2: Collaboration, Controls & Recording Stress Suite', () {
    late InMemorySignalingBus bus;

    setUp(() {
      bus = InMemorySignalingBus();
      bus.reset();
    });

    tearDown(() {
      bus.reset();
    });

    // Helper to create two production controllers connected via real P2P InMemorySignalingChannel
    Future<({
      VideoCallController controllerA,
      VideoCallController controllerB,
      VideoCallRepositoryImpl repoA,
      VideoCallRepositoryImpl repoB,
    })> createDualProductionControllers({
      String roomCode = 'STRESS-M2-ROOM',
    }) async {
      final room = MeetingRoom(id: roomCode, code: roomCode, title: 'Sala $roomCode');

      final dsA = VideoCallSignalingDataSource(
        channelFactory: (name) => InMemorySignalingChannel(name, bus),
      );
      final dsB = VideoCallSignalingDataSource(
        channelFactory: (name) => InMemorySignalingChannel(name, bus),
      );

      final repoA = VideoCallRepositoryImpl(dataSource: dsA);
      final repoB = VideoCallRepositoryImpl(dataSource: dsB);

      final pA = Participant(id: 'peer_a', name: 'Alex Sousa', ra: '24802449');
      final pB = Participant(id: 'peer_b', name: 'Beatriz Lima', ra: '24801122');

      final controllerA = VideoCallController(
        repository: repoA,
        room: room,
        localParticipant: pA,
      );

      final controllerB = VideoCallController(
        repository: repoB,
        room: room,
        localParticipant: pB,
      );

      // Allow JOIN and PRESENCE_SYNC handshake
      await Future<void>.delayed(const Duration(milliseconds: 60));

      return (
        controllerA: controllerA,
        controllerB: controllerB,
        repoA: repoA,
        repoB: repoB,
      );
    }

    // =========================================================================
    // 1. IN-CALL CHAT DRAWER EMPIRICAL TESTS
    // =========================================================================
    group('1. In-Call Chat Drawer Tests', () {
      test('Chat Drawer: Peer-to-peer message exchange between simulated peers', () async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        expect(cA.chatMessages, isEmpty);
        expect(cB.chatMessages, isEmpty);

        // Peer A sends a message
        cA.sendChatMessage('Olá Beatriz, tudo bem?');
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(cA.chatMessages.length, 1);
        expect(cA.chatMessages.first.text, 'Olá Beatriz, tudo bem?');
        expect(cA.chatMessages.first.senderId, 'peer_a');

        expect(cB.chatMessages.length, 1);
        expect(cB.chatMessages.first.text, 'Olá Beatriz, tudo bem?');
        expect(cB.chatMessages.first.senderId, 'peer_a');

        // Peer B replies
        cB.sendChatMessage('Olá Alex! Apresentação pronta.');
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(cA.chatMessages.length, 2);
        expect(cA.chatMessages.last.text, 'Olá Alex! Apresentação pronta.');
        expect(cA.chatMessages.last.senderId, 'peer_b');

        expect(cB.chatMessages.length, 2);
        expect(cB.chatMessages.last.text, 'Olá Alex! Apresentação pronta.');

        cA.leaveCall();
        cB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      test('Chat Drawer: Empty or whitespace-only messages are strictly rejected', () async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        cA.sendChatMessage('');
        cA.sendChatMessage('   ');
        cA.sendChatMessage('\t\n  ');
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(cA.chatMessages, isEmpty);
        expect(cB.chatMessages, isEmpty);

        cA.leaveCall();
        cB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      test('Chat Drawer: Unread badge counter logic and reset on drawer opening', () async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        expect(cB.isChatDrawerOpen, isFalse);
        expect(cB.unreadChatCount, 0);

        // Message 1 from Peer A
        cA.sendChatMessage('Mensagem 1');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(cB.unreadChatCount, 1);

        // Message 2 from Peer A
        cA.sendChatMessage('Mensagem 2');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(cB.unreadChatCount, 2);

        // Peer B opens drawer -> unreadChatCount resets to 0
        cB.toggleChatDrawer();
        expect(cB.isChatDrawerOpen, isTrue);
        expect(cB.unreadChatCount, 0);

        // Message 3 while drawer is open -> unreadChatCount remains 0
        cA.sendChatMessage('Mensagem 3');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(cB.unreadChatCount, 0);

        // Peer B closes drawer
        cB.toggleChatDrawer();
        expect(cB.isChatDrawerOpen, isFalse);
        expect(cB.unreadChatCount, 0);

        // Message 4 with closed drawer -> unreadChatCount increments to 1
        cA.sendChatMessage('Mensagem 4');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(cB.unreadChatCount, 1);

        cA.leaveCall();
        cB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      testWidgets('Chat Drawer: Timestamp display verification in widget tree', (tester) async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        cA.sendChatMessage('Mensagem com timestamp');
        await Future<void>.delayed(const Duration(milliseconds: 40));

        cB.toggleChatDrawer();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InCallChatDrawer(controller: cB),
            ),
          ),
        );
        await tester.pump();

        // Sender header and text are present
        expect(find.text('Alex Sousa (24802449)'), findsOneWidget);
        expect(find.text('Mensagem com timestamp'), findsOneWidget);

        // Verification of timestamp display:
        // Does InCallChatDrawer render ANY timestamp text widget for the message?
        final msg = cB.chatMessages.first;
        final hourMinute = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
        final hasFormattedTimestamp = find.textContaining(hourMinute).evaluate().isNotEmpty;
        final hasAnyTimestampWidget = find.byKey(const Key('chat_message_timestamp')).evaluate().isNotEmpty;

        debugPrint('Empirical finding - Timestamp text found: $hasFormattedTimestamp, Key found: $hasAnyTimestampWidget');

        cA.leaveCall();
        cB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });
    });

    // =========================================================================
    // 2. FLOATING EMOJI REACTIONS EMPIRICAL TESTS
    // =========================================================================
    group('2. Floating Emoji Reactions Tests', () {
      test('Reactions: Real-time broadcast and 2500ms self-pruning timer', () async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        expect(cA.activeReactions, isEmpty);
        expect(cB.activeReactions, isEmpty);

        // Peer A triggers reaction ❤️
        cA.sendReaction('❤️');
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(cA.activeReactions.length, 1);
        expect(cA.activeReactions.first.emoji, '❤️');
        expect(cB.activeReactions.length, 1);
        expect(cB.activeReactions.first.emoji, '❤️');

        // At t = 2000ms: reactions are still alive
        await Future<void>.delayed(const Duration(milliseconds: 2000));
        expect(cA.activeReactions.length, 1, reason: 'Reação deve persistir aos 2000ms');
        expect(cB.activeReactions.length, 1, reason: 'Reação remota deve persistir aos 2000ms');

        // At t = 2600ms total (+600ms): self-pruning timer of 2500ms has fired
        await Future<void>.delayed(const Duration(milliseconds: 650));
        expect(cA.activeReactions, isEmpty, reason: 'Reação local deve auto-remover aos 2500ms');
        expect(cB.activeReactions, isEmpty, reason: 'Reação remota deve auto-remover aos 2500ms');

        cA.leaveCall();
        cB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      test('Reactions: Multiple official emojis (❤️, 👍, 👏, 😂, 😮, 🎉) broadcast correctly', () async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        const officialEmojis = ['❤️', '👍', '👏', '😂', '😮', '🎉'];

        for (final emoji in officialEmojis) {
          cA.sendReaction(emoji);
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(cA.activeReactions.length, 6);
        expect(cB.activeReactions.length, 6);

        final receivedEmojis = cB.activeReactions.map((r) => r.emoji).toList();
        expect(receivedEmojis, containsAll(officialEmojis));

        cA.leaveCall();
        cB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      testWidgets('Reactions: FloatingReactionsOverlay rising animation check', (tester) async {
        final reactions = [
          EmojiReaction(
            id: 'r1',
            peerId: 'peer_1',
            peerName: 'Alex',
            emoji: '🎉',
            timestamp: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  FloatingReactionsOverlay(reactions: reactions),
                ],
              ),
            ),
          ),
        );

        final initialPosition = tester.getBottomLeft(find.byKey(const Key('reaction_item_r1')));

        // Advance 500ms and 1000ms
        await tester.pump(const Duration(milliseconds: 500));
        final midPosition = tester.getBottomLeft(find.byKey(const Key('reaction_item_r1')));

        await tester.pump(const Duration(milliseconds: 500));
        final endPosition = tester.getBottomLeft(find.byKey(const Key('reaction_item_r1')));

        final isAnimatedRising = initialPosition.dy != midPosition.dy && midPosition.dy != endPosition.dy;
        debugPrint('Empirical finding - Reaction positions: initial=$initialPosition, mid=$midPosition, end=$endPosition, isRising=$isAnimatedRising');
      });

      testWidgets('Toolbar Reactions: Check available emoji reaction buttons in toolbar', (tester) async {
        final fixture = await createDualProductionControllers();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MeetingControlsToolbar(controller: fixture.controllerA),
            ),
          ),
        );

        final hasHeart = find.byKey(const Key('toolbar_reaction_heart_button')).evaluate().isNotEmpty;
        final hasClap = find.byKey(const Key('toolbar_reaction_clap_button')).evaluate().isNotEmpty;
        final hasThumbsUp = find.text('👍').evaluate().isNotEmpty;
        final hasLaugh = find.text('😂').evaluate().isNotEmpty;
        final hasSurprised = find.text('😮').evaluate().isNotEmpty;
        final hasParty = find.text('🎉').evaluate().isNotEmpty;

        debugPrint('Empirical finding - Toolbar emojis: Heart=$hasHeart, Clap=$hasClap, ThumbsUp=$hasThumbsUp, Laugh=$hasLaugh, Surprised=$hasSurprised, Party=$hasParty');

        fixture.controllerA.leaveCall();
        fixture.controllerB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });
    });

    // =========================================================================
    // 3. HAND RAISING EMPIRICAL TESTS
    // =========================================================================
    group('3. Hand Raising & Queue Synchronization Tests', () {
      test('Hand Raise: FIFO queue ordering and lower-hand synchronization', () async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        expect(cA.raisedHandsQueue, isEmpty);
        expect(cB.raisedHandsQueue, isEmpty);

        // Peer A raises hand first
        cA.toggleHandRaise();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(cA.raisedHandsQueue.length, 1);
        expect(cA.raisedHandsQueue.first.peerId, 'peer_a');
        expect(cB.raisedHandsQueue.length, 1);
        expect(cB.raisedHandsQueue.first.peerId, 'peer_a');

        // Peer B raises hand second
        cB.toggleHandRaise();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(cA.raisedHandsQueue.length, 2);
        expect(cA.raisedHandsQueue[0].peerId, 'peer_a');
        expect(cA.raisedHandsQueue[1].peerId, 'peer_b');

        expect(cB.raisedHandsQueue.length, 2);
        expect(cB.raisedHandsQueue[0].peerId, 'peer_a');
        expect(cB.raisedHandsQueue[1].peerId, 'peer_b');

        // Peer A lowers hand -> Peer B advances to index 0
        cA.toggleHandRaise();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(cA.raisedHandsQueue.length, 1);
        expect(cA.raisedHandsQueue.first.peerId, 'peer_b');
        expect(cB.raisedHandsQueue.length, 1);
        expect(cB.raisedHandsQueue.first.peerId, 'peer_b');

        // Peer B lowers hand -> Queue empty
        cB.toggleHandRaise();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(cA.raisedHandsQueue, isEmpty);
        expect(cB.raisedHandsQueue, isEmpty);

        cA.leaveCall();
        cB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      test('Hand Raise BUG INSPECTION: Remote participant tile isHandRaised boolean state', () async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        // Initial state: neither has hand raised
        expect(cA.localParticipant.isHandRaised, isFalse);
        expect(cB.remoteParticipants.first.isHandRaised, isFalse);

        // Peer A raises hand
        cA.toggleHandRaise();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        // On Peer A (local):
        expect(cA.localParticipant.isHandRaised, isTrue);

        // On Peer B: what is Peer A's isHandRaised in cB.remoteParticipants?
        final peerAInB = cB.remoteParticipants.firstWhere((p) => p.id == 'peer_a');
        debugPrint('Empirical finding - When Peer A raises hand, cB sees peerA.isHandRaised = ${peerAInB.isHandRaised}');

        // Now Peer A lowers hand
        cA.toggleHandRaise();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final peerAInBLowered = cB.remoteParticipants.firstWhere((p) => p.id == 'peer_a');
        debugPrint('Empirical finding - When Peer A lowers hand, cB sees peerA.isHandRaised = ${peerAInBLowered.isHandRaised}');

        cA.leaveCall();
        cB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      testWidgets('Hand Raise: ✋ tile badge display on remote video tile in DynamicVideoGrid', (tester) async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        // Peer A raises hand
        cA.toggleHandRaise();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        // Render Peer B's view of the call
        await tester.pumpWidget(
          MaterialApp(
            home: VideoCallRoomPage(controller: cB),
          ),
        );
        await tester.pump();

        // Check if hand raised icon for peer_a is rendered in cB's view
        final handIconFinder = find.byKey(const Key('hand_raised_icon_peer_a'));
        final isHandBadgeRendered = handIconFinder.evaluate().isNotEmpty;
        debugPrint('Empirical finding - Is ✋ badge rendered on Peer A tile inside Peer B view: $isHandBadgeRendered');

        // Check if queue banner is rendered
        expect(find.byKey(const Key('raised_hands_banner')), findsOneWidget);
        expect(find.byKey(const Key('queue_item_peer_a')), findsOneWidget);

        cA.leaveCall();
        cB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });
    });

    // =========================================================================
    // 4. MEETING RECORDING & SESSION EXPORT EMPIRICAL TESTS
    // =========================================================================
    group('4. Meeting Recording & Session Export Tests', () {
      test('Recording: State broadcast, timer accumulation and stop behavior', () async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        expect(cA.recordingState.isRecording, isFalse);
        expect(cB.recordingState.isRecording, isFalse);

        // Peer A starts recording
        cA.toggleRecording();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(cA.recordingState.isRecording, isTrue);
        expect(cB.recordingState.isRecording, isTrue);
        expect(cB.recordingState.startedByPeerId, 'peer_a');

        // Let timer tick for 1.2s
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        expect(cA.recordingState.elapsedDuration.inSeconds, greaterThanOrEqualTo(1));

        // Peer A stops recording
        cA.toggleRecording();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(cA.recordingState.isRecording, isFalse);
        expect(cB.recordingState.isRecording, isFalse);

        // SessionExport generated
        expect(cA.lastSessionExport, isNotNull);
        expect(cA.lastSessionExport!.roomCode, 'STRESS-M2-ROOM');
        expect(cA.lastSessionExport!.totalParticipants, 2);

        cA.leaveCall();
        cB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      testWidgets('Recording: Banner and badge rendering in VideoCallRoomPage', (tester) async {
        final fixture = await createDualProductionControllers();
        final cB = fixture.controllerB;

        // Start recording
        fixture.controllerA.toggleRecording();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        await tester.pumpWidget(
          MaterialApp(
            home: VideoCallRoomPage(controller: cB),
          ),
        );
        await tester.pump();

        // Verify institutional banner
        expect(find.byKey(const Key('institutional_recording_banner')), findsOneWidget);
        expect(find.textContaining('fins acadêmicos e pedagógicos'), findsOneWidget);

        // Verify REC timer badge
        expect(find.byKey(const Key('recording_timer_badge')), findsOneWidget);
        expect(find.textContaining('● REC'), findsWidgets);

        // Check pulsating animation on badge
        final badgeWidget = tester.widget<Container>(find.byKey(const Key('recording_timer_badge')));
        debugPrint('Empirical finding - REC badge widget type: ${badgeWidget.runtimeType}');

        fixture.controllerA.leaveCall();
        fixture.controllerB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      test('Recording: Session export reactionCount retention after 2500ms self-pruning', () async {
        final fixture = await createDualProductionControllers();
        final cA = fixture.controllerA;

        // Start recording
        cA.toggleRecording();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        // Disparar 3 mensagens de chat e 4 reações de emoji
        cA.sendChatMessage('Mensagem 1');
        cA.sendChatMessage('Mensagem 2');
        cA.sendChatMessage('Mensagem 3');
        cA.sendReaction('👍');
        cA.sendReaction('🎉');
        cA.sendReaction('❤️');
        cA.sendReaction('👏');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(cA.chatMessages.length, 3);
        expect(cA.activeReactions.length, 4);

        // Aguarda transcorrer a janela de auto-remoção das reações (2600ms > 2500ms)
        await Future<void>.delayed(const Duration(milliseconds: 2600));

        // Reações ativas expiraram da tela
        expect(cA.activeReactions, isEmpty);

        // Para a gravação e gera o SessionExport
        cA.toggleRecording();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final export = cA.lastSessionExport;
        expect(export, isNotNull);
        expect(export!.chatMessageCount, 3);

        debugPrint('Empirical finding - SessionExport reactionCount after 2500ms pruning: ${export.reactionCount} (Expected: 4, Actual: ${export.reactionCount})');

        cA.leaveCall();
        fixture.controllerB.leaveCall();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });
    });
  });
}
