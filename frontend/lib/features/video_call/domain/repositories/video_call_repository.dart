// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import '../entities/chat_message.dart';
import '../entities/emoji_reaction.dart';
import '../entities/hand_raise_item.dart';
import '../entities/media_state_update.dart';
import '../entities/meeting_room.dart';
import '../entities/participant.dart';
import '../entities/recording_state.dart';

/// Contrato abstrato para orquestração de sinalização P2P e sincronização da reunião.
abstract class VideoCallRepository {
  /// Stream que emite novos participantes que ingressaram ou responderam à presença.
  Stream<Participant> get participantJoinedStream;

  /// Stream que emite o `peerId` de participantes que saíram ou foram podados pelo watchdog.
  Stream<String> get participantLeftStream;

  /// Stream que emite mensagens de chat recebidas dos pares na reunião.
  Stream<ChatMessage> get chatMessageStream;

  /// Stream que emite reações de emoji flutuantes disparadas na sala.
  Stream<EmojiReaction> get emojiReactionStream;

  /// Stream que emite eventos de mãos levantadas ou abaixadas.
  Stream<HandRaiseItem> get handRaiseStream;

  /// Stream que emite atualizações no estado de mídia de qualquer participante.
  Stream<MediaStateUpdate> get mediaStateStream;

  /// Stream que emite mudanças de estado global na gravação da conferência.
  Stream<RecordingState> get recordingStateStream;

  /// Conecta o cliente à sala, inicia a sinalização no canal e publica o handshake JOIN.
  Future<void> joinRoom(MeetingRoom room, Participant localParticipant);

  /// Desconecta o cliente da sala, transmite o envelope LEAVE e encerra a escuta do canal.
  Future<void> leaveRoom(String roomId, String peerId);

  /// Transmite uma mensagem de chat em broadcast para todos os pares na sala.
  Future<void> sendChatMessage(String roomId, ChatMessage message);

  /// Transmite uma reação emoji em broadcast para todos os pares na sala.
  Future<void> sendEmojiReaction(String roomId, EmojiReaction reaction);

  /// Alterna o status da mão levantada do participante local e transmite via sinalização.
  Future<void> toggleHandRaise(String roomId, String peerId, bool isRaised);

  /// Transmite atualizações de mídia local (mutar mic, fechar cam, compartilhar tela, nível RMS).
  Future<void> updateMediaState(
    String roomId,
    String peerId, {
    bool? isAudioMuted,
    bool? isVideoOff,
    bool? isScreenSharing,
    double? audioLevel,
  });

  /// Transmite alteração no estado global de gravação para sincronização entre todos os peers.
  Future<void> updateRecordingState(String roomId, RecordingState state);

  /// Libera canais, timers e stream controllers.
  Future<void> dispose();
}

/// Extensão do contrato de repositório com suporte a troca de sinais WebRTC P2P (SDP/ICE).
abstract class WebRtcSignalingRepository implements VideoCallRepository {
  /// Stream de sinais WebRTC (SDP Offer/Answer e candidatos ICE) recebidos de pares remotos.
  Stream<Map<String, dynamic>> get webRtcSignalStream;

  /// Transmite sinal WebRTC (Offer, Answer ou ICE Candidate) no canal da sala.
  Future<void> sendWebRtcSignal(
    String roomId,
    Map<String, dynamic> signalData,
  );
}
