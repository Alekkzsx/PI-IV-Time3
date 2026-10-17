// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/chat_message.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/emoji_reaction.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/hand_raise_item.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/media_state_update.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/meeting_room.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/participant.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/recording_state.dart';
import 'package:pi_iv_time3/features/video_call/domain/errors/video_call_failures.dart';
import 'package:pi_iv_time3/features/video_call/domain/repositories/media_repository.dart';
import 'package:pi_iv_time3/features/video_call/domain/repositories/recording_repository.dart';
import 'package:pi_iv_time3/features/video_call/domain/repositories/video_call_repository.dart';
import 'package:pi_iv_time3/features/video_call/domain/usecases/join_room_usecase.dart';
import 'package:pi_iv_time3/features/video_call/domain/usecases/leave_room_usecase.dart';
import 'package:pi_iv_time3/features/video_call/domain/usecases/send_chat_message_usecase.dart';
import 'package:pi_iv_time3/features/video_call/domain/usecases/send_reaction_usecase.dart';
import 'package:pi_iv_time3/features/video_call/domain/usecases/toggle_hand_raise_usecase.dart';
import 'package:pi_iv_time3/features/video_call/domain/usecases/toggle_media_state_usecase.dart';
import 'package:pi_iv_time3/features/video_call/domain/usecases/toggle_recording_usecase.dart';

class FakeVideoCallRepository implements VideoCallRepository {
  MeetingRoom? joinedRoom;
  Participant? joinedParticipant;
  String? leftRoomId;
  String? leftPeerId;
  ChatMessage? sentMessage;
  EmojiReaction? sentReaction;
  bool? handRaisedState;
  RecordingState? updatedRecordingState;
  MediaStateUpdate? lastMediaUpdate;
  bool shouldThrow = false;

  final StreamController<Participant> _participantJoined = StreamController<Participant>.broadcast();
  final StreamController<String> _participantLeft = StreamController<String>.broadcast();
  final StreamController<ChatMessage> _chat = StreamController<ChatMessage>.broadcast();
  final StreamController<EmojiReaction> _emoji = StreamController<EmojiReaction>.broadcast();
  final StreamController<HandRaiseItem> _handRaise = StreamController<HandRaiseItem>.broadcast();
  final StreamController<MediaStateUpdate> _media = StreamController<MediaStateUpdate>.broadcast();
  final StreamController<RecordingState> _recording = StreamController<RecordingState>.broadcast();

  @override
  Stream<Participant> get participantJoinedStream => _participantJoined.stream;
  @override
  Stream<String> get participantLeftStream => _participantLeft.stream;
  @override
  Stream<ChatMessage> get chatMessageStream => _chat.stream;
  @override
  Stream<EmojiReaction> get emojiReactionStream => _emoji.stream;
  @override
  Stream<HandRaiseItem> get handRaiseStream => _handRaise.stream;
  @override
  Stream<MediaStateUpdate> get mediaStateStream => _media.stream;
  @override
  Stream<RecordingState> get recordingStateStream => _recording.stream;

  @override
  Future<void> joinRoom(MeetingRoom room, Participant localParticipant) async {
    if (shouldThrow) throw Exception('Network error');
    joinedRoom = room;
    joinedParticipant = localParticipant;
  }

  @override
  Future<void> leaveRoom(String roomId, String peerId) async {
    if (shouldThrow) throw Exception('Network error');
    leftRoomId = roomId;
    leftPeerId = peerId;
  }

  @override
  Future<void> sendChatMessage(String roomId, ChatMessage message) async {
    if (shouldThrow) throw Exception('Network error');
    sentMessage = message;
  }

  @override
  Future<void> sendEmojiReaction(String roomId, EmojiReaction reaction) async {
    if (shouldThrow) throw Exception('Network error');
    sentReaction = reaction;
  }

  @override
  Future<void> toggleHandRaise(String roomId, String peerId, bool isRaised) async {
    if (shouldThrow) throw Exception('Network error');
    handRaisedState = isRaised;
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
    if (shouldThrow) throw Exception('Network error');
    lastMediaUpdate = MediaStateUpdate(
      peerId: peerId,
      isAudioMuted: isAudioMuted,
      isVideoOff: isVideoOff,
      isScreenSharing: isScreenSharing,
      audioLevel: audioLevel,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<void> updateRecordingState(String roomId, RecordingState state) async {
    if (shouldThrow) throw Exception('Network error');
    updatedRecordingState = state;
  }

  @override
  Future<void> dispose() async {
    await _participantJoined.close();
    await _participantLeft.close();
    await _chat.close();
    await _emoji.close();
    await _handRaise.close();
    await _media.close();
    await _recording.close();
  }
}

class FakeRecordingRepository implements RecordingRepository {
  bool isStarted = false;
  bool isPaused = false;
  bool isStopped = false;
  bool shouldThrow = false;

  final StreamController<RecordingState> _stateController = StreamController<RecordingState>.broadcast();

  @override
  Stream<RecordingState> get recordingStateStream => _stateController.stream;

  @override
  Future<void> startRecording({
    required String roomId,
    required String initiatorPeerId,
    required String initiatorName,
  }) async {
    if (shouldThrow) throw Exception('Recording hardware failure');
    isStarted = true;
  }

  @override
  Future<void> pauseRecording() async => isPaused = true;

  @override
  Future<void> resumeRecording() async => isPaused = false;

  @override
  Future<String?> stopRecording() async {
    if (shouldThrow) throw Exception('Failed to stop recording');
    isStopped = true;
    return 'blob:http://localhost/rec-123.webm';
  }

  @override
  Future<void> downloadRecording(String outputPath) async {}

  @override
  Future<void> dispose() async => _stateController.close();
}

void main() {
  late FakeVideoCallRepository fakeVideoRepo;
  late FakeRecordingRepository fakeRecRepo;

  setUp(() {
    fakeVideoRepo = FakeVideoCallRepository();
    fakeRecRepo = FakeRecordingRepository();
  });

  group('JoinRoomUseCase', () {
    test('succeeds with valid parameters and normalizes roomId', () async {
      final useCase = JoinRoomUseCase(fakeVideoRepo);
      final room = MeetingRoom(id: 'sala-101', title: 'Reunião do Projeto');
      final participant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );

      await useCase(room: room, localParticipant: participant);

      expect(fakeVideoRepo.joinedRoom, isNotNull);
      expect(fakeVideoRepo.joinedRoom!.id, equals('SALA-101'));
      expect(fakeVideoRepo.joinedParticipant!.isLocal, isTrue);
    });

    test('throws VideoCallValidationException for invalid room ID format', () async {
      final useCase = JoinRoomUseCase(fakeVideoRepo);
      final invalidRoom = MeetingRoom(id: 'A!', title: 'Sala Inválida');
      final participant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );

      expect(
        () => useCase(room: invalidRoom, localParticipant: participant),
        throwsA(isA<VideoCallValidationException>()),
      );
    });

    test('throws VideoCallValidationException for short name or RA', () async {
      final useCase = JoinRoomUseCase(fakeVideoRepo);
      final room = MeetingRoom(id: 'SALA-101', title: 'Sala Válida');

      final shortNameParticipant = Participant(
        id: 'peer_1',
        name: 'A',
        ra: '24802449',
      );
      expect(
        () => useCase(room: room, localParticipant: shortNameParticipant),
        throwsA(isA<VideoCallValidationException>()),
      );

      final shortRaParticipant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '12',
      );
      expect(
        () => useCase(room: room, localParticipant: shortRaParticipant),
        throwsA(isA<VideoCallValidationException>()),
      );
    });

    test('wraps repository exceptions in VideoCallException', () async {
      fakeVideoRepo.shouldThrow = true;
      final useCase = JoinRoomUseCase(fakeVideoRepo);
      final room = MeetingRoom(id: 'SALA-101', title: 'Sala Válida');
      final participant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );

      expect(
        () => useCase(room: room, localParticipant: participant),
        throwsA(isA<VideoCallException>()),
      );
    });
  });

  group('LeaveRoomUseCase', () {
    test('succeeds with valid parameters', () async {
      final useCase = LeaveRoomUseCase(fakeVideoRepo);
      await useCase(roomId: 'SALA-101', peerId: 'peer_1');

      expect(fakeVideoRepo.leftRoomId, equals('SALA-101'));
      expect(fakeVideoRepo.leftPeerId, equals('peer_1'));
    });

    test('validates non-empty roomId and peerId', () async {
      final useCase = LeaveRoomUseCase(fakeVideoRepo);

      expect(
        () => useCase(roomId: '   ', peerId: 'peer_1'),
        throwsA(isA<VideoCallValidationException>()),
      );
      expect(
        () => useCase(roomId: 'SALA-101', peerId: ''),
        throwsA(isA<VideoCallValidationException>()),
      );
    });
  });

  group('SendChatMessageUseCase', () {
    test('succeeds with valid message', () async {
      final useCase = SendChatMessageUseCase(fakeVideoRepo);
      final msg = ChatMessage(
        id: 'm1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        senderRa: '24802449',
        text: 'Olá colegas!',
        timestamp: DateTime.now(),
      );

      await useCase(roomId: 'SALA-101', message: msg);
      expect(fakeVideoRepo.sentMessage, isNotNull);
      expect(fakeVideoRepo.sentMessage!.text, equals('Olá colegas!'));
    });

    test('rejects empty message or message exceeding 1000 characters', () async {
      final useCase = SendChatMessageUseCase(fakeVideoRepo);

      final emptyMsg = ChatMessage(
        id: 'm1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        senderRa: '24802449',
        text: '   ',
        timestamp: DateTime.now(),
      );
      expect(
        () => useCase(roomId: 'SALA-101', message: emptyMsg),
        throwsA(isA<VideoCallValidationException>()),
      );

      final giantMsg = ChatMessage(
        id: 'm1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        senderRa: '24802449',
        text: 'A' * 1001,
        timestamp: DateTime.now(),
      );
      expect(
        () => useCase(roomId: 'SALA-101', message: giantMsg),
        throwsA(isA<VideoCallValidationException>()),
      );
    });
  });

  group('SendReactionUseCase', () {
    test('accepts supported emojis', () async {
      final useCase = SendReactionUseCase(fakeVideoRepo);
      final reaction = EmojiReaction(
        id: 'r1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        emoji: '👍',
        timestamp: DateTime.now(),
      );

      await useCase(roomId: 'SALA-101', reaction: reaction);
      expect(fakeVideoRepo.sentReaction, isNotNull);
      expect(fakeVideoRepo.sentReaction!.emoji, equals('👍'));
    });

    test('rejects unsupported emoji', () async {
      final useCase = SendReactionUseCase(fakeVideoRepo);
      final invalidReaction = EmojiReaction(
        id: 'r1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        emoji: '🔥', // Não está no set canônico {❤️, 👍, 👏, 😂, 😮, 🎉}
        timestamp: DateTime.now(),
      );

      expect(
        () => useCase(roomId: 'SALA-101', reaction: invalidReaction),
        throwsA(isA<VideoCallValidationException>()),
      );
    });
  });

  group('ToggleMediaStateUseCase', () {
    test('updates audio mute and volume level correctly', () async {
      final useCase = ToggleMediaStateUseCase(fakeVideoRepo);
      await useCase(
        roomId: 'SALA-101',
        peerId: 'peer_1',
        isAudioMuted: true,
        audioLevel: 0.85,
      );

      expect(fakeVideoRepo.lastMediaUpdate, isNotNull);
      expect(fakeVideoRepo.lastMediaUpdate!.isAudioMuted, isTrue);
      expect(fakeVideoRepo.lastMediaUpdate!.audioLevel, equals(0.85));
    });

    test('validates audioLevel boundary [0.0, 1.0]', () async {
      final useCase = ToggleMediaStateUseCase(fakeVideoRepo);

      expect(
        () => useCase(
          roomId: 'SALA-101',
          peerId: 'peer_1',
          audioLevel: 1.5,
        ),
        throwsA(isA<VideoCallValidationException>()),
      );
      expect(
        () => useCase(
          roomId: 'SALA-101',
          peerId: 'peer_1',
          audioLevel: -0.1,
        ),
        throwsA(isA<VideoCallValidationException>()),
      );
    });

    test('rejects call with no parameters supplied', () async {
      final useCase = ToggleMediaStateUseCase(fakeVideoRepo);
      expect(
        () => useCase(roomId: 'SALA-101', peerId: 'peer_1'),
        throwsA(isA<VideoCallValidationException>()),
      );
    });
  });

  group('ToggleHandRaiseUseCase', () {
    test('updates hand raise state', () async {
      final useCase = ToggleHandRaiseUseCase(fakeVideoRepo);
      await useCase(roomId: 'SALA-101', peerId: 'peer_1', isRaised: true);
      expect(fakeVideoRepo.handRaisedState, isTrue);

      await useCase(roomId: 'SALA-101', peerId: 'peer_1', isRaised: false);
      expect(fakeVideoRepo.handRaisedState, isFalse);
    });
  });

  group('ToggleRecordingUseCase', () {
    test('transitions from idle to recording', () async {
      final useCase = ToggleRecordingUseCase(
        videoCallRepository: fakeVideoRepo,
        recordingRepository: fakeRecRepo,
      );

      final participant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );

      final newState = await useCase(
        roomId: 'SALA-101',
        currentRecordingState: RecordingState.initial(),
        localParticipant: participant,
      );

      expect(fakeRecRepo.isStarted, isTrue);
      expect(newState.isRecording, isTrue);
      expect(fakeVideoRepo.updatedRecordingState!.isRecording, isTrue);
      expect(fakeVideoRepo.updatedRecordingState!.startedByPeerId, equals('peer_1'));
    });

    test('transitions from recording to completed', () async {
      final useCase = ToggleRecordingUseCase(
        videoCallRepository: fakeVideoRepo,
        recordingRepository: fakeRecRepo,
      );

      final participant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );

      final activeState = RecordingState(
        status: RecordingStatus.recording,
        isRecording: true,
        startedByPeerId: 'peer_1',
        startedByName: 'Alex Sousa',
        startedAt: DateTime.now(),
      );

      final stoppedState = await useCase(
        roomId: 'SALA-101',
        currentRecordingState: activeState,
        localParticipant: participant,
      );

      expect(fakeRecRepo.isStopped, isTrue);
      expect(stoppedState.isRecording, isFalse);
      expect(stoppedState.status, equals(RecordingStatus.completed));
      expect(stoppedState.outputPath, contains('.webm'));
    });

    test('handles errors and sets error status', () async {
      fakeRecRepo.shouldThrow = true;
      final useCase = ToggleRecordingUseCase(
        videoCallRepository: fakeVideoRepo,
        recordingRepository: fakeRecRepo,
      );

      final participant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );

      await expectLater(
        () => useCase(
          roomId: 'SALA-101',
          currentRecordingState: RecordingState.initial(),
          localParticipant: participant,
        ),
        throwsA(isA<RecordingException>()),
      );

      expect(fakeVideoRepo.updatedRecordingState, isNotNull);
      expect(fakeVideoRepo.updatedRecordingState!.status, equals(RecordingStatus.error));
    });
  });
}
