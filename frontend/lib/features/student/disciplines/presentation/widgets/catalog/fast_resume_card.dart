// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';
import '../ava/common/ava_common.dart';

/// [FastResumeCard]
///
/// Card institucional "Continuar de Onde Parou" (Fast-Resume do AVA).
/// Apresenta a disciplina ativa com estética clara padronizada (`#FAF8F5` + `#FFFFFF`),
/// cálculo dinâmico da próxima entrega pendente em banco de dados e atalhos rápidos.
class FastResumeCard extends StatelessWidget {
  /// Disciplina acadêmica sugerida para continuidade de estudos.
  final StudentDisciplineModel discipline;

  /// Callback de acionamento para retorno imediato ao cockpit AVA.
  final void Function(StudentDisciplineModel discipline, [int targetTab])
  onResume;

  /// Cria uma nova instância de [FastResumeCard].
  const FastResumeCard({
    super.key,
    required this.discipline,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final progress = discipline.progress.clamp(0.0, 1.0);
    final firstUnit = discipline.syllabusUnits.isEmpty
        ? null
        : discipline.syllabusUnits.first;
    final unitTitle =
        firstUnit?['title']?.toString() ??
        firstUnit?['name']?.toString() ??
        'Nenhum conteúdo publicado para esta unidade.';

    // Busca a próxima tarefa pendente real da disciplina via PortalController
    final controller = StudentPortalController.instance;
    final code = discipline.code.trim().toLowerCase();
    final pendingDeliveries = controller.deliveries.where((d) {
      final dCode = d.disciplineCode.trim().toLowerCase();
      return (dCode == code || dCode.contains(code) || code.contains(dCode)) &&
          d.status == 'Pendente';
    }).toList();

    final nextDelivery = pendingDeliveries.isNotEmpty
        ? pendingDeliveries.first
        : null;

    final pendingTaskText = nextDelivery != null
        ? '${nextDelivery.title} (${nextDelivery.dueDate})'
        : 'Nenhuma tarefa pendente';

    return AvaBannerSurfaceCard(
      overlineTag: 'DISCIPLINA EM ANDAMENTO • ACESSO RÁPIDO AO AVA',
      title: discipline.name,
      subtitle:
          '${discipline.professor} • ${discipline.location} • ${discipline.time}',
      headerTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          '${(progress * 100).round()}% concluído',
          style: jakarta(
            size: 11,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 850;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bloco de detalhes do tópico em andamento
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Conteúdo em Andamento',
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: jakarta(
                            size: 11.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unitTitle,
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w400,
                        color: const Color(0xFF52525B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botões de Ação
              if (isCompact) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPrimaryResumeBtn(context),
                    const SizedBox(height: 10),
                    _buildPendingTaskBtn(context, pendingTaskText, nextDelivery != null),
                    const SizedBox(height: 10),
                    _buildLiveClassBtn(context),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    _buildPrimaryResumeBtn(context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPendingTaskBtn(
                        context,
                        pendingTaskText,
                        nextDelivery != null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildLiveClassBtn(context),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryResumeBtn(BuildContext context) {
    return ElevatedButton.icon(
      key: const Key('btn_retomar_aula_ava'),
      onPressed: () => onResume(discipline, 0),
      icon: const Icon(
        Icons.play_arrow_rounded,
        size: 17,
        color: Colors.white,
      ),
      label: Text(
        'Retomar Aula no AVA',
        style: jakarta(
          size: 12.5,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildPendingTaskBtn(
    BuildContext context,
    String label,
    bool hasPending,
  ) {
    return OutlinedButton.icon(
      key: const Key('btn_tarefa_pendente_ava'),
      onPressed: () => onResume(discipline, 1),
      icon: Icon(
        Icons.assignment_outlined,
        size: 15,
        color: hasPending ? const Color(0xFFB45309) : const Color(0xFF71717A),
      ),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: jakarta(
          size: 12,
          weight: FontWeight.w600,
          color: hasPending ? const Color(0xFFB45309) : const Color(0xFF52525B),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: hasPending
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFF4F4F5),
        side: BorderSide(
          color: hasPending
              ? const Color(0xFFFDE68A)
              : const Color(0xFFE5E7EB),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildLiveClassBtn(BuildContext context) {
    return AnimatedBuilder(
      animation: AcademicBridgeService.instance,
      builder: (context, _) {
        final isOpen = AcademicBridgeService.instance.isSessionOpen(
          discipline.code,
        ) || discipline.isLive;

        return OutlinedButton.icon(
          key: const Key('btn_sala_virtual_resume'),
          onPressed: isOpen
              ? () => Navigator.of(context).pushNamed(
                  '/video-call',
                  arguments: {
                    'name': AppUserSession.instance.effectiveName,
                    'ra': AppUserSession.instance.identity ?? '',
                    'roomCode': discipline.code,
                    'role': 'aluno',
                  },
                )
              : () => onResume(discipline, 2),
          icon: Icon(
            isOpen ? Icons.sensors_rounded : Icons.lock_clock_outlined,
            size: 15,
            color: isOpen ? const Color(0xFF166534) : const Color(0xFF71717A),
          ),
          label: Text(
            isOpen ? 'Sala Virtual (Ao Vivo)' : 'Sala Virtual',
            style: jakarta(
              size: 12,
              weight: FontWeight.w600,
              color: isOpen ? const Color(0xFF166534) : const Color(0xFF52525B),
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: isOpen
                ? const Color(0xFFDCFCE7)
                : Colors.white,
            side: BorderSide(
              color: isOpen
                  ? const Color(0xFFBBF7D0)
                  : const Color(0xFFE5E7EB),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}

typedef StudentDisciplinesFastResumeCard = FastResumeCard;
