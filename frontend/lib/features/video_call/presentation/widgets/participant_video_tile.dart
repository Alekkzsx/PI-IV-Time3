// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/entities/participant.dart';
import 'audio_level_meter.dart';

/// Tile individual de exibição de vídeo/avatar de um participante real da conferência.
///
/// Apresenta o stream de câmera ou avatar com gradiente animado e iniciais,
/// insígnia institucional com nome e RA, badges de silenciamento, compartilhamento
/// de tela e mão levantada, além da moldura luminosa halo de alto-falante ativo.
class ParticipantVideoTile extends StatelessWidget {
  /// Entidade do participante real a ser renderizada.
  final Participant participant;

  /// Callback opcional ao clicar/tocar no quadro do participante (para destaque/pin).
  final VoidCallback? onTap;

  const ParticipantVideoTile({
    super.key,
    required this.participant,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSpeaking = participant.isSpeaking;

    return Container(
      key: Key('participant_tile_${participant.id}'),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSpeaking ? Colors.greenAccent : Colors.transparent,
          width: isSpeaking ? 3.0 : 1.0,
        ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
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
            // Feed de câmera ou Avatar com iniciais
            Center(
              child: participant.isVideoOff
                  ? CircleAvatar(
                      key: Key('avatar_${participant.id}'),
                      radius: 36,
                      backgroundColor: const Color(0xFF0F172A),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E1B4B)],
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                        child: Icon(
                          Icons.videocam,
                          color: Colors.white38,
                          size: 48,
                        ),
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
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${participant.name} (${participant.ra})',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (participant.role.isNotEmpty &&
                        participant.role.toLowerCase() != 'student' &&
                        participant.role.toLowerCase() != 'participant') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          participant.role.toLowerCase() == 'host'
                              ? 'Anfitrião'
                              : participant.role.toLowerCase() == 'presenter'
                                  ? 'Apresentador'
                                  : participant.role.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
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
                        color: Colors.indigoAccent,
                        size: 14,
                      ),
                    ],
                    if (participant.isAudioMuted) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.mic_off,
                        color: Colors.redAccent,
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

            // Indicador de mão levantada (topo direito)
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
