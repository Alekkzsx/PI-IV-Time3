// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/video_call/data/channel/in_memory_signaling_bus.dart';
import 'package:pi_iv_time3/features/video_call/data/datasources/video_call_room_remote_data_source.dart';
import 'package:pi_iv_time3/features/video_call/data/datasources/video_call_signaling_datasource.dart';
import 'package:pi_iv_time3/features/video_call/data/repositories/video_call_repository_impl.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/meeting_room.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/participant.dart';
import 'package:pi_iv_time3/features/video_call/presentation/controllers/video_call_controller.dart';
import 'package:pi_iv_time3/features/video_call/presentation/controllers/video_call_lobby_controller.dart';
import 'package:pi_iv_time3/features/video_call/presentation/pages/video_call_lobby_page.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/audio_level_meter.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/dynamic_video_grid.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/chat_message.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/emoji_reaction.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/hand_raise_item.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/media_state_update.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/recording_state.dart';
import 'package:pi_iv_time3/features/video_call/domain/repositories/video_call_repository.dart';
import 'package:pi_iv_time3/features/video_call/presentation/widgets/participant_video_tile.dart';

class _FakeRoomRemoteDataSource extends VideoCallRoomRemoteDataSource {
  @override
  Future<List<VideoCallRoomSummary>> listRooms() async => const [
    VideoCallRoomSummary(
      roomCode: 'APS-II',
      classCode: 'APS-II',
      title: 'APS-II',
      isOpen: true,
    ),
  ];

  @override
  Future<VideoCallRoomAccess> enterRoom(String roomCode) async =>
      const VideoCallRoomAccess(
        opened: false,
        webSocketTicket: 'test-ticket',
      );
}

class FakeChallengerRepository implements VideoCallRepository {
  final joinedCtrl = StreamController<Participant>.broadcast(sync: true);
  final leftCtrl = StreamController<String>.broadcast(sync: true);
  final chatCtrl = StreamController<ChatMessage>.broadcast(sync: true);
  final reactionCtrl = StreamController<EmojiReaction>.broadcast(sync: true);
  final handRaiseCtrl = StreamController<HandRaiseItem>.broadcast(sync: true);
  final mediaCtrl = StreamController<MediaStateUpdate>.broadcast(sync: true);
  final recordingCtrl = StreamController<RecordingState>.broadcast(sync: true);

  @override
  Stream<Participant> get participantJoinedStream => joinedCtrl.stream;
  @override
  Stream<String> get participantLeftStream => leftCtrl.stream;
  @override
  Stream<ChatMessage> get chatMessageStream => chatCtrl.stream;
  @override
  Stream<EmojiReaction> get emojiReactionStream => reactionCtrl.stream;
  @override
  Stream<HandRaiseItem> get handRaiseStream => handRaiseCtrl.stream;
  @override
  Stream<MediaStateUpdate> get mediaStateStream => mediaCtrl.stream;
  @override
  Stream<RecordingState> get recordingStateStream => recordingCtrl.stream;

  void emitParticipantJoined(Participant p) => joinedCtrl.add(p);
  void emitParticipantLeft(String peerId) => leftCtrl.add(peerId);

  @override
  Future<void> joinRoom(MeetingRoom room, Participant localParticipant) async {}
  @override
  Future<void> leaveRoom(String roomId, String peerId) async =>
      leftCtrl.add(peerId);
  @override
  Future<void> sendChatMessage(String roomId, ChatMessage message) async =>
      chatCtrl.add(message);
  @override
  Future<void> sendEmojiReaction(String roomId, EmojiReaction reaction) async =>
      reactionCtrl.add(reaction);
  @override
  Future<void> toggleHandRaise(
    String roomId,
    String peerId,
    bool isRaised,
  ) async {}
  @override
  Future<void> updateMediaState(
    String roomId,
    String peerId, {
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    double? audioLevel,
  }) async {}
  @override
  Future<void> updateRecordingState(
    String roomId,
    RecordingState state,
  ) async => recordingCtrl.add(state);

  @override
  Future<void> dispose() async {
    await joinedCtrl.close();
    await leftCtrl.close();
    await chatCtrl.close();
    await reactionCtrl.close();
    await handRaiseCtrl.close();
    await mediaCtrl.close();
    await recordingCtrl.close();
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
  group(
    'Challenger M2-1 Empirical Stress Test Suite: Lobby, Grid & Speaker Detection',
    () {
      late InMemorySignalingBus bus;

      setUp(() {
        bus = InMemorySignalingBus();
        bus.reset();
      });

      tearDown(() {
        bus.reset();
      });

      // Auxiliar para criar controladores duplos conectados via InMemorySignalingBus
      Future<
        ({
          VideoCallController controllerA,
          VideoCallController controllerB,
          VideoCallRepositoryImpl repoA,
          VideoCallRepositoryImpl repoB,
        })
      >
      createDualControllers({String roomCode = 'CHALLENGER-M2-1'}) async {
        final room = MeetingRoom(
          id: roomCode,
          code: roomCode,
          title: 'Sala $roomCode',
        );

        final dsA = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final dsB = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final repoA = VideoCallRepositoryImpl(dataSource: dsA);
        final repoB = VideoCallRepositoryImpl(dataSource: dsB);

        final pA = Participant(
          id: 'peer_a',
          name: 'Alex Sousa',
          ra: '24802449',
          isLocal: true,
        );
        final pB = Participant(
          id: 'peer_b',
          name: 'Beatriz Lima',
          ra: '24801122',
          isLocal: true,
        );

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

        // Aguarda o handshake P2P JOIN e PRESENCE_SYNC
        await Future<void>.delayed(const Duration(milliseconds: 60));

        return (
          controllerA: controllerA,
          controllerB: controllerB,
          repoA: repoA,
          repoB: repoB,
        );
      }

      // =========================================================================
      // 1. TESTES DE VALIDAÇÃO DE ENTRADA DO LOBBY PRÉ-INGRESSO E PRÉ-VISUALIZAÇÃO DE HARDWARE
      // =========================================================================
      group('1. Pre-Join Lobby Validation & Hardware State', () {
        late VideoCallLobbyController lobbyController;

        setUp(() {
          AppUserSession.instance.signOut();
          lobbyController = VideoCallLobbyController(
            roomDataSource: _FakeRoomRemoteDataSource(),
          );
        });

        tearDown(() {
          AppUserSession.instance.signOut();
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

        test(
          'RA validation: Rejects null, empty, whitespace, and length < 4',
          () {
            expect(lobbyController.validateRa(null), 'Informe seu RA');
            expect(lobbyController.validateRa(''), 'Informe seu RA');
            expect(lobbyController.validateRa('   '), 'Informe seu RA');
            expect(lobbyController.validateRa('1'), 'RA inválido');
            expect(lobbyController.validateRa('12'), 'RA inválido');
            expect(lobbyController.validateRa('123'), 'RA inválido');
            expect(lobbyController.validateRa('  123  '), 'RA inválido');
            expect(lobbyController.validateRa('1234'), isNull);
            expect(lobbyController.validateRa('24802449'), isNull);
          },
        );

        test('RA whitespace trimming during createCallController', () {
          final callCtrl = lobbyController.createCallController(
            name: 'Alex',
            ra: '  24802449  ',
            roomCode: 'SALA-101',
          );

          expect(callCtrl.localParticipant.ra, '24802449');
          callCtrl.dispose();
        });

        test(
          'Room code validation: Normalization, length bounds and character filtering',
          () {
            // Rejeita vazio / espaços em branco
            expect(
              lobbyController.validateRoomCode(null),
              'Informe o código da sala',
            );
            expect(
              lobbyController.validateRoomCode(''),
              'Informe o código da sala',
            );
            expect(
              lobbyController.validateRoomCode('   '),
              'Informe o código da sala',
            );

            // Limites de comprimento (< 2 caracteres ou > 60 caracteres)
            expect(
              lobbyController.validateRoomCode('A'),
              'Código da sala inválido',
            );
            expect(lobbyController.validateRoomCode('AB'), isNull);
            expect(
              lobbyController.validateRoomCode('A' * 60),
              isNull,
            ); // 60 caracteres
            expect(
              lobbyController.validateRoomCode('A' * 61),
              'Código da sala inválido',
            ); // 61 caracteres

            // Caracteres inválidos (pontuação fora de alfanumérico, ponto, sublinhado e hífen)
            expect(
              lobbyController.validateRoomCode('SALA@101'),
              'Código da sala inválido',
            );
            expect(
              lobbyController.validateRoomCode('SALA#101'),
              'Código da sala inválido',
            );
            expect(
              lobbyController.validateRoomCode('SALA\$101'),
              'Código da sala inválido',
            );

            // Padrões válidos (alfanumérico, pontos, sublinhados e hífens)
            expect(lobbyController.validateRoomCode('SALA_101'), isNull);
            expect(lobbyController.validateRoomCode('SALA.101'), isNull);
            expect(lobbyController.validateRoomCode('SALA-101'), isNull);
            expect(lobbyController.validateRoomCode('sala-101'), isNull);
            expect(lobbyController.validateRoomCode('ROOM-LAB-01'), isNull);
            expect(lobbyController.validateRoomCode('A-B-C'), isNull);
          },
        );

        test(
          'Room code normalization: Trims whitespace and uppercases room code',
          () {
            final callCtrl = lobbyController.createCallController(
              name: 'Alex',
              ra: '24802449',
              roomCode: '   lab-univesp-2026   ',
            );

            expect(callCtrl.room.code, 'LAB-UNIVESP-2026');
            expect(callCtrl.room.id, 'LAB-UNIVESP-2026');
            expect(callCtrl.room.title, 'Sala LAB-UNIVESP-2026');
            callCtrl.dispose();
          },
        );

        test(
          'Hardware toggles: Mic and camera toggling and level suppression',
          () {
            expect(lobbyController.isAudioMuted, isFalse);
            expect(lobbyController.isVideoOff, isFalse);
            expect(lobbyController.audioLevel, 0.05);

            // Alterna o microfone para mudo
            lobbyController.toggleAudio();
            expect(lobbyController.isAudioMuted, isTrue);
            expect(lobbyController.audioLevel, 0.0);

            // Tentar definir o nível de áudio enquanto mutado não tem efeito
            lobbyController.setAudioLevel(0.85);
            expect(lobbyController.audioLevel, 0.0);

            // Desmutar restaura o nível
            lobbyController.toggleAudio();
            expect(lobbyController.isAudioMuted, isFalse);
            lobbyController.setAudioLevel(0.40);
            expect(lobbyController.audioLevel, 0.40);

            // Desliga o vídeo
            lobbyController.toggleVideo();
            expect(lobbyController.isVideoOff, isTrue);

            // createCallController preserva os estados de hardware
            lobbyController.toggleAudio(); // Muta o microfone
            final callCtrl = lobbyController.createCallController(
              name: 'Alex',
              ra: '24802449',
              roomCode: 'SALA-101',
            );

            expect(callCtrl.localParticipant.isAudioMuted, isTrue);
            expect(callCtrl.localParticipant.isVideoOff, isTrue);
            expect(callCtrl.localParticipant.audioLevel, 0.0);
            callCtrl.dispose();
          },
        );

        testWidgets(
          'VideoCallLobbyPage interactive UI: Validation, toggles and submission',
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
              openedByName: 'Docente da turma',
              openedByIdentity: 'DOC-88410',
            );
            addTearDown(() => _closeOwnedSession(bridge, 'APS-II'));
            AppUserSession.instance.signIn(
              identity: '2024.1.00892',
              profile: 'aluno',
            );

            String? joinedName;
            String? joinedRa;
            String? joinedRoom;
            bool? joinedMuted;
            bool? joinedVideoOff;

            await tester.pumpWidget(
              MaterialApp(
                home: VideoCallLobbyPage(
                  controller: lobbyController,
                  roomDataSource: _FakeRoomRemoteDataSource(),
                  initialRoomCode: 'APS-II',
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

            // 1. Estado inicial da UI
            expect(
              find.byKey(const Key('lobby_camera_preview')),
              findsOneWidget,
            );
            expect(
              find.byKey(const Key('lobby_toggle_mic_button')),
              findsOneWidget,
            );
            expect(
              find.byKey(const Key('lobby_toggle_cam_button')),
              findsOneWidget,
            );
            expect(find.text('Microfone Ativo'), findsOneWidget);
            expect(find.text('Câmera Ligada'), findsOneWidget);

            // 2. Alterna os botões de microfone e câmera
            await tester.tap(find.byKey(const Key('lobby_toggle_mic_button')));
            await tester.tap(find.byKey(const Key('lobby_toggle_cam_button')));
            await tester.pump();

            expect(find.text('Mudo'), findsOneWidget);
            expect(find.text('Câmera Desligada'), findsOneWidget);
            expect(find.text('Câmera Desativada'), findsOneWidget);

            // 3. Envia usando a identidade e a turma fornecidas pela sessão ativa
            await tester.tap(find.byKey(const Key('lobby_join_button')));
            await tester.pump();

            expect(joinedName, '2024.1.00892');
            expect(joinedRa, '2024.1.00892');
            expect(joinedRoom, 'APS-II');
            expect(joinedMuted, isTrue);
            expect(joinedVideoOff, isTrue);
          },
        );
      });

      // =========================================================================
      // 2. GRADE DE VÍDEO DINÂMICA COM PARTICIPANTES ESTRITAMENTE REAIS (ZERO BOTS)
      // =========================================================================
      group('2. Dynamic Video Grid & Zero Bots Invariant', () {
        test(
          'Zero Bots Invariant: Solitary participant has strictly 1 tile, no synthetic bots',
          () async {
            final room = MeetingRoom(
              id: 'ZERO-BOTS-1',
              code: 'ZERO-BOTS-1',
              title: 'Sala 1',
            );
            final ds = VideoCallSignalingDataSource(
              channelFactory: (name) => InMemorySignalingChannel(name, bus),
            );
            final repo = VideoCallRepositoryImpl(dataSource: ds);
            final localUser = Participant(
              id: 'local_alex',
              name: 'Alex',
              ra: '24802449',
              isLocal: true,
            );

            final controller = VideoCallController(
              repository: repo,
              room: room,
              localParticipant: localUser,
            );

            // Estritamente 1 participante
            expect(controller.allParticipants.length, 1);
            expect(controller.remoteParticipants, isEmpty);
            expect(controller.allParticipants.first.id, 'local_alex');
            expect(controller.allParticipants.first.isLocal, isTrue);

            // Garante que não existam participantes fictícios/simulados
            final hasBot = controller.allParticipants.any(
              (p) =>
                  p.name.toLowerCase().contains('bot') || p.id.contains('mock'),
            );
            expect(hasBot, isFalse);

            controller.leaveCall();
            await repo.dispose();
          },
        );

        test(
          'Zero Bots Invariant: Dual participants display strictly 2 tiles across both peers',
          () async {
            final fixture = await createDualControllers(
              roomCode: 'ZERO-BOTS-2',
            );
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
          },
        );

        test(
          'Tile Removal: When Peer B leaves, their tile is removed immediately from Peer A',
          () async {
            final fixture = await createDualControllers(
              roomCode: 'ZERO-BOTS-LEAVE',
            );
            final cA = fixture.controllerA;
            final cB = fixture.controllerB;

            expect(cA.allParticipants.length, 2);

            // Peer B sai da sala
            cB.leaveCall();
            await Future<void>.delayed(const Duration(milliseconds: 50));

            // O bloco do Peer B é removido imediatamente no Peer A
            expect(cA.allParticipants.length, 1);
            expect(cA.remoteParticipants, isEmpty);
            expect(cA.allParticipants.first.id, 'peer_a');

            cA.dispose();
            cB.dispose();
            await fixture.repoA.dispose();
            await fixture.repoB.dispose();
          },
        );

        testWidgets(
          'DynamicVideoGrid widget tree: Layout adapts strictly to real count',
          (tester) async {
            final p1 = Participant(id: 'p1', name: 'Alex', ra: '24802449');
            final p2 = Participant(id: 'p2', name: 'Beatriz', ra: '24801122');
            final p3 = Participant(id: 'p3', name: 'Carlos', ra: '24803344');

            // 1. N = 0: Mensagem de estado vazio
            await tester.pumpWidget(
              const MaterialApp(
                home: Scaffold(body: DynamicVideoGrid(participants: [])),
              ),
            );
            expect(find.text('Nenhum participante conectado'), findsOneWidget);
            expect(find.byType(ParticipantVideoTile), findsNothing);

            // 2. N = 1: Exatamente 1 bloco solitário centralizado
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(body: DynamicVideoGrid(participants: [p1])),
              ),
            );
            expect(find.byType(ParticipantVideoTile), findsOneWidget);
            expect(
              find.byKey(const Key('participant_tile_p1')),
              findsOneWidget,
            );

            // 3. N = 2: Exatamente 2 blocos em layout Row (divisão dupla)
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(body: DynamicVideoGrid(participants: [p1, p2])),
              ),
            );
            expect(find.byType(ParticipantVideoTile), findsNWidgets(2));
            expect(
              find.byWidgetPredicate(
                (w) =>
                    w is Row &&
                    w.children.length == 2 &&
                    w.children.every((c) => c is Expanded),
              ),
              findsOneWidget,
            );

            // 4. N = 3: Layout em GridView
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: DynamicVideoGrid(participants: [p1, p2, p3]),
                ),
              ),
            );
            expect(find.byType(ParticipantVideoTile), findsNWidgets(3));
            expect(find.byType(GridView), findsOneWidget);
          },
        );

        test(
          'Adversarial Signaling: Self-join envelope rejected, duplicate peer updated, unknown leave handled',
          () async {
            final room = MeetingRoom(
              id: 'ADV-ROOM',
              code: 'ADV-ROOM',
              title: 'Sala',
            );
            final ds = VideoCallSignalingDataSource(
              channelFactory: (name) => InMemorySignalingChannel(name, bus),
            );
            final repo = VideoCallRepositoryImpl(dataSource: ds);
            final local = Participant(
              id: 'local_user',
              name: 'Local',
              ra: '12345',
              isLocal: true,
            );

            final controller = VideoCallController(
              repository: repo,
              room: room,
              localParticipant: local,
            );

            // 1. Peer envia envelope de autoingresso (id == local_user)
            controller.registerRemoteParticipant(
              Participant(id: 'local_user', name: 'Loopback Mock', ra: '0000'),
            );
            expect(controller.allParticipants.length, 1);
            expect(controller.remoteParticipants, isEmpty);

            // 2. Peer remoto real ingressa
            controller.registerRemoteParticipant(
              Participant(id: 'remote_1', name: 'Remote User', ra: '54321'),
            );
            expect(controller.allParticipants.length, 2);

            // 3. Ingresso duplicado de peer com atributos atualizados (substitui, não duplica)
            controller.registerRemoteParticipant(
              Participant(
                id: 'remote_1',
                name: 'Remote User Updated',
                ra: '54321',
              ),
            );
            expect(controller.allParticipants.length, 2);
            expect(
              controller.remoteParticipants.first.name,
              'Remote User Updated',
            );

            // 4. Evento de saída de peer desconhecido não lança erro nem altera participantes reais
            await repo.leaveRoom('ADV-ROOM', 'unknown_ghost_peer');
            await Future<void>.delayed(const Duration(milliseconds: 30));
            expect(controller.allParticipants.length, 2);

            controller.leaveCall();
            await repo.dispose();
          },
        );
      });

      // =========================================================================
      // 3. TESTES EMPÍRICOS DE DETECÇÃO DE ORADOR ATIVO E HISTERESE
      // =========================================================================
      group('3. Active Speaker Detection & Hysteresis', () {
        test(
          'Boundary Value Analysis: RMS volume threshold strictly > 0.15',
          () async {
            final room = MeetingRoom(
              id: 'SPEAKER-BVA',
              code: 'SPEAKER-BVA',
              title: 'Sala',
            );
            final ds = VideoCallSignalingDataSource(
              channelFactory: (name) => InMemorySignalingChannel(name, bus),
            );
            final repo = VideoCallRepositoryImpl(dataSource: ds);
            final local = Participant(
              id: 'alex',
              name: 'Alex',
              ra: '24802449',
              isLocal: true,
            );

            final controller = VideoCallController(
              repository: repo,
              room: room,
              localParticipant: local,
            );

            // 0.00: Silêncio -> false
            controller.setAudioLevel(0.00);
            expect(controller.localParticipant.isSpeaking, isFalse);

            // 0.14: Estritamente abaixo de 0.15 -> false
            controller.setAudioLevel(0.14);
            expect(controller.localParticipant.isSpeaking, isFalse);

            // 0.15: Limite exato -> false (a condição é > 0.15)
            controller.setAudioLevel(0.15);
            expect(controller.localParticipant.isSpeaking, isFalse);

            // 0.16: Estritamente acima de 0.15 -> true
            controller.setAudioLevel(0.16);
            expect(controller.localParticipant.isSpeaking, isTrue);

            // 0.90: Fala alta -> true
            controller.setAudioLevel(0.90);
            expect(controller.localParticipant.isSpeaking, isTrue);

            controller.leaveCall();
            await repo.dispose();
          },
        );

        test(
          '800ms Hysteresis Cooldown: Speaking state persists during silence window',
          () async {
            final room = MeetingRoom(
              id: 'SPEAKER-HYS',
              code: 'SPEAKER-HYS',
              title: 'Sala',
            );
            final ds = VideoCallSignalingDataSource(
              channelFactory: (name) => InMemorySignalingChannel(name, bus),
            );
            final repo = VideoCallRepositoryImpl(dataSource: ds);
            final local = Participant(
              id: 'alex',
              name: 'Alex',
              ra: '24802449',
              isLocal: true,
            );

            final controller = VideoCallController(
              repository: repo,
              room: room,
              localParticipant: local,
            );

            // 1. Participante fala (RMS = 0.50)
            controller.setAudioLevel(0.50);
            expect(controller.localParticipant.isSpeaking, isTrue);

            // 2. Áudio cai abaixo do limiar para 0.05
            controller.setAudioLevel(0.05);

            // 3. Aos 250ms de resfriamento: isSpeaking permanece TRUE
            await Future<void>.delayed(const Duration(milliseconds: 250));
            expect(
              controller.localParticipant.isSpeaking,
              isTrue,
              reason: 'isSpeaking deve persistir aos 250ms',
            );

            // 4. Aos 500ms de resfriamento: isSpeaking permanece TRUE
            await Future<void>.delayed(const Duration(milliseconds: 250));
            expect(
              controller.localParticipant.isSpeaking,
              isTrue,
              reason: 'isSpeaking deve persistir aos 500ms',
            );

            // 5. Aos 850ms totais (+350ms): temporizador de 800ms expirou, isSpeaking volta para FALSE
            await Future<void>.delayed(const Duration(milliseconds: 350));
            expect(
              controller.localParticipant.isSpeaking,
              isFalse,
              reason: 'isSpeaking deve resetar após 800ms de silêncio',
            );

            controller.leaveCall();
            await repo.dispose();
          },
        );

        test(
          'Hysteresis Cancellation: Volume surge during cooldown cancels timer and maintains isSpeaking=true',
          () async {
            final room = MeetingRoom(
              id: 'SPEAKER-SURGE',
              code: 'SPEAKER-SURGE',
              title: 'Sala',
            );
            final ds = VideoCallSignalingDataSource(
              channelFactory: (name) => InMemorySignalingChannel(name, bus),
            );
            final repo = VideoCallRepositoryImpl(dataSource: ds);
            final local = Participant(
              id: 'alex',
              name: 'Alex',
              ra: '24802449',
              isLocal: true,
            );

            final controller = VideoCallController(
              repository: repo,
              room: room,
              localParticipant: local,
            );

            // Fala -> cai para silêncio -> temporizador inicia
            controller.setAudioLevel(0.60);
            expect(controller.localParticipant.isSpeaking, isTrue);

            controller.setAudioLevel(0.04);
            await Future<void>.delayed(const Duration(milliseconds: 300));
            expect(controller.localParticipant.isSpeaking, isTrue);

            // Sobe novamente aos 300ms -> cancela temporizador
            controller.setAudioLevel(0.45);
            expect(controller.localParticipant.isSpeaking, isTrue);

            // Aguarda mais 600ms (900ms desde a queda inicial). AINDA deve ser true!
            await Future<void>.delayed(const Duration(milliseconds: 600));
            expect(controller.localParticipant.isSpeaking, isTrue);

            controller.leaveCall();
            await repo.dispose();
          },
        );

        test(
          'Mute immediate override: toggleAudio zeroes audio level and cancels speaking with 0ms delay',
          () async {
            final room = MeetingRoom(
              id: 'SPEAKER-MUTE',
              code: 'SPEAKER-MUTE',
              title: 'Sala',
            );
            final ds = VideoCallSignalingDataSource(
              channelFactory: (name) => InMemorySignalingChannel(name, bus),
            );
            final repo = VideoCallRepositoryImpl(dataSource: ds);
            final local = Participant(
              id: 'alex',
              name: 'Alex',
              ra: '24802449',
              isLocal: true,
            );

            final controller = VideoCallController(
              repository: repo,
              room: room,
              localParticipant: local,
            );

            controller.setAudioLevel(0.70);
            expect(controller.localParticipant.isSpeaking, isTrue);

            // Muta o microfone imediatamente
            controller.toggleAudio();
            expect(controller.localParticipant.isAudioMuted, isTrue);
            expect(controller.localParticipant.isSpeaking, isFalse);
            expect(controller.localParticipant.audioLevel, 0.0);

            // Enquanto mutado, setAudioLevel não tem efeito
            controller.setAudioLevel(0.95);
            expect(controller.localParticipant.isSpeaking, isFalse);
            expect(controller.localParticipant.audioLevel, 0.0);

            controller.leaveCall();
            await repo.dispose();
          },
        );

        testWidgets(
          'Visual Feedback: Emerald halo border and equalizer/audio meter verification',
          (tester) async {
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
                      Expanded(
                        child: ParticipantVideoTile(participant: silentUser),
                      ),
                      Expanded(
                        child: ParticipantVideoTile(participant: speakingUser),
                      ),
                    ],
                  ),
                ),
              ),
            );
            await tester.pump();

            // 1. Decoração do contêiner do participante em silêncio
            final silentTile = tester.widget<Container>(
              find.byKey(const Key('participant_tile_user_silent')),
            );
            final silentBorder =
                (silentTile.decoration as BoxDecoration).border as Border;
            expect(silentBorder.top.color, Colors.transparent);
            expect((silentTile.decoration as BoxDecoration).boxShadow, isNull);

            // 2. Decoração do contêiner do participante falando (Borda e Brilho de Halo Branco Monocromático)
            final speakingTile = tester.widget<Container>(
              find.byKey(const Key('participant_tile_user_speaking')),
            );
            final speakingBorder =
                (speakingTile.decoration as BoxDecoration).border as Border;
            expect(speakingBorder.top.color, Colors.white);
            expect(speakingBorder.top.width, 3.0);
            expect(
              (speakingTile.decoration as BoxDecoration).boxShadow,
              isNotNull,
            );

            final boxShadow =
                (speakingTile.decoration as BoxDecoration).boxShadow!.first;
            expect(boxShadow.color, Colors.white.withValues(alpha: 0.25));
            expect(boxShadow.blurRadius, 12);

            // 3. Presença e verificação do widget medidor de nível de áudio
            expect(find.byType(AudioLevelMeter), findsNWidgets(2));

            // 4. Análise empírica entre ícone de equalizador e AudioLevelMeter:
            // Existe um widget Icons.equalizer ou Icons.graphic_eq no bloco?
            final hasEqualizerIcon = find
                .byIcon(Icons.equalizer)
                .evaluate()
                .isNotEmpty;
            final hasGraphicEqIcon = find
                .byIcon(Icons.graphic_eq)
                .evaluate()
                .isNotEmpty;
            debugPrint(
              'Empirical finding - Icons.equalizer present: $hasEqualizerIcon, Icons.graphic_eq present: $hasGraphicEqIcon, AudioLevelMeter present: true',
            );

            // Nota: A arquitetura da UI usa a barra dinâmica AudioLevelMeter (cor mudando para branco ao falar)
            // em vez de um ícone de equalizador estático.
          },
        );

        test('Remote Peer Audio State & Speaking Sync', () async {
          final fixture = await createDualControllers(roomCode: 'SYNC-SPEAKER');
          final cA = fixture.controllerA;
          final cB = fixture.controllerB;

          // Peer A fala
          cA.setAudioLevel(0.70);
          await Future<void>.delayed(const Duration(milliseconds: 40));

          final peerAInB = cB.remoteParticipants.firstWhere(
            (p) => p.id == 'peer_a',
          );
          expect(peerAInB.isSpeaking, isTrue);
          expect(peerAInB.audioLevel, 0.70);

          // Peer A muta
          cA.toggleAudio();
          await Future<void>.delayed(const Duration(milliseconds: 40));

          final peerAInBMuted = cB.remoteParticipants.firstWhere(
            (p) => p.id == 'peer_a',
          );
          expect(peerAInBMuted.isAudioMuted, isTrue);
          expect(peerAInBMuted.isSpeaking, isFalse);

          cA.dispose();
          cB.dispose();
          await fixture.repoA.dispose();
          await fixture.repoB.dispose();
        });

        test(
          'Remote peer hysteresis vs immediate audioLevel broadcast investigation',
          () async {
            final fixture = await createDualControllers(
              roomCode: 'HYS-REMOTE-CHECK',
            );
            final cA = fixture.controllerA;
            final cB = fixture.controllerB;

            // Peer A fala
            cA.setAudioLevel(0.75);
            await Future<void>.delayed(const Duration(milliseconds: 40));

            expect(cA.localParticipant.isSpeaking, isTrue);
            final peerAInBStart = cB.remoteParticipants.firstWhere(
              (p) => p.id == 'peer_a',
            );
            expect(peerAInBStart.isSpeaking, isTrue);

            // Peer A para de falar -> cai para 0.04
            cA.setAudioLevel(0.04);
            await Future<void>.delayed(const Duration(milliseconds: 40));

            // No Peer A (local): temporizador de resfriamento de 800ms está ativo
            expect(
              cA.localParticipant.isSpeaking,
              isTrue,
              reason: 'Local peer A must have 800ms hysteresis',
            );

            // No Peer B (remoto): inspeciona o estado de fala remoto
            final peerAInBCooldown = cB.remoteParticipants.firstWhere(
              (p) => p.id == 'peer_a',
            );
            debugPrint(
              'Empirical finding - Remote Peer B view of Peer A isSpeaking during cooldown: ${peerAInBCooldown.isSpeaking}',
            );

            cA.dispose();
            cB.dispose();
            await fixture.repoA.dispose();
            await fixture.repoB.dispose();
          },
        );

        testWidgets(
          'Simultaneous active speakers: Dual monochrome white halo borders rendered',
          (tester) async {
            final speaker1 = Participant(
              id: 'p_spk_1',
              name: 'Professor Alex',
              ra: '24802449',
              isSpeaking: true,
              audioLevel: 0.70,
            );
            final speaker2 = Participant(
              id: 'p_spk_2',
              name: 'Aluna Beatriz',
              ra: '24801122',
              isSpeaking: true,
              audioLevel: 0.55,
            );

            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      Expanded(
                        child: ParticipantVideoTile(participant: speaker1),
                      ),
                      Expanded(
                        child: ParticipantVideoTile(participant: speaker2),
                      ),
                    ],
                  ),
                ),
              ),
            );
            await tester.pump();

            final tile1 = tester.widget<Container>(
              find.byKey(const Key('participant_tile_p_spk_1')),
            );
            final tile2 = tester.widget<Container>(
              find.byKey(const Key('participant_tile_p_spk_2')),
            );

            final border1 =
                (tile1.decoration as BoxDecoration).border as Border;
            final border2 =
                (tile2.decoration as BoxDecoration).border as Border;

            expect(border1.top.color, Colors.white);
            expect(border2.top.color, Colors.white);
            expect(border1.top.width, 3.0);
            expect(border2.top.width, 3.0);
          },
        );
      });

      // =========================================================================
      // 4. ESTRESSE DE GRADE DINÂMICA EM LARGA ESCALA E TESTES DE ENTRADA ADVERSARIAL
      // =========================================================================
      group('4. Large-Scale Multi-Peer & Adversarial Input Stress', () {
        test(
          'Multi-Peer Scaling (N=1 to N=10) and bulk peer leave pruning',
          () async {
            final local = Participant(
              id: 'local_host',
              name: 'Host',
              ra: '0001',
              isLocal: true,
            );
            final fakeRepo = FakeChallengerRepository();
            final room = MeetingRoom(
              id: 'SCALE-10',
              code: 'SCALE-10',
              title: 'Sala',
            );
            final controller = VideoCallController(
              repository: fakeRepo,
              room: room,
              localParticipant: local,
            );

            expect(controller.allParticipants.length, 1);

            // Registra sequencialmente 9 participantes remotos (N=10 no total)
            for (int i = 1; i <= 9; i++) {
              controller.registerRemoteParticipant(
                Participant(id: 'peer_$i', name: 'Aluno $i', ra: '100$i'),
              );
            }

            expect(controller.allParticipants.length, 10);
            expect(controller.remoteParticipants.length, 9);

            // Poda 5 peers via evento de saída
            for (int i = 1; i <= 5; i++) {
              fakeRepo.emitParticipantLeft('peer_$i');
            }

            expect(controller.allParticipants.length, 5);
            expect(controller.remoteParticipants.length, 4);

            // Poda os 4 peers remotos restantes
            for (int i = 6; i <= 9; i++) {
              fakeRepo.emitParticipantLeft('peer_$i');
            }

            expect(controller.allParticipants.length, 1);
            expect(controller.remoteParticipants, isEmpty);
            expect(controller.allParticipants.first.id, 'local_host');

            controller.dispose();
            await fakeRepo.dispose();
          },
        );

        test(
          'Adversarial room codes: Rejects emojis, unicode accents and punctuation',
          () {
            final lobbyCtrl = VideoCallLobbyController(
              roomDataSource: _FakeRoomRemoteDataSource(),
            );

            expect(
              lobbyCtrl.validateRoomCode('SALA-101-🔥'),
              'Código da sala inválido',
            );
            expect(
              lobbyCtrl.validateRoomCode('SALÃO-101'),
              'Código da sala inválido',
            );
            expect(
              lobbyCtrl.validateRoomCode('SALA?101'),
              'Código da sala inválido',
            );
            expect(
              lobbyCtrl.validateRoomCode('SALA:101'),
              'Código da sala inválido',
            );
            expect(
              lobbyCtrl.validateRoomCode('SALA/101'),
              'Código da sala inválido',
            );
            expect(
              lobbyCtrl.validateRoomCode('SALA=101'),
              'Código da sala inválido',
            );

            lobbyCtrl.dispose();
          },
        );

        test(
          'Hardware Rapid Toggle Stress: 10 consecutive toggles preserve state integrity',
          () {
            final lobbyCtrl = VideoCallLobbyController(
              roomDataSource: _FakeRoomRemoteDataSource(),
            );

            for (int i = 0; i < 10; i++) {
              lobbyCtrl.toggleAudio();
              lobbyCtrl.toggleVideo();
            }

            // Número par de alternâncias -> restaura o estado original false
            expect(lobbyCtrl.isAudioMuted, isFalse);
            expect(lobbyCtrl.isVideoOff, isFalse);
            expect(lobbyCtrl.audioLevel, 0.05);

            lobbyCtrl.dispose();
          },
        );
      });
    },
  );
}
