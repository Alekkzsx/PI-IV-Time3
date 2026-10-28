// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import '../../domain/entities/hand_raise_item.dart';
import '../../domain/entities/media_state_update.dart';
import '../channel/signaling_channel.dart';
import '../channel/signaling_channel_factory.dart';
import '../models/chat_message_model.dart';
import '../models/emoji_reaction_model.dart';
import '../models/participant_model.dart';
import '../models/recording_state_model.dart';
import '../models/signaling_envelope_model.dart';

/// Contrato da fonte de dados de sinalização P2P para videoconferência.
abstract class IVideoCallSignalingDataSource {
  Stream<ParticipantModel> get onParticipantJoined;
  Stream<String> get onParticipantLeft;
  Stream<ChatMessageModel> get onChatMessage;
  Stream<EmojiReactionModel> get onEmojiReaction;
  Stream<HandRaiseItem> get onHandRaise;
  Stream<MediaStateUpdate> get onMediaStateUpdate;
  Stream<RecordingStateModel> get onRecordingState;

  Future<void> connect({
    required String roomId,
    required ParticipantModel localParticipant,
    ISignalingChannel? customChannel,
  });

  Future<void> disconnect();

  Future<void> broadcastChatMessage(String roomId, ChatMessageModel message);

  Future<void> broadcastEmojiReaction(String roomId, EmojiReactionModel reaction);

  Future<void> broadcastHandRaise(
    String roomId, {
    required String peerId,
    required String participantName,
    required String academicId,
    required bool isRaised,
  });

  Future<void> broadcastMediaState(
    String roomId, {
    required String peerId,
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    double? audioLevel,
  });

  Future<void> broadcastRecordingState(String roomId, RecordingStateModel state);

  void updateLocalAudioLevel(double level);

  void dispose();
}

/// Extensão da fonte de dados de sinalização com suporte a troca de sinais WebRTC P2P.
abstract class IWebRtcSignalingDataSource
    implements IVideoCallSignalingDataSource {
  Stream<Map<String, dynamic>> get onWebRtcSignal;

  Future<void> broadcastWebRtcSignal(
    String roomId,
    Map<String, dynamic> signalData,
  );
}

/// Implementação da fonte de dados de sinalização P2P via [ISignalingChannel].
///
/// Garante o invariante Zero Bots:
/// - Handshake recíproco JOIN <-> PRESENCE_SYNC
/// - Heartbeat de 2.0s para telemetria de liveness e áudio RMS
/// - Watchdog de 5.0s para poda automática de nós desconectados abruptamente
class VideoCallSignalingDataSource
    implements IVideoCallSignalingDataSource, IWebRtcSignalingDataSource {
  final ISignalingChannel Function(String channelName)? _channelFactory;

  ISignalingChannel? _channel;
  StreamSubscription<String>? _channelSubscription;

  String? _roomId;
  ParticipantModel? _localParticipant;
  double _currentAudioLevel = 0.0;

  final Map<String, ParticipantModel> _remoteParticipants = {};
  final Map<String, DateTime> _lastSeen = {};

  Timer? _heartbeatTimer;
  Timer? _watchdogTimer;

  final StreamController<ParticipantModel> _onParticipantJoinedController =
      StreamController<ParticipantModel>.broadcast();
  final StreamController<String> _onParticipantLeftController =
      StreamController<String>.broadcast();
  final StreamController<ChatMessageModel> _onChatMessageController =
      StreamController<ChatMessageModel>.broadcast();
  final StreamController<EmojiReactionModel> _onEmojiReactionController =
      StreamController<EmojiReactionModel>.broadcast();
  final StreamController<HandRaiseItem> _onHandRaiseController =
      StreamController<HandRaiseItem>.broadcast();
  final StreamController<MediaStateUpdate> _onMediaStateUpdateController =
      StreamController<MediaStateUpdate>.broadcast();
  final StreamController<RecordingStateModel> _onRecordingStateController =
      StreamController<RecordingStateModel>.broadcast();
  final StreamController<Map<String, dynamic>> _onWebRtcSignalController =
      StreamController<Map<String, dynamic>>.broadcast();

  VideoCallSignalingDataSource({
    ISignalingChannel Function(String channelName)? channelFactory,
  }) : _channelFactory = channelFactory;

  @override
  Stream<ParticipantModel> get onParticipantJoined =>
      _onParticipantJoinedController.stream;

  @override
  Stream<String> get onParticipantLeft => _onParticipantLeftController.stream;

  @override
  Stream<ChatMessageModel> get onChatMessage => _onChatMessageController.stream;

  @override
  Stream<EmojiReactionModel> get onEmojiReaction =>
      _onEmojiReactionController.stream;

  @override
  Stream<HandRaiseItem> get onHandRaise => _onHandRaiseController.stream;

  @override
  Stream<MediaStateUpdate> get onMediaStateUpdate =>
      _onMediaStateUpdateController.stream;

  @override
  Stream<RecordingStateModel> get onRecordingState =>
      _onRecordingStateController.stream;

  @override
  Stream<Map<String, dynamic>> get onWebRtcSignal =>
      _onWebRtcSignalController.stream;

  /// Retorna a lista imutável dos participantes remotos atualmente descobertos.
  List<ParticipantModel> get remoteParticipants =>
      List<ParticipantModel>.unmodifiable(_remoteParticipants.values);

  @override
  Future<void> connect({
    required String roomId,
    required ParticipantModel localParticipant,
    ISignalingChannel? customChannel,
  }) async {
    _roomId = roomId.trim().toUpperCase();
    _localParticipant = localParticipant;

    final channelName = 'p2p_videocall_$_roomId';
    _channel = customChannel ??
        (_channelFactory != null
            ? _channelFactory(channelName)
            : createSignalingChannel(channelName));

    _remoteParticipants.clear();
    _lastSeen.clear();

    _channelSubscription?.cancel();
    _channelSubscription = _channel!.messageStream.listen(
      _handleInboundMessage,
      onError: (Object error) {
        // Ignora erros de canal para manter resiliência P2P
      },
    );

    _channel!.registerTeardownHook(_broadcastLeaveSync);

    // Dispara timers de batimento cardíaco e sentinela
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(milliseconds: 2000),
      _onHeartbeatTick,
    );

    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(
      const Duration(milliseconds: 1000),
      _onWatchdogTick,
    );

    // Publica anúncio inicial JOIN
    await _broadcastEnvelope(
      type: SignalingEnvelopeType.join,
      payload: _localParticipant!.toJson(),
    );
  }

  @override
  Future<void> disconnect() async {
    _broadcastLeaveSync();

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _watchdogTimer?.cancel();
    _watchdogTimer = null;

    await _channelSubscription?.cancel();
    _channelSubscription = null;

    await _channel?.close();
    _channel = null;

    _remoteParticipants.clear();
    _lastSeen.clear();
    _roomId = null;
    _localParticipant = null;
  }

  void _broadcastLeaveSync() {
    if (_roomId == null || _localParticipant == null || _channel == null) return;

    final leaveEnvelope = SignalingEnvelopeModel.create(
      type: SignalingEnvelopeType.leave,
      roomId: _roomId!,
      senderId: _localParticipant!.id,
      senderName: _localParticipant!.name,
      payload: {
        'peerId': _localParticipant!.id,
        'reason': 'user_left',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    try {
      _channel!.send(leaveEnvelope.toRawJson());
    } catch (_) {
      // falha silenciosa em teardown de página
    }
  }

  void _onHeartbeatTick(Timer timer) {
    if (_roomId == null || _localParticipant == null || _channel == null) return;

    final heartbeatPayload = {
      'peerId': _localParticipant!.id,
      'audioLevel': _currentAudioLevel,
      'isAudioMuted': _localParticipant!.isAudioMuted,
      'isVideoOff': _localParticipant!.isVideoOff,
      'isScreenSharing': _localParticipant!.isScreenSharing,
      'isHandRaised': _localParticipant!.isHandRaised,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _broadcastEnvelope(
      type: SignalingEnvelopeType.heartbeat,
      payload: heartbeatPayload,
    );
  }

  void _onWatchdogTick(Timer timer) {
    final now = DateTime.now();
    final expiredPeers = <String>[];

    for (final entry in _lastSeen.entries) {
      if (now.difference(entry.value) > const Duration(seconds: 5)) {
        expiredPeers.add(entry.key);
      }
    }

    for (final peerId in expiredPeers) {
      _lastSeen.remove(peerId);
      _remoteParticipants.remove(peerId);
      if (!_onParticipantLeftController.isClosed) {
        _onParticipantLeftController.add(peerId);
      }
    }
  }

  void _handleInboundMessage(String rawData) {
    try {
      final envelope = SignalingEnvelopeModel.fromRawJson(rawData);

      // Descartar envelopes de salas alheias ou eco do próprio remetente local
      if (envelope.roomId != _roomId) return;
      if (_localParticipant != null && envelope.senderId == _localParticipant!.id) {
        return;
      }

      final type = envelope.type.trim().toLowerCase();

      if (type == SignalingEnvelopeType.join) {
        _handleJoin(envelope);
      } else if (type == SignalingEnvelopeType.presenceSync) {
        _handlePresenceSync(envelope);
      } else if (type == SignalingEnvelopeType.heartbeat) {
        _handleHeartbeat(envelope);
      } else if (type == SignalingEnvelopeType.leave) {
        _handleLeave(envelope);
      } else if (type == SignalingEnvelopeType.chat) {
        _handleChat(envelope);
      } else if (type == SignalingEnvelopeType.emoji) {
        _handleEmoji(envelope);
      } else if (type == SignalingEnvelopeType.handRaise) {
        _handleHandRaise(envelope);
      } else if (type == SignalingEnvelopeType.mediaState) {
        _handleMediaState(envelope);
      } else if (type == SignalingEnvelopeType.recordingState) {
        _handleRecordingState(envelope);
      } else if (type == SignalingEnvelopeType.webrtcSignal) {
        _handleWebRtcSignal(envelope);
      }
    } catch (_) {
      // Ignora mensagens malformadas de terceiros
    }
  }

  void _handleJoin(SignalingEnvelopeModel envelope) {
    final participant = ParticipantModel.fromJson(envelope.payload);
    if (participant.id.isEmpty) return;

    _remoteParticipants[participant.id] = participant;
    _lastSeen[participant.id] = DateTime.now();

    if (!_onParticipantJoinedController.isClosed) {
      _onParticipantJoinedController.add(participant);
    }

    // Handshake Recíproco: responder imediatamente com PRESENCE_SYNC
    if (_localParticipant != null) {
      _broadcastEnvelope(
        type: SignalingEnvelopeType.presenceSync,
        payload: _localParticipant!.toJson(),
      );
    }
  }

  void _handlePresenceSync(SignalingEnvelopeModel envelope) {
    final participant = ParticipantModel.fromJson(envelope.payload);
    if (participant.id.isEmpty) return;

    _remoteParticipants[participant.id] = participant;
    _lastSeen[participant.id] = DateTime.now();

    if (!_onParticipantJoinedController.isClosed) {
      _onParticipantJoinedController.add(participant);
    }
  }

  void _handleHeartbeat(SignalingEnvelopeModel envelope) {
    final senderId = envelope.senderId;
    if (senderId.isEmpty) return;

    _lastSeen[senderId] = DateTime.now();

    final payload = envelope.payload;
    final audioLevel = (payload['audioLevel'] as num?)?.toDouble() ?? 0.0;
    final isAudioMuted = payload['isAudioMuted'] as bool?;
    final isVideoOff = payload['isVideoOff'] as bool?;
    final isScreenSharing = payload['isScreenSharing'] as bool?;

    final existing = _remoteParticipants[senderId];
    if (existing != null) {
      _remoteParticipants[senderId] = existing.copyWith(
        audioLevel: audioLevel,
        isAudioMuted: isAudioMuted,
        isVideoOff: isVideoOff,
        isScreenSharing: isScreenSharing,
        isSpeaking: (isAudioMuted == false) && (audioLevel > 0.15),
        lastHeartbeat: DateTime.now().millisecondsSinceEpoch,
      );
    }

    if (!_onMediaStateUpdateController.isClosed) {
      _onMediaStateUpdateController.add(
        MediaStateUpdate(
          peerId: senderId,
          audioLevel: audioLevel,
          isAudioMuted: isAudioMuted,
          isVideoOff: isVideoOff,
          isScreenSharing: isScreenSharing,
          timestamp: DateTime.fromMillisecondsSinceEpoch(envelope.timestamp),
        ),
      );
    }
  }

  void _handleLeave(SignalingEnvelopeModel envelope) {
    final peerId = (envelope.payload['peerId'] as String?) ?? envelope.senderId;
    if (peerId.isEmpty) return;

    _remoteParticipants.remove(peerId);
    _lastSeen.remove(peerId);

    if (!_onParticipantLeftController.isClosed) {
      _onParticipantLeftController.add(peerId);
    }
  }

  void _handleChat(SignalingEnvelopeModel envelope) {
    final message = ChatMessageModel.fromJson(envelope.payload);
    if (!_onChatMessageController.isClosed) {
      _onChatMessageController.add(message);
    }
  }

  void _handleEmoji(SignalingEnvelopeModel envelope) {
    final reaction = EmojiReactionModel.fromJson(envelope.payload);
    if (!_onEmojiReactionController.isClosed) {
      _onEmojiReactionController.add(reaction);
    }
  }

  void _handleHandRaise(SignalingEnvelopeModel envelope) {
    final payload = envelope.payload;
    final peerId = (payload['peerId'] as String?) ?? envelope.senderId;
    final name = (payload['name'] ?? payload['participantName'] ?? envelope.senderName) as String? ?? '';
    final ra = (payload['ra'] ?? payload['academicId']) as String? ?? '';
    final isRaised = (payload['isRaised'] as bool?) ?? true;
    final raisedAtMs = payload['raisedAt'];

    DateTime raisedAt;
    if (raisedAtMs is int) {
      raisedAt = DateTime.fromMillisecondsSinceEpoch(raisedAtMs);
    } else if (raisedAtMs is String) {
      raisedAt = DateTime.tryParse(raisedAtMs) ?? DateTime.now();
    } else {
      raisedAt = DateTime.now();
    }

    final item = HandRaiseItem(
      peerId: peerId,
      participantName: name,
      academicId: ra,
      raisedAt: raisedAt,
      isRaised: isRaised,
    );

    if (!_onHandRaiseController.isClosed) {
      _onHandRaiseController.add(item);
    }
  }

  void _handleMediaState(SignalingEnvelopeModel envelope) {
    final payload = envelope.payload;
    final peerId = (payload['peerId'] as String?) ?? envelope.senderId;

    final update = MediaStateUpdate(
      peerId: peerId,
      isAudioMuted: payload['isAudioMuted'] as bool?,
      isVideoOff: payload['isVideoOff'] as bool?,
      isScreenSharing: payload['isScreenSharing'] as bool?,
      audioLevel: (payload['audioLevel'] as num?)?.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(envelope.timestamp),
    );

    if (!_onMediaStateUpdateController.isClosed) {
      _onMediaStateUpdateController.add(update);
    }
  }

  void _handleRecordingState(SignalingEnvelopeModel envelope) {
    final model = RecordingStateModel.fromJson(envelope.payload);
    if (!_onRecordingStateController.isClosed) {
      _onRecordingStateController.add(model);
    }
  }

  void _handleWebRtcSignal(SignalingEnvelopeModel envelope) {
    final payload = Map<String, dynamic>.from(envelope.payload);
    final targetPeerId = payload['targetPeerId'] as String?;
    if (targetPeerId != null &&
        _localParticipant != null &&
        targetPeerId != _localParticipant!.id) {
      return;
    }
    payload['senderId'] = envelope.senderId;
    if (!_onWebRtcSignalController.isClosed) {
      _onWebRtcSignalController.add(payload);
    }
  }

  Future<void> _broadcastEnvelope({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    if (_channel == null || _roomId == null || _localParticipant == null) return;

    final envelope = SignalingEnvelopeModel.create(
      type: type,
      roomId: _roomId!,
      senderId: _localParticipant!.id,
      senderName: _localParticipant!.name,
      payload: payload,
    );

    try {
      await _channel!.send(envelope.toRawJson());
    } catch (_) {
      // resiliência em caso de erro de rede transitório
    }
  }

  @override
  Future<void> broadcastChatMessage(String roomId, ChatMessageModel message) async {
    await _broadcastEnvelope(
      type: SignalingEnvelopeType.chat,
      payload: message.toJson(),
    );
  }

  @override
  Future<void> broadcastEmojiReaction(String roomId, EmojiReactionModel reaction) async {
    await _broadcastEnvelope(
      type: SignalingEnvelopeType.emoji,
      payload: reaction.toJson(),
    );
  }

  @override
  Future<void> broadcastHandRaise(
    String roomId, {
    required String peerId,
    required String participantName,
    required String academicId,
    required bool isRaised,
  }) async {
    await _broadcastEnvelope(
      type: SignalingEnvelopeType.handRaise,
      payload: {
        'peerId': peerId,
        'participantName': participantName,
        'name': participantName,
        'academicId': academicId,
        'ra': academicId,
        'isRaised': isRaised,
        'raisedAt': DateTime.now().millisecondsSinceEpoch,
      },
    );
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
    if (audioLevel != null) {
      _currentAudioLevel = audioLevel;
    }
    if (_localParticipant != null) {
      _localParticipant = _localParticipant!.copyWith(
        isAudioMuted: isAudioMuted,
        isVideoOff: isVideoOff,
        isScreenSharing: isScreenSharing,
        audioLevel: audioLevel,
      );
    }

    await _broadcastEnvelope(
      type: SignalingEnvelopeType.mediaState,
      payload: {
        'peerId': peerId,
        if (isAudioMuted != null) 'isAudioMuted': isAudioMuted,
        if (isVideoOff != null) 'isVideoOff': isVideoOff,
        if (isScreenSharing != null) 'isScreenSharing': isScreenSharing,
        if (audioLevel != null) 'audioLevel': audioLevel,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  @override
  Future<void> broadcastRecordingState(String roomId, RecordingStateModel state) async {
    await _broadcastEnvelope(
      type: SignalingEnvelopeType.recordingState,
      payload: state.toJson(),
    );
  }

  @override
  Future<void> broadcastWebRtcSignal(
    String roomId,
    Map<String, dynamic> signalData,
  ) async {
    await _broadcastEnvelope(
      type: SignalingEnvelopeType.webrtcSignal,
      payload: signalData,
    );
  }

  @override
  void updateLocalAudioLevel(double level) {
    _currentAudioLevel = level;
  }

  @override
  void dispose() {
    disconnect();
    _onParticipantJoinedController.close();
    _onParticipantLeftController.close();
    _onChatMessageController.close();
    _onEmojiReactionController.close();
    _onHandRaiseController.close();
    _onMediaStateUpdateController.close();
    _onRecordingStateController.close();
    _onWebRtcSignalController.close();
  }
}
