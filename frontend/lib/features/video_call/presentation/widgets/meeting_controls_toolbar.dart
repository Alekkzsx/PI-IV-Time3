// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../controllers/video_call_controller.dart';

/// Barra flutuante inferior de controles e ações da conferência.
///
/// Agrupa os seletores de mídia (microfone, câmera, tela), reações de emojis,
/// levantamento de mão, gravação da reunião, abertura das gavetas de chat e participantes,
/// e botão de encerramento da chamada.
class MeetingControlsToolbar extends StatelessWidget {
  final VideoCallController controller;

  const MeetingControlsToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('meeting_controls_toolbar'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('toolbar_audio_button'),
            tooltip: controller.localParticipant.isAudioMuted
                ? 'Ativar Microfone'
                : 'Silenciar Microfone',
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
            tooltip: controller.localParticipant.isVideoOff
                ? 'Ligar Câmera'
                : 'Desligar Câmera',
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
            tooltip: controller.isScreenSharing
                ? 'Parar Apresentação'
                : 'Compartilhar Tela',
            icon: Icon(
              Icons.screen_share,
              color: controller.isScreenSharing
                  ? Colors.indigoAccent
                  : Colors.white,
            ),
            onPressed: controller.toggleScreenShare,
          ),
          IconButton(
            key: const Key('toolbar_hand_raise_button'),
            tooltip: controller.localParticipant.isHandRaised
                ? 'Abaixar Mão'
                : 'Levantar Mão',
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
            tooltip: 'Reagir com Coração',
            icon: const Text('❤️', style: TextStyle(fontSize: 18)),
            onPressed: () => controller.sendReaction('❤️'),
          ),
          IconButton(
            key: const Key('toolbar_reaction_clap_button'),
            tooltip: 'Reagir com Palmas',
            icon: const Text('👏', style: TextStyle(fontSize: 18)),
            onPressed: () => controller.sendReaction('👏'),
          ),
          IconButton(
            key: const Key('toolbar_record_button'),
            tooltip: controller.recordingState.isRecording
                ? 'Parar Gravação'
                : 'Gravar Reunião',
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
                tooltip: 'Chat',
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
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            key: const Key('toolbar_participants_button'),
            tooltip: 'Participantes',
            icon: const Icon(Icons.people_outline, color: Colors.white),
            onPressed: controller.toggleParticipantsDrawer,
          ),
          IconButton(
            key: const Key('toolbar_leave_button'),
            tooltip: 'Sair da Reunião',
            icon: const Icon(Icons.call_end, color: Colors.redAccent),
            onPressed: controller.leaveCall,
          ),
        ],
      ),
    );
  }
}
