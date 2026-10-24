// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/data/channel/in_memory_signaling_bus.dart';
import 'package:pi_iv_time3/features/video_call/data/datasources/video_call_signaling_datasource.dart';
import 'package:pi_iv_time3/features/video_call/data/models/chat_message_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/emoji_reaction_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/participant_model.dart';
import 'package:pi_iv_time3/features/video_call/data/repositories/video_call_repository_impl.dart';
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

  ParticipantModel makeParticipantModel({
    required String id,
    required String name,
    required String ra,
    String role = 'student',
  }) {
    return ParticipantModel(
      id: id,
      name: name,
      ra: ra,
      role: role,
      lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Participant makeParticipantEntity({
    required String id,
    required String name,
    required String ra,
    String role = 'student',
  }) {
    return Participant(
      id: id,
      name: name,
      ra: ra,
      role: role,
    );
  }

  group('Milestone 1 Empirical Stress Harness: Zero-Bot & P2P Transport', () {
    // -------------------------------------------------------------------------
    // Invariant 1: 1 peer alone in a room receives 0 remote discovery events
    // -------------------------------------------------------------------------
    group('Invariant 1: Solitary Peer receives 0 remote discovery events', () {
      test('Single peer joining SALA-101 produces exactly ZERO remote discovery events', () async {
        final ds = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final receivedPeers = <ParticipantModel>[];
        final sub = ds.onParticipantJoined.listen(receivedPeers.add);

        final p1 = makeParticipantModel(id: 'peer_solo', name: 'Alex Sousa', ra: '24802449');
        await ds.connect(roomId: 'SALA-101', localParticipant: p1);

        // Aguarda estabilização e verifica ausência de eventos
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(ds.remoteParticipants, isEmpty, reason: 'Remote participants list MUST remain strictly empty');
        expect(receivedPeers, isEmpty, reason: 'Zero bot discovery events must be emitted');

        await sub.cancel();
        ds.dispose();
      });

      test('Solitary peer stays alone over heartbeat cycles with zero fake participants created', () async {
        final ds = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final receivedPeers = <ParticipantModel>[];
        final sub = ds.onParticipantJoined.listen(receivedPeers.add);

        final p1 = makeParticipantModel(id: 'peer_solo_hb', name: 'Alex Sousa', ra: '24802449');
        await ds.connect(roomId: 'SALA-101', localParticipant: p1);

        // Aguarda mais de 2 segundos para passar pelo ciclo de heartbeat
        await Future<void>.delayed(const Duration(milliseconds: 2200));

        expect(ds.remoteParticipants, isEmpty);
        expect(receivedPeers, isEmpty);

        await sub.cancel();
        ds.dispose();
      });

      test('VideoCallRepositoryImpl verifies solitary peer invariant at domain level', () async {
        final ds = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final repo = VideoCallRepositoryImpl(dataSource: ds);

        final domainDiscovered = <Participant>[];
        final sub = repo.participantJoinedStream.listen(domainDiscovered.add);

        final room = MeetingRoom(id: 'SALA-101', code: 'SALA-101', title: 'Sala 101');
        final local = makeParticipantEntity(id: 'peer_repo_solo', name: 'Alex Sousa', ra: '24802449');

        await repo.joinRoom(room, local);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(domainDiscovered, isEmpty);

        await sub.cancel();
        await repo.dispose();
      });
    });

    // -------------------------------------------------------------------------
    // Invariant 2: Reciprocal discovery via JOIN <-> PRESENCE_SYNC in < 50ms
    // -------------------------------------------------------------------------
    group('Invariant 2: Reciprocal Discovery Timing & Handshake (< 50ms)', () {
      test('Peer 1 and Peer 2 reciprocally discover each other in strictly < 50ms', () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p1 = makeParticipantModel(id: 'peer_1', name: 'Alex Sousa', ra: '24802449');
        final p2 = makeParticipantModel(id: 'peer_2', name: 'Beatriz Lima', ra: '24801122');

        await ds1.connect(roomId: 'SALA-101', localParticipant: p1);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final p1DiscoveredP2 = Completer<ParticipantModel>();
        final p2DiscoveredP1 = Completer<ParticipantModel>();

        final sub1 = ds1.onParticipantJoined.listen((p) {
          if (p.id == 'peer_2' && !p1DiscoveredP2.isCompleted) {
            p1DiscoveredP2.complete(p);
          }
        });

        final sub2 = ds2.onParticipantJoined.listen((p) {
          if (p.id == 'peer_1' && !p2DiscoveredP1.isCompleted) {
            p2DiscoveredP1.complete(p);
          }
        });

        final stopwatch = Stopwatch()..start();
        await ds2.connect(roomId: 'SALA-101', localParticipant: p2);

        await Future.wait([p1DiscoveredP2.future, p2DiscoveredP1.future]);
        stopwatch.stop();

        final elapsedMs = stopwatch.elapsedMilliseconds;
        // ignore: avoid_print
        print('Empirical reciprocal discovery latency: ${elapsedMs}ms');

        expect(elapsedMs, lessThan(50), reason: 'Reciprocal discovery must complete in < 50ms');

        final discoveredOn1 = await p1DiscoveredP2.future;
        final discoveredOn2 = await p2DiscoveredP1.future;

        expect(discoveredOn1.id, equals('peer_2'));
        expect(discoveredOn1.name, equals('Beatriz Lima'));
        expect(discoveredOn1.ra, equals('24801122'));

        expect(discoveredOn2.id, equals('peer_1'));
        expect(discoveredOn2.name, equals('Alex Sousa'));
        expect(discoveredOn2.ra, equals('24802449'));

        expect(ds1.remoteParticipants.length, equals(1));
        expect(ds2.remoteParticipants.length, equals(1));

        await sub1.cancel();
        await sub2.cancel();
        ds1.dispose();
        ds2.dispose();
      });

      test('Stress Benchmark: 25 sequential reciprocal handshakes consistently under 50ms', () async {
        final latencies = <int>[];

        for (int i = 0; i < 25; i++) {
          final busIter = InMemorySignalingBus();
          busIter.reset();

          final dsA = VideoCallSignalingDataSource(
            channelFactory: (name) => InMemorySignalingChannel(name, busIter),
          );
          final dsB = VideoCallSignalingDataSource(
            channelFactory: (name) => InMemorySignalingChannel(name, busIter),
          );

          final pa = makeParticipantModel(id: 'peer_a_$i', name: 'User A', ra: 'RA_$i');
          final pb = makeParticipantModel(id: 'peer_b_$i', name: 'User B', ra: 'RB_$i');

          await dsA.connect(roomId: 'SALA-BENCH', localParticipant: pa);

          final aDiscoveredB = Completer<void>();
          final bDiscoveredA = Completer<void>();

          final sA = dsA.onParticipantJoined.listen((p) {
            if (p.id == pb.id && !aDiscoveredB.isCompleted) aDiscoveredB.complete();
          });
          final sB = dsB.onParticipantJoined.listen((p) {
            if (p.id == pa.id && !bDiscoveredA.isCompleted) bDiscoveredA.complete();
          });

          final sw = Stopwatch()..start();
          await dsB.connect(roomId: 'SALA-BENCH', localParticipant: pb);
          await Future.wait([aDiscoveredB.future, bDiscoveredA.future]);
          sw.stop();

          latencies.add(sw.elapsedMilliseconds);

          await sA.cancel();
          await sB.cancel();
          dsA.dispose();
          dsB.dispose();
          busIter.reset();
        }

        final maxLatency = latencies.reduce((a, b) => a > b ? a : b);
        final avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;
        // ignore: avoid_print
        print('25 iterations benchmark -> Max: ${maxLatency}ms, Avg: ${avgLatency.toStringAsFixed(2)}ms');

        expect(maxLatency, lessThan(50), reason: 'Every single reciprocal handshake must execute in < 50ms');
      });
    });

    // -------------------------------------------------------------------------
    // Invariant 3: 3 peers connect -> all 3 see each other (Full-Mesh N*(N-1))
    // -------------------------------------------------------------------------
    group('Invariant 3: 3-Peer Full-Mesh Topology Dynamic Discovery', () {
      test('When Peer 3 connects, all 3 peers discover each other', () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds3 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p1 = makeParticipantModel(id: 'p1', name: 'Alex', ra: '24802449');
        final p2 = makeParticipantModel(id: 'p2', name: 'Beatriz', ra: '24801122');
        final p3 = makeParticipantModel(id: 'p3', name: 'Carlos', ra: '24803344');

        final p1Joined = <String>{};
        final p2Joined = <String>{};
        final p3Joined = <String>{};

        final s1 = ds1.onParticipantJoined.listen((p) => p1Joined.add(p.id));
        final s2 = ds2.onParticipantJoined.listen((p) => p2Joined.add(p.id));
        final s3 = ds3.onParticipantJoined.listen((p) => p3Joined.add(p.id));

        // Ingressam Sequencialmente
        await ds1.connect(roomId: 'SALA-101', localParticipant: p1);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await ds2.connect(roomId: 'SALA-101', localParticipant: p2);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await ds3.connect(roomId: 'SALA-101', localParticipant: p3);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Verificação da malha P2P recíproca completa
        expect(ds1.remoteParticipants.map((p) => p.id).toSet(), equals({'p2', 'p3'}));
        expect(ds2.remoteParticipants.map((p) => p.id).toSet(), equals({'p1', 'p3'}));
        expect(ds3.remoteParticipants.map((p) => p.id).toSet(), equals({'p1', 'p2'}));

        expect(p1Joined, equals({'p2', 'p3'}));
        expect(p2Joined, equals({'p1', 'p3'}));
        expect(p3Joined, equals({'p1', 'p2'}));

        await s1.cancel();
        await s2.cancel();
        await s3.cancel();
        ds1.dispose();
        ds2.dispose();
        ds3.dispose();
      });

      test('Concurrent Join: Peer 2 and Peer 3 connect simultaneously into room', () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds3 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p1 = makeParticipantModel(id: 'peer_c1', name: 'Alex', ra: '24802449');
        final p2 = makeParticipantModel(id: 'peer_c2', name: 'Beatriz', ra: '24801122');
        final p3 = makeParticipantModel(id: 'peer_c3', name: 'Carlos', ra: '24803344');

        await ds1.connect(roomId: 'SALA-101', localParticipant: p1);

        // Conecta P2 e P3 concorrentemente
        await Future.wait([
          ds2.connect(roomId: 'SALA-101', localParticipant: p2),
          ds3.connect(roomId: 'SALA-101', localParticipant: p3),
        ]);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ds1.remoteParticipants.length, equals(2));
        expect(ds2.remoteParticipants.length, equals(2));
        expect(ds3.remoteParticipants.length, equals(2));

        expect(ds1.remoteParticipants.map((p) => p.id).toSet(), equals({'peer_c2', 'peer_c3'}));
        expect(ds2.remoteParticipants.map((p) => p.id).toSet(), equals({'peer_c1', 'peer_c3'}));
        expect(ds3.remoteParticipants.map((p) => p.id).toSet(), equals({'peer_c1', 'peer_c2'}));

        ds1.dispose();
        ds2.dispose();
        ds3.dispose();
      });
    });

    // -------------------------------------------------------------------------
    // Invariant 4: Peer 2 leaves -> Peer 1 and Peer 3 receive leave event immediately
    // -------------------------------------------------------------------------
    group('Invariant 4: Immediate Leave Event Propagation', () {
      test('When Peer 2 leaves, both Peer 1 and Peer 3 receive onParticipantLeft immediately', () async {
        final ds1 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds2 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final ds3 = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final p1 = makeParticipantModel(id: 'p1', name: 'Alex', ra: '24802449');
        final p2 = makeParticipantModel(id: 'p2', name: 'Beatriz', ra: '24801122');
        final p3 = makeParticipantModel(id: 'p3', name: 'Carlos', ra: '24803344');

        await ds1.connect(roomId: 'SALA-101', localParticipant: p1);
        await ds2.connect(roomId: 'SALA-101', localParticipant: p2);
        await ds3.connect(roomId: 'SALA-101', localParticipant: p3);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ds1.remoteParticipants.length, equals(2));
        expect(ds3.remoteParticipants.length, equals(2));

        final p1SawLeave = Completer<String>();
        final p3SawLeave = Completer<String>();

        final s1 = ds1.onParticipantLeft.listen((leftId) {
          if (leftId == 'p2' && !p1SawLeave.isCompleted) p1SawLeave.complete(leftId);
        });
        final s3 = ds3.onParticipantLeft.listen((leftId) {
          if (leftId == 'p2' && !p3SawLeave.isCompleted) p3SawLeave.complete(leftId);
        });

        final sw = Stopwatch()..start();
        await ds2.disconnect();

        await Future.wait([p1SawLeave.future, p3SawLeave.future]);
        sw.stop();

        final leaveMs = sw.elapsedMilliseconds;
        // ignore: avoid_print
        print('Empirical leave propagation latency: ${leaveMs}ms');

        expect(leaveMs, lessThan(50), reason: 'Leave notification must be received immediately (< 50ms)');
        expect(await p1SawLeave.future, equals('p2'));
        expect(await p3SawLeave.future, equals('p2'));

        // Validação da lista de remotos podada
        expect(ds1.remoteParticipants.map((p) => p.id).toList(), equals(['p3']));
        expect(ds3.remoteParticipants.map((p) => p.id).toList(), equals(['p1']));
        expect(ds2.remoteParticipants, isEmpty);

        await s1.cancel();
        await s3.cancel();
        ds1.dispose();
        ds2.dispose();
        ds3.dispose();
      });

      test('Simulated abrupt tab closing triggers teardown hook and dispatches LEAVE immediately', () async {
        final channel1 = InMemorySignalingChannel('p2p_videocall_SALA-101', bus);
        final channel2 = InMemorySignalingChannel('p2p_videocall_SALA-101', bus);
        final channel3 = InMemorySignalingChannel('p2p_videocall_SALA-101', bus);

        final ds1 = VideoCallSignalingDataSource();
        final ds2 = VideoCallSignalingDataSource();
        final ds3 = VideoCallSignalingDataSource();

        final p1 = makeParticipantModel(id: 'p1', name: 'Alex', ra: '24802449');
        final p2 = makeParticipantModel(id: 'p2', name: 'Beatriz', ra: '24801122');
        final p3 = makeParticipantModel(id: 'p3', name: 'Carlos', ra: '24803344');

        await ds1.connect(roomId: 'SALA-101', localParticipant: p1, customChannel: channel1);
        await ds2.connect(roomId: 'SALA-101', localParticipant: p2, customChannel: channel2);
        await ds3.connect(roomId: 'SALA-101', localParticipant: p3, customChannel: channel3);
        await Future<void>.delayed(const Duration(milliseconds: 40));

        final p1Received = Completer<String>();
        final p3Received = Completer<String>();

        final s1 = ds1.onParticipantLeft.listen((id) {
          if (id == 'p2' && !p1Received.isCompleted) p1Received.complete(id);
        });
        final s3 = ds3.onParticipantLeft.listen((id) {
          if (id == 'p2' && !p3Received.isCompleted) p3Received.complete(id);
        });

        // Simula o fechamento abrupto de aba do Peer 2 (onBeforeUnload)
        channel2.simulateTeardown();

        await Future.wait([p1Received.future, p3Received.future]);

        expect(await p1Received.future, equals('p2'));
        expect(await p3Received.future, equals('p2'));

        expect(ds1.remoteParticipants.map((p) => p.id), contains('p3'));
        expect(ds1.remoteParticipants.map((p) => p.id), isNot(contains('p2')));

        await s1.cancel();
        await s3.cancel();
        ds1.dispose();
        ds2.dispose();
        ds3.dispose();
      });
    });

    // -------------------------------------------------------------------------
    // Invariant 5: Multi-Room Strict Isolation (ZERO cross-room leakage)
    // -------------------------------------------------------------------------
    group('Invariant 5: Multi-Room Strict Isolation & Zero Leakage', () {
      test('Peer in SALA-101 and Peer in SALA-102 have ZERO cross-discovery', () async {
        final dsA = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );
        final dsB = VideoCallSignalingDataSource(
          channelFactory: (name) => InMemorySignalingChannel(name, bus),
        );

        final pA = makeParticipantModel(id: 'peer_room_a', name: 'Alex', ra: '24802449');
        final pB = makeParticipantModel(id: 'peer_room_b', name: 'Beatriz', ra: '24801122');

        final aDiscovered = <ParticipantModel>[];
        final bDiscovered = <ParticipantModel>[];

        final sA = dsA.onParticipantJoined.listen(aDiscovered.add);
        final sB = dsB.onParticipantJoined.listen(bDiscovered.add);

        await dsA.connect(roomId: 'SALA-101', localParticipant: pA);
        await dsB.connect(roomId: 'SALA-102', localParticipant: pB);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(dsA.remoteParticipants, isEmpty, reason: 'Peer A must not discover Peer B in a different room');
        expect(dsB.remoteParticipants, isEmpty, reason: 'Peer B must not discover Peer A in a different room');
        expect(aDiscovered, isEmpty);
        expect(bDiscovered, isEmpty);

        await sA.cancel();
        await sB.cancel();
        dsA.dispose();
        dsB.dispose();
      });

      test('Multi-peer cross-traffic isolation: Zero messages or participants leak between SALA-101 and SALA-102', () async {
        // Sala 101: 3 peers
        final dsA1 = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));
        final dsA2 = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));
        final dsA3 = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));

        // Sala 102: 2 peers
        final dsB1 = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));
        final dsB2 = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));

        // Sala 103: 1 peer
        final dsC1 = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));

        final pA1 = makeParticipantModel(id: 'a1', name: 'A1', ra: '1001');
        final pA2 = makeParticipantModel(id: 'a2', name: 'A2', ra: '1002');
        final pA3 = makeParticipantModel(id: 'a3', name: 'A3', ra: '1003');

        final pB1 = makeParticipantModel(id: 'b1', name: 'B1', ra: '2001');
        final pB2 = makeParticipantModel(id: 'b2', name: 'B2', ra: '2002');

        final pC1 = makeParticipantModel(id: 'c1', name: 'C1', ra: '3001');

        // Coletores de eventos em SALA-101 (devem receber apenas mensagens de peers A)
        final chatInA1 = <ChatMessageModel>[];
        final emojiInA1 = <EmojiReactionModel>[];
        final subChatA1 = dsA1.onChatMessage.listen(chatInA1.add);
        final subEmojiA1 = dsA1.onEmojiReaction.listen(emojiInA1.add);

        // Coletores de eventos em SALA-102
        final chatInB2 = <ChatMessageModel>[];
        final subChatB2 = dsB2.onChatMessage.listen(chatInB2.add);

        // Conecta todos
        await dsA1.connect(roomId: 'SALA-101', localParticipant: pA1);
        await dsA2.connect(roomId: 'SALA-101', localParticipant: pA2);
        await dsA3.connect(roomId: 'SALA-101', localParticipant: pA3);

        await dsB1.connect(roomId: 'SALA-102', localParticipant: pB1);
        await dsB2.connect(roomId: 'SALA-102', localParticipant: pB2);

        await dsC1.connect(roomId: 'SALA-103', localParticipant: pC1);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Verificação dos grupos de participantes por sala
        expect(dsA1.remoteParticipants.map((p) => p.id).toSet(), equals({'a2', 'a3'}));
        expect(dsA2.remoteParticipants.map((p) => p.id).toSet(), equals({'a1', 'a3'}));
        expect(dsA3.remoteParticipants.map((p) => p.id).toSet(), equals({'a1', 'a2'}));

        expect(dsB1.remoteParticipants.map((p) => p.id).toSet(), equals({'b2'}));
        expect(dsB2.remoteParticipants.map((p) => p.id).toSet(), equals({'b1'}));

        expect(dsC1.remoteParticipants, isEmpty);

        // Transmissão massiva de mensagens na SALA-102
        await dsB1.broadcastChatMessage(
          'SALA-102',
          const ChatMessageModel(
            id: 'msg_b1',
            senderId: 'b1',
            senderName: 'B1',
            senderRa: '2001',
            text: 'Segredo de SALA-102',
            timestamp: 123456789,
          ),
        );
        await dsB1.broadcastEmojiReaction(
          'SALA-102',
          const EmojiReactionModel(
            id: 'em_b1',
            senderId: 'b1',
            senderName: 'B1',
            emoji: '❤️',
            timestamp: 123456789,
          ),
        );

        // Transmissão na SALA-103
        await dsC1.broadcastChatMessage(
          'SALA-103',
          const ChatMessageModel(
            id: 'msg_c1',
            senderId: 'c1',
            senderName: 'C1',
            senderRa: '3001',
            text: 'Monólogo de SALA-103',
            timestamp: 123456789,
          ),
        );

        // Transmissão legítima na SALA-101 (A2 -> A1)
        await dsA2.broadcastChatMessage(
          'SALA-101',
          const ChatMessageModel(
            id: 'msg_a2',
            senderId: 'a2',
            senderName: 'A2',
            senderRa: '1002',
            text: 'Mensagem pública de SALA-101',
            timestamp: 123456789,
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        // SALA-102 peer B2 recebeu msg de B1
        expect(chatInB2.length, equals(1));
        expect(chatInB2.first.text, equals('Segredo de SALA-102'));

        // SALA-101 peer A1 recebeu APENAS a msg de A2; NENHUMA de B1 ou C1
        expect(chatInA1.length, equals(1));
        expect(chatInA1.first.text, equals('Mensagem pública de SALA-101'));
        expect(chatInA1.any((m) => m.senderId == 'b1' || m.senderId == 'c1'), isFalse);

        // Emojis de SALA-102 não vazaram para SALA-101
        expect(emojiInA1, isEmpty);

        await subChatA1.cancel();
        await subEmojiA1.cancel();
        await subChatB2.cancel();

        dsA1.dispose();
        dsA2.dispose();
        dsA3.dispose();
        dsB1.dispose();
        dsB2.dispose();
        dsC1.dispose();
      });

      test('Room ID normalization: case and whitespace normalization connects same room and isolates different rooms', () async {
        final ds1 = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));
        final ds2 = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));
        final dsDiff = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));

        final p1 = makeParticipantModel(id: 'p1', name: 'Alex', ra: '24802449');
        final p2 = makeParticipantModel(id: 'p2', name: 'Beatriz', ra: '24801122');
        final pDiff = makeParticipantModel(id: 'pDiff', name: 'Carlos', ra: '24803344');

        // ' sala-101 ' e 'SALA-101' normalizam para a mesma sala
        await ds1.connect(roomId: '  sala-101  ', localParticipant: p1);
        await ds2.connect(roomId: 'SALA-101', localParticipant: p2);
        await dsDiff.connect(roomId: 'SALA-102', localParticipant: pDiff);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(ds1.remoteParticipants.length, equals(1));
        expect(ds1.remoteParticipants.first.id, equals('p2'));

        expect(ds2.remoteParticipants.length, equals(1));
        expect(ds2.remoteParticipants.first.id, equals('p1'));

        expect(dsDiff.remoteParticipants, isEmpty);

        ds1.dispose();
        ds2.dispose();
        dsDiff.dispose();
      });
    });

    // -------------------------------------------------------------------------
    // Invariant 6: Adversarial Stress & Malformed Packet Resilience
    // -------------------------------------------------------------------------
    group('Invariant 6: Adversarial Stress & Malformed Envelope Resilience', () {
      test('High-throughput burst: 100 concurrent messages delivered without loss or race condition', () async {
        final ds1 = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));
        final ds2 = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));

        final p1 = makeParticipantModel(id: 'burst_1', name: 'Alex', ra: '24802449');
        final p2 = makeParticipantModel(id: 'burst_2', name: 'Beatriz', ra: '24801122');

        await ds1.connect(roomId: 'SALA-BURST', localParticipant: p1);
        await ds2.connect(roomId: 'SALA-BURST', localParticipant: p2);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final receivedMessages = <ChatMessageModel>[];
        final sub = ds2.onChatMessage.listen(receivedMessages.add);

        final burstFutures = <Future<void>>[];
        for (int i = 0; i < 100; i++) {
          burstFutures.add(
            ds1.broadcastChatMessage(
              'SALA-BURST',
              ChatMessageModel(
                id: 'burst_msg_$i',
                senderId: 'burst_1',
                senderName: 'Alex',
                senderRa: '24802449',
                text: 'Burst message seq $i',
                timestamp: 1729169480000 + i,
              ),
            ),
          );
        }

        await Future.wait(burstFutures);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(receivedMessages.length, equals(100), reason: 'All 100 burst messages must be delivered');

        await sub.cancel();
        ds1.dispose();
        ds2.dispose();
      });

      test('Malformed raw payload injection: Datasource ignores corrupted JSON gracefully', () async {
        final rawChannel = InMemorySignalingChannel('p2p_videocall_SALA-ROBUST', bus);
        final ds = VideoCallSignalingDataSource(channelFactory: (n) => InMemorySignalingChannel(n, bus));

        final p = makeParticipantModel(id: 'legit_peer', name: 'Alex', ra: '24802449');
        await ds.connect(roomId: 'SALA-ROBUST', localParticipant: p);

        final receivedMessages = <ChatMessageModel>[];
        final sub = ds.onChatMessage.listen(receivedMessages.add);

        // Injeta dados corrompidos e mensagens de salas erradas no barramento
        await rawChannel.send('NOT_A_JSON');
        await rawChannel.send('{corrupted json format');
        await rawChannel.send('{"type": "UNKNOWN_ACTION", "roomId": "SALA-ROBUST"}');
        await rawChannel.send('{"roomId": "WRONG_ROOM", "type": "chat", "payload": {"text": "Should not receive"}}');

        // Envia mensagem legítima em seguida
        await rawChannel.send(
          '{"type":"chat","roomId":"SALA-ROBUST","senderId":"adversary","senderName":"Hacker","timestamp":1000,'
          '"payload":{"id":"legit_1","senderId":"adversary","senderName":"Hacker","senderRa":"99999999","text":"I survived!","timestamp":1000}}',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Datasource sobreviveu sem quebras e processou a mensagem válida
        expect(receivedMessages.length, equals(1));
        expect(receivedMessages.first.text, equals('I survived!'));

        await sub.cancel();
        await rawChannel.close();
        ds.dispose();
      });
    });
  });
}
