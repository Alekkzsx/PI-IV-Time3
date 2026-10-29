// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/chat_message.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/emoji_reaction.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/hand_raise_item.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/media_state_update.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/meeting_room.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/participant.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/recording_state.dart';
import 'package:pi_iv_time3/features/video_call/domain/repositories/video_call_repository.dart';
import 'package:pi_iv_time3/features/video_call/presentation/controllers/video_call_controller.dart';
import 'package:pi_iv_time3/features/video_call/presentation/controllers/video_call_lobby_controller.dart';
import 'package:pi_iv_time3/features/video_call/presentation/pages/video_call_lobby_page.dart';
import 'package:pi_iv_time3/features/video_call/presentation/pages/video_call_room_page.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/audio_level_meter.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/dynamic_video_grid.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/floating_reactions_overlay.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/participant_video_tile.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/raised_hands_banner.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/screen_share_view.dart';

/// Implementação de teste para VideoCallRepository da camada de domínio.
class FakeDomainVideoCallRepository implements VideoCallRepository {
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
    _leftCtrl.add(peerId);
  }

  @override
  Future<void> sendChatMessage(String roomId, ChatMessage message) async {
    _chatCtrl.add(message);
  }

  @override
  Future<void> sendEmojiReaction(String roomId, EmojiReaction reaction) async {
    _reactionCtrl.add(reaction);
  }

  @override
  Future<void> toggleHandRaise(
    String roomId,
    String peerId,
    bool isRaised,
  ) async {
    _handRaiseCtrl.add(
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
    _mediaCtrl.add(
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
    _recordingCtrl.add(state);
  }

  void emitParticipantJoined(Participant p) => _joinedCtrl.add(p);
  void emitHandRaise(HandRaiseItem item) => _handRaiseCtrl.add(item);
  void emitMediaState(MediaStateUpdate update) => _mediaCtrl.add(update);
  void emitRecordingState(RecordingState state) => _recordingCtrl.add(state);

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

void _closeOwnedSession(AcademicBridgeService bridge, String code) {
  final session = bridge.getSession(code);
  if (!session.isOpen) return;
  final role = session.openedByRole;
  final identity = session.openedByIdentity;
  if (role == null || identity == null) {
    throw StateError('Sessão aberta sem identidade responsável.');
  }
  AppUserSession.instance.signIn(identity: identity, profile: role);
  bridge.closeSession(code);
  AppUserSession.instance.signOut();
}

void main() {
  group('VideoCallLobbyController Tests', () {
    late VideoCallLobbyController controller;
    late FakeDomainVideoCallRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeDomainVideoCallRepository();
      controller = VideoCallLobbyController(repository: fakeRepo);
    });

    tearDown(() async {
      await fakeRepo.dispose();
    });

    test('Initial state values and setters', () {
      expect(controller.name, isEmpty);
      expect(controller.ra, isEmpty);
      expect(controller.roomCode, 'SALA-101');
      expect(controller.isAudioMuted, isFalse);
      expect(controller.isVideoOff, isFalse);
      expect(controller.audioLevel, 0.05);

      controller.setName('Alex Sousa');
      expect(controller.name, 'Alex Sousa');

      controller.setRa('24802449');
      expect(controller.ra, '24802449');

      controller.setRoomCode('SALA-202');
      expect(controller.roomCode, 'SALA-202');

      controller.toggleAudio();
      expect(controller.isAudioMuted, isTrue);
      expect(controller.audioLevel, 0.0);

      controller.toggleAudio();
      expect(controller.isAudioMuted, isFalse);
      expect(controller.audioLevel, 0.05);

      controller.toggleVideo();
      expect(controller.isVideoOff, isTrue);

      controller.setAudioLevel(0.4);
      expect(controller.audioLevel, 0.4);
    });

    test('Input validation partition rules', () {
      expect(controller.validateName(null), 'Informe seu nome');
      expect(controller.validateName('   '), 'Informe seu nome');
      expect(controller.validateName('Alex'), isNull);

      expect(controller.validateRa(null), 'Informe seu RA');
      expect(controller.validateRa('   '), 'Informe seu RA');
      expect(controller.validateRa('123'), 'RA inválido');
      expect(controller.validateRa('24802449'), isNull);

      expect(controller.validateRoomCode(null), 'Informe o código da sala');
      expect(controller.validateRoomCode(''), 'Informe o código da sala');
      expect(controller.validateRoomCode('AB'), 'Código da sala inválido');
      expect(
        controller.validateRoomCode('SALA_INVALID@'),
        'Código da sala inválido',
      );
      expect(controller.validateRoomCode('SALA-101'), isNull);
    });

    test('createCallController provisions functional VideoCallController', () {
      final callCtrl = controller.createCallController(
        name: ' Alex Sousa ',
        ra: ' 24802449 ',
        roomCode: ' sala-101 ',
      );

      expect(callCtrl.room.code, 'SALA-101');
      expect(callCtrl.localParticipant.name, 'Alex Sousa');
      expect(callCtrl.localParticipant.ra, '24802449');
      expect(callCtrl.allParticipants.length, 1);
      callCtrl.dispose();
    });
  });

  group('VideoCallController Invariant & State Tests', () {
    late FakeDomainVideoCallRepository fakeRepo;
    late MeetingRoom room;
    late Participant localUser;
    late VideoCallController controller;

    setUp(() {
      fakeRepo = FakeDomainVideoCallRepository();
      room = MeetingRoom(id: 'SALA-101', code: 'SALA-101', title: 'Sala 101');
      localUser = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
        isLocal: true,
      );
      controller = VideoCallController(
        repository: fakeRepo,
        room: room,
        localParticipant: localUser,
      );
    });

    tearDown(() async {
      controller.dispose();
      await fakeRepo.dispose();
    });

    test(
      'Zero Bots: Alone has strictly 1 participant, registering peer creates 2',
      () {
        expect(controller.allParticipants.length, 1);
        expect(controller.remoteParticipants, isEmpty);

        final peer2 = Participant(
          id: 'peer_2',
          name: 'Colega Univesp',
          ra: '25015323',
        );
        controller.registerRemoteParticipant(peer2);

        expect(controller.allParticipants.length, 2);
        expect(controller.remoteParticipants.length, 1);
      },
    );

    test('Media toggles mutate local participant and update repository', () {
      controller.toggleAudio();
      expect(controller.localParticipant.isAudioMuted, isTrue);

      controller.toggleVideo();
      expect(controller.localParticipant.isVideoOff, isTrue);

      controller.toggleScreenShare();
      expect(controller.isScreenSharing, isTrue);
      expect(controller.localParticipant.isScreenSharing, isTrue);
    });

    test('Active speaker detection triggers with RMS > 0.15', () {
      controller.setAudioLevel(0.20);
      expect(controller.localParticipant.isSpeaking, isTrue);

      // Dropping below 0.15 enters hysteresis
      controller.setAudioLevel(0.05);
      expect(controller.localParticipant.isSpeaking, isTrue);
    });

    test(
      'Chat, Reactions, Hand Raising and Drawers mutate state correctly',
      () {
        controller.sendChatMessage('  Olá a todos!  ');
        expect(controller.chatMessages.length, 1);
        expect(controller.chatMessages.first.text, 'Olá a todos!');

        controller.sendReaction('❤️');
        expect(controller.activeReactions.length, 1);
        expect(controller.activeReactions.first.emoji, '❤️');

        controller.toggleHandRaise();
        expect(controller.localParticipant.isHandRaised, isTrue);
        expect(controller.raisedHandsQueue.length, 1);

        controller.toggleHandRaise();
        expect(controller.localParticipant.isHandRaised, isFalse);
        expect(controller.raisedHandsQueue, isEmpty);

        expect(controller.isChatDrawerOpen, isFalse);
        controller.toggleChatDrawer();
        expect(controller.isChatDrawerOpen, isTrue);
        expect(controller.isParticipantsDrawerOpen, isFalse);

        controller.toggleParticipantsDrawer();
        expect(controller.isParticipantsDrawerOpen, isTrue);
        expect(controller.isChatDrawerOpen, isFalse);
      },
    );

    test('Recording lifecycle generates SessionExport ledger', () {
      expect(controller.recordingState.isRecording, isFalse);
      expect(controller.lastSessionExport, isNull);

      controller.toggleRecording();
      expect(controller.recordingState.isRecording, isTrue);

      controller.toggleRecording();
      expect(controller.recordingState.isRecording, isFalse);
      expect(controller.lastSessionExport, isNotNull);
      expect(controller.lastSessionExport!.roomCode, 'SALA-101');
      expect(
        controller.lastSessionExport!.attendeeNames,
        contains('Alex Sousa'),
      );
    });

    test(
      'Student cannot record or share screen in an academic class',
      () async {
        final studentRepository = FakeDomainVideoCallRepository();
        final studentController = VideoCallController(
          repository: studentRepository,
          room: MeetingRoom(id: 'APS-II', code: 'APS-II', title: 'APS-II'),
          localParticipant: Participant(
            id: 'student_1',
            name: 'Aluno',
            ra: '2024.1.00892',
            role: 'aluno',
            isLocal: true,
          ),
        );

        expect(studentController.canManageMeeting, isFalse);
        studentController.toggleRecording();
        studentController.toggleScreenShare();
        expect(studentController.recordingState.isRecording, isFalse);
        expect(studentController.isLocalScreenSharing, isFalse);

        studentController.dispose();
        await studentRepository.dispose();
      },
    );

    test(
      'Remote participant raising hand updates remoteParticipants.first.isHandRaised',
      () {
        final remotePeer = Participant(
          id: 'peer_remote',
          name: 'Maria Silva',
          ra: '24809999',
        );
        controller.registerRemoteParticipant(remotePeer);
        expect(controller.remoteParticipants.first.isHandRaised, isFalse);

        fakeRepo.emitHandRaise(
          HandRaiseItem(
            peerId: 'peer_remote',
            name: 'Maria Silva',
            ra: '24809999',
            raisedAt: DateTime.now(),
          ),
        );
        expect(controller.remoteParticipants.first.isHandRaised, isTrue);
        expect(controller.raisedHandsQueue.length, 1);

        // Lower hand
        fakeRepo.emitHandRaise(
          HandRaiseItem(
            peerId: 'peer_remote',
            name: 'Maria Silva',
            ra: '24809999',
            raisedAt: DateTime.now(),
          ),
        );
        expect(controller.remoteParticipants.first.isHandRaised, isFalse);
        expect(controller.raisedHandsQueue, isEmpty);
      },
    );

    test(
      'Remote participant starts recording and increments remote elapsed duration',
      () {
        expect(controller.recordingState.isRecording, isFalse);

        fakeRepo.emitRecordingState(
          RecordingState(
            isRecording: true,
            startedAt: DateTime.now(),
            elapsedDuration: Duration.zero,
            startedByPeerId: 'peer_remote',
            startedByName: 'Maria Silva',
          ),
        );
        expect(controller.recordingState.isRecording, isTrue);
        expect(controller.recordingState.startedByName, 'Maria Silva');

        // Stop recording
        fakeRepo.emitRecordingState(
          RecordingState(
            isRecording: false,
            startedAt: DateTime.now().subtract(const Duration(seconds: 10)),
            elapsedDuration: const Duration(seconds: 10),
            startedByPeerId: 'peer_remote',
          ),
        );
        expect(controller.recordingState.isRecording, isFalse);
        expect(controller.lastSessionExport, isNotNull);
      },
    );

    test(
      'Muted remote peer with incoming audioLevel does not become active speaker',
      () {
        final remotePeer = Participant(
          id: 'peer_muted',
          name: 'Carlos',
          ra: '24807777',
          isAudioMuted: true,
        );
        controller.registerRemoteParticipant(remotePeer);
        expect(controller.remoteParticipants.first.isAudioMuted, isTrue);

        // Send audioLevel update without isAudioMuted field
        fakeRepo.emitMediaState(
          MediaStateUpdate(
            peerId: 'peer_muted',
            audioLevel: 0.8,
            timestamp: DateTime.now(),
          ),
        );
        final updated = controller.remoteParticipants.firstWhere(
          (p) => p.id == 'peer_muted',
        );
        expect(updated.isAudioMuted, isTrue);
        expect(updated.isSpeaking, isFalse);
      },
    );

    test(
      'Total reactions count is accumulated and preserved in SessionExport',
      () {
        controller.sendReaction('❤️');
        controller.sendReaction('👍');
        fakeRepo.sendEmojiReaction(
          'SALA-101',
          EmojiReaction(
            id: 'rx_1',
            peerId: 'peer_remote',
            peerName: 'Maria',
            emoji: '🎉',
            timestamp: DateTime.now(),
          ),
        );
        expect(controller.totalReactionsCount, 3);

        controller.toggleRecording();
        controller.toggleRecording();
        expect(controller.lastSessionExport!.reactionCount, 3);
      },
    );
  });

  group('Presentation Widgets Tests', () {
    testWidgets('AudioLevelMeter renders correct colors based on threshold', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AudioLevelMeter(level: 0.10))),
      );
      expect(find.byKey(const Key('audio_level_meter')), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AudioLevelMeter(level: 0.50))),
      );
      expect(find.byKey(const Key('audio_level_meter')), findsOneWidget);
    });

    testWidgets(
      'ParticipantVideoTile renders camera feed and avatar fallback',
      (tester) async {
        final participantVideoOn = Participant(
          id: 'peer_1',
          name: 'Alex Sousa',
          ra: '24802449',
          isVideoOff: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ParticipantVideoTile(participant: participantVideoOn),
            ),
          ),
        );

        expect(
          find.byKey(const Key('participant_tile_peer_1')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('camera_feed_peer_1')), findsOneWidget);
        expect(find.text('Alex Sousa (24802449)'), findsOneWidget);

        final participantVideoOff = participantVideoOn.copyWith(
          isVideoOff: true,
          isHandRaised: true,
          isSpeaking: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ParticipantVideoTile(participant: participantVideoOff),
            ),
          ),
        );

        expect(find.byKey(const Key('avatar_peer_1')), findsOneWidget);
        expect(
          find.byKey(const Key('hand_raised_icon_peer_1')),
          findsOneWidget,
        );
      },
    );

    testWidgets('DynamicVideoGrid adapts to count and screen share mode', (
      tester,
    ) async {
      final p1 = Participant(id: 'p1', name: 'User 1', ra: '11111');
      final p2 = Participant(id: 'p2', name: 'User 2', ra: '22222');

      // Empty
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DynamicVideoGrid(participants: [])),
        ),
      );
      expect(find.text('Nenhum participante conectado'), findsOneWidget);

      // N = 1
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DynamicVideoGrid(participants: [p1])),
        ),
      );
      expect(find.byType(ParticipantVideoTile), findsOneWidget);

      // N = 2
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DynamicVideoGrid(participants: [p1, p2])),
        ),
      );
      expect(find.byType(ParticipantVideoTile), findsNWidgets(2));

      // Screen Share
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicVideoGrid(
              participants: [p1, p2],
              isScreenSharing: true,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('screen_share_view')), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('ScreenShareView renders title and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ScreenShareView(presenterName: 'Prof. Alex')),
        ),
      );
      expect(find.byKey(const Key('screen_share_view')), findsOneWidget);
      expect(find.text('Apresentação de Tela Ativa'), findsOneWidget);
      expect(find.text('Apresentado por Prof. Alex'), findsOneWidget);
    });

    testWidgets('FloatingReactionsOverlay renders emoji texts', (tester) async {
      final reaction = EmojiReaction(
        id: 'r1',
        peerId: 'p1',
        emoji: '🎉',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FloatingReactionsOverlay(reactions: [reaction])),
        ),
      );
      expect(find.byKey(const Key('reaction_item_r1')), findsOneWidget);
      expect(find.text('🎉'), findsOneWidget);
    });

    testWidgets('RaisedHandsBanner renders queue chips', (tester) async {
      final item = HandRaiseItem(
        peerId: 'p1',
        name: 'Aluno Aluno',
        ra: '12345',
        raisedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RaisedHandsBanner(queue: [item])),
        ),
      );
      expect(find.byKey(const Key('raised_hands_banner')), findsOneWidget);
      expect(find.byKey(const Key('queue_item_p1')), findsOneWidget);
      expect(find.text('Aluno Aluno (12345)'), findsOneWidget);
    });
  });

  group('Presentation Pages Tests', () {
    testWidgets(
      'VideoCallLobbyPage renders form, preview, and submits onJoin',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final bridge = AcademicBridgeService.instance;
        AppUserSession.instance.signIn(
          identity: 'DOC-88410',
          profile: 'docente',
        );
        _closeOwnedSession(bridge, 'APS-II');
        bridge.openSession(
          rawCourseCode: 'APS-II',
          openedByRole: 'docente',
          openedByName: 'Profa. Dra. Helena Bittencourt',
          openedByIdentity: 'DOC-88410',
        );
        AppUserSession.instance.signIn(
          identity: '2024.1.00892',
          profile: 'aluno',
        );
        addTearDown(AppUserSession.instance.signOut);
        addTearDown(() => _closeOwnedSession(bridge, 'APS-II'));

        String? submittedName;
        String? submittedRa;
        String? submittedRoom;

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: '/video-call',
            onGenerateInitialRoutes: (initialRoute) => [
              MaterialPageRoute<void>(
                settings: RouteSettings(name: initialRoute),
                builder: (_) => VideoCallLobbyPage(
                  initialRoomCode: 'APS-II',
                  onJoin: (name, ra, room, muted, videoOff) {
                    submittedName = name;
                    submittedRa = ra;
                    submittedRoom = room;
                  },
                ),
              ),
            ],
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const SizedBox.shrink(),
            ),
          ),
        );

        expect(find.byKey(const Key('lobby_camera_preview')), findsOneWidget);
        expect(find.byKey(const Key('lobby_name_field')), findsOneWidget);
        expect(find.byKey(const Key('lobby_ra_field')), findsOneWidget);
        expect(find.byKey(const Key('lobby_room_code_field')), findsOneWidget);

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('lobby_join_button')));
        await tester.pumpAndSettle();

        expect(submittedName, '2024.1.00892');
        expect(submittedRa, '2024.1.00892');
        expect(submittedRoom, 'APS-II');
      },
    );

    testWidgets(
      'VideoCallRoomPage renders grid, toolbar, and handles drawers',
      (tester) async {
        final fakeRepo = FakeDomainVideoCallRepository();
        final room = MeetingRoom(
          id: 'SALA-101',
          code: 'SALA-101',
          title: 'Sala 101',
        );
        final localUser = Participant(
          id: 'peer_local',
          name: 'Alex Sousa',
          ra: '24802449',
          isLocal: true,
        );
        final controller = VideoCallController(
          repository: fakeRepo,
          room: room,
          localParticipant: localUser,
        );

        await tester.pumpWidget(
          MaterialApp(home: VideoCallRoomPage(controller: controller)),
        );

        expect(
          find.byKey(const Key('meeting_controls_toolbar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('participant_tile_peer_local')),
          findsOneWidget,
        );
        expect(find.text('Sala 101 (SALA-101)'), findsOneWidget);

        // Open Chat Drawer
        await tester.tap(find.byKey(const Key('toolbar_chat_button')));
        await tester.pump();
        expect(find.byKey(const Key('in_call_chat_drawer')), findsOneWidget);

        // Close Chat Drawer
        await tester.tap(find.byKey(const Key('close_chat_drawer_button')));
        await tester.pump();
        expect(find.byKey(const Key('in_call_chat_drawer')), findsNothing);

        // Open Participants Drawer
        await tester.tap(find.byKey(const Key('toolbar_participants_button')));
        await tester.pump();
        expect(find.byKey(const Key('participants_drawer')), findsOneWidget);

        // Close Participants Drawer
        await tester.tap(
          find.byKey(const Key('close_participants_drawer_button')),
        );
        await tester.pump();
        expect(find.byKey(const Key('participants_drawer')), findsNothing);

        // Toggle recording shows banner and REC timer badge
        controller.toggleRecording();
        await tester.pump();
        expect(
          find.byKey(const Key('institutional_recording_banner')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('recording_timer_badge')), findsOneWidget);

        controller.dispose();
        await fakeRepo.dispose();
      },
    );
  });
}
