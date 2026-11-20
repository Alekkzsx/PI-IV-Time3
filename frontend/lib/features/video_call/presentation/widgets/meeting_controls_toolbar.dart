// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../controllers/video_call_controller.dart';
import '../theme/video_call_theme.dart';

/// Barra flutuante inferior de controles e ações da conferência (Estética Preto, Cinza e Branco).
///
/// Agrupa os seletores de mídia (microfone, câmera, tela), reações de emojis,
/// levantamento de mão, gravação da reunião, abertura das gavetas de chat e participantes,
/// e botão de encerramento da chamada.
class MeetingControlsToolbar extends StatelessWidget {
  final VideoCallController controller;
  final VoidCallback? onLeaveCall;

  const MeetingControlsToolbar({
    super.key,
    required this.controller,
    this.onLeaveCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('meeting_controls_toolbar'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: VideoCallColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VideoCallColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
                    ? VideoCallColors.textMuted
                    : VideoCallColors.accentWhite,
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
                    ? VideoCallColors.textMuted
                    : VideoCallColors.accentWhite,
              ),
              onPressed: controller.toggleVideo,
            ),
            if (controller.canManageMeeting)
              IconButton(
                key: const Key('toolbar_screen_share_button'),
                tooltip: controller.isScreenSharing
                    ? 'Parar Apresentação'
                    : 'Compartilhar Tela',
                style: IconButton.styleFrom(
                  backgroundColor: controller.isScreenSharing
                      ? VideoCallColors.accentWhite
                      : Colors.transparent,
                ),
                icon: Icon(
                  Icons.screen_share,
                  color: controller.isScreenSharing
                      ? VideoCallColors.background
                      : VideoCallColors.accentWhite,
                ),
                onPressed: controller.toggleScreenShare,
              ),
            IconButton(
              key: const Key('toolbar_hand_raise_button'),
              tooltip: controller.localParticipant.isHandRaised
                  ? 'Abaixar Mão'
                  : 'Levantar Mão',
              style: IconButton.styleFrom(
                backgroundColor: controller.localParticipant.isHandRaised
                    ? VideoCallColors.accentWhite
                    : Colors.transparent,
              ),
              icon: Icon(
                Icons.pan_tool,
                color: controller.localParticipant.isHandRaised
                    ? VideoCallColors.background
                    : VideoCallColors.accentWhite,
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
              key: const Key('toolbar_reaction_thumbs_up_button'),
              tooltip: 'Reagir com Joinha',
              icon: const Text('👍', style: TextStyle(fontSize: 18)),
              onPressed: () => controller.sendReaction('👍'),
            ),
            IconButton(
              key: const Key('toolbar_reaction_clap_button'),
              tooltip: 'Reagir com Palmas',
              icon: const Text('👏', style: TextStyle(fontSize: 18)),
              onPressed: () => controller.sendReaction('👏'),
            ),
            IconButton(
              key: const Key('toolbar_reaction_laugh_button'),
              tooltip: 'Reagir com Risada',
              icon: const Text('😂', style: TextStyle(fontSize: 18)),
              onPressed: () => controller.sendReaction('😂'),
            ),
            IconButton(
              key: const Key('toolbar_reaction_surprised_button'),
              tooltip: 'Reagir com Surpresa',
              icon: const Text('😮', style: TextStyle(fontSize: 18)),
              onPressed: () => controller.sendReaction('😮'),
            ),
            IconButton(
              key: const Key('toolbar_reaction_party_button'),
              tooltip: 'Reagir com Festa',
              icon: const Text('🎉', style: TextStyle(fontSize: 18)),
              onPressed: () => controller.sendReaction('🎉'),
            ),
            if (controller.canManageMeeting)
              IconButton(
                key: const Key('toolbar_record_button'),
                tooltip: controller.recordingState.isRecording
                    ? 'Parar Gravação e Baixar'
                    : 'Gravar Reunião',
                style: IconButton.styleFrom(
                  backgroundColor: controller.recordingState.isRecording
                      ? VideoCallColors.accentWhite
                      : Colors.transparent,
                ),
                icon: Icon(
                  Icons.fiber_manual_record,
                  color: controller.recordingState.isRecording
                      ? VideoCallColors.background
                      : VideoCallColors.accentWhite,
                ),
                onPressed: controller.toggleRecording,
              ),
            Stack(
              children: [
                IconButton(
                  key: const Key('toolbar_chat_button'),
                  tooltip: 'Chat',
                  style: IconButton.styleFrom(
                    backgroundColor: controller.isChatDrawerOpen
                        ? VideoCallColors.surfaceHover
                        : Colors.transparent,
                  ),
                  icon: const Icon(
                    Icons.chat,
                    color: VideoCallColors.accentWhite,
                  ),
                  onPressed: controller.toggleChatDrawer,
                ),
                if (controller.unreadChatCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: CircleAvatar(
                      key: const Key('unread_chat_badge'),
                      radius: 9,
                      backgroundColor: VideoCallColors.accentWhite,
                      child: Text(
                        '${controller.unreadChatCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: VideoCallColors.background,
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
              style: IconButton.styleFrom(
                backgroundColor: controller.isParticipantsDrawerOpen
                    ? VideoCallColors.surfaceHover
                    : Colors.transparent,
              ),
              icon: const Icon(
                Icons.people_outline,
                color: VideoCallColors.accentWhite,
              ),
              onPressed: controller.toggleParticipantsDrawer,
            ),
            const SizedBox(width: 4),
            IconButton(
              key: const Key('toolbar_leave_button'),
              tooltip: 'Sair da Reunião',
              style: IconButton.styleFrom(
                backgroundColor: VideoCallColors.surfaceElevated,
              ),
              icon: const Icon(
                Icons.call_end,
                color: VideoCallColors.accentWhite,
              ),
              onPressed: () {
                if (onLeaveCall != null) {
                  onLeaveCall!();
                } else {
                  controller.leaveCall();
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
