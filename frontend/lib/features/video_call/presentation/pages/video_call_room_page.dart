// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../controllers/video_call_controller.dart';
import '../widgets/dynamic_video_grid.dart';
import '../widgets/floating_reactions_overlay.dart';
import '../widgets/in_call_chat_drawer.dart';
import '../widgets/meeting_controls_toolbar.dart';
import '../widgets/participants_drawer.dart';
import '../widgets/raised_hands_banner.dart';

/// Página principal da sala de reunião virtual P2P.
///
/// Compõe a grade de vídeo adaptativa (DynamicVideoGrid), banner de gravação institucional,
/// fila de mãos levantadas, barra de ferramentas flutuante, overlay de reações e
/// gavetas deslizantes de chat e participantes.
class VideoCallRoomPage extends StatelessWidget {
  final VideoCallController controller;

  const VideoCallRoomPage({super.key, required this.controller});

  static String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

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
                  // Banner de conformidade de gravação institucional
                  if (controller.recordingState.isRecording)
                    Container(
                      key: const Key('institutional_recording_banner'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 16,
                      ),
                      color: Colors.red.shade900,
                      child: const Center(
                        child: Text(
                          '● REC — Esta reunião está sendo gravada para fins acadêmicos e pedagógicos.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  // Banner superior da fila de mãos levantadas
                  RaisedHandsBanner(queue: controller.raisedHandsQueue),
                  // Grade dinâmica responsiva de vídeos (Strictly Zero Bots)
                  Expanded(
                    child: DynamicVideoGrid(
                      participants: controller.allParticipants,
                      isScreenSharing: controller.isScreenSharing,
                    ),
                  ),
                ],
              ),
              // Overlay de partículas de reações de emojis flutuantes
              FloatingReactionsOverlay(reactions: controller.activeReactions),
              // Cabeçalho superior com título e código da sala
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Badge de temporizador de gravação ativa
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
              // Barra inferior flutuante de controles
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: MeetingControlsToolbar(controller: controller),
                ),
              ),
              // Gaveta lateral deslizante de chat
              if (controller.isChatDrawerOpen)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: InCallChatDrawer(controller: controller),
                ),
              // Gaveta lateral deslizante de participantes
              if (controller.isParticipantsDrawerOpen)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: ParticipantsDrawer(controller: controller),
                ),
            ],
          ),
        );
      },
    );
  }
}
