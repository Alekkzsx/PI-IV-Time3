// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';

/// Aba do AVA com transmissão ao vivo da aula, exibição de slides e controles multimídia.
class AvaLiveClassroomTab extends StatelessWidget {
  final StudentPortalController controller;

  const AvaLiveClassroomTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AULA AO VIVO: Padrões de Projeto Estruturais',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/video-call'),
                icon: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Abrir Sala Completa WebRTC',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 380,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.slideshow,
                        size: 64,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Slide ${controller.currentSlideIndex} de ${controller.totalSlides}: Padrão Adapter em Arquitetura Limpa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Profa. Dra. Helena Bittencourt compartilhando tela',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'CC (Legenda Automática): "...o padrão adapter permite que interfaces incompatíveis colaborem sem refatorar o código existente..."',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  controller.isMicMuted ? Icons.mic_off : Icons.mic,
                  color: controller.isMicMuted
                      ? Colors.redAccent
                      : Colors.white,
                ),
                onPressed: controller.toggleMic,
                tooltip: 'Microfone',
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  controller.isCameraOff ? Icons.videocam_off : Icons.videocam,
                  color: controller.isCameraOff
                      ? Colors.redAccent
                      : Colors.white,
                ),
                onPressed: controller.toggleCamera,
                tooltip: 'Câmera',
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  Icons.pan_tool,
                  color: controller.isHandRaised
                      ? Colors.amberAccent
                      : Colors.white,
                ),
                onPressed: controller.toggleHandRaise,
                tooltip: 'Levantar a Mão',
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: controller.prevSlide,
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                label: const Text(
                  'Anterior',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: controller.nextSlide,
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                label: const Text(
                  'Próximo',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

