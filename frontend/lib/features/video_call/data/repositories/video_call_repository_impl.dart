// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Marcelo Zarpelon - RA: 25015323

import 'dart:async';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/emoji_reaction.dart';
import '../../domain/entities/hand_raise_item.dart';
import '../../domain/entities/media_state_update.dart';
import '../../domain/entities/meeting_room.dart';
import '../../domain/entities/participant.dart';
import '../../domain/entities/recording_state.dart';
import '../../domain/repositories/video_call_repository.dart';
import '../datasources/video_call_signaling_datasource.dart';
import '../models/chat_message_model.dart';
import '../models/emoji_reaction_model.dart';
import '../models/participant_model.dart';
import '../models/recording_state_model.dart';

/// Implementação do repositório de videoconferência aderente ao Clean Architecture.
///
/// Faz a ponte entre as fontes de dados de sinalização P2P e a camada de domínio.
class VideoCallRepositoryImpl
    implements VideoCallRepository, WebRtcSignalingRepository {
  final IVideoCallSignalingDataSource _dataSource;
  Participant? _localParticipant;

  VideoCallRepositoryImpl({
    required IVideoCallSignalingDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Stream<Participant> get participantJoinedStream =>
      _dataSource.onParticipantJoined.map((model) => model.toEntity());

  @override
  Stream<String> get participantLeftStream => _dataSource.onParticipantLeft;

  @override
  Stream<ChatMessage> get chatMessageStream =>
      _dataSource.onChatMessage.map((model) => model.toEntity());

  @override
  Stream<EmojiReaction> get emojiReactionStream =>
      _dataSource.onEmojiReaction.map((model) => model.toEntity());

  @override
  Stream<HandRaiseItem> get handRaiseStream => _dataSource.onHandRaise;

  @override
  Stream<MediaStateUpdate> get mediaStateStream => _dataSource.onMediaStateUpdate;

  @override
  Stream<RecordingState> get recordingStateStream =>
      _dataSource.onRecordingState.map((model) => model.toEntity());

  @override
  Future<void> joinRoom(MeetingRoom room, Participant localParticipant) async {
    _localParticipant = localParticipant;
    final model = ParticipantModel.fromEntity(localParticipant);
    await _dataSource.connect(
      roomId: room.code,
      localParticipant: model,
    );
  }

  @override
  Future<void> leaveRoom(String roomId, String peerId) async {
    await _dataSource.disconnect();
    _localParticipant = null;
  }

  @override
  Future<void> sendChatMessage(String roomId, ChatMessage message) async {
    final messageModel = ChatMessageModel.fromEntity(message);
    await _dataSource.broadcastChatMessage(roomId, messageModel);
  }

  @override
  Future<void> sendEmojiReaction(String roomId, EmojiReaction reaction) async {
    final reactionModel = EmojiReactionModel.fromEntity(reaction);
    await _dataSource.broadcastEmojiReaction(roomId, reactionModel);
  }

  @override
  Future<void> toggleHandRaise(String roomId, String peerId, bool isRaised) async {
    await _dataSource.broadcastHandRaise(
      roomId,
      peerId: peerId,
      participantName: _localParticipant?.name ?? '',
      academicId: _localParticipant?.ra ?? '',
      isRaised: isRaised,
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
    if (_localParticipant != null && _localParticipant!.id == peerId) {
      _localParticipant = _localParticipant!.copyWith(
        isAudioMuted: isAudioMuted,
        isVideoOff: isVideoOff,
        isScreenSharing: isScreenSharing,
        audioLevel: audioLevel,
      );
    }
    await _dataSource.broadcastMediaState(
      roomId,
      peerId: peerId,
      isAudioMuted: isAudioMuted,
      isVideoOff: isVideoOff,
      isScreenSharing: isScreenSharing,
      audioLevel: audioLevel,
    );
  }

  @override
  Future<void> updateRecordingState(String roomId, RecordingState state) async {
    final stateModel = RecordingStateModel.fromEntity(state);
    await _dataSource.broadcastRecordingState(roomId, stateModel);
  }

  @override
  Stream<Map<String, dynamic>> get webRtcSignalStream {
    final ds = _dataSource;
    if (ds is IWebRtcSignalingDataSource) {
      return ds.onWebRtcSignal;
    }
    return const Stream.empty();
  }

  @override
  Future<void> sendWebRtcSignal(
    String roomId,
    Map<String, dynamic> signalData,
  ) async {
    final ds = _dataSource;
    if (ds is IWebRtcSignalingDataSource) {
      await ds.broadcastWebRtcSignal(roomId, signalData);
    }
  }

  @override
  Future<void> dispose() async {
    _dataSource.dispose();
  }
}
