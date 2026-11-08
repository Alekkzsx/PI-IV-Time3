// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'common/ava_common.dart';

/// [AvaLiveClassroomTab]
///
/// Aba 2 do Cockpit AVA: Sala Virtual e Aulas Síncronas.
/// Monitora a abertura de transmissões síncronas ao vivo via [AcademicBridgeService]
/// e utiliza [AvaOpenSectionHeader] responsivo para evitar overflow em mobile.
class AvaLiveClassroomTab extends StatelessWidget {
  /// Controlador reativo que provê a disciplina selecionada.
  final StudentPortalController controller;

  /// Cria uma nova instância de [AvaLiveClassroomTab].
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvaOpenSectionHeader(
              title: 'Sala Virtual e Aulas Síncronas',
              subtitle:
                  'Transmissão de aulas ao vivo com registro de presença digital via WebRTC.',
              trailing: ElevatedButton.icon(
                onPressed: () => _handleJoinSession(
                  context,
                  isOpen: isOpen,
                  disciplineCode: disciplineCode,
                ),
                icon: Icon(
                  isOpen ? Icons.videocam : Icons.lock_clock,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  isOpen ? 'Ingressar na Sala WebRTC' : 'Aguardando Docente',
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOpen
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card Principal da Transmissão (Moldura Dark Clean)
            Container(
              height: 360,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isOpen ? Icons.sensors : Icons.videocam_off_outlined,
                            size: 48,
                            color: isOpen
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isOpen
                                ? 'Sessão WebRTC ativa transmitida por ${session.openedByName ?? "Docente"}'
                                : 'Transmissão síncrona aguardando abertura pelo docente',
                            style: jakarta(
                              size: 14,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'A assiduidade é computada automaticamente durante a permanência na sala.',
                            style: jakarta(
                              size: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? 'AO VIVO' : 'OFFLINE',
                            style: jakarta(
                              size: 11,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleJoinSession(
    BuildContext context, {
    required bool isOpen,
    required String disciplineCode,
  }) {
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
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
            const SizedBox(width: 8),
            Text(
              'Sessão Não Iniciada',
              style: jakarta(
                size: 16,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
          ],
        ),
        content: Text(
          'A videochamada da disciplina $disciplineCode ainda não foi aberta pelo docente responsável.\n\nApenas o professor da disciplina ou a coordenação podem abrir a chamada da turma.',
          style: jakarta(size: 13, color: const Color(0xFF52525B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Compreendido',
              style: jakarta(size: 13, color: const Color(0xFF18181B)),
            ),
          ),
        ],
      ),
    );
  }
}
