// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Represents a physical participant in the video conference room.
///
/// Invariant: ZERO BOTS. Only actual connected peers exist as instances.
class Participant {
  final String id;
  final String name;
  final String ra;
  final String role; // 'student' or 'teacher'
  final bool isAudioMuted;
  final bool isVideoOff;
  final bool isScreenSharing;
  final bool isHandRaised;
  final bool isSpeaking;
  final double audioLevel; // 0.0 to 1.0 RMS

  const Participant({
    required this.id,
    required this.name,
    required this.ra,
    this.role = 'student',
    this.isAudioMuted = false,
    this.isVideoOff = false,
    this.isScreenSharing = false,
    this.isHandRaised = false,
    this.isSpeaking = false,
    this.audioLevel = 0.0,
  });

  Participant copyWith({
    String? id,
    String? name,
    String? ra,
    String? role,
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    bool? isHandRaised,
    bool? isSpeaking,
    double? audioLevel,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      ra: ra ?? this.ra,
      role: role ?? this.role,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      audioLevel: audioLevel ?? this.audioLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ra': ra,
        'role': role,
        'isAudioMuted': isAudioMuted,
        'isVideoOff': isVideoOff,
        'isScreenSharing': isScreenSharing,
        'isHandRaised': isHandRaised,
        'isSpeaking': isSpeaking,
        'audioLevel': audioLevel,
      };

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'] as String,
        name: json['name'] as String,
        ra: json['ra'] as String,
        role: (json['role'] as String?) ?? 'student',
        isAudioMuted: (json['isAudioMuted'] as bool?) ?? false,
        isVideoOff: (json['isVideoOff'] as bool?) ?? false,
        isScreenSharing: (json['isScreenSharing'] as bool?) ?? false,
        isHandRaised: (json['isHandRaised'] as bool?) ?? false,
        isSpeaking: (json['isSpeaking'] as bool?) ?? false,
        audioLevel: (json['audioLevel'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          ra == other.ra &&
          role == other.role &&
          isAudioMuted == other.isAudioMuted &&
          isVideoOff == other.isVideoOff &&
          isScreenSharing == other.isScreenSharing &&
          isHandRaised == other.isHandRaised &&
          isSpeaking == other.isSpeaking &&
          audioLevel == other.audioLevel;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        ra,
        role,
        isAudioMuted,
        isVideoOff,
        isScreenSharing,
        isHandRaised,
        isSpeaking,
        audioLevel,
      );
}

/// Represents the meeting room identity and configuration.
class MeetingRoom {
  final String id;
  final String code;
  final String title;

  const MeetingRoom({
    required this.id,
    required this.code,
    required this.title,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
      };

  factory MeetingRoom.fromJson(Map<String, dynamic> json) => MeetingRoom(
        id: json['id'] as String,
        code: json['code'] as String,
        title: (json['title'] as String?) ?? 'Sala de Reunião',
      );
}

/// Real-time chat message exchanged peer-to-peer.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRa;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRa,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'senderRa': senderRa,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        senderRa: json['senderRa'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Floating emoji reaction broadcast to peers.
class EmojiReaction {
  final String id;
  final String peerId;
  final String peerName;
  final String emoji;
  final DateTime timestamp;

  const EmojiReaction({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.emoji,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'peerId': peerId,
        'peerName': peerName,
        'emoji': emoji,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EmojiReaction.fromJson(Map<String, dynamic> json) => EmojiReaction(
        id: json['id'] as String,
        peerId: json['peerId'] as String,
        peerName: json['peerName'] as String,
        emoji: json['emoji'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// An entry in the ordered raised-hands participant queue.
class HandRaiseItem {
  final String peerId;
  final String name;
  final String ra;
  final DateTime raisedAt;

  const HandRaiseItem({
    required this.peerId,
    required this.name,
    required this.ra,
    required this.raisedAt,
  });

  Map<String, dynamic> toJson() => {
        'peerId': peerId,
        'name': name,
        'ra': ra,
        'raisedAt': raisedAt.toIso8601String(),
      };

  factory HandRaiseItem.fromJson(Map<String, dynamic> json) => HandRaiseItem(
        peerId: json['peerId'] as String,
        name: json['name'] as String,
        ra: json['ra'] as String,
        raisedAt: DateTime.parse(json['raisedAt'] as String),
      );
}

/// Dynamic media state update broadcast when audio/video/screen change.
class MediaStateUpdate {
  final String peerId;
  final bool? isAudioMuted;
  final bool? isVideoOff;
  final bool? isScreenSharing;
  final double? audioLevel;

  const MediaStateUpdate({
    required this.peerId,
    this.isAudioMuted,
    this.isVideoOff,
    this.isScreenSharing,
    this.audioLevel,
  });

  Map<String, dynamic> toJson() => {
        'peerId': peerId,
        if (isAudioMuted != null) 'isAudioMuted': isAudioMuted,
        if (isVideoOff != null) 'isVideoOff': isVideoOff,
        if (isScreenSharing != null) 'isScreenSharing': isScreenSharing,
        if (audioLevel != null) 'audioLevel': audioLevel,
      };

  factory MediaStateUpdate.fromJson(Map<String, dynamic> json) =>
      MediaStateUpdate(
        peerId: json['peerId'] as String,
        isAudioMuted: json['isAudioMuted'] as bool?,
        isVideoOff: json['isVideoOff'] as bool?,
        isScreenSharing: json['isScreenSharing'] as bool?,
        audioLevel: (json['audioLevel'] as num?)?.toDouble(),
      );
}

/// Global recording state synchronized across all peers in the room.
class RecordingState {
  final bool isRecording;
  final DateTime? startedAt;
  final Duration elapsedDuration;
  final String? startedByPeerId;

  const RecordingState({
    this.isRecording = false,
    this.startedAt,
    this.elapsedDuration = Duration.zero,
    this.startedByPeerId,
  });

  RecordingState copyWith({
    bool? isRecording,
    DateTime? startedAt,
    Duration? elapsedDuration,
    String? startedByPeerId,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      startedAt: startedAt ?? this.startedAt,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      startedByPeerId: startedByPeerId ?? this.startedByPeerId,
    );
  }

  Map<String, dynamic> toJson() => {
        'isRecording': isRecording,
        'startedAt': startedAt?.toIso8601String(),
        'elapsedDurationMs': elapsedDuration.inMilliseconds,
        'startedByPeerId': startedByPeerId,
      };

  factory RecordingState.fromJson(Map<String, dynamic> json) => RecordingState(
        isRecording: (json['isRecording'] as bool?) ?? false,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        elapsedDuration: Duration(
          milliseconds: (json['elapsedDurationMs'] as int?) ?? 0,
        ),
        startedByPeerId: json['startedByPeerId'] as String?,
      );
}

/// Snapshot ledger of the recorded meeting session for export.
class SessionExport {
  final String roomCode;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration totalDuration;
  final int totalParticipants;
  final List<String> attendeeNames;
  final int chatMessageCount;
  final int reactionCount;

  const SessionExport({
    required this.roomCode,
    required this.startedAt,
    required this.endedAt,
    required this.totalDuration,
    required this.totalParticipants,
    required this.attendeeNames,
    required this.chatMessageCount,
    required this.reactionCount,
  });

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'totalDurationSeconds': totalDuration.inSeconds,
        'totalParticipants': totalParticipants,
        'attendeeNames': attendeeNames,
        'chatMessageCount': chatMessageCount,
        'reactionCount': reactionCount,
        'exportFormat': 'academic_session_ledger_v1',
      };
}

/// Abstract contract for the raw P2P signaling channel.
abstract class ISignalingChannel {
  Stream<String> get messageStream;
  Future<void> send(String data);
  Future<void> close();
}

/// Abstract repository contract adhering to Clean Architecture.
abstract class VideoCallRepository {
  Stream<Participant> get participantJoinedStream;
  Stream<String> get participantLeftStream;
  Stream<ChatMessage> get chatMessageStream;
  Stream<EmojiReaction> get emojiReactionStream;
  Stream<HandRaiseItem> get handRaiseStream;
  Stream<MediaStateUpdate> get mediaStateStream;
  Stream<RecordingState> get recordingStateStream;

  Future<void> joinRoom(MeetingRoom room, Participant localParticipant);
  Future<void> leaveRoom(String roomId, String peerId);
  Future<void> sendChatMessage(String roomId, ChatMessage message);
  Future<void> sendEmojiReaction(String roomId, EmojiReaction reaction);
  Future<void> toggleHandRaise(String roomId, String peerId, bool isRaised);
  Future<void> updateMediaState(
    String roomId,
    String peerId, {
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    double? audioLevel,
  });
  Future<void> updateRecordingState(String roomId, RecordingState state);
}
