// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/data/channel/signaling_channel.dart';
import 'package:pi_iv_time3/features/video_call/data/datasources/video_call_signaling_datasource.dart';
import 'package:pi_iv_time3/features/video_call/data/models/chat_message_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/emoji_reaction_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/participant_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/recording_state_model.dart';
import 'package:pi_iv_time3/features/video_call/data/repositories/video_call_repository_impl.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/chat_message.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/emoji_reaction.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/hand_raise_item.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/media_state_update.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/meeting_room.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/participant.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/recording_state.dart';

class MockSignalingDataSource implements IVideoCallSignalingDataSource {
  String? connectedRoomId;
  ParticipantModel? connectedLocalParticipant;
  bool isDisconnected = false;

  String? lastBroadcastChatRoomId;
  ChatMessageModel? lastBroadcastChatMessage;

  String? lastBroadcastEmojiRoomId;
  EmojiReactionModel? lastBroadcastEmojiReaction;

  String? lastHandRaiseRoomId;
  String? lastHandRaisePeerId;
  bool? lastHandRaiseIsRaised;

  String? lastMediaRoomId;
  String? lastMediaPeerId;
  bool? lastMediaIsAudioMuted;
  double? lastMediaAudioLevel;

  String? lastRecordingRoomId;
  RecordingStateModel? lastRecordingState;

  final StreamController<ParticipantModel> _participantJoinedCtrl =
      StreamController<ParticipantModel>.broadcast();
  final StreamController<String> _participantLeftCtrl =
      StreamController<String>.broadcast();
  final StreamController<ChatMessageModel> _chatCtrl =
      StreamController<ChatMessageModel>.broadcast();
  final StreamController<EmojiReactionModel> _emojiCtrl =
      StreamController<EmojiReactionModel>.broadcast();
  final StreamController<HandRaiseItem> _handRaiseCtrl =
      StreamController<HandRaiseItem>.broadcast();
  final StreamController<MediaStateUpdate> _mediaCtrl =
      StreamController<MediaStateUpdate>.broadcast();
  final StreamController<RecordingStateModel> _recordingCtrl =
      StreamController<RecordingStateModel>.broadcast();

  @override
  Stream<ParticipantModel> get onParticipantJoined => _participantJoinedCtrl.stream;
  @override
  Stream<String> get onParticipantLeft => _participantLeftCtrl.stream;
  @override
  Stream<ChatMessageModel> get onChatMessage => _chatCtrl.stream;
  @override
  Stream<EmojiReactionModel> get onEmojiReaction => _emojiCtrl.stream;
  @override
  Stream<HandRaiseItem> get onHandRaise => _handRaiseCtrl.stream;
  @override
  Stream<MediaStateUpdate> get onMediaStateUpdate => _mediaCtrl.stream;
  @override
  Stream<RecordingStateModel> get onRecordingState => _recordingCtrl.stream;

  @override
  Future<void> connect({
    required String roomId,
    required ParticipantModel localParticipant,
    ISignalingChannel? customChannel,
  }) async {
    connectedRoomId = roomId;
    connectedLocalParticipant = localParticipant;
  }

  @override
  Future<void> disconnect() async {
    isDisconnected = true;
  }

  @override
  Future<void> broadcastChatMessage(String roomId, ChatMessageModel message) async {
    lastBroadcastChatRoomId = roomId;
    lastBroadcastChatMessage = message;
  }

  @override
  Future<void> broadcastEmojiReaction(String roomId, EmojiReactionModel reaction) async {
    lastBroadcastEmojiRoomId = roomId;
    lastBroadcastEmojiReaction = reaction;
  }

  @override
  Future<void> broadcastHandRaise(
    String roomId, {
    required String peerId,
    required String participantName,
    required String academicId,
    required bool isRaised,
  }) async {
    lastHandRaiseRoomId = roomId;
    lastHandRaisePeerId = peerId;
    lastHandRaiseIsRaised = isRaised;
  }

  @override
  Future<void> broadcastMediaState(
    String roomId, {
    required String peerId,
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    double? audioLevel,
  }) async {
    lastMediaRoomId = roomId;
    lastMediaPeerId = peerId;
    lastMediaIsAudioMuted = isAudioMuted;
    lastMediaAudioLevel = audioLevel;
  }

  @override
  Future<void> broadcastRecordingState(String roomId, RecordingStateModel state) async {
    lastRecordingRoomId = roomId;
    lastRecordingState = state;
  }

  @override
  void updateLocalAudioLevel(double level) {}

  @override
  void dispose() {
    _participantJoinedCtrl.close();
    _participantLeftCtrl.close();
    _chatCtrl.close();
    _emojiCtrl.close();
    _handRaiseCtrl.close();
    _mediaCtrl.close();
    _recordingCtrl.close();
  }

  void emitParticipant(ParticipantModel model) => _participantJoinedCtrl.add(model);
  void emitLeave(String peerId) => _participantLeftCtrl.add(peerId);
  void emitChat(ChatMessageModel model) => _chatCtrl.add(model);
  void emitEmoji(EmojiReactionModel model) => _emojiCtrl.add(model);
  void emitHand(HandRaiseItem item) => _handRaiseCtrl.add(item);
  void emitMedia(MediaStateUpdate update) => _mediaCtrl.add(update);
  void emitRecording(RecordingStateModel model) => _recordingCtrl.add(model);
}

void main() {
  late MockSignalingDataSource mockDataSource;
  late VideoCallRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockSignalingDataSource();
    repository = VideoCallRepositoryImpl(dataSource: mockDataSource);
  });

  tearDown(() {
    repository.dispose();
  });

  group('VideoCallRepositoryImpl', () {
    test('joinRoom delegates to datasource with converted ParticipantModel', () async {
      final room = MeetingRoom(id: 'SALA-101', title: 'Sala 101');
      final participant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
        isAudioMuted: false,
      );

      await repository.joinRoom(room, participant);

      expect(mockDataSource.connectedRoomId, equals('SALA-101'));
      expect(mockDataSource.connectedLocalParticipant, isNotNull);
      expect(mockDataSource.connectedLocalParticipant!.id, equals('peer_1'));
      expect(mockDataSource.connectedLocalParticipant!.name, equals('Alex Sousa'));
    });

    test('leaveRoom delegates to datasource disconnect', () async {
      await repository.leaveRoom('SALA-101', 'peer_1');
      expect(mockDataSource.isDisconnected, isTrue);
    });

    test('sendChatMessage converts entity to model and broadcasts', () async {
      final msg = ChatMessage(
        id: 'm1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        senderRa: '24802449',
        text: 'Olá pessoal',
        timestamp: DateTime(2026, 10, 17, 10, 0),
      );

      await repository.sendChatMessage('SALA-101', msg);

      expect(mockDataSource.lastBroadcastChatRoomId, equals('SALA-101'));
      expect(mockDataSource.lastBroadcastChatMessage, isNotNull);
      expect(mockDataSource.lastBroadcastChatMessage!.text, equals('Olá pessoal'));
    });

    test('sendEmojiReaction converts entity to model and broadcasts', () async {
      final reaction = EmojiReaction(
        id: 'r1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        emoji: '❤️',
        timestamp: DateTime(2026, 10, 17, 10, 0),
      );

      await repository.sendEmojiReaction('SALA-101', reaction);

      expect(mockDataSource.lastBroadcastEmojiRoomId, equals('SALA-101'));
      expect(mockDataSource.lastBroadcastEmojiReaction!.emoji, equals('❤️'));
    });

    test('toggleHandRaise broadcasts with local participant metadata', () async {
      final room = MeetingRoom(id: 'SALA-101', title: 'Sala 101');
      final participant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );

      await repository.joinRoom(room, participant);
      await repository.toggleHandRaise('SALA-101', 'peer_1', true);

      expect(mockDataSource.lastHandRaiseRoomId, equals('SALA-101'));
      expect(mockDataSource.lastHandRaisePeerId, equals('peer_1'));
      expect(mockDataSource.lastHandRaiseIsRaised, isTrue);
    });

    test('updateMediaState delegates to datasource', () async {
      await repository.updateMediaState(
        'SALA-101',
        'peer_1',
        isAudioMuted: true,
        audioLevel: 0.95,
      );

      expect(mockDataSource.lastMediaRoomId, equals('SALA-101'));
      expect(mockDataSource.lastMediaPeerId, equals('peer_1'));
      expect(mockDataSource.lastMediaIsAudioMuted, isTrue);
      expect(mockDataSource.lastMediaAudioLevel, closeTo(0.95, 0.001));
    });

    test('updateRecordingState converts entity to model and broadcasts', () async {
      const state = RecordingState(
        status: RecordingStatus.recording,
        isRecording: true,
        startedByPeerId: 'peer_1',
        startedByName: 'Alex Sousa',
      );

      await repository.updateRecordingState('SALA-101', state);

      expect(mockDataSource.lastRecordingRoomId, equals('SALA-101'));
      expect(mockDataSource.lastRecordingState!.isRecording, isTrue);
      expect(mockDataSource.lastRecordingState!.status, equals('recording'));
    });

    test('streams map models to domain entities accurately', () async {
      Participant? emittedParticipant;
      String? emittedLeftPeerId;
      ChatMessage? emittedChat;
      EmojiReaction? emittedEmoji;
      HandRaiseItem? emittedHand;
      MediaStateUpdate? emittedMedia;
      RecordingState? emittedRecording;

      final s1 = repository.participantJoinedStream.listen((p) => emittedParticipant = p);
      final s2 = repository.participantLeftStream.listen((id) => emittedLeftPeerId = id);
      final s3 = repository.chatMessageStream.listen((c) => emittedChat = c);
      final s4 = repository.emojiReactionStream.listen((e) => emittedEmoji = e);
      final s5 = repository.handRaiseStream.listen((h) => emittedHand = h);
      final s6 = repository.mediaStateStream.listen((m) => emittedMedia = m);
      final s7 = repository.recordingStateStream.listen((r) => emittedRecording = r);

      mockDataSource.emitParticipant(
        const ParticipantModel(
          id: 'peer_2',
          name: 'Beatriz',
          ra: '24801122',
          lastHeartbeat: 1729169480000,
        ),
      );
      mockDataSource.emitLeave('peer_2');
      mockDataSource.emitChat(
        const ChatMessageModel(
          id: 'c1',
          senderId: 'peer_2',
          senderName: 'Beatriz',
          senderRa: '24801122',
          text: 'Olá',
          timestamp: 1729169480000,
        ),
      );
      mockDataSource.emitEmoji(
        const EmojiReactionModel(
          id: 'e1',
          senderId: 'peer_2',
          senderName: 'Beatriz',
          emoji: '👏',
          timestamp: 1729169480000,
        ),
      );
      mockDataSource.emitHand(
        HandRaiseItem(
          peerId: 'peer_2',
          participantName: 'Beatriz',
          academicId: '24801122',
          raisedAt: DateTime.now(),
        ),
      );
      mockDataSource.emitMedia(
        MediaStateUpdate(
          peerId: 'peer_2',
          isAudioMuted: false,
          audioLevel: 0.6,
          timestamp: DateTime.now(),
        ),
      );
      mockDataSource.emitRecording(
        const RecordingStateModel(
          isRecording: true,
          status: 'recording',
          recordedById: 'peer_2',
          recordedByName: 'Beatriz',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(emittedParticipant, isNotNull);
      expect(emittedParticipant!.name, equals('Beatriz'));
      expect(emittedLeftPeerId, equals('peer_2'));
      expect(emittedChat!.text, equals('Olá'));
      expect(emittedEmoji!.emoji, equals('👏'));
      expect(emittedHand!.participantName, equals('Beatriz'));
      expect(emittedMedia!.audioLevel, closeTo(0.6, 0.001));
      expect(emittedRecording!.isRecording, isTrue);

      await s1.cancel();
      await s2.cancel();
      await s3.cancel();
      await s4.cancel();
      await s5.cancel();
      await s6.cancel();
      await s7.cancel();
    });
  });
}
