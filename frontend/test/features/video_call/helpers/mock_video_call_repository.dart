// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'dart:convert';
import 'in_memory_signaling_bus.dart';
import 'video_call_contracts.dart';

/// In-memory implementation of [VideoCallRepository] operating over [InMemorySignalingBus].
///
/// Provides zero-backend real-time P2P simulation across multiple controller
/// instances in memory, enabling full end-to-end multi-peer tests on Dart VM.
class MockVideoCallRepository implements VideoCallRepository {
  final StreamController<Participant> _participantJoinedController =
      StreamController<Participant>.broadcast();
  final StreamController<String> _participantLeftController =
      StreamController<String>.broadcast();
  final StreamController<ChatMessage> _chatMessageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<EmojiReaction> _emojiReactionController =
      StreamController<EmojiReaction>.broadcast();
  final StreamController<HandRaiseItem> _handRaiseController =
      StreamController<HandRaiseItem>.broadcast();
  final StreamController<MediaStateUpdate> _mediaStateController =
      StreamController<MediaStateUpdate>.broadcast();
  final StreamController<RecordingState> _recordingStateController =
      StreamController<RecordingState>.broadcast();

  InMemorySignalingBus? _bus;
  StreamSubscription<String>? _busSubscription;
  Participant? _localParticipant;

  @override
  Stream<Participant> get participantJoinedStream =>
      _participantJoinedController.stream;

  @override
  Stream<String> get participantLeftStream =>
      _participantLeftController.stream;

  @override
  Stream<ChatMessage> get chatMessageStream => _chatMessageController.stream;

  @override
  Stream<EmojiReaction> get emojiReactionStream =>
      _emojiReactionController.stream;

  @override
  Stream<HandRaiseItem> get handRaiseStream => _handRaiseController.stream;

  @override
  Stream<MediaStateUpdate> get mediaStateStream => _mediaStateController.stream;

  @override
  Stream<RecordingState> get recordingStateStream =>
      _recordingStateController.stream;

  @override
  Future<void> joinRoom(MeetingRoom room, Participant localParticipant) async {
    _localParticipant = localParticipant;
    _bus = InMemorySignalingBus.forRoom(room.code);

    // Subscribe to bus messages sent by other peers
    _busSubscription = _bus!.subscribe(localParticipant.id).listen(_handleRawEnvelope);

    // Broadcast JOIN envelope to room
    final joinEnvelope = jsonEncode({
      'type': 'JOIN',
      'senderId': localParticipant.id,
      'participant': localParticipant.toJson(),
    });
    _bus!.broadcast(senderId: localParticipant.id, rawData: joinEnvelope);
  }

  void _handleRawEnvelope(String rawData) {
    try {
      final map = jsonDecode(rawData) as Map<String, dynamic>;
      final type = map['type'] as String;

      switch (type) {
        case 'JOIN':
          final participant = Participant.fromJson(
            map['participant'] as Map<String, dynamic>,
          );
          _participantJoinedController.add(participant);

          // Respond with PRESENCE_SYNC so the new peer discovers us
          if (_localParticipant != null && _bus != null) {
            final syncEnvelope = jsonEncode({
              'type': 'PRESENCE_SYNC',
              'senderId': _localParticipant!.id,
              'targetId': participant.id,
              'participant': _localParticipant!.toJson(),
            });
            _bus!.broadcast(
              senderId: _localParticipant!.id,
              rawData: syncEnvelope,
            );
          }
          break;

        case 'PRESENCE_SYNC':
          final targetId = map['targetId'] as String?;
          if (targetId == null || targetId == _localParticipant?.id) {
            final participant = Participant.fromJson(
              map['participant'] as Map<String, dynamic>,
            );
            _participantJoinedController.add(participant);
          }
          break;

        case 'LEAVE':
          final leftPeerId = map['peerId'] as String;
          _participantLeftController.add(leftPeerId);
          break;

        case 'CHAT':
          final chat = ChatMessage.fromJson(
            map['chat'] as Map<String, dynamic>,
          );
          _chatMessageController.add(chat);
          break;

        case 'EMOJI':
          final emoji = EmojiReaction.fromJson(
            map['emoji'] as Map<String, dynamic>,
          );
          _emojiReactionController.add(emoji);
          break;

        case 'HAND_RAISE':
          final hand = HandRaiseItem.fromJson(
            map['hand'] as Map<String, dynamic>,
          );
          _handRaiseController.add(hand);
          break;

        case 'MEDIA_STATE':
          final media = MediaStateUpdate.fromJson(
            map['media'] as Map<String, dynamic>,
          );
          _mediaStateController.add(media);
          break;

        case 'RECORDING_STATE':
          final rec = RecordingState.fromJson(
            map['recording'] as Map<String, dynamic>,
          );
          _recordingStateController.add(rec);
          break;
      }
    } catch (_) {
      // Ignore malformed payloads defensively
    }
  }

  @override
  Future<void> leaveRoom(String roomId, String peerId) async {
    if (_bus != null) {
      final leaveEnvelope = jsonEncode({
        'type': 'LEAVE',
        'senderId': peerId,
        'peerId': peerId,
      });
      _bus!.broadcast(senderId: peerId, rawData: leaveEnvelope);
    }
    await _busSubscription?.cancel();
    _busSubscription = null;
    _bus = null;
    _localParticipant = null;
  }

  @override
  Future<void> sendChatMessage(String roomId, ChatMessage message) async {
    final envelope = jsonEncode({
      'type': 'CHAT',
      'senderId': message.senderId,
      'chat': message.toJson(),
    });
    _bus?.broadcast(senderId: message.senderId, rawData: envelope);
  }

  @override
  Future<void> sendEmojiReaction(String roomId, EmojiReaction reaction) async {
    final envelope = jsonEncode({
      'type': 'EMOJI',
      'senderId': reaction.peerId,
      'emoji': reaction.toJson(),
    });
    _bus?.broadcast(senderId: reaction.peerId, rawData: envelope);
  }

  @override
  Future<void> toggleHandRaise(String roomId, String peerId, bool isRaised) async {
    final hand = HandRaiseItem(
      peerId: peerId,
      name: _localParticipant?.name ?? 'Peer',
      ra: _localParticipant?.ra ?? '000000',
      raisedAt: DateTime.now(),
    );
    final envelope = jsonEncode({
      'type': 'HAND_RAISE',
      'senderId': peerId,
      'isRaised': isRaised,
      'hand': hand.toJson(),
    });
    _bus?.broadcast(senderId: peerId, rawData: envelope);
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
    final update = MediaStateUpdate(
      peerId: peerId,
      isAudioMuted: isAudioMuted,
      isVideoOff: isVideoOff,
      isScreenSharing: isScreenSharing,
      audioLevel: audioLevel,
    );
    final envelope = jsonEncode({
      'type': 'MEDIA_STATE',
      'senderId': peerId,
      'media': update.toJson(),
    });
    _bus?.broadcast(senderId: peerId, rawData: envelope);
  }

  @override
  Future<void> updateRecordingState(String roomId, RecordingState state) async {
    final envelope = jsonEncode({
      'type': 'RECORDING_STATE',
      'senderId': state.startedByPeerId ?? 'unknown',
      'recording': state.toJson(),
    });
    _bus?.broadcast(senderId: state.startedByPeerId ?? 'unknown', rawData: envelope);
  }

  void dispose() {
    _busSubscription?.cancel();
    _participantJoinedController.close();
    _participantLeftController.close();
    _chatMessageController.close();
    _emojiReactionController.close();
    _handRaiseController.close();
    _mediaStateController.close();
    _recordingStateController.close();
  }
}
