// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'ava_section_card.dart';

/// Aba do AVA com transmissão ao vivo da aula, exibição de slides e controles multimídia.
class AvaLiveClassroomTab extends StatelessWidget {
  final StudentPortalController controller;

  const AvaLiveClassroomTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AcademicBridgeService.instance,
      builder: (context, _) {
        final disciplineCode = controller.selectedDiscipline.code;
        final isOpen = AcademicBridgeService.instance.isSessionOpen(
          disciplineCode,
        );
        final session = AcademicBridgeService.instance.getSession(
          disciplineCode,
        );

        return AvaSectionCard(
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isOpen
                              ? Colors.greenAccent
                              : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOpen
                              ? 'AULA AO VIVO: Padrões de Projeto (Aberta por ${session.openedByName ?? "Docente"})'
                              : 'AULA AO VIVO: Aguardando abertura pelo Docente',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: InstColors.ink,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (isOpen) {
                          Navigator.of(context).pushNamed(
                            '/video-call',
                            arguments: {
                              'name': StudentMockData.studentName,
                              'ra': StudentMockData.studentRa,
                              'roomCode': disciplineCode,
                              'role': 'aluno',
                            },
                          );
                        } else {
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: InstColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: InstColors.warning,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Sessão Não Iniciada',
                                    style: TextStyle(color: InstColors.ink),
                                  ),
                                ],
                              ),
                              content: Text(
                                'A videochamada da disciplina $disciplineCode ainda não foi iniciada pelo docente responsável nem pela administração.\n\nApenas o professor da disciplina ou a coordenação podem abrir a chamada da turma.',
                                style: const TextStyle(color: InstColors.muted),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text(
                                    'Compreendido',
                                    style: TextStyle(color: InstColors.ink),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        isOpen ? Icons.open_in_new : Icons.lock_clock,
                        size: 16,
                        color: isOpen ? InstColors.success : InstColors.muted,
                      ),
                      label: Text(
                        isOpen ? 'Ingressar na Sala WebRTC' : 'Sala em Espera',
                        style: TextStyle(
                          color: isOpen ? InstColors.success : InstColors.muted,
                          fontWeight: isOpen
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isOpen
                              ? InstColors.success.withValues(alpha: 0.5)
                              : InstColors.borderStrong,
                        ),
                      ),
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
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
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  IconButton(
                    icon: Icon(
                      controller.isMicMuted ? Icons.mic_off : Icons.mic,
                      color: controller.isMicMuted
                          ? InstColors.danger
                          : InstColors.ink,
                    ),
                    onPressed: controller.toggleMic,
                    tooltip: 'Microfone',
                  ),
                  IconButton(
                    icon: Icon(
                      controller.isCameraOff
                          ? Icons.videocam_off
                          : Icons.videocam,
                      color: controller.isCameraOff
                          ? InstColors.danger
                          : InstColors.ink,
                    ),
                    onPressed: controller.toggleCamera,
                    tooltip: 'Câmera',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.pan_tool,
                      color: controller.isHandRaised
                          ? InstColors.warning
                          : InstColors.ink,
                    ),
                    onPressed: controller.toggleHandRaise,
                    tooltip: 'Levantar a Mão',
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.prevSlide,
                    icon: const Icon(Icons.chevron_left, color: InstColors.ink),
                    label: const Text(
                      'Anterior',
                      style: TextStyle(color: InstColors.ink),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: InstColors.borderStrong),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.nextSlide,
                    icon: const Icon(
                      Icons.chevron_right,
                      color: InstColors.ink,
                    ),
                    label: const Text(
                      'Próximo',
                      style: TextStyle(color: InstColors.ink),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: InstColors.borderStrong),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
