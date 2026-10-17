// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/data/channel/in_memory_signaling_bus.dart';
import 'package:pi_iv_time3/features/video_call/data/datasources/video_call_signaling_datasource.dart';
import 'package:pi_iv_time3/features/video_call/data/models/chat_message_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/emoji_reaction_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/participant_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/signaling_envelope_model.dart';
import 'package:pi_iv_time3/features/video_call/data/repositories/video_call_repository_impl.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/chat_message.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/emoji_reaction.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/meeting_room.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/participant.dart';

void main() {
  late InMemorySignalingBus bus;

  setUp(() {
    bus = InMemorySignalingBus();
    bus.reset();
  });

  tearDown(() {
    bus.reset();
  });

  group('Empirical Challenger M1-2: Stress & Hardening Test Suite', () {
    // -------------------------------------------------------------------------
    // OBJECTIVE 1: LIVENESS HEARTBEAT & WATCHDOG PRUNING ON SILENCE (CRASH/FREEZE)
    // -------------------------------------------------------------------------
    test(
      'Watchdog Pruning: Detects heartbeat silence after 5.0s and prunes crashed peer',
      () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p1 = ParticipantModel(
          id: 'peer_1',
          name: 'Alex Sousa',
          ra: '24802449',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );

        await ds1.connect(roomId: 'WATCHDOG-ROOM-1', localParticipant: p1);

        final leftPeers = <String>[];
        final leftSub = ds1.onParticipantLeft.listen(leftPeers.add);

        // Simulamos um peer secundário conectando via canal de sinalização direto
        final rawChannel = InMemorySignalingChannel(
          'p2p_videocall_WATCHDOG-ROOM-1',
          bus,
        );

        final crashedPeerJoin = SignalingEnvelopeModel.create(
          type: SignalingEnvelopeType.join,
          roomId: 'WATCHDOG-ROOM-1',
          senderId: 'peer_crashed',
          senderName: 'Frozen Browser Tab',
          payload: {
            'id': 'peer_crashed',
            'name': 'Frozen Browser Tab',
            'ra': '99999999',
            'isAudioMuted': false,
            'isVideoOff': false,
            'isScreenSharing': false,
            'isHandRaised': false,
            'audioLevel': 0.0,
          },
        );

        // Também conectamos um peer saudável que continuará enviando batimentos
        final healthyPeerJoin = SignalingEnvelopeModel.create(
          type: SignalingEnvelopeType.join,
          roomId: 'WATCHDOG-ROOM-1',
          senderId: 'peer_healthy',
          senderName: 'Active Healthy Peer',
          payload: {
            'id': 'peer_healthy',
            'name': 'Active Healthy Peer',
            'ra': '88888888',
          },
        );

        await rawChannel.send(crashedPeerJoin.toRawJson());
        await rawChannel.send(healthyPeerJoin.toRawJson());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Ambos os nós foram descobertos
        expect(ds1.remoteParticipants.length, equals(2));
        expect(ds1.remoteParticipants.any((p) => p.id == 'peer_crashed'), isTrue);
        expect(ds1.remoteParticipants.any((p) => p.id == 'peer_healthy'), isTrue);
        expect(leftPeers, isEmpty);

        // Loop de batimento para o peer saudável enquanto o crashed peer congela (sem heartbeats)
        final healthyHeartbeatTimer = Timer.periodic(
          const Duration(milliseconds: 1500),
          (_) {
            final heartbeat = SignalingEnvelopeModel.create(
              type: SignalingEnvelopeType.heartbeat,
              roomId: 'WATCHDOG-ROOM-1',
              senderId: 'peer_healthy',
              senderName: 'Active Healthy Peer',
              payload: {
                'peerId': 'peer_healthy',
                'audioLevel': 0.10,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
            );
            rawChannel.send(heartbeat.toRawJson());
          },
        );

        // Ponto de checagem intermediário: aos 3.0s (antes do timeout de 5.0s)
        await Future<void>.delayed(const Duration(milliseconds: 3000));
        expect(
          ds1.remoteParticipants.any((p) => p.id == 'peer_crashed'),
          isTrue,
          reason: 'Peer não deve ser podado antes dos 5.0s de inatividade',
        );
        expect(leftPeers, isEmpty);

        // Aguarda transcorrer a janela total para que o watchdog de 1.0s detecte o timeout de 5.0s
        // (3000ms já transcorridos + 3300ms = 6300ms > 5000ms threshold + 1000ms watchdog tick)
        await Future<void>.delayed(const Duration(milliseconds: 3300));

        healthyHeartbeatTimer.cancel();

        // Verificação final do Watchdog:
        // 1. O nó travado deve ter sido podado de remoteParticipants
        expect(
          ds1.remoteParticipants.any((p) => p.id == 'peer_crashed'),
          isFalse,
          reason: 'Crashed peer deve ter sido podado após 5.0s de silêncio de heartbeat',
        );
        // 2. Evento de saída emitido
        expect(
          leftPeers,
          contains('peer_crashed'),
          reason: 'Stream onParticipantLeft deve notificar poda do peer_crashed',
        );
        // 3. O nó saudável NÃO deve ter sido podado, pois enviou heartbeats regulares
        expect(
          ds1.remoteParticipants.any((p) => p.id == 'peer_healthy'),
          isTrue,
          reason: 'Peer saudável que enviou heartbeats deve permanecer conectado',
        );
        expect(leftPeers.contains('peer_healthy'), isFalse);

        await leftSub.cancel();
        await rawChannel.close();
        ds1.dispose();
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    // -------------------------------------------------------------------------
    // OBJECTIVE 2: RAPID BURST MESSAGES (100 CHAT + 50 EMOJI REACTIONS)
    // -------------------------------------------------------------------------
    test(
      'Burst Testing: 100 rapid chat messages with zero loss and strict FIFO ordering',
      () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p1 = ParticipantModel(
          id: 'peer_1',
          name: 'Alex Sousa',
          ra: '24802449',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );
        final p2 = ParticipantModel(
          id: 'peer_2',
          name: 'Beatriz Lima',
          ra: '24801122',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );

        await ds1.connect(roomId: 'BURST-CHAT-ROOM', localParticipant: p1);
        await ds2.connect(roomId: 'BURST-CHAT-ROOM', localParticipant: p2);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final receivedChats = <ChatMessageModel>[];
        final ds1EchoChats = <ChatMessageModel>[];

        final sub2 = ds2.onChatMessage.listen(receivedChats.add);
        final sub1 = ds1.onChatMessage.listen(ds1EchoChats.add);

        const totalMessages = 100;

        // Disparo sequencial ultra-rápido de 100 mensagens
        for (int i = 0; i < totalMessages; i++) {
          final chat = ChatMessageModel(
            id: 'burst_msg_$i',
            senderId: 'peer_1',
            senderName: 'Alex Sousa',
            senderRa: '24802449',
            text: 'Burst message seq: $i',
            timestamp: 1729000000000 + i,
          );
          await ds1.broadcastChatMessage('BURST-CHAT-ROOM', chat);
        }

        // Aguarda vazão completa pelo barramento
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Verificação 1: Zero perda de mensagens (exatamente 100 recebidas)
        expect(
          receivedChats.length,
          equals(totalMessages),
          reason: 'Todas as 100 mensagens devem ser entregues sem perda',
        );

        // Verificação 2: Ordenação estrita FIFO (0 a 99)
        for (int i = 0; i < totalMessages; i++) {
          expect(receivedChats[i].id, equals('burst_msg_$i'));
          expect(receivedChats[i].text, equals('Burst message seq: $i'));
          expect(receivedChats[i].timestamp, equals(1729000000000 + i));
        }

        // Verificação 3: Supressão de eco (emissor não recebe suas próprias mensagens)
        expect(
          ds1EchoChats,
          isEmpty,
          reason: 'Invariante W3C: emissor não deve receber eco próprio',
        );

        await sub1.cancel();
        await sub2.cancel();
        ds1.dispose();
        ds2.dispose();
      },
    );

    test(
      'Burst Testing: 50 rapid emoji reactions with zero loss and rotation sequence preservation',
      () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p1 = ParticipantModel(
          id: 'peer_1',
          name: 'Alex Sousa',
          ra: '24802449',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );
        final p2 = ParticipantModel(
          id: 'peer_2',
          name: 'Beatriz Lima',
          ra: '24801122',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );

        await ds1.connect(roomId: 'BURST-EMOJI-ROOM', localParticipant: p1);
        await ds2.connect(roomId: 'BURST-EMOJI-ROOM', localParticipant: p2);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final receivedEmojis = <EmojiReactionModel>[];
        final ds1EchoEmojis = <EmojiReactionModel>[];

        final sub2 = ds2.onEmojiReaction.listen(receivedEmojis.add);
        final sub1 = ds1.onEmojiReaction.listen(ds1EchoEmojis.add);

        const officialEmojis = ['❤️', '👍', '👏', '😂', '😮', '🎉'];
        const totalEmojis = 50;

        for (int i = 0; i < totalEmojis; i++) {
          final emoji = officialEmojis[i % officialEmojis.length];
          final reaction = EmojiReactionModel(
            id: 'burst_emoji_$i',
            senderId: 'peer_1',
            senderName: 'Alex Sousa',
            emoji: emoji,
            timestamp: 1729100000000 + i,
          );
          await ds1.broadcastEmojiReaction('BURST-EMOJI-ROOM', reaction);
        }

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Verificação 1: Zero perda de reações
        expect(
          receivedEmojis.length,
          equals(totalEmojis),
          reason: 'Todas as 50 reações de emoji devem ser recebidas',
        );

        // Verificação 2: Preservação de sequência e integridade de conteúdo
        for (int i = 0; i < totalEmojis; i++) {
          final expectedEmoji = officialEmojis[i % officialEmojis.length];
          expect(receivedEmojis[i].id, equals('burst_emoji_$i'));
          expect(receivedEmojis[i].emoji, equals(expectedEmoji));
          expect(receivedEmojis[i].timestamp, equals(1729100000000 + i));
        }

        // Verificação 3: Supressão de eco
        expect(ds1EchoEmojis, isEmpty);

        await sub1.cancel();
        await sub2.cancel();
        ds1.dispose();
        ds2.dispose();
      },
    );

    test(
      'Burst Testing: Concurrent interleaved 100 chats + 50 emojis simultaneously',
      () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p1 = ParticipantModel(
          id: 'peer_1',
          name: 'Alex Sousa',
          ra: '24802449',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );
        final p2 = ParticipantModel(
          id: 'peer_2',
          name: 'Beatriz Lima',
          ra: '24801122',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );

        await ds1.connect(roomId: 'INTERLEAVED-BURST-ROOM', localParticipant: p1);
        await ds2.connect(roomId: 'INTERLEAVED-BURST-ROOM', localParticipant: p2);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        final receivedChats = <ChatMessageModel>[];
        final receivedEmojis = <EmojiReactionModel>[];

        final subChat = ds2.onChatMessage.listen(receivedChats.add);
        final subEmoji = ds2.onEmojiReaction.listen(receivedEmojis.add);

        // Dispara simultaneamente via Future.wait
        final chatFutures = List.generate(100, (i) {
          return ds1.broadcastChatMessage(
            'INTERLEAVED-BURST-ROOM',
            ChatMessageModel(
              id: 'inter_chat_$i',
              senderId: 'peer_1',
              senderName: 'Alex Sousa',
              senderRa: '24802449',
              text: 'Interleaved chat #$i',
              timestamp: 1000 + i,
            ),
          );
        });

        final emojiFutures = List.generate(50, (i) {
          return ds1.broadcastEmojiReaction(
            'INTERLEAVED-BURST-ROOM',
            EmojiReactionModel(
              id: 'inter_emoji_$i',
              senderId: 'peer_1',
              senderName: 'Alex Sousa',
              emoji: '🎉',
              timestamp: 2000 + i,
            ),
          );
        });

        await Future.wait([...chatFutures, ...emojiFutures]);
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(receivedChats.length, equals(100));
        expect(receivedEmojis.length, equals(50));

        await subChat.cancel();
        await subEmoji.cancel();
        ds1.dispose();
        ds2.dispose();
      },
    );

    // -------------------------------------------------------------------------
    // OBJECTIVE 3: MALFORMED JSON, UNKNOWN ENVELOPES & ADVERSARIAL ATTACKS
    // -------------------------------------------------------------------------
    test(
      'Robustness: Malformed JSON and unknown envelopes do not crash datasource or disconnect peers',
      () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p1 = ParticipantModel(
          id: 'peer_1',
          name: 'Alex Sousa',
          ra: '24802449',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );
        final p2 = ParticipantModel(
          id: 'peer_2',
          name: 'Beatriz Lima',
          ra: '24801122',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );

        await ds1.connect(roomId: 'ATTACK-ROOM-1', localParticipant: p1);
        await ds2.connect(roomId: 'ATTACK-ROOM-1', localParticipant: p2);
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Confirma estado inicial conectado
        expect(ds1.remoteParticipants.length, equals(1));
        expect(ds2.remoteParticipants.length, equals(1));

        final leftEventsOnDs2 = <String>[];
        final leftSub = ds2.onParticipantLeft.listen(leftEventsOnDs2.add);

        // Canal adversário que injetará lixo na sala
        final attacker = InMemorySignalingChannel(
          'p2p_videocall_ATTACK-ROOM-1',
          bus,
        );

        // Bateria de envelopes corrompidos, inválidos e malformados
        final corruptedPayloads = <String>[
          // 1. Strings não-JSON
          '',
          '   ',
          'NOT_JSON_DATA_STRING',
          '{unclosed: json, bracket',
          '<xml><attack>true</attack></xml>',
          'NaN',
          'null',
          'undefined',
          '123456789',
          '"valid json string but not an object"',
          '[1, 2, 3, "array instead of map"]',

          // 2. JSON sem schema obrigatório
          '{}',
          '{"foo": "bar"}',
          jsonEncode({'roomId': 'ATTACK-ROOM-1'}),
          jsonEncode({'type': 'chat'}),

          // 3. Tipos primitivos conflitantes
          jsonEncode({'type': 1234, 'roomId': 'ATTACK-ROOM-1'}),
          jsonEncode({'type': 'chat', 'roomId': 9999}),
          jsonEncode({'type': 'chat', 'roomId': 'ATTACK-ROOM-1', 'timestamp': 'NOT_A_TIMESTAMP'}),
          jsonEncode({'type': 'chat', 'roomId': 'ATTACK-ROOM-1', 'payload': 'STRING_NOT_MAP'}),

          // 4. Injeção de sala alheia
          jsonEncode({
            'protocol': 'p2p_videocall_v1',
            'type': 'chat',
            'roomId': 'OTHER_ROOM_INJECTION',
            'senderId': 'hacker',
            'senderName': 'Hacker',
            'timestamp': 1000,
            'payload': {'text': 'should be discarded'},
          }),

          // 5. Impersonação de remetente local
          jsonEncode({
            'protocol': 'p2p_videocall_v1',
            'type': 'chat',
            'roomId': 'ATTACK-ROOM-1',
            'senderId': 'peer_2', // enviando com ID do ds2 para tentar confundi-lo
            'senderName': 'Beatriz Fake',
            'timestamp': 1000,
            'payload': {'text': 'spoofed echo'},
          }),

          // 6. Tipos de envelope desconhecidos ou hostis
          jsonEncode({
            'protocol': 'p2p_videocall_v1',
            'type': 'ADMIN_NUKE_ALL',
            'roomId': 'ATTACK-ROOM-1',
            'senderId': 'hacker',
            'senderName': 'Hacker',
            'timestamp': 1000,
            'payload': {'action': 'drop_all'},
          }),
          jsonEncode({
            'protocol': 'p2p_videocall_v1',
            'type': '__proto__',
            'roomId': 'ATTACK-ROOM-1',
            'senderId': 'hacker',
            'senderName': 'Hacker',
            'timestamp': 1000,
            'payload': {'pollute': true},
          }),
          jsonEncode({
            'protocol': 'p2p_videocall_v1',
            'type': 'custom_unrecognized_feature',
            'roomId': 'ATTACK-ROOM-1',
            'senderId': 'hacker',
            'senderName': 'Hacker',
            'timestamp': 1000,
            'payload': {'data': 'unknown'},
          }),

          // 7. Payload de heartbeat com tipos corrompidos
          jsonEncode({
            'protocol': 'p2p_videocall_v1',
            'type': 'heartbeat',
            'roomId': 'ATTACK-ROOM-1',
            'senderId': 'peer_1',
            'senderName': 'Alex Sousa',
            'timestamp': 1000,
            'payload': {
              'audioLevel': 'THIS_IS_NOT_A_NUM',
              'isAudioMuted': 'NOT_A_BOOL',
            },
          }),

          // 8. Carga útil massiva (50KB)
          jsonEncode({
            'protocol': 'p2p_videocall_v1',
            'type': 'custom_large',
            'roomId': 'ATTACK-ROOM-1',
            'senderId': 'hacker',
            'senderName': 'Hacker',
            'timestamp': 1000,
            'payload': {'huge': 'A' * 50000},
          }),
        ];

        // Injeta todas as 25+ mensagens adversárias sequencialmente
        for (final badPayload in corruptedPayloads) {
          await attacker.send(badPayload);
        }

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Verificação 1: Nenhum nó legítimo foi desconectado
        expect(
          ds1.remoteParticipants.length,
          equals(1),
          reason: 'ds1 não deve perder peer_2 por causa de pacotes corrompidos',
        );
        expect(
          ds2.remoteParticipants.length,
          equals(1),
          reason: 'ds2 não deve perder peer_1 por causa de pacotes corrompidos',
        );
        expect(
          leftEventsOnDs2,
          isEmpty,
          reason: 'Nenhum evento onParticipantLeft espúrio deve ter sido disparado',
        );

        // Verificação 2: O barramento e os datasources continuam funcionando normalmente
        ChatMessageModel? postAttackChat;
        final validChatSub = ds2.onChatMessage.listen((c) => postAttackChat = c);

        await ds1.broadcastChatMessage(
          'ATTACK-ROOM-1',
          const ChatMessageModel(
            id: 'post_attack_msg',
            senderId: 'peer_1',
            senderName: 'Alex Sousa',
            senderRa: '24802449',
            text: 'Sistema sobreviveu ao ataque perfeitamente!',
            timestamp: 1729169999000,
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          postAttackChat,
          isNotNull,
          reason: 'Mensagem válida subsequente deve ser entregue após ataques malformados',
        );
        expect(
          postAttackChat!.text,
          equals('Sistema sobreviveu ao ataque perfeitamente!'),
        );

        await validChatSub.cancel();
        await leftSub.cancel();
        await attacker.close();
        ds1.dispose();
        ds2.dispose();
      },
    );

    // -------------------------------------------------------------------------
    // INTEGRATION VERIFICATION: REPOSITORY LAYER STRESS & USECASE RESILIENCE
    // -------------------------------------------------------------------------
    test(
      'Repository Layer Integration: Burst & Handshake through VideoCallRepositoryImpl',
      () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final repo1 = VideoCallRepositoryImpl(dataSource: ds1);
        final repo2 = VideoCallRepositoryImpl(dataSource: ds2);

        final p1 = Participant(id: 'peer_1', name: 'Alex Sousa', ra: '24802449');
        final p2 = Participant(id: 'peer_2', name: 'Beatriz Lima', ra: '24801122');
        final room = MeetingRoom(id: 'REPO-STRESS-1', title: 'Stress Test Room');

        final repo2Chats = <ChatMessage>[];
        final repo2Emojis = <EmojiReaction>[];
        final subChat = repo2.chatMessageStream.listen(repo2Chats.add);
        final subEmoji = repo2.emojiReactionStream.listen(repo2Emojis.add);

        await repo1.joinRoom(room, p1);
        await repo2.joinRoom(room, p2);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // 100 mensagens e 50 reações através do repositório
        for (int i = 0; i < 100; i++) {
          await repo1.sendChatMessage(
            'REPO-STRESS-1',
            ChatMessage(
              id: 'repo_chat_$i',
              senderId: 'peer_1',
              senderName: 'Alex Sousa',
              senderRa: '24802449',
              text: 'Repo message $i',
              timestamp: DateTime.fromMillisecondsSinceEpoch(1000 + i),
            ),
          );
        }

        for (int i = 0; i < 50; i++) {
          await repo1.sendEmojiReaction(
            'REPO-STRESS-1',
            EmojiReaction(
              id: 'repo_emoji_$i',
              senderId: 'peer_1',
              senderName: 'Alex Sousa',
              emoji: '👍',
              timestamp: DateTime.fromMillisecondsSinceEpoch(2000 + i),
            ),
          );
        }

        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(repo2Chats.length, equals(100));
        expect(repo2Emojis.length, equals(50));
        expect(repo2Chats.first.text, equals('Repo message 0'));
        expect(repo2Chats.last.text, equals('Repo message 99'));

        await subChat.cancel();
        await subEmoji.cancel();
        await repo1.dispose();
        await repo2.dispose();
      },
    );

    // -------------------------------------------------------------------------
    // OBJECTIVE 4: ACTIVE SPEAKER DETECTION & MUTE INVARIANT VIA HEARTBEAT
    // -------------------------------------------------------------------------
    test(
      'Audio & Speaker Invariant: isSpeaking is strictly false when muted and respects 0.15 threshold',
      () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final rawChannel = InMemorySignalingChannel(
          'p2p_videocall_AUDIO-ROOM-1',
          bus,
        );

        final p1 = ParticipantModel(
          id: 'peer_1',
          name: 'Alex Sousa',
          ra: '24802449',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );

        await ds1.connect(roomId: 'AUDIO-ROOM-1', localParticipant: p1);

        // Join peer_speaker
        final joinEnvelope = SignalingEnvelopeModel.create(
          type: SignalingEnvelopeType.join,
          roomId: 'AUDIO-ROOM-1',
          senderId: 'peer_speaker',
          senderName: 'Carlos Silva',
          payload: {
            'id': 'peer_speaker',
            'name': 'Carlos Silva',
            'ra': '24803333',
            'isAudioMuted': false,
            'audioLevel': 0.0,
          },
        );
        await rawChannel.send(joinEnvelope.toRawJson());
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(ds1.remoteParticipants.first.isSpeaking, isFalse);

        // Sub-scenario A: Volume 0.15 (limiar exato) com mic aberto -> NÃO falando (>0.15 requerido)
        final hbThreshold = SignalingEnvelopeModel.create(
          type: SignalingEnvelopeType.heartbeat,
          roomId: 'AUDIO-ROOM-1',
          senderId: 'peer_speaker',
          senderName: 'Carlos Silva',
          payload: {
            'peerId': 'peer_speaker',
            'audioLevel': 0.15,
            'isAudioMuted': false,
          },
        );
        await rawChannel.send(hbThreshold.toRawJson());
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(
          ds1.remoteParticipants.first.isSpeaking,
          isFalse,
          reason: 'No limiar exato de 0.15, isSpeaking deve ser false',
        );

        // Sub-scenario B: Volume 0.16 com mic aberto -> FALANDO (ultrapassou 0.15)
        final hbSpeaking = SignalingEnvelopeModel.create(
          type: SignalingEnvelopeType.heartbeat,
          roomId: 'AUDIO-ROOM-1',
          senderId: 'peer_speaker',
          senderName: 'Carlos Silva',
          payload: {
            'peerId': 'peer_speaker',
            'audioLevel': 0.16,
            'isAudioMuted': false,
          },
        );
        await rawChannel.send(hbSpeaking.toRawJson());
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(
          ds1.remoteParticipants.first.isSpeaking,
          isTrue,
          reason: 'Acima de 0.15 com mic desmutado, isSpeaking deve ser true',
        );

        // Sub-scenario C: Volume alto (0.85), mas com mic MUTADO -> NUNCA falando
        final hbMutedHigh = SignalingEnvelopeModel.create(
          type: SignalingEnvelopeType.heartbeat,
          roomId: 'AUDIO-ROOM-1',
          senderId: 'peer_speaker',
          senderName: 'Carlos Silva',
          payload: {
            'peerId': 'peer_speaker',
            'audioLevel': 0.85,
            'isAudioMuted': true,
          },
        );
        await rawChannel.send(hbMutedHigh.toRawJson());
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(
          ds1.remoteParticipants.first.isSpeaking,
          isFalse,
          reason: 'Invariante estrito: participante mutado NUNCA deve ser considerado speaking',
        );

        await rawChannel.close();
        ds1.dispose();
      },
    );

    // -------------------------------------------------------------------------
    // OBJECTIVE 5: RECONNECTION CHURN STRESS
    // -------------------------------------------------------------------------
    test(
      'Reconnection Churn: 10 consecutive connect/disconnect cycles leave no zombie timers or state corruption',
      () async {
        final ds = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p = ParticipantModel(
          id: 'churn_peer',
          name: 'Churn Tester',
          ra: '24802449',
          lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
        );

        for (int i = 0; i < 10; i++) {
          await ds.connect(roomId: 'CHURN-ROOM', localParticipant: p);
          expect(ds.remoteParticipants, isEmpty);
          await ds.disconnect();
          expect(ds.remoteParticipants, isEmpty);
        }

        // Reconecta uma 11ª vez e verifica que funciona perfeitamente
        await ds.connect(roomId: 'CHURN-ROOM', localParticipant: p);

        final peer2 = InMemorySignalingChannel('p2p_videocall_CHURN-ROOM', bus);
        final join2 = SignalingEnvelopeModel.create(
          type: SignalingEnvelopeType.join,
          roomId: 'CHURN-ROOM',
          senderId: 'peer_after_churn',
          senderName: 'Stable Peer',
          payload: {
            'id': 'peer_after_churn',
            'name': 'Stable Peer',
            'ra': '24809999',
          },
        );
        await peer2.send(join2.toRawJson());
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(ds.remoteParticipants.length, equals(1));
        expect(ds.remoteParticipants.first.id, equals('peer_after_churn'));

        await peer2.close();
        ds.dispose();
      },
    );

    // -------------------------------------------------------------------------
    // OBJECTIVE 6: ROOM CODE NORMALIZATION & CROSS-ROOM ISOLATION
    // -------------------------------------------------------------------------
    test(
      'Room Isolation & Normalization: lowercase and whitespace room codes match; cross-room traffic ignored',
      () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p1 = ParticipantModel(id: 'peer_1', name: 'Alex', ra: '24802449', lastHeartbeat: 0);
        final p2 = ParticipantModel(id: 'peer_2', name: 'Beatriz', ra: '24801122', lastHeartbeat: 0);

        // ds1 usa 'sala-alpha' minúsculo
        await ds1.connect(roomId: 'sala-alpha', localParticipant: p1);
        // ds2 usa '  SALA-ALPHA  ' com espaços e maiúsculo
        await ds2.connect(roomId: '  SALA-ALPHA  ', localParticipant: p2);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Ambos devem ter normalizado para 'SALA-ALPHA' e se conectado mutuamente
        expect(ds1.remoteParticipants.length, equals(1));
        expect(ds1.remoteParticipants.first.id, equals('peer_2'));
        expect(ds2.remoteParticipants.length, equals(1));
        expect(ds2.remoteParticipants.first.id, equals('peer_1'));

        // Canal em outra sala despacha chat
        final otherRoomChannel = InMemorySignalingChannel('p2p_videocall_OTHER-ROOM', bus);
        final crossRoomChat = SignalingEnvelopeModel.create(
          type: SignalingEnvelopeType.chat,
          roomId: 'OTHER-ROOM',
          senderId: 'intruder',
          senderName: 'Intruder',
          payload: {'id': 'x1', 'senderId': 'intruder', 'text': 'cross-room leak!'},
        );

        ChatMessageModel? ds1ReceivedChat;
        final sub = ds1.onChatMessage.listen((c) => ds1ReceivedChat = c);

        await otherRoomChannel.send(crossRoomChat.toRawJson());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          ds1ReceivedChat,
          isNull,
          reason: 'Mensagens de salas distintas NUNCA devem vazar para SALA-ALPHA',
        );

        await sub.cancel();
        await otherRoomChannel.close();
        ds1.dispose();
        ds2.dispose();
      },
    );

    // -------------------------------------------------------------------------
    // OBJECTIVE 7: ABRUPT BROWSER TEARDOWN HOOK DISPATCHES LEAVE
    // -------------------------------------------------------------------------
    test(
      'Teardown Hook: simulateTeardown broadcasts LEAVE envelope synchronously',
      () async {
        late InMemorySignalingChannel ds2Channel;
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) {
            ds2Channel = InMemorySignalingChannel(name, bus);
            return ds2Channel;
          },
        );

        final p1 = ParticipantModel(id: 'peer_1', name: 'Alex', ra: '24802449', lastHeartbeat: 0);
        final p2 = ParticipantModel(id: 'peer_2', name: 'Beatriz', ra: '24801122', lastHeartbeat: 0);

        await ds1.connect(roomId: 'TEARDOWN-ROOM', localParticipant: p1);
        await ds2.connect(roomId: 'TEARDOWN-ROOM', localParticipant: p2);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ds1.remoteParticipants.length, equals(1));

        final leftPeersOnDs1 = <String>[];
        final leftSub = ds1.onParticipantLeft.listen(leftPeersOnDs1.add);

        // Simula o evento pagehide / beforeunload do navegador na aba do ds2
        ds2Channel.simulateTeardown();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          leftPeersOnDs1,
          contains('peer_2'),
          reason: 'simulateTeardown deve disparar o broadcastLeaveSync e notificar ds1',
        );
        expect(ds1.remoteParticipants, isEmpty);

        await leftSub.cancel();
        ds1.dispose();
        ds2.dispose();
      },
    );
  });
}
