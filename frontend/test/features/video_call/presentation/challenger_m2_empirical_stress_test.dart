// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/chat_message.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/emoji_reaction.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/hand_raise_item.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/media_state_update.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/meeting_room.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/participant.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/recording_state.dart';
import 'package:pi_iv_time3/features/video_call/domain/repositories/video_call_repository.dart';
import 'package:pi_iv_time3/features/video_call/presentation/controllers/video_call_controller.dart';
import 'package:pi_iv_time3/features/video_call/presentation/pages/video_call_room_page.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/floating_reactions_overlay.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/in_call_chat_drawer.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/meeting_controls_toolbar.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/raised_hands_banner.dart';

/// Test repository that interconnects two peer controllers synchronously in memory.
class LinkedDomainVideoCallRepository implements VideoCallRepository {
  LinkedDomainVideoCallRepository? peerRepo;

  final _joinedCtrl = StreamController<Participant>.broadcast(sync: true);
  final _leftCtrl = StreamController<String>.broadcast(sync: true);
  final _chatCtrl = StreamController<ChatMessage>.broadcast(sync: true);
  final _reactionCtrl = StreamController<EmojiReaction>.broadcast(sync: true);
  final _handRaiseCtrl = StreamController<HandRaiseItem>.broadcast(sync: true);
  final _mediaCtrl = StreamController<MediaStateUpdate>.broadcast(sync: true);
  final _recordingCtrl = StreamController<RecordingState>.broadcast(sync: true);

  @override
  Stream<Participant> get participantJoinedStream => _joinedCtrl.stream;

  @override
  Stream<String> get participantLeftStream => _leftCtrl.stream;

  @override
  Stream<ChatMessage> get chatMessageStream => _chatCtrl.stream;

  @override
  Stream<EmojiReaction> get emojiReactionStream => _reactionCtrl.stream;

  @override
  Stream<HandRaiseItem> get handRaiseStream => _handRaiseCtrl.stream;

  @override
  Stream<MediaStateUpdate> get mediaStateStream => _mediaCtrl.stream;

  @override
  Stream<RecordingState> get recordingStateStream => _recordingCtrl.stream;

  @override
  Future<void> joinRoom(MeetingRoom room, Participant localParticipant) async {}

  @override
  Future<void> leaveRoom(String roomId, String peerId) async {
    peerRepo?._leftCtrl.add(peerId);
  }

  @override
  Future<void> sendChatMessage(String roomId, ChatMessage message) async {
    peerRepo?._chatCtrl.add(message);
  }

  @override
  Future<void> sendEmojiReaction(String roomId, EmojiReaction reaction) async {
    peerRepo?._reactionCtrl.add(reaction);
  }

  @override
  Future<void> toggleHandRaise(String roomId, String peerId, bool isRaised) async {
    peerRepo?._handRaiseCtrl.add(
      HandRaiseItem(
        peerId: peerId,
        raisedAt: DateTime.now(),
        isRaised: isRaised,
      ),
    );
  }

  @override
  Future<void> updateMediaState(
    String roomId,
    String peerId, {
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    double? audioLevel,
  }) async {
    peerRepo?._mediaCtrl.add(
      MediaStateUpdate(
        peerId: peerId,
        isAudioMuted: isAudioMuted,
        isVideoOff: isVideoOff,
        isScreenSharing: isScreenSharing,
        audioLevel: audioLevel,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateRecordingState(String roomId, RecordingState state) async {
    peerRepo?._recordingCtrl.add(state);
  }

  @override
  Future<void> dispose() async {
    await _joinedCtrl.close();
    await _leftCtrl.close();
    await _chatCtrl.close();
    await _reactionCtrl.close();
    await _handRaiseCtrl.close();
    await _mediaCtrl.close();
    await _recordingCtrl.close();
  }
}

void main() {
  group('Empirical Challenger M2-2: Collaboration, Controls & Recording Stress Suite', () {
    late LinkedDomainVideoCallRepository repoA;
    late LinkedDomainVideoCallRepository repoB;
    late VideoCallController controllerA;
    late VideoCallController controllerB;
    final room = MeetingRoom(id: 'CHALLENGER-M2', code: 'CHALLENGER-M2', title: 'Sala M2');

    setUp(() {
      repoA = LinkedDomainVideoCallRepository();
      repoB = LinkedDomainVideoCallRepository();
      repoA.peerRepo = repoB;
      repoB.peerRepo = repoA;

      final pA = Participant(id: 'peer_a', name: 'Alex Sousa', ra: '24802449');
      final pB = Participant(id: 'peer_b', name: 'Beatriz Lima', ra: '24801122');

      controllerA = VideoCallController(
        repository: repoA,
        room: room,
        localParticipant: pA,
      );
      controllerB = VideoCallController(
        repository: repoB,
        room: room,
        localParticipant: pB,
      );

      // Register peers mutually
      controllerA.registerRemoteParticipant(pB);
      controllerB.registerRemoteParticipant(pA);
    });

    tearDown(() {
      controllerA.dispose();
      controllerB.dispose();
      repoA.dispose();
      repoB.dispose();
    });

    // =========================================================================
    // 1. IN-CALL CHAT DRAWER EMPIRICAL TESTS
    // =========================================================================
    group('1. In-Call Chat Drawer Tests', () {
      test('Chat Drawer: Peer-to-peer message exchange between simulated peers', () {
        expect(controllerA.chatMessages, isEmpty);
        expect(controllerB.chatMessages, isEmpty);

        // Peer A sends a message
        controllerA.sendChatMessage('Olá turma!');
        expect(controllerA.chatMessages.length, 1);
        expect(controllerA.chatMessages.first.text, 'Olá turma!');
        expect(controllerA.chatMessages.first.isLocal, isTrue);

        // Peer B receives Peer A's message
        expect(controllerB.chatMessages.length, 1);
        expect(controllerB.chatMessages.first.text, 'Olá turma!');
        expect(controllerB.chatMessages.first.senderId, 'peer_a');
        expect(controllerB.chatMessages.first.senderName, 'Alex Sousa');
        expect(controllerB.chatMessages.first.senderRa, '24802449');

        // Peer B replies
        controllerB.sendChatMessage('Olá Alex!');
        expect(controllerB.chatMessages.length, 2);
        expect(controllerA.chatMessages.length, 2);
        expect(controllerA.chatMessages.last.text, 'Olá Alex!');
        expect(controllerA.chatMessages.last.senderId, 'peer_b');
      });

      test('Chat Drawer: Empty or whitespace-only messages are strictly rejected', () {
        controllerA.sendChatMessage('');
        controllerA.sendChatMessage('   ');
        controllerA.sendChatMessage('\t\n  ');

        expect(controllerA.chatMessages, isEmpty);
        expect(controllerB.chatMessages, isEmpty);
      });

      test('Chat Drawer: Unread badge counter logic and reset on drawer opening', () {
        expect(controllerB.isChatDrawerOpen, isFalse);
        expect(controllerB.unreadChatCount, 0);

        // Message 1 from Peer A
        controllerA.sendChatMessage('Mensagem 1');
        expect(controllerB.unreadChatCount, 1);

        // Message 2 from Peer A
        controllerA.sendChatMessage('Mensagem 2');
        expect(controllerB.unreadChatCount, 2);

        // Peer B opens drawer -> unreadChatCount resets to 0
        controllerB.toggleChatDrawer();
        expect(controllerB.isChatDrawerOpen, isTrue);
        expect(controllerB.unreadChatCount, 0);

        // Message 3 while drawer is open -> unreadChatCount remains 0
        controllerA.sendChatMessage('Mensagem 3');
        expect(controllerB.unreadChatCount, 0);

        // Peer B closes drawer
        controllerB.toggleChatDrawer();
        expect(controllerB.isChatDrawerOpen, isFalse);
        expect(controllerB.unreadChatCount, 0);

        // Message 4 with closed drawer -> unreadChatCount increments to 1
        controllerA.sendChatMessage('Mensagem 4');
        expect(controllerB.unreadChatCount, 1);
      });

      testWidgets('Chat Drawer DEFECT: Timestamp display is absent in InCallChatDrawer', (tester) async {
        controllerA.sendChatMessage('Mensagem com carimbo de tempo');
        controllerB.toggleChatDrawer();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InCallChatDrawer(controller: controllerB),
            ),
          ),
        );
        await tester.pump();

        // Sender header and text are present
        expect(find.text('Alex Sousa (24802449)'), findsOneWidget);
        expect(find.text('Mensagem com carimbo de tempo'), findsOneWidget);

        // Check if ANY timestamp is displayed in the drawer
        final msg = controllerB.chatMessages.first;
        final hourMinute = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
        final hasFormattedTimestamp = find.textContaining(hourMinute).evaluate().isNotEmpty;
        final hasAnyTimestampKey = find.byKey(const Key('chat_message_timestamp')).evaluate().isNotEmpty;

        debugPrint('Empirical finding [Chat Drawer] - Formatted timestamp rendered: $hasFormattedTimestamp, Key rendered: $hasAnyTimestampKey');
        // REQUIREMENT VIOLATION EMPIRICAL ASSERTION:
        // InCallChatDrawer line 81-110 renders only senderName, senderRa, and text.
        // It DOES NOT render msg.timestamp.
        expect(hasFormattedTimestamp, isFalse, reason: 'InCallChatDrawer fails to display message timestamps required by R4');
      });
    });

    // =========================================================================
    // 2. FLOATING EMOJI REACTIONS EMPIRICAL TESTS
    // =========================================================================
    group('2. Floating Emoji Reactions Tests', () {
      testWidgets('Reactions: Real-time broadcast and 2500ms self-pruning timer', (tester) async {
        expect(controllerA.activeReactions, isEmpty);
        expect(controllerB.activeReactions, isEmpty);

        // Peer A triggers reaction ❤️
        controllerA.sendReaction('❤️');
        expect(controllerA.activeReactions.length, 1);
        expect(controllerA.activeReactions.first.emoji, '❤️');
        expect(controllerB.activeReactions.length, 1);
        expect(controllerB.activeReactions.first.emoji, '❤️');

        // At t = 2000ms: reactions are still alive
        await tester.pump(const Duration(milliseconds: 2000));
        expect(controllerA.activeReactions.length, 1, reason: 'Reação local deve persistir aos 2000ms');
        expect(controllerB.activeReactions.length, 1, reason: 'Reação remota deve persistir aos 2000ms');

        // At t = 3000ms+: self-pruning timer (2500ms) has fired and purges reactions
        await tester.pump(const Duration(milliseconds: 1000));
        debugPrint('Empirical finding [Reaction Timers] - controllerA reactions: ${controllerA.activeReactions.length}, controllerB reactions: ${controllerB.activeReactions.length}');
        await tester.pump(const Duration(milliseconds: 1000));
        debugPrint('Empirical finding [Reaction Timers +1s] - controllerA: ${controllerA.activeReactions.length}, controllerB: ${controllerB.activeReactions.length}');
        expect(controllerA.activeReactions, isEmpty, reason: 'Reação local deve auto-remover aos 2500ms');
        expect(controllerB.activeReactions, isEmpty, reason: 'Reação remota deve auto-remover aos 2500ms');
      });

      test('Reactions: Multiple official emojis (❤️, 👍, 👏, 😂, 😮, 🎉) broadcast correctly', () {
        const officialEmojis = ['❤️', '👍', '👏', '😂', '😮', '🎉'];

        for (final emoji in officialEmojis) {
          controllerA.sendReaction(emoji);
        }

        expect(controllerA.activeReactions.length, 6);
        expect(controllerB.activeReactions.length, 6);

        final receivedEmojis = controllerB.activeReactions.map((r) => r.emoji).toList();
        expect(receivedEmojis, containsAll(officialEmojis));
      });

      testWidgets('Reactions DEFECT: FloatingReactionsOverlay lacks physics-based rising animation', (tester) async {
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

        final isAnimatedRising = (initialPosition.dy != midPosition.dy) && (midPosition.dy != endPosition.dy);
        debugPrint('Empirical finding [Reactions Overlay] - initial.dy=${initialPosition.dy}, mid.dy=${midPosition.dy}, end.dy=${endPosition.dy}, isAnimatedRising=$isAnimatedRising');

        // REQUIREMENT VIOLATION EMPIRICAL ASSERTION:
        // FloatingReactionsOverlay is a StatelessWidget with a static Positioned(bottom: 80).
        // It has NO upward movement or animation over time.
        expect(isAnimatedRising, isFalse, reason: 'FloatingReactionsOverlay is completely static and lacks the physics-based rising animation required by R4');
        expect(initialPosition.dy, equals(midPosition.dy));
        expect(midPosition.dy, equals(endPosition.dy));
      });

      testWidgets('Toolbar Reactions DEFECT: MeetingControlsToolbar only triggers 2 of 6 official emojis', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MeetingControlsToolbar(controller: controllerA),
            ),
          ),
        );

        final hasHeart = find.byKey(const Key('toolbar_reaction_heart_button')).evaluate().isNotEmpty;
        final hasClap = find.byKey(const Key('toolbar_reaction_clap_button')).evaluate().isNotEmpty;
        final hasThumbsUp = find.text('👍').evaluate().isNotEmpty;
        final hasLaugh = find.text('😂').evaluate().isNotEmpty;
        final hasSurprised = find.text('😮').evaluate().isNotEmpty;
        final hasParty = find.text('🎉').evaluate().isNotEmpty;

        debugPrint('Empirical finding [Toolbar Emojis] - Heart: $hasHeart, Clap: $hasClap, ThumbsUp: $hasThumbsUp, Laugh: $hasLaugh, Surprised: $hasSurprised, Party: $hasParty');

        expect(hasHeart, isTrue);
        expect(hasClap, isTrue);
        // Emojis (👍, 😂, 😮, 🎉) specified in R4 are missing triggers in the toolbar
        expect(hasThumbsUp, isFalse);
        expect(hasLaugh, isFalse);
        expect(hasSurprised, isFalse);
        expect(hasParty, isFalse);
      });
    });

    // =========================================================================
    // 3. HAND RAISING EMPIRICAL TESTS & INVERTED BOOLEAN BUG VERIFICATION
    // =========================================================================
    group('3. Hand Raising & Queue Synchronization Tests', () {
      test('Hand Raise: FIFO queue ordering and lower-hand synchronization', () {
        expect(controllerA.raisedHandsQueue, isEmpty);
        expect(controllerB.raisedHandsQueue, isEmpty);

        // Peer A raises hand first
        controllerA.toggleHandRaise();
        expect(controllerA.raisedHandsQueue.length, 1);
        expect(controllerA.raisedHandsQueue.first.peerId, 'peer_a');
        expect(controllerB.raisedHandsQueue.length, 1);
        expect(controllerB.raisedHandsQueue.first.peerId, 'peer_a');

        // Peer B raises hand second
        controllerB.toggleHandRaise();
        expect(controllerA.raisedHandsQueue.length, 2);
        expect(controllerA.raisedHandsQueue[0].peerId, 'peer_a');
        expect(controllerA.raisedHandsQueue[1].peerId, 'peer_b');

        expect(controllerB.raisedHandsQueue.length, 2);
        expect(controllerB.raisedHandsQueue[0].peerId, 'peer_a');
        expect(controllerB.raisedHandsQueue[1].peerId, 'peer_b');

        // Peer A lowers hand -> Peer B advances to index 0
        controllerA.toggleHandRaise();
        expect(controllerA.raisedHandsQueue.length, 1);
        expect(controllerA.raisedHandsQueue.first.peerId, 'peer_b');
        expect(controllerB.raisedHandsQueue.length, 1);
        expect(controllerB.raisedHandsQueue.first.peerId, 'peer_b');

        // Peer B lowers hand -> Queue empty
        controllerB.toggleHandRaise();
        expect(controllerA.raisedHandsQueue, isEmpty);
        expect(controllerB.raisedHandsQueue, isEmpty);
      });

      test('Hand Raise CRITICAL DEFECT: Inverted boolean in _onHandRaiseReceived sets remote isHandRaised backwards', () {
        // Initial state
        expect(controllerA.localParticipant.isHandRaised, isFalse);
        expect(controllerB.remoteParticipants.first.isHandRaised, isFalse);

        // Peer A raises hand
        controllerA.toggleHandRaise();

        // Local state on Peer A is correct:
        expect(controllerA.localParticipant.isHandRaised, isTrue);

        // Remote state on Peer B:
        // VideoCallController.dart line 169:
        // isHandRaised: !_raisedHandsQueue.any((h) => h.peerId == item.peerId)
        // Because of the '!', when Peer A's hand is in the queue, isHandRaised is set to FALSE!
        final peerAInB = controllerB.remoteParticipants.firstWhere((p) => p.id == 'peer_a');
        debugPrint('Empirical finding [Hand Raise Inversion] - When Peer A raises hand, Peer B sees peerA.isHandRaised = ${peerAInB.isHandRaised}');

        // EMPIRICAL BUG CONFIRMATION:
        expect(peerAInB.isHandRaised, isFalse,
            reason: 'CRITICAL BUG: Remote participant isHandRaised is FALSE when hand is raised due to inverted boolean !any()');

        // Now Peer A LOWERS hand
        controllerA.toggleHandRaise();

        final peerAInBLowered = controllerB.remoteParticipants.firstWhere((p) => p.id == 'peer_a');
        debugPrint('Empirical finding [Hand Raise Inversion] - When Peer A lowers hand, Peer B sees peerA.isHandRaised = ${peerAInBLowered.isHandRaised}');

        // EMPIRICAL BUG CONFIRMATION:
        expect(peerAInBLowered.isHandRaised, isTrue,
            reason: 'CRITICAL BUG: Remote participant isHandRaised becomes TRUE when hand is lowered due to inverted boolean !any()');
      });

      testWidgets('Hand Raise CRITICAL DEFECT: ✋ tile badge is NOT shown when remote hand is raised, and appears when lowered', (tester) async {
        // Peer A raises hand
        controllerA.toggleHandRaise();

        // Build Peer B's meeting room page
        await tester.pumpWidget(
          MaterialApp(
            home: VideoCallRoomPage(controller: controllerB),
          ),
        );
        await tester.pump();

        // Queue banner shows Peer A
        expect(find.byKey(const Key('raised_hands_banner')), findsOneWidget);
        expect(find.byKey(const Key('queue_item_peer_a')), findsOneWidget);

        // But on Peer A's video tile inside Peer B's view:
        // Hand raised icon key: 'hand_raised_icon_peer_a'
        final handIconFinder = find.byKey(const Key('hand_raised_icon_peer_a'));
        final isHandBadgeRenderedWhenRaised = handIconFinder.evaluate().isNotEmpty;
        debugPrint('Empirical finding [Tile Badge] - Is ✋ badge rendered on Peer A tile when hand is raised: $isHandBadgeRenderedWhenRaised');

        // EMPIRICAL BUG CONFIRMATION: The badge is MISSING from the video tile!
        expect(isHandBadgeRenderedWhenRaised, isFalse,
            reason: 'CRITICAL BUG: ✋ badge is not rendered on remote participant tile when hand is raised');

        // Now Peer A LOWERS their hand
        controllerA.toggleHandRaise();
        await tester.pump();

        final isHandBadgeRenderedWhenLowered = find.byKey(const Key('hand_raised_icon_peer_a')).evaluate().isNotEmpty;
        debugPrint('Empirical finding [Tile Badge] - Is ✋ badge rendered on Peer A tile when hand is LOWERED: $isHandBadgeRenderedWhenLowered');

        // EMPIRICAL BUG CONFIRMATION: The badge SUDDENLY APPEARS when lowered!
        expect(isHandBadgeRenderedWhenLowered, isTrue,
            reason: 'CRITICAL BUG: ✋ badge incorrectly appears on remote participant tile when hand is lowered');
      });
    });

    // =========================================================================
    // 4. MEETING RECORDING & SESSION EXPORT EMPIRICAL TESTS
    // =========================================================================
    group('4. Meeting Recording & Session Export Tests', () {
      test('Recording: State broadcast, timer accumulation and stop behavior', () {
        expect(controllerA.recordingState.isRecording, isFalse);
        expect(controllerB.recordingState.isRecording, isFalse);

        // Peer A starts recording
        controllerA.toggleRecording();

        expect(controllerA.recordingState.isRecording, isTrue);
        expect(controllerB.recordingState.isRecording, isTrue);
        expect(controllerB.recordingState.startedByPeerId, 'peer_a');

        // Peer A stops recording
        controllerA.toggleRecording();

        expect(controllerA.recordingState.isRecording, isFalse);
        expect(controllerB.recordingState.isRecording, isFalse);

        // SessionExport generated
        expect(controllerA.lastSessionExport, isNotNull);
        expect(controllerA.lastSessionExport!.roomCode, 'CHALLENGER-M2');
        expect(controllerA.lastSessionExport!.totalParticipants, 2);
      });

      testWidgets('Recording: Banner and badge rendering in VideoCallRoomPage', (tester) async {
        // Start recording
        controllerA.toggleRecording();

        await tester.pumpWidget(
          MaterialApp(
            home: VideoCallRoomPage(controller: controllerB),
          ),
        );
        await tester.pump();

        // Verify institutional banner
        expect(find.byKey(const Key('institutional_recording_banner')), findsOneWidget);
        expect(find.textContaining('fins acadêmicos e pedagógicos'), findsOneWidget);

        // Verify REC timer badge
        expect(find.byKey(const Key('recording_timer_badge')), findsOneWidget);
        expect(find.textContaining('● REC'), findsWidgets);

        // DEFECT CHECK: Is the badge pulsating?
        // In VideoCallRoomPage line 101, it is a static Container without AnimationController or AnimatedOpacity
        final badgeFinder = find.byKey(const Key('recording_timer_badge'));
        final isAnimatedWidget = find.descendant(
          of: badgeFinder,
          matching: find.byType(AnimatedWidget),
        ).evaluate().isNotEmpty;

        debugPrint('Empirical finding [Recording Badge] - Is pulsating animated widget: $isAnimatedWidget');
        expect(isAnimatedWidget, isFalse,
            reason: 'Recording badge is a static Container and lacks pulsating animation');

        // Stop recording to cleanly cancel recording timer
        controllerA.toggleRecording();
        await tester.pump();
      });

      testWidgets('Recording DEFECT: Session export reactionCount drops to 0 after 2500ms self-pruning timer', (tester) async {
        // Start recording
        controllerA.toggleRecording();

        // Dispatch 3 chat messages and 4 emoji reactions
        controllerA.sendChatMessage('Mensagem 1');
        controllerA.sendChatMessage('Mensagem 2');
        controllerA.sendChatMessage('Mensagem 3');
        controllerA.sendReaction('👍');
        controllerA.sendReaction('🎉');
        controllerA.sendReaction('❤️');
        controllerA.sendReaction('👏');

        expect(controllerA.chatMessages.length, 3);
        expect(controllerA.activeReactions.length, 4);

        // Advance fake time past the 2500ms self-pruning window
        await tester.pump(const Duration(milliseconds: 2600));

        // Active reactions pruned from UI
        expect(controllerA.activeReactions, isEmpty);

        // Stop recording to generate SessionExport ledger
        controllerA.toggleRecording();

        final export = controllerA.lastSessionExport;
        expect(export, isNotNull);
        expect(export!.chatMessageCount, 3);

        debugPrint('Empirical finding [Session Export Defect] - Total reactions sent: 4. Export reactionCount: ${export.reactionCount}');

        // EMPIRICAL BUG CONFIRMATION:
        // VideoCallController line 389:
        // reactionCount: _activeReactions.length,
        // Because it counts _activeReactions instead of a cumulative session counter,
        // the recorded session ledger records 0 reactions even though 4 reactions occurred!
        expect(export.reactionCount, equals(0),
            reason: 'DEFECT CONFIRMED: reactionCount in SessionExport uses pruned _activeReactions.length instead of cumulative counter, resulting in 0');
      });
    });
  });
}
