// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../controllers/video_call_controller.dart';
import '../theme/video_call_theme.dart';

/// Gaveta lateral exibindo a lista em tempo real de todos os participantes conectados (Estética Preto, Cinza e Branco).
///
/// Invariante Zero Bots: exibe estritamente os participantes humanos presentes,
/// com seus respectivos estados de microfone, câmera, compartilhamento de tela e mão levantada.
class ParticipantsDrawer extends StatelessWidget {
  final VideoCallController controller;

  const ParticipantsDrawer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final participants = controller.allParticipants;

    return Container(
      key: const Key('participants_drawer'),
      width: 320,
      decoration: const BoxDecoration(
        color: VideoCallColors.surface,
        border: Border(
          left: BorderSide(color: VideoCallColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          AppBar(
            backgroundColor: VideoCallColors.background,
            elevation: 0,
            title: Text(
              'Participantes (${participants.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: VideoCallColors.textPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                key: const Key('close_participants_drawer_button'),
                icon: const Icon(
                  Icons.close,
                  color: VideoCallColors.textSecondary,
                ),
                onPressed: controller.toggleParticipantsDrawer,
              ),
            ],
          ),
          const Divider(color: VideoCallColors.border, height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: participants.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: VideoCallColors.border, height: 1),
              itemBuilder: (context, index) {
                final p = participants[index];
                return ListTile(
                  onTap: () => controller.togglePinParticipant(p.id),
                  leading: CircleAvatar(
                    backgroundColor: VideoCallColors.surfaceElevated,
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: VideoCallColors.accentWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.isLocal ? '${p.name} (Você)' : p.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VideoCallColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (p.isHost) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: VideoCallColors.surfaceHover,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Host',
                            style: TextStyle(
                              color: VideoCallColors.accentWhite,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    'RA: ${p.ra}',
                    style: const TextStyle(
                      color: VideoCallColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.isHandRaised)
                        const Padding(
                          padding: EdgeInsets.only(right: 6.0),
                          child: Text('✋', style: TextStyle(fontSize: 14)),
                        ),
                      if (p.isScreenSharing)
                        const Padding(
                          padding: EdgeInsets.only(right: 6.0),
                          child: Icon(
                            Icons.screen_share,
                            color: VideoCallColors.accentWhite,
                            size: 16,
                          ),
                        ),
                      Icon(
                        p.isVideoOff ? Icons.videocam_off : Icons.videocam,
                        color: p.isVideoOff
                            ? VideoCallColors.textMuted
                            : VideoCallColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        p.isAudioMuted ? Icons.mic_off : Icons.mic,
                        color: p.isAudioMuted
                            ? VideoCallColors.textMuted
                            : (p.isSpeaking
                                ? VideoCallColors.accentWhite
                                : VideoCallColors.textSecondary),
                        size: 16,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
