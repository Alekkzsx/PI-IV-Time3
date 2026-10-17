// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:flutter/material.dart';
import 'video_call_contracts.dart';

/// Concrete controller implementing the VideoCallController contract from PROJECT.md.
///
/// Handles real-time synchronization, zero-bot enforcement, active speaker detection,
/// chat, reactions, hand raises, and recording state.
class VideoCallTestController extends ChangeNotifier {
  final VideoCallRepository repository;
  final MeetingRoom room;

  Participant _localParticipant;
  final Map<String, Participant> _remoteParticipants = {};
  final List<ChatMessage> _chatMessages = [];
  final List<EmojiReaction> _activeReactions = [];
  final List<HandRaiseItem> _raisedHandsQueue = [];
  RecordingState _recordingState = const RecordingState();
  SessionExport? _lastSessionExport;

  bool _isScreenSharing = false;
  bool _isChatDrawerOpen = false;
  bool _isParticipantsDrawerOpen = false;
  int _unreadChatCount = 0;
  Duration _callDuration = Duration.zero;

  Timer? _callDurationTimer;
  Timer? _recordingTimer;
  Timer? _speakingHysteresisTimer;
  final List<StreamSubscription> _subscriptions = [];

  VideoCallTestController({
    required this.repository,
    required this.room,
    required Participant localParticipant,
  }) : _localParticipant = localParticipant {
    _init();
  }

  Participant get localParticipant => _localParticipant;
  List<Participant> get remoteParticipants =>
      List.unmodifiable(_remoteParticipants.values);

  /// Invariant: strictly real participants.
  /// Alone = exactly 1. Two connected = exactly 2. Zero bots.
  List<Participant> get allParticipants =>
      List.unmodifiable([_localParticipant, ..._remoteParticipants.values]);

  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  List<EmojiReaction> get activeReactions =>
      List.unmodifiable(_activeReactions);
  List<HandRaiseItem> get raisedHandsQueue =>
      List.unmodifiable(_raisedHandsQueue);
  RecordingState get recordingState => _recordingState;
  SessionExport? get lastSessionExport => _lastSessionExport;
  bool get isScreenSharing => _isScreenSharing;
  bool get isChatDrawerOpen => _isChatDrawerOpen;
  bool get isParticipantsDrawerOpen => _isParticipantsDrawerOpen;
  int get unreadChatCount => _unreadChatCount;
  Duration get callDuration => _callDuration;

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
    _subscriptions.add(
      repository.handRaiseStream.listen(_onHandRaiseReceived),
    );
    _subscriptions.add(
      repository.mediaStateStream.listen(_onMediaStateReceived),
    );
    _subscriptions.add(
      repository.recordingStateStream.listen(_onRecordingStateReceived),
    );

    // Join room over signaling bus
    repository.joinRoom(room, _localParticipant);

    // Call duration timer
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _onParticipantJoined(Participant peer) {
    if (peer.id != _localParticipant.id) {
      _remoteParticipants[peer.id] = peer;
      notifyListeners();
    }
  }

  void _onParticipantLeft(String peerId) {
    if (_remoteParticipants.containsKey(peerId)) {
      _remoteParticipants.remove(peerId);
      _raisedHandsQueue.removeWhere((item) => item.peerId == peerId);
      notifyListeners();
    }
  }

  void _onChatMessageReceived(ChatMessage message) {
    _chatMessages.add(message);
    if (!_isChatDrawerOpen) {
      _unreadChatCount++;
    }
    notifyListeners();
  }

  void _onEmojiReactionReceived(EmojiReaction reaction) {
    _activeReactions.add(reaction);
    notifyListeners();
    // Auto-remove reaction after 2500ms ascent duration
    Timer(const Duration(milliseconds: 2500), () {
      _activeReactions.remove(reaction);
      notifyListeners();
    });
  }

  void _onHandRaiseReceived(HandRaiseItem item) {
    final existingIndex =
        _raisedHandsQueue.indexWhere((h) => h.peerId == item.peerId);
    if (existingIndex >= 0) {
      _raisedHandsQueue.removeAt(existingIndex);
    } else {
      _raisedHandsQueue.add(item);
    }

    if (_remoteParticipants.containsKey(item.peerId)) {
      final p = _remoteParticipants[item.peerId]!;
      _remoteParticipants[item.peerId] =
          p.copyWith(isHandRaised: !_raisedHandsQueue.any((h) => h.peerId == item.peerId));
    }
    notifyListeners();
  }

  void _onMediaStateReceived(MediaStateUpdate update) {
    if (_remoteParticipants.containsKey(update.peerId)) {
      final current = _remoteParticipants[update.peerId]!;
      final newAudioLevel = update.audioLevel ?? current.audioLevel;
      final isSpeaking = newAudioLevel > 0.15;

      _remoteParticipants[update.peerId] = current.copyWith(
        isAudioMuted: update.isAudioMuted ?? current.isAudioMuted,
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
    if (!state.isRecording && state.startedAt != null) {
      _generateSessionExport();
    }
    notifyListeners();
  }

  void toggleAudio() {
    final newMuted = !_localParticipant.isAudioMuted;
    _localParticipant = _localParticipant.copyWith(
      isAudioMuted: newMuted,
      isSpeaking: newMuted ? false : _localParticipant.isSpeaking,
      audioLevel: newMuted ? 0.0 : _localParticipant.audioLevel,
    );
    repository.updateMediaState(
      room.code,
      _localParticipant.id,
      isAudioMuted: newMuted,
      audioLevel: newMuted ? 0.0 : _localParticipant.audioLevel,
    );
    notifyListeners();
  }

  void toggleVideo() {
    final newVideoOff = !_localParticipant.isVideoOff;
    _localParticipant = _localParticipant.copyWith(isVideoOff: newVideoOff);
    repository.updateMediaState(
      room.code,
      _localParticipant.id,
      isVideoOff: newVideoOff,
    );
    notifyListeners();
  }

  void toggleScreenShare() {
    _isScreenSharing = !_isScreenSharing;
    _localParticipant =
        _localParticipant.copyWith(isScreenSharing: _isScreenSharing);
    repository.updateMediaState(
      room.code,
      _localParticipant.id,
      isScreenSharing: _isScreenSharing,
    );
    notifyListeners();
  }

  void setAudioLevel(double level) {
    if (_localParticipant.isAudioMuted) return;

    final isSpeaking = level > 0.15;
    _localParticipant = _localParticipant.copyWith(
      audioLevel: level,
      isSpeaking: isSpeaking,
    );

    if (isSpeaking) {
      _speakingHysteresisTimer?.cancel();
      _speakingHysteresisTimer = Timer(const Duration(milliseconds: 800), () {
        if (!_localParticipant.isAudioMuted && _localParticipant.audioLevel <= 0.15) {
          _localParticipant = _localParticipant.copyWith(isSpeaking: false);
          notifyListeners();
        }
      });
    }

    repository.updateMediaState(
      room.code,
      _localParticipant.id,
      audioLevel: level,
    );
    notifyListeners();
  }

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
      _raisedHandsQueue.removeWhere((item) => item.peerId == _localParticipant.id);
    }

    repository.toggleHandRaise(
      room.code,
      _localParticipant.id,
      newHandRaised,
    );
    notifyListeners();
  }

  void sendReaction(String emoji) {
    final reaction = EmojiReaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      peerId: _localParticipant.id,
      peerName: _localParticipant.name,
      emoji: emoji,
      timestamp: DateTime.now(),
    );
    _activeReactions.add(reaction);
    repository.sendEmojiReaction(room.code, reaction);
    notifyListeners();

    Timer(const Duration(milliseconds: 2500), () {
      _activeReactions.remove(reaction);
      notifyListeners();
    });
  }

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
    );
    _chatMessages.add(chat);
    repository.sendChatMessage(room.code, chat);
    notifyListeners();
  }

  void toggleRecording() {
    if (_recordingState.isRecording) {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      final stoppedState = _recordingState.copyWith(isRecording: false);
      _recordingState = stoppedState;
      repository.updateRecordingState(room.code, stoppedState);
      _generateSessionExport();
    } else {
      final startedState = RecordingState(
        isRecording: true,
        startedAt: DateTime.now(),
        elapsedDuration: Duration.zero,
        startedByPeerId: _localParticipant.id,
      );
      _recordingState = startedState;
      repository.updateRecordingState(room.code, startedState);

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_recordingState.isRecording) {
          _recordingState = _recordingState.copyWith(
            elapsedDuration:
                _recordingState.elapsedDuration + const Duration(seconds: 1),
          );
          notifyListeners();
        }
      });
    }
    notifyListeners();
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
      reactionCount: _activeReactions.length,
    );
  }

  void toggleChatDrawer() {
    _isChatDrawerOpen = !_isChatDrawerOpen;
    if (_isChatDrawerOpen) {
      _unreadChatCount = 0;
      _isParticipantsDrawerOpen = false;
    }
    notifyListeners();
  }

  void toggleParticipantsDrawer() {
    _isParticipantsDrawerOpen = !_isParticipantsDrawerOpen;
    if (_isParticipantsDrawerOpen) {
      _isChatDrawerOpen = false;
    }
    notifyListeners();
  }

  void leaveCall() {
    repository.leaveRoom(room.code, _localParticipant.id);
    dispose();
  }

  @override
  void dispose() {
    _callDurationTimer?.cancel();
    _recordingTimer?.cancel();
    _speakingHysteresisTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}

// ============================================================================
// MODULAR PRESENTATION WIDGETS
// ============================================================================

/// Visual meter indicating RMS audio level.
class AudioLevelMeter extends StatelessWidget {
  final double level; // 0.0 to 1.0

  const AudioLevelMeter({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('audio_level_meter'),
      height: 6,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: level.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: level > 0.15 ? Colors.greenAccent : Colors.lightBlueAccent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

/// Participant video tile widget rendering webcam or avatar fallback.
class ParticipantVideoTile extends StatelessWidget {
  final Participant participant;

  const ParticipantVideoTile({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('participant_tile_${participant.id}'),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: participant.isSpeaking ? Colors.greenAccent : Colors.transparent,
          width: participant.isSpeaking ? 3 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: participant.isVideoOff
                ? CircleAvatar(
                    key: Key('avatar_${participant.id}'),
                    radius: 36,
                    backgroundColor: const Color(0xFF0F172A),
                    child: Text(
                      participant.name.isNotEmpty
                          ? participant.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Container(
                    key: Key('camera_feed_${participant.id}'),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.videocam, color: Colors.white38, size: 48),
                    ),
                  ),
          ),
          // Name and RA badge
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${participant.name} (${participant.ra})',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  if (participant.isAudioMuted) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.mic_off, color: Colors.redAccent, size: 14),
                  ] else ...[
                    const SizedBox(width: 6),
                    AudioLevelMeter(level: participant.audioLevel),
                  ],
                ],
              ),
            ),
          ),
          // Hand raised indicator
          if (participant.isHandRaised)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                key: Key('hand_raised_icon_${participant.id}'),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: const Text('✋', style: TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dynamic video grid displaying 1, 2, or N participant tiles.
class DynamicVideoGrid extends StatelessWidget {
  final List<Participant> participants;
  final bool isScreenSharing;

  const DynamicVideoGrid({
    super.key,
    required this.participants,
    this.isScreenSharing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isScreenSharing) {
      return Column(
        children: [
          const Expanded(flex: 3, child: ScreenShareView()),
          Expanded(
            flex: 1,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: participants.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 180,
                  child: ParticipantVideoTile(participant: participants[index]),
                );
              },
            ),
          ),
        ],
      );
    }

    if (participants.length <= 1) {
      return Center(
        child: participants.isEmpty
            ? const Text('Nenhum participante conectado',
                style: TextStyle(color: Colors.white))
            : ParticipantVideoTile(participant: participants.first),
      );
    }

    if (participants.length == 2) {
      return Row(
        children: [
          Expanded(child: ParticipantVideoTile(participant: participants[0])),
          Expanded(child: ParticipantVideoTile(participant: participants[1])),
        ],
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return ParticipantVideoTile(participant: participants[index]);
      },
    );
  }
}

/// Screen sharing presentation viewport.
class ScreenShareView extends StatelessWidget {
  const ScreenShareView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('screen_share_view'),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigoAccent, width: 2),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.present_to_all, color: Colors.indigoAccent, size: 64),
            SizedBox(height: 12),
            Text(
              'Apresentação de Tela Ativa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliding in-call chat drawer with synchronized messages.
class InCallChatDrawer extends StatefulWidget {
  final VideoCallTestController controller;

  const InCallChatDrawer({super.key, required this.controller});

  @override
  State<InCallChatDrawer> createState() => _InCallChatDrawerState();
}

class _InCallChatDrawerState extends State<InCallChatDrawer> {
  final TextEditingController _textController = TextEditingController();

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      widget.controller.sendChatMessage(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('in_call_chat_drawer'),
      width: 320,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          AppBar(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Chat da Chamada', style: TextStyle(fontSize: 16)),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                key: const Key('close_chat_drawer_button'),
                icon: const Icon(Icons.close),
                onPressed: widget.controller.toggleChatDrawer,
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.controller.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = widget.controller.chatMessages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${msg.senderName} (${msg.senderRa})',
                        style: const TextStyle(
                          color: Colors.indigoAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat_input_field'),
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  key: const Key('send_chat_message_button'),
                  icon: const Icon(Icons.send, color: Colors.indigoAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay rendering floating animated emoji reactions.
class FloatingReactionsOverlay extends StatelessWidget {
  final List<EmojiReaction> reactions;

  const FloatingReactionsOverlay({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: reactions.map((r) {
          return Positioned(
            key: Key('reaction_item_${r.id}'),
            bottom: 80,
            right: 40 + (reactions.indexOf(r) * 30.0) % 200,
            child: Text(
              r.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Raised hands banner displaying the queue of attendees waiting to speak.
class RaisedHandsBanner extends StatelessWidget {
  final List<HandRaiseItem> queue;

  const RaisedHandsBanner({super.key, required this.queue});

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('raised_hands_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber.shade900.withValues(alpha: 0.9),
      child: Row(
        children: [
          const Text('✋ Mãos Levantadas: ',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: queue.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      key: Key('queue_item_${item.peerId}'),
                      label: Text('${item.name} (${item.ra})'),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom floating controls toolbar.
class MeetingControlsToolbar extends StatelessWidget {
  final VideoCallTestController controller;

  const MeetingControlsToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('meeting_controls_toolbar'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('toolbar_audio_button'),
            icon: Icon(
              controller.localParticipant.isAudioMuted
                  ? Icons.mic_off
                  : Icons.mic,
              color: controller.localParticipant.isAudioMuted
                  ? Colors.redAccent
                  : Colors.white,
            ),
            onPressed: controller.toggleAudio,
          ),
          IconButton(
            key: const Key('toolbar_video_button'),
            icon: Icon(
              controller.localParticipant.isVideoOff
                  ? Icons.videocam_off
                  : Icons.videocam,
              color: controller.localParticipant.isVideoOff
                  ? Colors.redAccent
                  : Colors.white,
            ),
            onPressed: controller.toggleVideo,
          ),
          IconButton(
            key: const Key('toolbar_screen_share_button'),
            icon: Icon(
              Icons.screen_share,
              color:
                  controller.isScreenSharing ? Colors.indigoAccent : Colors.white,
            ),
            onPressed: controller.toggleScreenShare,
          ),
          IconButton(
            key: const Key('toolbar_hand_raise_button'),
            icon: Icon(
              Icons.pan_tool,
              color: controller.localParticipant.isHandRaised
                  ? Colors.amber
                  : Colors.white,
            ),
            onPressed: controller.toggleHandRaise,
          ),
          IconButton(
            key: const Key('toolbar_reaction_heart_button'),
            icon: const Text('❤️', style: TextStyle(fontSize: 18)),
            onPressed: () => controller.sendReaction('❤️'),
          ),
          IconButton(
            key: const Key('toolbar_reaction_clap_button'),
            icon: const Text('👏', style: TextStyle(fontSize: 18)),
            onPressed: () => controller.sendReaction('👏'),
          ),
          IconButton(
            key: const Key('toolbar_record_button'),
            icon: Icon(
              Icons.fiber_manual_record,
              color: controller.recordingState.isRecording
                  ? Colors.redAccent
                  : Colors.white,
            ),
            onPressed: controller.toggleRecording,
          ),
          Stack(
            children: [
              IconButton(
                key: const Key('toolbar_chat_button'),
                icon: const Icon(Icons.chat, color: Colors.white),
                onPressed: controller.toggleChatDrawer,
              ),
              if (controller.unreadChatCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: CircleAvatar(
                    key: const Key('unread_chat_badge'),
                    radius: 9,
                    backgroundColor: Colors.redAccent,
                    child: Text(
                      '${controller.unreadChatCount}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            key: const Key('toolbar_leave_button'),
            icon: const Icon(Icons.call_end, color: Colors.redAccent),
            onPressed: controller.leaveCall,
          ),
        ],
      ),
    );
  }
}

/// Complete meeting room page assembling all controls and sub-views.
class VideoCallRoomPage extends StatelessWidget {
  final VideoCallTestController controller;

  const VideoCallRoomPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF05070B),
          body: Stack(
            children: [
              Column(
                children: [
                  // Institutional recording compliance banner
                  if (controller.recordingState.isRecording)
                    Container(
                      key: const Key('institutional_recording_banner'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.red.shade900,
                      child: const Center(
                        child: Text(
                          '● REC — Esta reunião está sendo gravada para fins acadêmicos e pedagógicos.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  // Raised hands queue banner
                  RaisedHandsBanner(queue: controller.raisedHandsQueue),
                  // Main dynamic video grid
                  Expanded(
                    child: DynamicVideoGrid(
                      participants: controller.allParticipants,
                      isScreenSharing: controller.isScreenSharing,
                    ),
                  ),
                ],
              ),
              // Floating reaction particles overlay
              FloatingReactionsOverlay(reactions: controller.activeReactions),
              // Top room information header
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${controller.room.title} (${controller.room.code})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              // Top recording timer badge
              if (controller.recordingState.isRecording)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    key: const Key('recording_timer_badge'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '● REC ${_formatDuration(controller.recordingState.elapsedDuration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Bottom floating toolbar
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: MeetingControlsToolbar(controller: controller),
                ),
              ),
              // Sliding chat drawer
              if (controller.isChatDrawerOpen)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: InCallChatDrawer(controller: controller),
                ),
            ],
          ),
        );
      },
    );
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

/// Pre-join lobby page for input validation, mic/cam preview, and room entry.
class VideoCallLobbyPage extends StatefulWidget {
  final Function(String name, String ra, String roomCode, bool isAudioMuted, bool isVideoOff)?
      onJoin;

  const VideoCallLobbyPage({super.key, this.onJoin});

  @override
  State<VideoCallLobbyPage> createState() => _VideoCallLobbyPageState();
}

class _VideoCallLobbyPageState extends State<VideoCallLobbyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _raController = TextEditingController();
  final _roomCodeController = TextEditingController(text: 'SALA-101');

  bool _isAudioMuted = false;
  bool _isVideoOff = false;
  final double _audioLevelPreview = 0.05;

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onJoin?.call(
        _nameController.text.trim(),
        _raController.text.trim(),
        _roomCodeController.text.trim().toUpperCase(),
        _isAudioMuted,
        _isVideoOff,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      appBar: AppBar(
        title: const Text('Pré-chamada (Lobby)'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const Duration(milliseconds: 500) == Duration.zero
                ? null
                : const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Camera preview box
                  Container(
                    key: const Key('lobby_camera_preview'),
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _isVideoOff
                          ? const Text(
                              'Câmera Desativada',
                              style: TextStyle(color: Colors.white54),
                            )
                          : const Icon(Icons.videocam,
                              color: Colors.white54, size: 64),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mic level meter preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isAudioMuted ? Icons.mic_off : Icons.mic,
                        color: _isAudioMuted ? Colors.redAccent : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      AudioLevelMeter(
                        level: _isAudioMuted ? 0.0 : _audioLevelPreview,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Hardware toggles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        key: const Key('lobby_toggle_mic_button'),
                        icon: Icon(
                          _isAudioMuted ? Icons.mic_off : Icons.mic,
                          color: _isAudioMuted ? Colors.redAccent : Colors.white,
                        ),
                        label: Text(_isAudioMuted ? 'Mudo' : 'Microfone Ativo'),
                        onPressed: () {
                          setState(() {
                            _isAudioMuted = !_isAudioMuted;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        key: const Key('lobby_toggle_cam_button'),
                        icon: Icon(
                          _isVideoOff ? Icons.videocam_off : Icons.videocam,
                          color: _isVideoOff ? Colors.redAccent : Colors.white,
                        ),
                        label: Text(_isVideoOff ? 'Câmera Desligada' : 'Câmera Ligada'),
                        onPressed: () {
                          setState(() {
                            _isVideoOff = !_isVideoOff;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Name input
                  TextFormField(
                    key: const Key('lobby_name_field'),
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome de Exibição',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe seu nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // RA input
                  TextFormField(
                    key: const Key('lobby_ra_field'),
                    controller: _raController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'RA Institucional',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe seu RA';
                      }
                      if (val.trim().length < 4) {
                        return 'RA inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Room Code input
                  TextFormField(
                    key: const Key('lobby_room_code_field'),
                    controller: _roomCodeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Código da Sala (ex: SALA-101)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Informe o código da sala';
                      }
                      final regex = RegExp(r'^[A-Z0-9\-]{3,32}$', caseSensitive: false);
                      if (!regex.hasMatch(val.trim())) {
                        return 'Código da sala inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Join room button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('lobby_join_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                      ),
                      onPressed: _submit,
                      child: const Text(
                        'Entrar na Reunião',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
