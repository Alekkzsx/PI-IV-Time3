// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../controllers/video_call_controller.dart';

/// Gaveta lateral exibindo a lista em tempo real de todos os participantes conectados.
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
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          AppBar(
            backgroundColor: const Color(0xFF1E293B),
            title: Text(
              'Participantes (${participants.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                key: const Key('close_participants_drawer_button'),
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: controller.toggleParticipantsDrawer,
              ),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: participants.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final p = participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1E293B),
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
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
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (p.isHost) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigoAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Host',
                            style: TextStyle(
                              color: Colors.white,
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
                      color: Colors.white54,
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
                            color: Colors.indigoAccent,
                            size: 16,
                          ),
                        ),
                      Icon(
                        p.isVideoOff ? Icons.videocam_off : Icons.videocam,
                        color: p.isVideoOff ? Colors.redAccent : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        p.isAudioMuted ? Icons.mic_off : Icons.mic,
                        color: p.isAudioMuted
                            ? Colors.redAccent
                            : (p.isSpeaking
                                ? Colors.greenAccent
                                : Colors.white70),
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
