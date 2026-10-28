// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/state/academic_bridge_service.dart';
import '../../data/media/call_media_engine.dart';
import '../../data/media/call_media_engine_factory.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/emoji_reaction.dart';
import '../../domain/entities/hand_raise_item.dart';
import '../../domain/entities/media_state_update.dart';
import '../../domain/entities/meeting_room.dart';
import '../../domain/entities/participant.dart';
import '../../domain/entities/recording_state.dart';
import '../../domain/entities/session_export.dart';
import '../../domain/repositories/video_call_repository.dart';

/// Controlador central de estado e ciclo de vida da chamada de vídeo P2P.
///
/// Implementa a sincronização em tempo real de presença (Invariante Zero Bots),
/// controle de streams reais de áudio/vídeo/WebRTC, detecção de orador ativo com histerese,
/// compartilhamento de tela real (`getDisplayMedia`), chat interno, reações de emojis,
/// fila de mãos levantadas e gravação real (`MediaRecorder`) da sessão acadêmica.
class VideoCallController extends ChangeNotifier {
  final VideoCallRepository repository;
  final MeetingRoom room;
  final ICallMediaEngine mediaEngine;

  Participant _localParticipant;
  final Map<String, Participant> _remoteParticipants = {};
  final List<ChatMessage> _chatMessages = [];
  final List<EmojiReaction> _activeReactions = [];
  final List<HandRaiseItem> _raisedHandsQueue = [];
  RecordingState _recordingState = const RecordingState();
  SessionExport? _lastSessionExport;
  String? _lastDownloadedFileName;
  int _totalReactionsCount = 0;

  bool _isScreenSharing = false;
  bool _isChatDrawerOpen = false;
  bool _isParticipantsDrawerOpen = false;
  int _unreadChatCount = 0;
  Duration _callDuration = Duration.zero;
  String? _pinnedParticipantId;
  String? _mediaStatus;

  Timer? _callDurationTimer;
  Timer? _recordingTimer;
  Timer? _speakingHysteresisTimer;
  final List<Timer> _reactionTimers = [];
  final List<StreamSubscription> _subscriptions = [];
  bool _isDisposed = false;

  VideoCallController({
    required this.repository,
    required this.room,
    required Participant localParticipant,
    ICallMediaEngine? mediaEngine,
  }) : _localParticipant = localParticipant,
       mediaEngine = mediaEngine ?? createPlatformMediaEngine() {
    _init();
  }

  Participant get localParticipant => _localParticipant;
  bool get canManageMeeting {
    final bridge = AcademicBridgeService.instance;
    return !bridge.hasSession(room.code) ||
        bridge.canUserOpenSessionForCourse(
          role: _localParticipant.role,
          rawCourseCode: room.code,
        );
  }

  List<Participant> get remoteParticipants =>
      List.unmodifiable(_remoteParticipants.values);

  /// Invariante estrita de Zero Bots:
  /// Participante sozinho = exatamente 1 tile.
  /// Dois conectados = exatamente 2 tiles.
  /// Zero participantes sintéticos ou mocks.
  List<Participant> get allParticipants =>
      List.unmodifiable([_localParticipant, ..._remoteParticipants.values]);

  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  List<EmojiReaction> get activeReactions =>
      List.unmodifiable(_activeReactions);
  List<HandRaiseItem> get raisedHandsQueue =>
      List.unmodifiable(_raisedHandsQueue);
  RecordingState get recordingState => _recordingState;
  SessionExport? get lastSessionExport => _lastSessionExport;
  String? get lastDownloadedFileName => _lastDownloadedFileName;
  int get totalReactionsCount => _totalReactionsCount;
  bool get isScreenSharing =>
      _isScreenSharing ||
      _remoteParticipants.values.any((p) => p.isScreenSharing);
  bool get isLocalScreenSharing => _isScreenSharing;
  bool get isChatDrawerOpen => _isChatDrawerOpen;
  bool get isParticipantsDrawerOpen => _isParticipantsDrawerOpen;
  int get unreadChatCount => _unreadChatCount;
  Duration get callDuration => _callDuration;
  String? get pinnedParticipantId => _pinnedParticipantId;
  String? get mediaStatus => _mediaStatus;

  /// Retorna o `viewType` de vídeo registrado para um participante (local ou remoto).
  String? getParticipantVideoViewType(Participant participant) {
    if (participant.isLocal) {
      return mediaEngine.getVideoViewType('local');
    }
    return mediaEngine.getVideoViewType(participant.id);
  }

  /// Retorna o `viewType` do compartilhamento de tela (local ou do par apresentador).
  String? get screenShareVideoViewType {
    if (_isScreenSharing) {
      return mediaEngine.getVideoViewType('screen') ??
          mediaEngine.getVideoViewType('local');
    }
    final remotePresenter = _remoteParticipants.values
        .where((p) => p.isScreenSharing)
        .firstOrNull;
    if (remotePresenter != null) {
      return mediaEngine.getVideoViewType(remotePresenter.id);
    }
    return null;
  }

  /// Retorna o nome de quem está compartilhando a tela atualmente.
  String? get activePresenterName {
    if (_isScreenSharing) return '${_localParticipant.name} (Você)';
    final remotePresenter = _remoteParticipants.values
        .where((p) => p.isScreenSharing)
        .firstOrNull;
    return remotePresenter?.name;
  }

  void _init() {
    _subscriptions.add(
      repository.participantJoinedStream.listen(_onParticipantJoined),
    );
    _subscriptions.add(
      repository.participantLeftStream.listen(_onParticipantLeft),
    );
    _subscriptions.add(
      repository.chatMessageStream.listen(_onChatMessageReceived),
    );
    _subscriptions.add(
      repository.emojiReactionStream.listen(_onEmojiReactionReceived),
    );
    _subscriptions.add(repository.handRaiseStream.listen(_onHandRaiseReceived));
    _subscriptions.add(
      repository.mediaStateStream.listen(_onMediaStateReceived),
    );
    _subscriptions.add(
      repository.recordingStateStream.listen(_onRecordingStateReceived),
    );
    final repo = repository;
    if (repo is WebRtcSignalingRepository) {
      _subscriptions.add(
        repo.webRtcSignalStream.listen(_onWebRtcSignalReceived),
      );
    }

    // Conecta streams do motor de mídia real (Microfone RMS, WebRTC e Tela)
    _subscriptions.add(
      mediaEngine.onLocalAudioLevel.listen((level) {
        if (!_isDisposed && !_localParticipant.isAudioMuted) {
          setAudioLevel(level);
        }
      }),
    );
    _subscriptions.add(
      mediaEngine.onScreenShareStoppedExternally.listen((_) {
        if (!_isDisposed && _isScreenSharing) {
          _isScreenSharing = false;
          _localParticipant = _localParticipant.copyWith(
            isScreenSharing: false,
          );
          repository.updateMediaState(
            room.code,
            _localParticipant.id,
            isScreenSharing: false,
          );
          notifyListeners();
        }
      }),
    );
    _subscriptions.add(
      mediaEngine.onOutboundWebRtcSignal.listen((signalData) {
        if (!_isDisposed && repo is WebRtcSignalingRepository) {
          repo.sendWebRtcSignal(room.code, signalData);
        }
      }),
    );
    _subscriptions.add(
      mediaEngine.onVideoStreamUpdated.listen((_) {
        if (!_isDisposed) {
          notifyListeners();
        }
      }),
    );
    _subscriptions.add(
      mediaEngine.onMediaStatus.listen((message) {
        if (!_isDisposed) {
          _mediaStatus = message;
          notifyListeners();
        }
      }),
    );

    // Inicializa hardware local caso ainda não tenha vindo pré-aquecido do Lobby
    mediaEngine.initializeLocalMedia(
      audioMuted: _localParticipant.isAudioMuted,
      videoOff: _localParticipant.isVideoOff,
    );

    // Ingresso oficial na sala via barramento de sinalização P2P
    repository.joinRoom(room, _localParticipant);

    // Timer de duração da chamada em segundos
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isDisposed) {
        _callDuration += const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  /// Permite o registro manual de participantes remotos em simulações ou testes.
  void registerRemoteParticipant(Participant peer) {
    _onParticipantJoined(peer);
  }

  void _onParticipantJoined(Participant peer) {
    if (peer.id != _localParticipant.id) {
      final isNewPeer = !_remoteParticipants.containsKey(peer.id);
      _remoteParticipants[peer.id] = peer;

      if (isNewPeer) {
        // Inicia negociação WebRTC P2P determinística entre os dois participantes reais
        final isInitiator = _localParticipant.id.compareTo(peer.id) < 0;
        mediaEngine.connectToPeer(peer.id, isInitiator: isInitiator);
      }
      notifyListeners();
    }
  }

  void _onParticipantLeft(String peerId) {
    if (_remoteParticipants.containsKey(peerId)) {
      _remoteParticipants.remove(peerId);
      _raisedHandsQueue.removeWhere((item) => item.peerId == peerId);
      if (_pinnedParticipantId == peerId) {
        _pinnedParticipantId = null;
      }
      mediaEngine.disconnectPeer(peerId);
      notifyListeners();
    }
  }

  void _onWebRtcSignalReceived(Map<String, dynamic> signalData) {
    final senderId = signalData['senderId'] as String?;
    if (senderId == null || senderId == _localParticipant.id) return;
    mediaEngine.handleInboundWebRtcSignal(senderId, signalData);
  }

  void _onChatMessageReceived(ChatMessage message) {
    if (message.senderId == _localParticipant.id) return;
    _chatMessages.add(message);
    if (!_isChatDrawerOpen) {
      _unreadChatCount++;
    }
    notifyListeners();
  }

  void _onEmojiReactionReceived(EmojiReaction reaction) {
    if (reaction.peerId == _localParticipant.id) return;
    _totalReactionsCount++;
    _activeReactions.add(reaction);
    notifyListeners();

    // Auto-remoção da reação após término da subida animada (2500ms)
    final timer = Timer(const Duration(milliseconds: 2500), () {
      if (!_isDisposed) {
        _activeReactions.remove(reaction);
        notifyListeners();
      }
    });
    _reactionTimers.add(timer);
  }

  void _onHandRaiseReceived(HandRaiseItem item) {
    if (item.peerId == _localParticipant.id) return;
    final existingIndex = _raisedHandsQueue.indexWhere(
      (h) => h.peerId == item.peerId,
    );
    final bool shouldLower = !item.isRaised || existingIndex >= 0;
    if (shouldLower) {
      if (existingIndex >= 0) {
        _raisedHandsQueue.removeAt(existingIndex);
      }
    } else {
      _raisedHandsQueue.add(item);
    }

    if (_remoteParticipants.containsKey(item.peerId)) {
      final p = _remoteParticipants[item.peerId]!;
      _remoteParticipants[item.peerId] = p.copyWith(isHandRaised: !shouldLower);
    }
    notifyListeners();
  }

  void _onMediaStateReceived(MediaStateUpdate update) {
    if (_remoteParticipants.containsKey(update.peerId)) {
      final current = _remoteParticipants[update.peerId]!;
      final newAudioLevel = update.audioLevel ?? current.audioLevel;
      final isMuted = update.isAudioMuted ?? current.isAudioMuted;
      final isSpeaking = !isMuted && (newAudioLevel > 0.15);

      _remoteParticipants[update.peerId] = current.copyWith(
        isAudioMuted: isMuted,
        isVideoOff: update.isVideoOff ?? current.isVideoOff,
        isScreenSharing: update.isScreenSharing ?? current.isScreenSharing,
        audioLevel: newAudioLevel,
        isSpeaking: isSpeaking,
      );
      notifyListeners();
    }
  }

  void _onRecordingStateReceived(RecordingState state) {
    _recordingState = state;
    if (state.isRecording) {
      _recordingTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (_recordingState.isRecording && !_isDisposed) {
          _recordingState = _recordingState.copyWith(
            elapsedDuration:
                _recordingState.elapsedDuration + const Duration(seconds: 1),
          );
          notifyListeners();
        }
      });
    } else {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      if (state.startedAt != null) {
        _generateSessionExport();
      }
    }
    notifyListeners();
  }

  /// Alterna o microfone físico do participante local.
  void toggleAudio() {
    final newMuted = !_localParticipant.isAudioMuted;
    _localParticipant = _localParticipant.copyWith(
      isAudioMuted: newMuted,
      isSpeaking: newMuted ? false : _localParticipant.isSpeaking,
      audioLevel: newMuted ? 0.0 : _localParticipant.audioLevel,
    );
    mediaEngine.setMicrophoneMuted(newMuted);
    repository.updateMediaState(
      room.code,
      _localParticipant.id,
      isAudioMuted: newMuted,
      audioLevel: newMuted ? 0.0 : _localParticipant.audioLevel,
    );
    notifyListeners();
  }

  /// Alterna a câmera de vídeo física do participante local.
  void toggleVideo() {
    final newVideoOff = !_localParticipant.isVideoOff;
    _localParticipant = _localParticipant.copyWith(isVideoOff: newVideoOff);
    mediaEngine.setCameraOff(newVideoOff);
    repository.updateMediaState(
      room.code,
      _localParticipant.id,
      isVideoOff: newVideoOff,
    );
    notifyListeners();
  }

  /// Alterna o modo de compartilhamento de tela local (`getDisplayMedia`).
  void toggleScreenShare() {
    if (!canManageMeeting) return;
    if (_isScreenSharing) {
      _isScreenSharing = false;
      _localParticipant = _localParticipant.copyWith(isScreenSharing: false);
      repository.updateMediaState(
        room.code,
        _localParticipant.id,
        isScreenSharing: false,
      );
      notifyListeners();
      mediaEngine.stopScreenShare();
    } else {
      _isScreenSharing = true;
      _localParticipant = _localParticipant.copyWith(isScreenSharing: true);
      repository.updateMediaState(
        room.code,
        _localParticipant.id,
        isScreenSharing: true,
      );
      notifyListeners();
      mediaEngine.startScreenShare().then((started) {
        if (!started && !_isDisposed && _isScreenSharing) {
          _isScreenSharing = false;
          _localParticipant = _localParticipant.copyWith(
            isScreenSharing: false,
          );
          repository.updateMediaState(
            room.code,
            _localParticipant.id,
            isScreenSharing: false,
          );
          notifyListeners();
        }
      });
    }
  }

  /// Fixa ou desafixa um participante em destaque (Pin / Spotlight).
  void togglePinParticipant(String participantId) {
    if (_pinnedParticipantId == participantId) {
      _pinnedParticipantId = null;
    } else {
      _pinnedParticipantId = participantId;
    }
    notifyListeners();
  }

  /// Copia o código da sala para a área de transferência.
  Future<void> copyRoomInfo() async {
    await mediaEngine.copyToClipboard(room.code);
  }

  /// Atualiza o nível RMS de áudio local com histerese de 800ms para orador ativo.
  void setAudioLevel(double level) {
    if (_localParticipant.isAudioMuted) return;

    final exceeds = level > 0.15;
    if (exceeds) {
      _speakingHysteresisTimer?.cancel();
      _speakingHysteresisTimer = null;
      _localParticipant = _localParticipant.copyWith(
        audioLevel: level,
        isSpeaking: true,
      );
    } else {
      _localParticipant = _localParticipant.copyWith(audioLevel: level);
      if (_localParticipant.isSpeaking && _speakingHysteresisTimer == null) {
        _speakingHysteresisTimer = Timer(const Duration(milliseconds: 800), () {
          if (!_localParticipant.isAudioMuted &&
              _localParticipant.audioLevel <= 0.15) {
            _localParticipant = _localParticipant.copyWith(isSpeaking: false);
            notifyListeners();
          }
          _speakingHysteresisTimer = null;
        });
      }
    }

    repository.updateMediaState(
      room.code,
      _localParticipant.id,
      audioLevel: level,
    );
    notifyListeners();
  }

  /// Alterna o levantamento de mão e atualiza a fila ordenada FIFO.
  void toggleHandRaise() {
    final newHandRaised = !_localParticipant.isHandRaised;
    _localParticipant = _localParticipant.copyWith(isHandRaised: newHandRaised);

    if (newHandRaised) {
      _raisedHandsQueue.add(
        HandRaiseItem(
          peerId: _localParticipant.id,
          name: _localParticipant.name,
          ra: _localParticipant.ra,
          raisedAt: DateTime.now(),
        ),
      );
    } else {
      _raisedHandsQueue.removeWhere(
        (item) => item.peerId == _localParticipant.id,
      );
    }

    repository.toggleHandRaise(room.code, _localParticipant.id, newHandRaised);
    notifyListeners();
  }

  static int _reactionSequenceCounter = 0;

  /// Dispara reação animada de emoji e transmite aos pares conectados.
  void sendReaction(String emoji) {
    _totalReactionsCount++;
    final reaction = EmojiReaction(
      id: '${DateTime.now().microsecondsSinceEpoch}_${++_reactionSequenceCounter}',
      peerId: _localParticipant.id,
      peerName: _localParticipant.name,
      emoji: emoji,
      timestamp: DateTime.now(),
    );
    _activeReactions.add(reaction);
    repository.sendEmojiReaction(room.code, reaction);
    notifyListeners();

    final timer = Timer(const Duration(milliseconds: 2500), () {
      if (!_isDisposed) {
        _activeReactions.remove(reaction);
        notifyListeners();
      }
    });
    _reactionTimers.add(timer);
  }

  /// Envia mensagem de chat interno com sanitização de espaços em branco.
  void sendChatMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chat = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      senderId: _localParticipant.id,
      senderName: _localParticipant.name,
      senderRa: _localParticipant.ra,
      text: trimmed,
      timestamp: DateTime.now(),
      isLocal: true,
    );
    _chatMessages.add(chat);
    repository.sendChatMessage(room.code, chat);
    notifyListeners();
  }

  /// Alterna a gravação real da reunião (`MediaRecorder`) e propaga o estado aos peers.
  void toggleRecording() {
    if (!canManageMeeting) return;
    if (_recordingState.isRecording) {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      final stoppedState = _recordingState.copyWith(isRecording: false);
      _recordingState = stoppedState;
      repository.updateRecordingState(room.code, stoppedState);
      _generateSessionExport();
      notifyListeners();
      final exportSnap = _lastSessionExport;
      if (exportSnap != null) {
        mediaEngine.stopRecordingAndDownload(exportSnap).then((fileName) {
          if (!_isDisposed) {
            _lastDownloadedFileName = fileName;
            notifyListeners();
          }
        });
      }
    } else {
      final startedState = RecordingState(
        isRecording: true,
        startedAt: DateTime.now(),
        elapsedDuration: Duration.zero,
        startedByPeerId: _localParticipant.id,
        startedByName: _localParticipant.name,
      );
      _recordingState = startedState;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_recordingState.isRecording && !_isDisposed) {
          _recordingState = _recordingState.copyWith(
            elapsedDuration:
                _recordingState.elapsedDuration + const Duration(seconds: 1),
          );
          notifyListeners();
        }
      });
      repository.updateRecordingState(room.code, startedState);
      notifyListeners();
      mediaEngine.startRecording();
    }
  }

  void _generateSessionExport() {
    _lastSessionExport = SessionExport(
      roomCode: room.code,
      startedAt: _recordingState.startedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
      totalDuration: _recordingState.elapsedDuration,
      totalParticipants: allParticipants.length,
      attendeeNames: allParticipants.map((p) => p.name).toList(),
      chatMessageCount: _chatMessages.length,
      reactionCount: _totalReactionsCount,
    );
  }

  /// Alterna a visibilidade da gaveta lateral de chat.
  void toggleChatDrawer() {
    _isChatDrawerOpen = !_isChatDrawerOpen;
    if (_isChatDrawerOpen) {
      _unreadChatCount = 0;
      _isParticipantsDrawerOpen = false;
    }
    notifyListeners();
  }

  /// Alterna a visibilidade da gaveta de participantes da chamada.
  void toggleParticipantsDrawer() {
    _isParticipantsDrawerOpen = !_isParticipantsDrawerOpen;
    if (_isParticipantsDrawerOpen) {
      _isChatDrawerOpen = false;
    }
    notifyListeners();
  }

  /// Desconecta o participante da conferência e transmite o envelope LEAVE.
  void leaveCall() {
    repository.leaveRoom(room.code, _localParticipant.id);
    dispose();
  }

  /// Permite atualização programática do tempo de chamada.
  void updateCallDuration(Duration duration) {
    _callDuration = duration;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _callDurationTimer?.cancel();
    _recordingTimer?.cancel();
    _speakingHysteresisTimer?.cancel();
    for (final timer in _reactionTimers) {
      timer.cancel();
    }
    _reactionTimers.clear();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    mediaEngine.dispose();
    super.dispose();
  }
}
