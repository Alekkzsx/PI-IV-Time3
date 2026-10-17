// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/data/channel/in_memory_signaling_bus.dart';
import 'package:pi_iv_time3/features/video_call/data/datasources/video_call_signaling_datasource.dart';
import 'package:pi_iv_time3/features/video_call/data/models/chat_message_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/emoji_reaction_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/participant_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/recording_state_model.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/hand_raise_item.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/media_state_update.dart';

void main() {
  late InMemorySignalingBus bus;

  setUp(() {
    bus = InMemorySignalingBus();
    bus.reset();
  });

  tearDown(() {
    bus.reset();
  });

  group('VideoCallSignalingDataSource (Zero Bots & Signaling Protocol)', () {
    test('Scenario 1: Solitary Join produces ZERO fake participants', () async {
      final dataSource = VideoCallSignalingDataSource(
        channelFactory: (name) => InMemorySignalingChannel(name, bus),
      );

      final joinedPeers = <ParticipantModel>[];
      final sub = dataSource.onParticipantJoined.listen(joinedPeers.add);

      final p1 = ParticipantModel(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
        lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
      );

      await dataSource.connect(roomId: 'SALA-101', localParticipant: p1);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(dataSource.remoteParticipants, isEmpty);
      expect(joinedPeers, isEmpty, reason: 'No bots or mock participants must be created');

      await sub.cancel();
      dataSource.dispose();
    });

    test('Scenario 2: Reciprocal Handshake Discovery connects 2 real peers', () async {
      final ds1 = VideoCallSignalingDataSource(
        channelFactory: (name) => InMemorySignalingChannel(name, bus),
      );
      final ds2 = VideoCallSignalingDataSource(
        channelFactory: (name) => InMemorySignalingChannel(name, bus),
      );

      final ds1Joined = <ParticipantModel>[];
      final ds2Joined = <ParticipantModel>[];

      final sub1 = ds1.onParticipantJoined.listen(ds1Joined.add);
      final sub2 = ds2.onParticipantJoined.listen(ds2Joined.add);

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

      // Peer 1 entra primeiro na sala
      await ds1.connect(roomId: 'SALA-101', localParticipant: p1);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Peer 2 entra na mesma sala (envia JOIN -> Peer 1 responde PRESENCE_SYNC)
      await ds2.connect(roomId: 'SALA-101', localParticipant: p2);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Peer 1 descobriu Peer 2
      expect(ds1.remoteParticipants.length, equals(1));
      expect(ds1.remoteParticipants.first.id, equals('peer_2'));
      expect(ds1Joined.any((p) => p.id == 'peer_2'), isTrue);

      // Peer 2 descobriu Peer 1 via PRESENCE_SYNC
      expect(ds2.remoteParticipants.length, equals(1));
      expect(ds2.remoteParticipants.first.id, equals('peer_1'));
      expect(ds2Joined.any((p) => p.id == 'peer_1'), isTrue);

      await sub1.cancel();
      await sub2.cancel();
      ds1.dispose();
      ds2.dispose();
    });

    test('Scenario 3: Graceful Exit removes peer immediately', () async {
      final ds1 = VideoCallSignalingDataSource(
        channelFactory: (name) => InMemorySignalingChannel(name, bus),
      );
      final ds2 = VideoCallSignalingDataSource(
        channelFactory: (name) => InMemorySignalingChannel(name, bus),
      );

      final leftPeersOnDs1 = <String>[];
      final subLeft = ds1.onParticipantLeft.listen(leftPeersOnDs1.add);

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

      await ds1.connect(roomId: 'SALA-101', localParticipant: p1);
      await ds2.connect(roomId: 'SALA-101', localParticipant: p2);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(ds1.remoteParticipants.length, equals(1));

      // Peer 2 desconecta formalmente
      await ds2.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(leftPeersOnDs1, contains('peer_2'));
      expect(ds1.remoteParticipants, isEmpty);

      await subLeft.cancel();
      ds1.dispose();
      ds2.dispose();
    });

    test('Scenario 4: Demuxes chat, emoji, hand raise, media and recording', () async {
      final ds1 = VideoCallSignalingDataSource(
        channelFactory: (name) => InMemorySignalingChannel(name, bus),
      );
      final ds2 = VideoCallSignalingDataSource(
        channelFactory: (name) => InMemorySignalingChannel(name, bus),
      );

      ChatMessageModel? receivedChat;
      EmojiReactionModel? receivedEmoji;
      HandRaiseItem? receivedHand;
      MediaStateUpdate? receivedMedia;
      RecordingStateModel? receivedRecording;

      final s1 = ds2.onChatMessage.listen((msg) => receivedChat = msg);
      final s2 = ds2.onEmojiReaction.listen((r) => receivedEmoji = r);
      final s3 = ds2.onHandRaise.listen((h) => receivedHand = h);
      final s4 = ds2.onMediaStateUpdate.listen((m) => receivedMedia = m);
      final s5 = ds2.onRecordingState.listen((rec) => receivedRecording = rec);

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

      await ds1.connect(roomId: 'SALA-101', localParticipant: p1);
      await ds2.connect(roomId: 'SALA-101', localParticipant: p2);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Broadcast Chat
      await ds1.broadcastChatMessage(
        'SALA-101',
        const ChatMessageModel(
          id: 'c1',
          senderId: 'peer_1',
          senderName: 'Alex Sousa',
          senderRa: '24802449',
          text: 'Boa noite a todos!',
          timestamp: 1729169480000,
        ),
      );

      // Broadcast Emoji
      await ds1.broadcastEmojiReaction(
        'SALA-101',
        const EmojiReactionModel(
          id: 'e1',
          senderId: 'peer_1',
          senderName: 'Alex Sousa',
          emoji: '🎉',
          timestamp: 1729169480000,
        ),
      );

      // Broadcast Hand Raise
      await ds1.broadcastHandRaise(
        'SALA-101',
        peerId: 'peer_1',
        participantName: 'Alex Sousa',
        academicId: '24802449',
        isRaised: true,
      );

      // Broadcast Media State
      await ds1.broadcastMediaState(
        'SALA-101',
        peerId: 'peer_1',
        isAudioMuted: true,
        audioLevel: 0.88,
      );

      // Broadcast Recording State
      await ds1.broadcastRecordingState(
        'SALA-101',
        const RecordingStateModel(
          isRecording: true,
          status: 'recording',
          recordedById: 'peer_1',
          recordedByName: 'Alex Sousa',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(receivedChat, isNotNull);
      expect(receivedChat!.text, equals('Boa noite a todos!'));

      expect(receivedEmoji, isNotNull);
      expect(receivedEmoji!.emoji, equals('🎉'));

      expect(receivedHand, isNotNull);
      expect(receivedHand!.isRaised, isTrue);
      expect(receivedHand!.participantName, equals('Alex Sousa'));

      expect(receivedMedia, isNotNull);
      expect(receivedMedia!.isAudioMuted, isTrue);
      expect(receivedMedia!.audioLevel, closeTo(0.88, 0.001));

      expect(receivedRecording, isNotNull);
      expect(receivedRecording!.isRecording, isTrue);

      await s1.cancel();
      await s2.cancel();
      await s3.cancel();
      await s4.cancel();
      await s5.cancel();

      ds1.dispose();
      ds2.dispose();
    });
  });
}
