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

/// Test repository that interconnects two peer controllers synchronously in memory.
class InterconnectedVideoCallRepository implements VideoCallRepository {
  InterconnectedVideoCallRepository? peerRepo;

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
  group('Challenger M2-4 Deep Empirical Stress Harness', () {
    late InterconnectedVideoCallRepository repoA;
    late InterconnectedVideoCallRepository repoB;
    late VideoCallController controllerA;
    late VideoCallController controllerB;
    final room = MeetingRoom(id: 'CHALLENGER-M2-4', code: 'CHALLENGER-M2-4', title: 'Sala M2-4');

    setUp(() {
      repoA = InterconnectedVideoCallRepository();
      repoB = InterconnectedVideoCallRepository();
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
    // 1. VERIFY FLOATING REACTIONS RISING ANIMATION: VERTICAL DELTA > 0
    // =========================================================================
    group('1. Floating Reactions Rising Animation Metrics', () {
      testWidgets('Empirical trajectory profiling: vertical delta > 0 at all progressive intervals', (tester) async {
        final reaction = EmojiReaction(
          id: 'reaction_rising_test',
          peerId: 'peer_a',
          peerName: 'Alex Sousa',
          emoji: '🎉',
          timestamp: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  FloatingReactionsOverlay(reactions: [reaction]),
                ],
              ),
            ),
          ),
        );

        final finder = find.byKey(const Key('reaction_item_reaction_rising_test'));
        expect(finder, findsOneWidget);

        // Sample trajectory across t = 0 to t = 2500ms
        final dy0 = tester.getBottomLeft(finder).dy;
        await tester.pump(const Duration(milliseconds: 250));
        final dy250 = tester.getBottomLeft(finder).dy;
        await tester.pump(const Duration(milliseconds: 250));
        final dy500 = tester.getBottomLeft(finder).dy;
        await tester.pump(const Duration(milliseconds: 500));
        final dy1000 = tester.getBottomLeft(finder).dy;
        await tester.pump(const Duration(milliseconds: 500));
        final dy1500 = tester.getBottomLeft(finder).dy;
        await tester.pump(const Duration(milliseconds: 500));
        final dy2000 = tester.getBottomLeft(finder).dy;
        await tester.pump(const Duration(milliseconds: 500));
        final dy2500 = tester.getBottomLeft(finder).dy;

        final delta250 = dy0 - dy250;
        final delta500 = dy0 - dy500;
        final delta1000 = dy0 - dy1000;
        final delta1500 = dy0 - dy1500;
        final delta2000 = dy0 - dy2000;
        final delta2500 = dy0 - dy2500;

        debugPrint('Empirical Trajectory [Rising Reaction]:');
        debugPrint('  t=0ms: dy=$dy0 (initial)');
        debugPrint('  t=250ms: dy=$dy250, delta=$delta250');
        debugPrint('  t=500ms: dy=$dy500, delta=$delta500');
        debugPrint('  t=1000ms: dy=$dy1000, delta=$delta1000');
        debugPrint('  t=1500ms: dy=$dy1500, delta=$delta1500');
        debugPrint('  t=2000ms: dy=$dy2000, delta=$delta2000');
        debugPrint('  t=2500ms: dy=$dy2500, delta=$delta2500');

        // Assert strictly positive vertical deltas (rising upwards in Flutter screen coordinates)
        expect(delta250, greaterThan(0.0), reason: 'Must rise upwards after 250ms');
        expect(delta500, greaterThan(delta250), reason: 'Must rise higher at 500ms');
        expect(delta1000, greaterThan(delta500), reason: 'Must rise higher at 1000ms');
        expect(delta1500, greaterThan(delta1000), reason: 'Must rise higher at 1500ms');
        expect(delta2000, greaterThan(delta1500), reason: 'Must rise higher at 2000ms');
        expect(delta2500, greaterThan(delta2000), reason: 'Must reach apex at 2500ms');

        // Net vertical displacement must equal Tween range (280.0 - 60.0 = 220.0 pixels)
        expect(delta2500, closeTo(220.0, 0.5), reason: 'Total vertical displacement must reach 220.0 px');
      });

      testWidgets('Burst stress test: 20 concurrent animated particles rise without crashing or frame loss', (tester) async {
        final reactions = List.generate(
          20,
          (i) => EmojiReaction(
            id: 'burst_$i',
            peerId: 'peer_a',
            peerName: 'Alex Sousa',
            emoji: ['❤️', '👍', '👏', '😂', '😮', '🎉'][i % 6],
            timestamp: DateTime.now(),
          ),
        );

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

        expect(find.byType(FloatingReactionsOverlay), findsOneWidget);

        // Advance 1000ms
        await tester.pump(const Duration(milliseconds: 1000));

        for (var i = 0; i < 20; i++) {
          final itemFinder = find.byKey(Key('reaction_item_burst_$i'));
          expect(itemFinder, findsOneWidget);
          final pos = tester.getBottomLeft(itemFinder);
          expect(pos.dy, lessThan(600.0 - 60.0), reason: 'Particle $i must be rising');
        }
      });
    });

    // =========================================================================
    // 2. VERIFY CHAT MESSAGE TIMESTAMPS RENDERED IN WIDGET TREE
    // =========================================================================
    group('2. Chat Message Timestamps in Widget Tree', () {
      testWidgets('Timestamps rendered with correct HH:mm formatting for local and remote messages', (tester) async {
        // Prepare historical timestamps
        final t1 = DateTime(2026, 10, 17, 8, 5); // 08:05
        final t2 = DateTime(2026, 10, 17, 14, 30); // 14:30
        final t3 = DateTime(2026, 10, 17, 23, 59); // 23:59

        controllerB.chatMessages.add(
          ChatMessage(
            id: 'm1',
            senderId: 'peer_a',
            senderName: 'Alex Sousa',
            senderRa: '24802449',
            text: 'Bom dia turma!',
            timestamp: t1,
          ),
        );
        controllerB.chatMessages.add(
          ChatMessage(
            id: 'm2',
            senderId: 'peer_b',
            senderName: 'Beatriz Lima',
            senderRa: '24801122',
            text: 'Boa tarde!',
            timestamp: t2,
            isLocal: true,
          ),
        );
        controllerB.chatMessages.add(
          ChatMessage(
            id: 'm3',
            senderId: 'peer_a',
            senderName: 'Alex Sousa',
            senderRa: '24802449',
            text: 'Reunião quase no fim',
            timestamp: t3,
          ),
        );

        controllerB.toggleChatDrawer();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InCallChatDrawer(controller: controllerB),
            ),
          ),
        );
        await tester.pump();

        final timestampFinders = find.byKey(const Key('chat_message_timestamp'));
        expect(timestampFinders, findsNWidgets(3));

        expect(find.text('08:05'), findsOneWidget);
        expect(find.text('14:30'), findsOneWidget);
        expect(find.text('23:59'), findsOneWidget);

        debugPrint('Empirical finding [Chat Timers] - All 3 timestamps (08:05, 14:30, 23:59) rendered correctly');
      });

      testWidgets('Adversarial sender name stress: 150-char sender name does not overflow timestamp', (tester) async {
        final longName = 'A' * 150;
        controllerB.chatMessages.add(
          ChatMessage(
            id: 'm_long',
            senderId: 'peer_adversarial',
            senderName: longName,
            senderRa: '99999999',
            text: 'Testando overflow de linha com nome gigante',
            timestamp: DateTime(2026, 10, 17, 12, 0),
          ),
        );
        controllerB.toggleChatDrawer();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InCallChatDrawer(controller: controllerB),
            ),
          ),
        );
        await tester.pump();

        // Must render timestamp without Throwing RenderFlex overflow exception
        expect(find.text('12:00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    // =========================================================================
    // 3. VERIFY ALL 6 EMOJIS ACCESSIBLE IN TOOLBAR
    // =========================================================================
    group('3. All 6 Emojis Accessible in Toolbar', () {
      testWidgets('All 6 emoji buttons present, interactive, and trigger real-time P2P dispatch', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MeetingControlsToolbar(controller: controllerA),
            ),
          ),
        );

        final testCases = <Map<String, dynamic>>[
          {
            'key': const Key('toolbar_reaction_heart_button'),
            'emoji': '❤️',
            'tooltip': 'Reagir com Coração',
          },
          {
            'key': const Key('toolbar_reaction_thumbs_up_button'),
            'emoji': '👍',
            'tooltip': 'Reagir com Joinha',
          },
          {
            'key': const Key('toolbar_reaction_clap_button'),
            'emoji': '👏',
            'tooltip': 'Reagir com Palmas',
          },
          {
            'key': const Key('toolbar_reaction_laugh_button'),
            'emoji': '😂',
            'tooltip': 'Reagir com Risada',
          },
          {
            'key': const Key('toolbar_reaction_surprised_button'),
            'emoji': '😮',
            'tooltip': 'Reagir com Surpresa',
          },
          {
            'key': const Key('toolbar_reaction_party_button'),
            'emoji': '🎉',
            'tooltip': 'Reagir com Festa',
          },
        ];

        for (final tc in testCases) {
          final btnKey = tc['key'] as Key;
          final emoji = tc['emoji'] as String;
          final tooltip = tc['tooltip'] as String;

          final btnFinder = find.byKey(btnKey);
          expect(btnFinder, findsOneWidget, reason: 'Button for $emoji must exist');

          final iconBtn = tester.widget<IconButton>(btnFinder);
          expect(iconBtn.tooltip, equals(tooltip));

          // Tap the button
          await tester.tap(btnFinder);
          await tester.pump();

          // Verify controller A sent reaction
          expect(controllerA.activeReactions.last.emoji, equals(emoji));

          // Verify controller B received reaction via P2P bus
          expect(controllerB.activeReactions.last.emoji, equals(emoji));

          debugPrint('Empirical finding [Toolbar Trigger] - $emoji ($tooltip) triggered and synchronized to remote peer');
        }

        expect(controllerA.activeReactions.length, equals(6));
        expect(controllerB.activeReactions.length, equals(6));
      });
    });

    // =========================================================================
    // 4. VERIFY SESSION EXPORT REACTION RETENTION AFTER 2500MS SELF-PRUNING
    // =========================================================================
    group('4. Session Export Reaction Retention', () {
      testWidgets('Auditable session ledger preserves total reaction count after multi-stage self-pruning', (tester) async {
        // Start recording
        controllerA.toggleRecording();
        expect(controllerA.recordingState.isRecording, isTrue);
        expect(controllerB.recordingState.isRecording, isTrue);

        // Stage 1: Send 6 reactions from Peer A
        final batch1 = ['❤️', '👍', '👏', '😂', '😮', '🎉'];
        for (final emoji in batch1) {
          controllerA.sendReaction(emoji);
        }

        expect(controllerA.activeReactions.length, 6);
        expect(controllerB.activeReactions.length, 6);
        expect(controllerA.totalReactionsCount, 6);
        expect(controllerB.totalReactionsCount, 6);

        // Advance 3000ms: All batch 1 reactions must be pruned from UI
        await tester.pump(const Duration(milliseconds: 3000));
        expect(controllerA.activeReactions, isEmpty, reason: 'Active reactions must be self-pruned');
        expect(controllerB.activeReactions, isEmpty, reason: 'Remote active reactions must be self-pruned');

        // Counters must remain intact:
        expect(controllerA.totalReactionsCount, 6);
        expect(controllerB.totalReactionsCount, 6);

        // Stage 2: Send 4 reactions from Peer B
        final batch2 = ['👍', '🎉', '❤️', '👏'];
        for (final emoji in batch2) {
          controllerB.sendReaction(emoji);
        }

        expect(controllerA.activeReactions.length, 4);
        expect(controllerB.activeReactions.length, 4);
        expect(controllerA.totalReactionsCount, 10);
        expect(controllerB.totalReactionsCount, 10);

        // Advance another 3000ms: All batch 2 reactions self-pruned
        await tester.pump(const Duration(milliseconds: 3000));
        expect(controllerA.activeReactions, isEmpty);
        expect(controllerB.activeReactions, isEmpty);

        // Stop recording
        controllerA.toggleRecording();
        expect(controllerA.recordingState.isRecording, isFalse);
        expect(controllerB.recordingState.isRecording, isFalse);

        // Verify SessionExport on Peer A (initiator)
        final exportA = controllerA.lastSessionExport;
        expect(exportA, isNotNull);
        expect(exportA!.reactionCount, equals(10), reason: 'Export reactionCount must retain all 10 cumulative reactions');
        expect(exportA.roomCode, equals('CHALLENGER-M2-4'));
        expect(exportA.totalParticipants, equals(2));

        // Verify SessionExport on Peer B (remote listener)
        final exportB = controllerB.lastSessionExport;
        expect(exportB, isNotNull);
        expect(exportB!.reactionCount, equals(10), reason: 'Remote peer export reactionCount must also retain 10 reactions');

        // Verify JSON serialization format conforms to academic_session_ledger_v1
        final jsonA = exportA.toJson();
        expect(jsonA['exportFormat'], equals('academic_session_ledger_v1'));
        expect(jsonA['reactionCount'], equals(10));
        expect(jsonA['totalParticipants'], equals(2));

        debugPrint('Empirical finding [Session Export Audit] - Total reactions sent: 10, Pruned: 10, Export reactionCount: ${exportA.reactionCount}, JSON format: ${jsonA['exportFormat']}');
      });
    });

    // =========================================================================
    // 5. VERIFY PULSATING REC BADGE ANIMATION
    // =========================================================================
    group('5. Pulsating REC Badge Animation', () {
      testWidgets('Pulsating REC badge dynamically modulates opacity between 0.6 and 1.0 periodically', (tester) async {
        controllerA.toggleRecording();

        await tester.pumpWidget(
          MaterialApp(
            home: VideoCallRoomPage(controller: controllerA),
          ),
        );
        await tester.pump();

        final badgeFinder = find.byKey(const Key('recording_timer_badge'));
        expect(badgeFinder, findsOneWidget);

        // Locate inner Opacity widget inside _PulsatingRecBadge
        final opacityFinder = find.descendant(
          of: badgeFinder,
          matching: find.byType(Opacity),
        );
        expect(opacityFinder, findsOneWidget);

        // Sample opacity at t=0ms, 250ms, 500ms, 750ms, 1000ms, 1500ms, 2000ms
        final op0 = tester.widget<Opacity>(opacityFinder).opacity;

        await tester.pump(const Duration(milliseconds: 250));
        final op250 = tester.widget<Opacity>(opacityFinder).opacity;

        await tester.pump(const Duration(milliseconds: 250));
        final op500 = tester.widget<Opacity>(opacityFinder).opacity;

        await tester.pump(const Duration(milliseconds: 250));
        final op750 = tester.widget<Opacity>(opacityFinder).opacity;

        await tester.pump(const Duration(milliseconds: 250));
        final op1000 = tester.widget<Opacity>(opacityFinder).opacity;

        await tester.pump(const Duration(milliseconds: 500));
        final op1500 = tester.widget<Opacity>(opacityFinder).opacity;

        await tester.pump(const Duration(milliseconds: 500));
        final op2000 = tester.widget<Opacity>(opacityFinder).opacity;

        debugPrint('Empirical finding [Pulsating REC Badge Opacity Profile]:');
        debugPrint('  t=0ms: opacity=$op0');
        debugPrint('  t=250ms: opacity=$op250');
        debugPrint('  t=500ms: opacity=$op500');
        debugPrint('  t=750ms: opacity=$op750');
        debugPrint('  t=1000ms: opacity=$op1000');
        debugPrint('  t=1500ms: opacity=$op1500');
        debugPrint('  t=2000ms: opacity=$op2000');

        // Assert bound limits [0.6, 1.0]
        final allOpacities = [op0, op250, op500, op750, op1000, op1500, op2000];
        for (final op in allOpacities) {
          expect(op, greaterThanOrEqualTo(0.5999));
          expect(op, lessThanOrEqualTo(1.0001));
        }

        // Verify opacity is actively oscillating (min < max with significant delta)
        final minOp = allOpacities.reduce((a, b) => a < b ? a : b);
        final maxOp = allOpacities.reduce((a, b) => a > b ? a : b);
        final modulationRange = maxOp - minOp;

        expect(minOp, closeTo(0.6, 0.05));
        expect(maxOp, closeTo(1.0, 0.05));
        expect(modulationRange, greaterThan(0.35), reason: 'Opacity must oscillate across at least 0.35 units');

        // Stop recording to avoid active timer leaks
        controllerA.toggleRecording();
        await tester.pump();

        // Badge must disappear when recording is stopped
        expect(find.byKey(const Key('recording_timer_badge')), findsNothing);
      });
    });
  });
}
