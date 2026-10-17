// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/data/channel/in_memory_signaling_bus.dart';
import 'package:pi_iv_time3/features/video_call/data/datasources/video_call_signaling_datasource.dart';
import 'package:pi_iv_time3/features/video_call/data/repositories/video_call_repository_impl.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/meeting_room.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/participant.dart';
import 'package:pi_iv_time3/features/video_call/presentation/controllers/video_call_controller.dart';
import 'package:pi_iv_time3/features/video_call/presentation/controllers/video_call_lobby_controller.dart';
import 'package:pi_iv_time3/features/video_call/presentation/pages/video_call_lobby_page.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/audio_level_meter.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/dynamic_video_grid.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/participant_video_tile.dart';

void main() {
  group('Challenger M2-1 Empirical Stress Test Suite: Lobby, Grid & Speaker Detection', () {
    late InMemorySignalingBus bus;

    setUp(() {
      bus = InMemorySignalingBus();
      bus.reset();
    });

    tearDown(() {
      bus.reset();
    });

    // Helper to create dual controllers connected via InMemorySignalingBus
    Future<({
      VideoCallController controllerA,
      VideoCallController controllerB,
      VideoCallRepositoryImpl repoA,
      VideoCallRepositoryImpl repoB,
    })> createDualControllers({
      String roomCode = 'CHALLENGER-M2-1',
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

      final pA = Participant(id: 'peer_a', name: 'Alex Sousa', ra: '24802449', isLocal: true);
      final pB = Participant(id: 'peer_b', name: 'Beatriz Lima', ra: '24801122', isLocal: true);

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

      // Await P2P JOIN & PRESENCE_SYNC handshake
      await Future<void>.delayed(const Duration(milliseconds: 60));

      return (
        controllerA: controllerA,
        controllerB: controllerB,
        repoA: repoA,
        repoB: repoB,
      );
    }

    // =========================================================================
    // 1. PRE-JOIN LOBBY INPUT VALIDATION & HARDWARE PREVIEW TESTS
    // =========================================================================
    group('1. Pre-Join Lobby Validation & Hardware State', () {
      late VideoCallLobbyController lobbyController;

      setUp(() {
        lobbyController = VideoCallLobbyController();
      });

      tearDown(() {
        lobbyController.dispose();
      });

      test('Name validation: Rejects null, empty, whitespace and tabs', () {
        expect(lobbyController.validateName(null), 'Informe seu nome');
        expect(lobbyController.validateName(''), 'Informe seu nome');
        expect(lobbyController.validateName('   '), 'Informe seu nome');
        expect(lobbyController.validateName('\t\n  '), 'Informe seu nome');
        expect(lobbyController.validateName('A'), isNull);
        expect(lobbyController.validateName('Alex Gabriel'), isNull);
      });

      test('Name whitespace trimming during createCallController', () {
        final callCtrl = lobbyController.createCallController(
          name: '   Alex Gabriel Soares Sousa   ',
          ra: '24802449',
          roomCode: 'SALA-101',
        );

        expect(callCtrl.localParticipant.name, 'Alex Gabriel Soares Sousa');
        callCtrl.dispose();
      });

      test('RA validation: Rejects null, empty, whitespace, and length < 4', () {
        expect(lobbyController.validateRa(null), 'Informe seu RA');
        expect(lobbyController.validateRa(''), 'Informe seu RA');
        expect(lobbyController.validateRa('   '), 'Informe seu RA');
        expect(lobbyController.validateRa('1'), 'RA inválido');
        expect(lobbyController.validateRa('12'), 'RA inválido');
        expect(lobbyController.validateRa('123'), 'RA inválido');
        expect(lobbyController.validateRa('  123  '), 'RA inválido');
        expect(lobbyController.validateRa('1234'), isNull);
        expect(lobbyController.validateRa('24802449'), isNull);
      });

      test('RA whitespace trimming during createCallController', () {
        final callCtrl = lobbyController.createCallController(
          name: 'Alex',
          ra: '  24802449  ',
          roomCode: 'SALA-101',
        );

        expect(callCtrl.localParticipant.ra, '24802449');
        callCtrl.dispose();
      });

      test('Room code validation: Normalization, length bounds and character filtering', () {
        // Rejects empty / whitespace
        expect(lobbyController.validateRoomCode(null), 'Informe o código da sala');
        expect(lobbyController.validateRoomCode(''), 'Informe o código da sala');
        expect(lobbyController.validateRoomCode('   '), 'Informe o código da sala');

        // Length boundaries (< 3 chars or > 32 chars)
        expect(lobbyController.validateRoomCode('A'), 'Código da sala inválido');
        expect(lobbyController.validateRoomCode('AB'), 'Código da sala inválido');
        expect(lobbyController.validateRoomCode('ABC'), isNull);
        expect(lobbyController.validateRoomCode('12345678901234567890123456789012'), isNull); // 32 chars
        expect(lobbyController.validateRoomCode('123456789012345678901234567890123'), 'Código da sala inválido'); // 33 chars

        // Illegal characters (spaces, underscores, special characters)
        expect(lobbyController.validateRoomCode('SALA 101'), 'Código da sala inválido');
        expect(lobbyController.validateRoomCode('SALA_101'), 'Código da sala inválido');
        expect(lobbyController.validateRoomCode('SALA@101'), 'Código da sala inválido');
        expect(lobbyController.validateRoomCode('SALA#101'), 'Código da sala inválido');
        expect(lobbyController.validateRoomCode('SALA.101'), 'Código da sala inválido');

        // Valid patterns (alphanumeric and hyphens, case-insensitive)
        expect(lobbyController.validateRoomCode('SALA-101'), isNull);
        expect(lobbyController.validateRoomCode('sala-101'), isNull);
        expect(lobbyController.validateRoomCode('ROOM-LAB-01'), isNull);
        expect(lobbyController.validateRoomCode('A-B-C'), isNull);
      });

      test('Room code normalization: Trims whitespace and uppercases room code', () {
        final callCtrl = lobbyController.createCallController(
          name: 'Alex',
          ra: '24802449',
          roomCode: '   lab-univesp-2026   ',
        );

        expect(callCtrl.room.code, 'LAB-UNIVESP-2026');
        expect(callCtrl.room.id, 'LAB-UNIVESP-2026');
        expect(callCtrl.room.title, 'Sala LAB-UNIVESP-2026');
        callCtrl.dispose();
      });

      test('Hardware toggles: Mic and camera toggling and level suppression', () {
        expect(lobbyController.isAudioMuted, isFalse);
        expect(lobbyController.isVideoOff, isFalse);
        expect(lobbyController.audioLevel, 0.05);

        // Toggle Mic to Mute
        lobbyController.toggleAudio();
        expect(lobbyController.isAudioMuted, isTrue);
        expect(lobbyController.audioLevel, 0.0);

        // Attempting to set audio level while muted has no effect
        lobbyController.setAudioLevel(0.85);
        expect(lobbyController.audioLevel, 0.0);

        // Unmute restores level
        lobbyController.toggleAudio();
        expect(lobbyController.isAudioMuted, isFalse);
        lobbyController.setAudioLevel(0.40);
        expect(lobbyController.audioLevel, 0.40);

        // Toggle Video off
        lobbyController.toggleVideo();
        expect(lobbyController.isVideoOff, isTrue);

        // createCallController preserves hardware states
        lobbyController.toggleAudio(); // Mute mic
        final callCtrl = lobbyController.createCallController(
          name: 'Alex',
          ra: '24802449',
          roomCode: 'SALA-101',
        );

        expect(callCtrl.localParticipant.isAudioMuted, isTrue);
        expect(callCtrl.localParticipant.isVideoOff, isTrue);
        expect(callCtrl.localParticipant.audioLevel, 0.0);
        callCtrl.dispose();
      });

      testWidgets('VideoCallLobbyPage interactive UI: Validation, toggles and submission', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        String? joinedName;
        String? joinedRa;
        String? joinedRoom;
        bool? joinedMuted;
        bool? joinedVideoOff;

        await tester.pumpWidget(
          MaterialApp(
            home: VideoCallLobbyPage(
              controller: lobbyController,
              onJoin: (name, ra, room, muted, videoOff) {
                joinedName = name;
                joinedRa = ra;
                joinedRoom = room;
                joinedMuted = muted;
                joinedVideoOff = videoOff;
              },
            ),
          ),
        );
        await tester.pump();

        // 1. Initial UI state
        expect(find.byKey(const Key('lobby_camera_preview')), findsOneWidget);
        expect(find.byKey(const Key('lobby_toggle_mic_button')), findsOneWidget);
        expect(find.byKey(const Key('lobby_toggle_cam_button')), findsOneWidget);
        expect(find.text('Microfone Ativo'), findsOneWidget);
        expect(find.text('Câmera Ligada'), findsOneWidget);

        // 2. Submit with empty name -> Triggers validation error and blocks onJoin
        await tester.tap(find.byKey(const Key('lobby_join_button')));
        await tester.pump();

        expect(find.text('Informe seu nome'), findsOneWidget);
        expect(joinedName, isNull);

        // 3. Toggle Mic and Cam buttons
        await tester.tap(find.byKey(const Key('lobby_toggle_mic_button')));
        await tester.tap(find.byKey(const Key('lobby_toggle_cam_button')));
        await tester.pump();

        expect(find.text('Mudo'), findsOneWidget);
        expect(find.text('Câmera Desligada'), findsOneWidget);
        expect(find.text('Câmera Desativada'), findsOneWidget);

        // 4. Fill form with spaces to test trimming and normalization
        await tester.enterText(find.byKey(const Key('lobby_name_field')), '   Alex Sousa   ');
        await tester.enterText(find.byKey(const Key('lobby_ra_field')), '   24802449   ');
        await tester.enterText(find.byKey(const Key('lobby_room_code_field')), '   sala-202   ');
        await tester.pump();

        // 5. Submit valid form
        await tester.tap(find.byKey(const Key('lobby_join_button')));
        await tester.pump();

        expect(joinedName, 'Alex Sousa');
        expect(joinedRa, '24802449');
        expect(joinedRoom, 'SALA-202');
        expect(joinedMuted, isTrue);
        expect(joinedVideoOff, isTrue);
      });
    });

    // =========================================================================
    // 2. DYNAMIC VIDEO GRID WITH STRICTLY REAL PARTICIPANTS (ZERO BOTS)
    // =========================================================================
    group('2. Dynamic Video Grid & Zero Bots Invariant', () {
      test('Zero Bots Invariant: Solitary participant has strictly 1 tile, no synthetic bots', () async {
        final room = MeetingRoom(id: 'ZERO-BOTS-1', code: 'ZERO-BOTS-1', title: 'Sala 1');
        final ds = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final repo = VideoCallRepositoryImpl(dataSource: ds);
        final localUser = Participant(id: 'local_alex', name: 'Alex', ra: '24802449', isLocal: true);

        final controller = VideoCallController(
          repository: repo,
          room: room,
          localParticipant: localUser,
        );

        // Strictly 1 participant
        expect(controller.allParticipants.length, 1);
        expect(controller.remoteParticipants, isEmpty);
        expect(controller.allParticipants.first.id, 'local_alex');
        expect(controller.allParticipants.first.isLocal, isTrue);

        // Ensure no dummy/mock participants exist
        final hasBot = controller.allParticipants.any(
          (p) => p.name.toLowerCase().contains('bot') || p.id.contains('mock'),
        );
        expect(hasBot, isFalse);

        controller.leaveCall();
        await repo.dispose();
      });

      test('Zero Bots Invariant: Dual participants display strictly 2 tiles across both peers', () async {
        final fixture = await createDualControllers(roomCode: 'ZERO-BOTS-2');
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        expect(cA.allParticipants.length, 2);
        expect(cB.allParticipants.length, 2);

        expect(cA.remoteParticipants.length, 1);
        expect(cB.remoteParticipants.length, 1);

        expect(cA.remoteParticipants.first.id, 'peer_b');
        expect(cB.remoteParticipants.first.id, 'peer_a');

        cA.dispose();
        cB.dispose();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      test('Tile Removal: When Peer B leaves, their tile is removed immediately from Peer A', () async {
        final fixture = await createDualControllers(roomCode: 'ZERO-BOTS-LEAVE');
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        expect(cA.allParticipants.length, 2);

        // Peer B leaves the room
        cB.leaveCall();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Tile for Peer B is removed immediately on Peer A
        expect(cA.allParticipants.length, 1);
        expect(cA.remoteParticipants, isEmpty);
        expect(cA.allParticipants.first.id, 'peer_a');

        cA.dispose();
        cB.dispose();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });

      testWidgets('DynamicVideoGrid widget tree: Layout adapts strictly to real count', (tester) async {
        final p1 = Participant(id: 'p1', name: 'Alex', ra: '24802449');
        final p2 = Participant(id: 'p2', name: 'Beatriz', ra: '24801122');
        final p3 = Participant(id: 'p3', name: 'Carlos', ra: '24803344');

        // 1. N = 0: Empty state message
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: DynamicVideoGrid(participants: []),
            ),
          ),
        );
        expect(find.text('Nenhum participante conectado'), findsOneWidget);
        expect(find.byType(ParticipantVideoTile), findsNothing);

        // 2. N = 1: Exactly 1 solitary tile centered
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DynamicVideoGrid(participants: [p1]),
            ),
          ),
        );
        expect(find.byType(ParticipantVideoTile), findsOneWidget);
        expect(find.byKey(const Key('participant_tile_p1')), findsOneWidget);

        // 3. N = 2: Exactly 2 tiles in Row layout (dual split)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DynamicVideoGrid(participants: [p1, p2]),
            ),
          ),
        );
        expect(find.byType(ParticipantVideoTile), findsNWidgets(2));
        expect(
          find.byWidgetPredicate(
            (w) => w is Row && w.children.length == 2 && w.children.every((c) => c is Expanded),
          ),
          findsOneWidget,
        );

        // 4. N = 3: GridView layout
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DynamicVideoGrid(participants: [p1, p2, p3]),
            ),
          ),
        );
        expect(find.byType(ParticipantVideoTile), findsNWidgets(3));
        expect(find.byType(GridView), findsOneWidget);
      });

      test('Adversarial Signaling: Self-join envelope rejected, duplicate peer updated, unknown leave handled', () async {
        final room = MeetingRoom(id: 'ADV-ROOM', code: 'ADV-ROOM', title: 'Sala');
        final ds = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final repo = VideoCallRepositoryImpl(dataSource: ds);
        final local = Participant(id: 'local_user', name: 'Local', ra: '12345', isLocal: true);

        final controller = VideoCallController(
          repository: repo,
          room: room,
          localParticipant: local,
        );

        // 1. Peer sends self-join envelope (id == local_user)
        controller.registerRemoteParticipant(
          Participant(id: 'local_user', name: 'Loopback Mock', ra: '0000'),
        );
        expect(controller.allParticipants.length, 1);
        expect(controller.remoteParticipants, isEmpty);

        // 2. Real remote peer joins
        controller.registerRemoteParticipant(
          Participant(id: 'remote_1', name: 'Remote User', ra: '54321'),
        );
        expect(controller.allParticipants.length, 2);

        // 3. Duplicate peer join with updated attributes (replaces, does not duplicate)
        controller.registerRemoteParticipant(
          Participant(id: 'remote_1', name: 'Remote User Updated', ra: '54321'),
        );
        expect(controller.allParticipants.length, 2);
        expect(controller.remoteParticipants.first.name, 'Remote User Updated');

        // 4. Unknown peer leave event does not throw or mutate real participants
        await repo.leaveRoom('ADV-ROOM', 'unknown_ghost_peer');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(controller.allParticipants.length, 2);

        controller.leaveCall();
        await repo.dispose();
      });
    });

    // =========================================================================
    // 3. ACTIVE SPEAKER DETECTION & HYSTERESIS EMPIRICAL TESTS
    // =========================================================================
    group('3. Active Speaker Detection & Hysteresis', () {
      test('Boundary Value Analysis: RMS volume threshold strictly > 0.15', () async {
        final room = MeetingRoom(id: 'SPEAKER-BVA', code: 'SPEAKER-BVA', title: 'Sala');
        final ds = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final repo = VideoCallRepositoryImpl(dataSource: ds);
        final local = Participant(id: 'alex', name: 'Alex', ra: '24802449', isLocal: true);

        final controller = VideoCallController(
          repository: repo,
          room: room,
          localParticipant: local,
        );

        // 0.00: Silence -> false
        controller.setAudioLevel(0.00);
        expect(controller.localParticipant.isSpeaking, isFalse);

        // 0.14: Strictly below 0.15 -> false
        controller.setAudioLevel(0.14);
        expect(controller.localParticipant.isSpeaking, isFalse);

        // 0.15: Exact boundary -> false (condition is > 0.15)
        controller.setAudioLevel(0.15);
        expect(controller.localParticipant.isSpeaking, isFalse);

        // 0.16: Strictly above 0.15 -> true
        controller.setAudioLevel(0.16);
        expect(controller.localParticipant.isSpeaking, isTrue);

        // 0.90: Loud speech -> true
        controller.setAudioLevel(0.90);
        expect(controller.localParticipant.isSpeaking, isTrue);

        controller.leaveCall();
        await repo.dispose();
      });

      test('800ms Hysteresis Cooldown: Speaking state persists during silence window', () async {
        final room = MeetingRoom(id: 'SPEAKER-HYS', code: 'SPEAKER-HYS', title: 'Sala');
        final ds = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final repo = VideoCallRepositoryImpl(dataSource: ds);
        final local = Participant(id: 'alex', name: 'Alex', ra: '24802449', isLocal: true);

        final controller = VideoCallController(
          repository: repo,
          room: room,
          localParticipant: local,
        );

        // 1. Participant speaks (RMS = 0.50)
        controller.setAudioLevel(0.50);
        expect(controller.localParticipant.isSpeaking, isTrue);

        // 2. Audio drops below threshold to 0.05
        controller.setAudioLevel(0.05);

        // 3. At 250ms into cooldown: isSpeaking remains TRUE
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(controller.localParticipant.isSpeaking, isTrue, reason: 'isSpeaking deve persistir aos 250ms');

        // 4. At 500ms into cooldown: isSpeaking remains TRUE
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(controller.localParticipant.isSpeaking, isTrue, reason: 'isSpeaking deve persistir aos 500ms');

        // 5. At 850ms total (+350ms): 800ms timer has expired, isSpeaking resets to FALSE
        await Future<void>.delayed(const Duration(milliseconds: 350));
        expect(controller.localParticipant.isSpeaking, isFalse, reason: 'isSpeaking deve resetar após 800ms de silêncio');

        controller.leaveCall();
        await repo.dispose();
      });

      test('Hysteresis Cancellation: Volume surge during cooldown cancels timer and maintains isSpeaking=true', () async {
        final room = MeetingRoom(id: 'SPEAKER-SURGE', code: 'SPEAKER-SURGE', title: 'Sala');
        final ds = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final repo = VideoCallRepositoryImpl(dataSource: ds);
        final local = Participant(id: 'alex', name: 'Alex', ra: '24802449', isLocal: true);

        final controller = VideoCallController(
          repository: repo,
          room: room,
          localParticipant: local,
        );

        // Speak -> drops to silence -> timer starts
        controller.setAudioLevel(0.60);
        expect(controller.localParticipant.isSpeaking, isTrue);

        controller.setAudioLevel(0.04);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(controller.localParticipant.isSpeaking, isTrue);

        // Surges again at 300ms -> cancels timer
        controller.setAudioLevel(0.45);
        expect(controller.localParticipant.isSpeaking, isTrue);

        // Wait another 600ms (900ms from initial drop). Should STILL be true!
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(controller.localParticipant.isSpeaking, isTrue);

        controller.leaveCall();
        await repo.dispose();
      });

      test('Mute immediate override: toggleAudio zeroes audio level and cancels speaking with 0ms delay', () async {
        final room = MeetingRoom(id: 'SPEAKER-MUTE', code: 'SPEAKER-MUTE', title: 'Sala');
        final ds = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final repo = VideoCallRepositoryImpl(dataSource: ds);
        final local = Participant(id: 'alex', name: 'Alex', ra: '24802449', isLocal: true);

        final controller = VideoCallController(
          repository: repo,
          room: room,
          localParticipant: local,
        );

        controller.setAudioLevel(0.70);
        expect(controller.localParticipant.isSpeaking, isTrue);

        // Mute mic immediately
        controller.toggleAudio();
        expect(controller.localParticipant.isAudioMuted, isTrue);
        expect(controller.localParticipant.isSpeaking, isFalse);
        expect(controller.localParticipant.audioLevel, 0.0);

        // While muted, setAudioLevel has no effect
        controller.setAudioLevel(0.95);
        expect(controller.localParticipant.isSpeaking, isFalse);
        expect(controller.localParticipant.audioLevel, 0.0);

        controller.leaveCall();
        await repo.dispose();
      });

      testWidgets('Visual Feedback: Emerald halo border and equalizer/audio meter verification', (tester) async {
        final silentUser = Participant(
          id: 'user_silent',
          name: 'Silencioso',
          ra: '1111',
          isSpeaking: false,
          audioLevel: 0.05,
        );

        final speakingUser = Participant(
          id: 'user_speaking',
          name: 'Falando',
          ra: '2222',
          isSpeaking: true,
          audioLevel: 0.65,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(child: ParticipantVideoTile(participant: silentUser)),
                  Expanded(child: ParticipantVideoTile(participant: speakingUser)),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        // 1. Silent participant container decoration
        final silentTile = tester.widget<Container>(
          find.byKey(const Key('participant_tile_user_silent')),
        );
        final silentBorder = (silentTile.decoration as BoxDecoration).border as Border;
        expect(silentBorder.top.color, Colors.transparent);
        expect((silentTile.decoration as BoxDecoration).boxShadow, isNull);

        // 2. Speaking participant container decoration (Emerald Halo Border & Glow)
        final speakingTile = tester.widget<Container>(
          find.byKey(const Key('participant_tile_user_speaking')),
        );
        final speakingBorder = (speakingTile.decoration as BoxDecoration).border as Border;
        expect(speakingBorder.top.color, Colors.greenAccent);
        expect(speakingBorder.top.width, 3.0);
        expect((speakingTile.decoration as BoxDecoration).boxShadow, isNotNull);

        final boxShadow = (speakingTile.decoration as BoxDecoration).boxShadow!.first;
        expect(boxShadow.color, const Color(0xFF10B981).withValues(alpha: 0.35));
        expect(boxShadow.blurRadius, 12);

        // 3. Audio level meter widget presence and verification
        expect(find.byType(AudioLevelMeter), findsNWidgets(2));

        // 4. Equalizer Icon vs AudioLevelMeter empirical examination:
        // Does an Icons.equalizer or Icons.graphic_eq widget exist in the tile?
        final hasEqualizerIcon = find.byIcon(Icons.equalizer).evaluate().isNotEmpty;
        final hasGraphicEqIcon = find.byIcon(Icons.graphic_eq).evaluate().isNotEmpty;
        debugPrint('Empirical finding - Icons.equalizer present: $hasEqualizerIcon, Icons.graphic_eq present: $hasGraphicEqIcon, AudioLevelMeter present: true');

        // Note: The UI architecture uses the dynamic AudioLevelMeter bar (color transitioning to greenAccent when speaking)
        // rather than a static equalizer icon.
      });

      test('Remote Peer Audio State & Speaking Sync', () async {
        final fixture = await createDualControllers(roomCode: 'SYNC-SPEAKER');
        final cA = fixture.controllerA;
        final cB = fixture.controllerB;

        // Peer A speaks
        cA.setAudioLevel(0.70);
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final peerAInB = cB.remoteParticipants.firstWhere((p) => p.id == 'peer_a');
        expect(peerAInB.isSpeaking, isTrue);
        expect(peerAInB.audioLevel, 0.70);

        // Peer A mutes
        cA.toggleAudio();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final peerAInBMuted = cB.remoteParticipants.firstWhere((p) => p.id == 'peer_a');
        expect(peerAInBMuted.isAudioMuted, isTrue);
        expect(peerAInBMuted.isSpeaking, isFalse);

        cA.dispose();
        cB.dispose();
        await fixture.repoA.dispose();
        await fixture.repoB.dispose();
      });
    });
  });
}
