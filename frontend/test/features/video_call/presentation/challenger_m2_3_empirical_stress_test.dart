// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/data/channel/in_memory_signaling_bus.dart';
import 'package:pi_iv_time3/features/video_call/data/datasources/video_call_signaling_datasource.dart';
import 'package:pi_iv_time3/features/video_call/data/models/participant_model.dart';
import 'package:pi_iv_time3/features/video_call/data/repositories/video_call_repository_impl.dart';
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
import 'package:pi_iv_time3/features/video_call/presentation/widgets/dynamic_video_grid.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/participant_video_tile.dart';

/// Test repository interconnecting two peers synchronously in memory
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
  group('Challenger M2-3: Empirical Verification of Remediated Hand Raise & Recording Timer', () {
    // =========================================================================
    // SECTION 1: DUAL-PEER HAND RAISE SYNCHRONIZATION & TILE BADGE EMPIRICAL TEST
    // =========================================================================
    group('1. Dual-Peer Hand Raise Synchronization & ParticipantVideoTile Badge Display', () {
      late LinkedDomainVideoCallRepository repoA;
      late LinkedDomainVideoCallRepository repoB;
      late VideoCallController controllerA;
      late VideoCallController controllerB;
      final room = MeetingRoom(id: 'CHALLENGER-M2-3', code: 'CHALLENGER-M2-3', title: 'Sala M2-3');

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

        controllerA.registerRemoteParticipant(pB);
        controllerB.registerRemoteParticipant(pA);
      });

      tearDown(() {
        controllerA.dispose();
        controllerB.dispose();
        repoA.dispose();
        repoB.dispose();
      });

      test('Step 1.1: Peer A raises hand -> Peer B remoteParticipants.first.isHandRaised is TRUE', () {
        // Initial state
        expect(controllerA.localParticipant.isHandRaised, isFalse);
        expect(controllerB.remoteParticipants.first.isHandRaised, isFalse);

        // Peer A raises hand
        controllerA.toggleHandRaise();

        // Local state on Peer A
        expect(controllerA.localParticipant.isHandRaised, isTrue);

        // Remote state on Peer B
        final remoteAOnB = controllerB.remoteParticipants.firstWhere((p) => p.id == 'peer_a');
        expect(remoteAOnB.isHandRaised, isTrue,
            reason: 'Peer B remote participant isHandRaised MUST be true after Peer A raises hand');
        expect(controllerB.raisedHandsQueue.length, 1);
        expect(controllerB.raisedHandsQueue.first.peerId, 'peer_a');
      });

      testWidgets('Step 1.2: ParticipantVideoTile renders ✋ badge when isHandRaised == true', (tester) async {
        // Peer A raises hand
        controllerA.toggleHandRaise();

        final remoteAOnB = controllerB.remoteParticipants.firstWhere((p) => p.id == 'peer_a');
        expect(remoteAOnB.isHandRaised, isTrue);

        // Render ParticipantVideoTile for Peer A in Peer B's UI
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 240,
                child: ParticipantVideoTile(participant: remoteAOnB),
              ),
            ),
          ),
        );
        await tester.pump();

        // Check for hand raised badge
        final badgeKeyFinder = find.byKey(const Key('hand_raised_icon_peer_a'));
        expect(badgeKeyFinder, findsOneWidget,
            reason: 'ParticipantVideoTile must render Container with key hand_raised_icon_peer_a');

        final handEmojiFinder = find.descendant(
          of: badgeKeyFinder,
          matching: find.text('✋'),
        );
        expect(handEmojiFinder, findsOneWidget,
            reason: 'ParticipantVideoTile must render verbatim ✋ emoji text badge');
      });

      test('Step 2.1: Peer A lowers hand -> Peer B remoteParticipants.first.isHandRaised is FALSE', () {
        // Peer A raises hand first
        controllerA.toggleHandRaise();
        expect(controllerB.remoteParticipants.first.isHandRaised, isTrue);

        // Peer A lowers hand
        controllerA.toggleHandRaise();

        // Local state on Peer A
        expect(controllerA.localParticipant.isHandRaised, isFalse);

        // Remote state on Peer B
        final remoteAOnB = controllerB.remoteParticipants.firstWhere((p) => p.id == 'peer_a');
        expect(remoteAOnB.isHandRaised, isFalse,
            reason: 'Peer B remote participant isHandRaised MUST be false after Peer A lowers hand');
        expect(controllerB.raisedHandsQueue, isEmpty);
      });

      testWidgets('Step 2.2: ParticipantVideoTile removes ✋ badge when isHandRaised == false', (tester) async {
        // Peer A raises hand
        controllerA.toggleHandRaise();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 240,
                child: ParticipantVideoTile(
                  participant: controllerB.remoteParticipants.firstWhere((p) => p.id == 'peer_a'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('hand_raised_icon_peer_a')), findsOneWidget);

        // Peer A lowers hand
        controllerA.toggleHandRaise();

        // Re-render tile with updated participant entity
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 240,
                child: ParticipantVideoTile(
                  participant: controllerB.remoteParticipants.firstWhere((p) => p.id == 'peer_a'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('hand_raised_icon_peer_a')), findsNothing,
            reason: 'ParticipantVideoTile must remove ✋ badge once hand is lowered');
        expect(find.text('✋'), findsNothing);
      });

      testWidgets('Step 2.3: End-to-end Room Page test: hand raise & lower in full VideoCallRoomPage', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: VideoCallRoomPage(controller: controllerB),
          ),
        );
        await tester.pump();

        // Initially no hand raise icon and no raised hands banner
        expect(find.byKey(const Key('hand_raised_icon_peer_a')), findsNothing);
        expect(find.byKey(const Key('raised_hands_banner')), findsNothing);

        // Peer A raises hand
        controllerA.toggleHandRaise();
        await tester.pump();

        // Verify badge appears in video grid and queue banner appears
        expect(find.byKey(const Key('hand_raised_icon_peer_a')), findsOneWidget);
        expect(find.byKey(const Key('raised_hands_banner')), findsOneWidget);
        expect(find.byKey(const Key('queue_item_peer_a')), findsOneWidget);

        // Peer A lowers hand
        controllerA.toggleHandRaise();
        await tester.pump();

        // Verify badge disappears and banner is dismissed
        expect(find.byKey(const Key('hand_raised_icon_peer_a')), findsNothing);
        expect(find.byKey(const Key('raised_hands_banner')), findsNothing);
      });
    });

    // =========================================================================
    // SECTION 2: REMOTE RECORDING TIMER ELAPSED DURATION INCREMENTING
    // =========================================================================
    group('2. Remote Recording Timer Elapsed Duration Synchronization', () {
      late LinkedDomainVideoCallRepository repoA;
      late LinkedDomainVideoCallRepository repoB;
      late VideoCallController controllerA;
      late VideoCallController controllerB;
      final room = MeetingRoom(id: 'CHALLENGER-REC', code: 'CHALLENGER-REC', title: 'Sala REC');

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

        controllerA.registerRemoteParticipant(pB);
        controllerB.registerRemoteParticipant(pA);
      });

      tearDown(() {
        controllerA.dispose();
        controllerB.dispose();
        repoA.dispose();
        repoB.dispose();
      });

      testWidgets('Step 3.1: Remote peer increments elapsedDuration second by second via internal timer', (tester) async {
        expect(controllerA.recordingState.isRecording, isFalse);
        expect(controllerB.recordingState.isRecording, isFalse);
        expect(controllerB.recordingState.elapsedDuration, Duration.zero);

        // Peer A starts recording
        controllerA.toggleRecording();
        await tester.pump();

        expect(controllerA.recordingState.isRecording, isTrue);
        expect(controllerB.recordingState.isRecording, isTrue);
        expect(controllerB.recordingState.startedByPeerId, 'peer_a');

        controllerB.addListener(() {
          debugPrint('LISTENER controllerB: isRecording=${controllerB.recordingState.isRecording}, elapsed=${controllerB.recordingState.elapsedDuration.inSeconds}');
        });

        // Advance 1 second
        await tester.pump(const Duration(seconds: 1));
        debugPrint('DBG: cA elapsed=${controllerA.recordingState.elapsedDuration.inSeconds}, cB elapsed=${controllerB.recordingState.elapsedDuration.inSeconds}');
        expect(controllerB.recordingState.elapsedDuration.inSeconds, equals(1),
            reason: 'Remote peer elapsedDuration must be 1s after 1s tick');

        // Advance 2nd second
        await tester.pump(const Duration(seconds: 1));
        expect(controllerB.recordingState.elapsedDuration.inSeconds, equals(2),
            reason: 'Remote peer elapsedDuration must be 2s after 2s tick');

        // Advance 3rd second
        await tester.pump(const Duration(seconds: 1));
        expect(controllerB.recordingState.elapsedDuration.inSeconds, equals(3),
            reason: 'Remote peer elapsedDuration must be 3s after 3s tick');

        // Peer A stops recording
        controllerA.toggleRecording();
        await tester.pump();

        expect(controllerB.recordingState.isRecording, isFalse);
        final finalDuration = controllerB.recordingState.elapsedDuration.inSeconds;

        // Advance further time: verify remote timer is cancelled and elapsedDuration does NOT advance further
        await tester.pump(const Duration(seconds: 2));
        expect(controllerB.recordingState.elapsedDuration.inSeconds, equals(finalDuration),
            reason: 'Cancelled remote recording timer must not continue incrementing elapsedDuration');

        // Verify SessionExport generated on remote peer B
        expect(controllerB.lastSessionExport, isNotNull);
        expect(controllerB.lastSessionExport!.totalDuration.inSeconds, equals(3));
      });

      testWidgets('Step 3.2: Remote VideoCallRoomPage displays pulsating REC badge with advancing time', (tester) async {
        controllerA.toggleRecording();

        await tester.pumpWidget(
          MaterialApp(
            home: VideoCallRoomPage(controller: controllerB),
          ),
        );
        await tester.pump();

        // Check initial display 00:00:00
        expect(find.byKey(const Key('recording_timer_badge')), findsOneWidget);
        expect(find.textContaining('● REC 00:00:00'), findsOneWidget);

        // Advance 2 seconds
        await tester.pump(const Duration(seconds: 2));
        expect(find.textContaining('● REC 00:00:02'), findsOneWidget,
            reason: 'VideoCallRoomPage on remote peer renders advancing elapsedDuration in REC badge');

        // Stop recording
        controllerA.toggleRecording();
        await tester.pump();

        // REC badge should disappear when recording is stopped
        expect(find.byKey(const Key('recording_timer_badge')), findsNothing);
      });
    });

    // =========================================================================
    // SECTION 3: FULL STACK REAL P2P SIGNALING BUS VERIFICATION
    // =========================================================================
    group('3. Full-Stack InMemorySignalingBus Multi-Peer Stress Tests', () {
      late InMemorySignalingBus bus;
      late VideoCallSignalingDataSource dsA;
      late VideoCallSignalingDataSource dsB;
      late VideoCallRepositoryImpl repoA;
      late VideoCallRepositoryImpl repoB;
      late VideoCallController controllerA;
      late VideoCallController controllerB;
      final room = MeetingRoom(id: 'REAL-P2P-ROOM', code: 'REAL-P2P-ROOM', title: 'Sala Real P2P');

      setUp(() async {
        bus = InMemorySignalingBus();
        bus.reset();

        dsA = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        dsB = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        repoA = VideoCallRepositoryImpl(dataSource: dsA);
        repoB = VideoCallRepositoryImpl(dataSource: dsB);

        final pA = Participant(id: 'peer_alex', name: 'Alex Sousa', ra: '24802449');
        final pB = Participant(id: 'peer_beatriz', name: 'Beatriz Lima', ra: '24801122');

        await repoA.joinRoom(room, pA);
        await repoB.joinRoom(room, pB);

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

        // Ensure cross-registration
        controllerA.registerRemoteParticipant(pB);
        controllerB.registerRemoteParticipant(pA);
      });

      tearDown(() {
        controllerA.dispose();
        controllerB.dispose();
        repoA.dispose();
        repoB.dispose();
        bus.reset();
      });

      test('Real P2P Bus: Peer A raises hand -> serialized over bus -> Peer B updates state', () async {
        expect(controllerB.remoteParticipants.first.isHandRaised, isFalse);

        controllerA.toggleHandRaise();
        // Give time for bus dispatch
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final peerAInB = controllerB.remoteParticipants.firstWhere((p) => p.id == 'peer_alex');
        expect(peerAInB.isHandRaised, isTrue,
            reason: 'Hand raise propagated across real P2P signaling channel');

        // Lower hand
        controllerA.toggleHandRaise();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final peerAInBLowered = controllerB.remoteParticipants.firstWhere((p) => p.id == 'peer_alex');
        expect(peerAInBLowered.isHandRaised, isFalse,
            reason: 'Hand lower propagated across real P2P signaling channel');
      });

      testWidgets('Real P2P Bus: Peer A starts recording -> Peer B increments timer', (tester) async {
        controllerA.toggleRecording();
        await tester.pump(const Duration(milliseconds: 50));

        expect(controllerB.recordingState.isRecording, isTrue);

        // Advance 2 seconds
        await tester.pump(const Duration(seconds: 2));
        expect(controllerB.recordingState.elapsedDuration.inSeconds, greaterThanOrEqualTo(2));

        controllerA.toggleRecording();
        await tester.pump(const Duration(milliseconds: 50));
        expect(controllerB.recordingState.isRecording, isFalse);
      });
    });

    // =========================================================================
    // SECTION 4: ADVERSARIAL STRESS & EDGE CASES
    // =========================================================================
    group('4. Adversarial Stress & Edge Cases', () {
      late LinkedDomainVideoCallRepository repoA;
      late LinkedDomainVideoCallRepository repoB;
      late VideoCallController controllerA;
      late VideoCallController controllerB;
      final room = MeetingRoom(id: 'STRESS-M2-3', code: 'STRESS-M2-3', title: 'Sala Stress');

      setUp(() {
        repoA = LinkedDomainVideoCallRepository();
        repoB = LinkedDomainVideoCallRepository();
        repoA.peerRepo = repoB;
        repoB.peerRepo = repoA;

        final pA = Participant(id: 'peer_a', name: 'Alex Sousa', ra: '24802449');
        final pB = Participant(id: 'peer_b', name: 'Beatriz Lima', ra: '24801122');

        controllerA = VideoCallController(repository: repoA, room: room, localParticipant: pA);
        controllerB = VideoCallController(repository: repoB, room: room, localParticipant: pB);

        controllerA.registerRemoteParticipant(pB);
        controllerB.registerRemoteParticipant(pA);
      });

      tearDown(() {
        controllerA.dispose();
        controllerB.dispose();
        repoA.dispose();
        repoB.dispose();
      });

      test('Adversarial 1: Rapid 10x toggle of hand raise leaves consistent state on both peers', () {
        // Toggle 10 times (even count -> final state must be lowered / false)
        for (int i = 0; i < 10; i++) {
          controllerA.toggleHandRaise();
        }

        expect(controllerA.localParticipant.isHandRaised, isFalse);
        expect(controllerB.remoteParticipants.first.isHandRaised, isFalse);
        expect(controllerA.raisedHandsQueue, isEmpty);
        expect(controllerB.raisedHandsQueue, isEmpty);

        // Toggle 1 more time (11th time -> final state must be raised / true)
        controllerA.toggleHandRaise();
        expect(controllerA.localParticipant.isHandRaised, isTrue);
        expect(controllerB.remoteParticipants.first.isHandRaised, isTrue);
        expect(controllerA.raisedHandsQueue.length, 1);
        expect(controllerB.raisedHandsQueue.length, 1);
      });

      testWidgets('Adversarial 2: Screen Sharing mode maintains ✋ badge on filmstrip tile', (tester) async {
        // Peer A raises hand
        controllerA.toggleHandRaise();

        final pAInB = controllerB.remoteParticipants.firstWhere((p) => p.id == 'peer_a');
        expect(pAInB.isHandRaised, isTrue);

        // Peer B renders DynamicVideoGrid in Screen Sharing mode
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DynamicVideoGrid(
                participants: [controllerB.localParticipant, pAInB],
                isScreenSharing: true,
              ),
            ),
          ),
        );
        await tester.pump();

        // Both screen share view and horizontal filmstrip tile for peer A are present
        expect(find.byKey(const Key('screen_share_view')), findsOneWidget);
        expect(find.byKey(const Key('hand_raised_icon_peer_a')), findsOneWidget);
        expect(find.text('✋'), findsOneWidget);
      });

      testWidgets('Adversarial 3: Recording start -> stop -> restart does not leak timers or corrupt duration', (tester) async {
        // Cycle 1: Start and record 2 seconds
        controllerA.toggleRecording();
        await tester.pump(const Duration(seconds: 2));
        expect(controllerB.recordingState.elapsedDuration.inSeconds, equals(2));

        // Stop Cycle 1
        controllerA.toggleRecording();
        await tester.pump();
        expect(controllerB.recordingState.isRecording, isFalse);
        expect(controllerB.lastSessionExport!.totalDuration.inSeconds, equals(2));

        // Cycle 2: Restart recording
        controllerA.toggleRecording();
        await tester.pump();
        expect(controllerB.recordingState.isRecording, isTrue);
        expect(controllerB.recordingState.elapsedDuration, Duration.zero);

        // Record another 3 seconds
        await tester.pump(const Duration(seconds: 3));
        expect(controllerB.recordingState.elapsedDuration.inSeconds, equals(3));

        // Stop Cycle 2
        controllerA.toggleRecording();
        await tester.pump();
        expect(controllerB.recordingState.isRecording, isFalse);
        expect(controllerB.lastSessionExport!.totalDuration.inSeconds, equals(3));
      });
    });
  });
}
