// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/entities/participant.dart';
import '../theme/video_call_theme.dart';
import 'audio_level_meter.dart';
import 'real_video_renderer.dart';

/// Tile individual de exibição de vídeo/avatar de um participante real da conferência.
///
/// Apresenta o stream de câmera HTML5 real via [RealVideoRenderer] ou avatar com
/// gradiente monocromático e iniciais, insígnia institucional com nome e RA, badges de
/// silenciamento, compartilhamento de tela e mão levantada, além da moldura luminosa
/// branca de alto-falante ativo (Estética Preto, Cinza e Branco).
class ParticipantVideoTile extends StatelessWidget {
  /// Entidade do participante real a ser renderizada.
  final Participant participant;

  /// Identificador opcional da view HTML5 `<video>` registrada no `platformViewRegistry`.
  final String? videoViewType;

  /// Indica se este participante está fixado (pin/spotlight) na grade.
  final bool isPinned;

  /// Callback opcional ao clicar/tocar no quadro do participante (para destaque/pin).
  final VoidCallback? onTap;

  const ParticipantVideoTile({
    super.key,
    required this.participant,
    this.videoViewType,
    this.isPinned = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSpeaking = participant.isSpeaking;

    return Container(
      key: Key('participant_tile_${participant.id}'),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: VideoCallColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSpeaking
              ? VideoCallColors.accentWhite
              : (isPinned ? VideoCallColors.borderStrong : Colors.transparent),
          width: isSpeaking ? 3.0 : 1.0,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: VideoCallColors.accentWhite.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Feed de câmera real ou Avatar monocromático com iniciais
            Center(
              child: participant.isVideoOff
                  ? CircleAvatar(
                      key: Key('avatar_${participant.id}'),
                      radius: 36,
                      backgroundColor: VideoCallColors.background,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: VideoCallColors.borderStrong,
                            width: 1.5,
                          ),
                          gradient: const LinearGradient(
                            colors: [
                              VideoCallColors.surfaceHover,
                              VideoCallColors.surface,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            participant.name.isNotEmpty
                                ? participant.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              color: VideoCallColors.accentWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      key: Key('camera_feed_${participant.id}'),
                      decoration: BoxDecoration(
                        color: VideoCallColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: RealVideoRenderer(
                        viewType: videoViewType,
                        fallbackIcon: Icons.videocam,
                      ),
                    ),
            ),

            // Barra inferior com Nome, RA, Papel e Medidor de Áudio
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: VideoCallColors.background.withValues(alpha: 0.80),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: VideoCallColors.border,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${participant.name} (${participant.ra})',
                      style: const TextStyle(
                        color: VideoCallColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (participant.role.isNotEmpty &&
                        participant.role.toLowerCase() != 'student' &&
                        participant.role.toLowerCase() != 'participant') ...[
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
                        child: Text(
                          participant.role.toLowerCase() == 'host'
                              ? 'Anfitrião'
                              : participant.role.toLowerCase() == 'presenter'
                                  ? 'Apresentador'
                                  : participant.role.toUpperCase(),
                          style: const TextStyle(
                            color: VideoCallColors.accentWhite,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (participant.isScreenSharing) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.screen_share,
                        color: VideoCallColors.accentWhite,
                        size: 14,
                      ),
                    ],
                    if (participant.isAudioMuted) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.mic_off,
                        color: VideoCallColors.textSecondary,
                        size: 14,
                      ),
                    ] else ...[
                      const SizedBox(width: 6),
                      AudioLevelMeter(level: participant.audioLevel),
                    ],
                  ],
                ),
              ),
            ),

            // Indicador de participante fixado (topo esquerdo)
            if (isPinned)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VideoCallColors.background.withValues(alpha: 0.80),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: VideoCallColors.borderStrong),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.push_pin,
                        size: 12,
                        color: VideoCallColors.accentWhite,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Fixado',
                        style: TextStyle(
                          color: VideoCallColors.accentWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Indicador de mão levantada (topo direito)
            if (participant.isHandRaised)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  key: Key('hand_raised_icon_${participant.id}'),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: VideoCallColors.accentWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VideoCallColors.background,
                      width: 1.5,
                    ),
                  ),
                  child: const Text('✋', style: TextStyle(fontSize: 16)),
                ),
              ),

            // Detector de toque opcional
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
