// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'ava_section_card.dart';

/// Aba do AVA que direciona à sala ao vivo quando o docente inicia a sessão.
class AvaLiveClassroomTab extends StatelessWidget {
  final StudentPortalController controller;

  const AvaLiveClassroomTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AcademicBridgeService.instance,
      builder: (context, _) {
        final disciplineCode = controller.selectedDiscipline?.code ?? '';
        final isOpen =
            AcademicBridgeService.instance.isSessionOpen(disciplineCode) ||
            controller.selectedDiscipline?.isLive == true;
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
                              ? 'AULA AO VIVO: ${controller.selectedDiscipline?.name ?? disciplineCode} (Aberta por ${session.openedByName ?? "Docente"})'
                              : 'AULA AO VIVO: Aguardando abertura pelo Docente',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
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
                              'name': AppUserSession.instance.effectiveName,
                              'ra': AppUserSession.instance.identity ?? '',
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
                          const Text(
                            'A transmissão e os materiais da aula serão exibidos aqui quando disponibilizados.',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.selectedDiscipline?.professor ?? '',
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
                          'A legenda da transmissão será exibida quando disponível.',
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
            ],
          ),
        );
      },
    );
  }
}
