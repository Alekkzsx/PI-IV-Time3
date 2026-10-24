// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../controllers/video_call_controller.dart';
import '../theme/video_call_theme.dart';
import '../widgets/dynamic_video_grid.dart';
import '../widgets/floating_reactions_overlay.dart';
import '../widgets/in_call_chat_drawer.dart';
import '../widgets/meeting_controls_toolbar.dart';
import '../widgets/participants_drawer.dart';
import '../widgets/raised_hands_banner.dart';

/// Página principal da sala de reunião virtual P2P (Estética Preto, Cinza e Branco).
///
/// Compõe a grade de vídeo adaptativa (DynamicVideoGrid) com streams reais WebRTC,
/// banner de gravação institucional, fila de mãos levantadas, barra de ferramentas
/// flutuante, overlay de reações e gavetas deslizantes de chat e participantes.
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          controller.leaveCall();
        }
      },
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: VideoCallColors.background,
            body: Row(
              children: [
                // Palco principal da conferência (redimensiona automaticamente quando o Chat/Participantes abre)
                Expanded(
                  child: Column(
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
                          decoration: const BoxDecoration(
                            color: VideoCallColors.accentWhite,
                            border: Border(
                              bottom: BorderSide(
                                color: VideoCallColors.border,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '● REC — Esta reunião está sendo gravada para fins acadêmicos e pedagógicos.',
                              style: TextStyle(
                                color: VideoCallColors.background,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (controller.mediaStatus case final status?)
                        Container(
                          key: const Key('call_media_status'),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          color: VideoCallColors.surfaceElevated,
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: VideoCallColors.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      // Banner superior da fila de mãos levantadas (nunca sobreposto pelo chat)
                      RaisedHandsBanner(queue: controller.raisedHandsQueue),
                      // Área de vídeo + overlays do palco
                      Expanded(
                        child: Stack(
                          children: [
                            // Grade dinâmica responsiva de vídeos reais (Strictly Zero Bots)
                            Positioned.fill(
                              child: DynamicVideoGrid(
                                participants: controller.allParticipants,
                                isScreenSharing: controller.isScreenSharing,
                                videoViewTypeBuilder:
                                    controller.getParticipantVideoViewType,
                                screenShareViewType:
                                    controller.screenShareVideoViewType,
                                activePresenterName:
                                    controller.activePresenterName,
                                pinnedParticipantId:
                                    controller.pinnedParticipantId,
                                onParticipantTap: (p) =>
                                    controller.togglePinParticipant(p.id),
                              ),
                            ),
                            // Overlay de partículas de reações de emojis flutuantes (canto inferior esquerdo do palco)
                            Positioned.fill(
                              child: FloatingReactionsOverlay(
                                reactions: controller.activeReactions,
                              ),
                            ),
                            // Cabeçalho superior com título, código da sala e botão de cópia
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: VideoCallColors.surface.withValues(
                                    alpha: 0.90,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: VideoCallColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${controller.room.title} (${controller.room.code})',
                                      style: const TextStyle(
                                        color: VideoCallColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      key: const Key('copy_room_info_button'),
                                      onTap: () async {
                                        await controller.copyRoomInfo();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              backgroundColor: VideoCallColors
                                                  .surfaceElevated,
                                              content: Text(
                                                'Código da sala (${controller.room.code}) copiado para a área de transferência.',
                                                style: const TextStyle(
                                                  color: VideoCallColors
                                                      .textPrimary,
                                                ),
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Icon(
                                        Icons.copy_rounded,
                                        size: 14,
                                        color: VideoCallColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Badge de temporizador de gravação ativa com animação pulsante
                            if (controller.recordingState.isRecording)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  key: const Key('recording_timer_badge'),
                                  child: _PulsatingRecBadge(
                                    text:
                                        '● REC ${_formatDuration(controller.recordingState.elapsedDuration)}',
                                  ),
                                ),
                              ),
                            // Barra inferior flutuante de controles centralizada no palco
                            Positioned(
                              bottom: 24,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: MeetingControlsToolbar(
                                  controller: controller,
                                  onLeaveCall: () {
                                    controller.leaveCall();
                                    if (context.mounted) {
                                      Navigator.of(context).maybePop();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Gaveta lateral de chat (lado a lado com o palco, sem cobrir reações ou vídeos)
                if (controller.isChatDrawerOpen)
                  InCallChatDrawer(controller: controller),
                // Gaveta lateral de participantes (lado a lado com o palco, sem cobrir reações ou vídeos)
                if (controller.isParticipantsDrawerOpen)
                  ParticipantsDrawer(controller: controller),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PulsatingRecBadge extends StatefulWidget {
  final String text;

  const _PulsatingRecBadge({required this.text});

  @override
  State<_PulsatingRecBadge> createState() => _PulsatingRecBadgeState();
}

class _PulsatingRecBadgeState extends State<_PulsatingRecBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: VideoCallColors.accentWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: VideoCallColors.borderStrong),
            ),
            child: Text(
              widget.text,
              style: const TextStyle(
                color: VideoCallColors.background,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
