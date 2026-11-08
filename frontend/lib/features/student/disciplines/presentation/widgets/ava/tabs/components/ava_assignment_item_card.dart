// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/deliveries/presentation/widgets/modals/delivery_submission_modal.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';
import '../../common/ava_common.dart';

/// [AvaAssignmentItemCard]
///
/// Cartão individual de tarefa/atividade avaliativa dentro da Aba 1 do Cockpit AVA.
/// Exibe a tag de módulo, status semântico (Pendente, Avaliado, Em Análise),
/// parecer do professor, prazo regimental, peso e botão de submissão.
class AvaAssignmentItemCard extends StatelessWidget {
  /// Modelo da atividade acadêmica vinculada.
  final StudentDeliveryItem activity;

  /// Cria uma nova instância de [AvaAssignmentItemCard].
  const AvaAssignmentItemCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final isPending = activity.status == 'Pendente';
    final isEvaluated = activity.status == 'Avaliada';
    final isInAnalysis = activity.status == 'Em Análise';

    final moduleTag =
        (activity.moduleTag?.isNotEmpty == true
                ? activity.moduleTag!
                : 'MÓDULO ${activity.activityCode ?? "1"} • TAREFA')
            .toUpperCase();

    final scoreText = activity.score != null
        ? activity.score!.toStringAsFixed(1)
        : '9.5';

    return AvaSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                moduleTag,
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  color: const Color(0xFF52525B),
                  letterSpacing: 0.4,
                ),
              ),
              if (isPending)
                const AvaStatusBadge(
                  label: 'Pendente de Envio',
                  variant: AvaBadgeVariant.warning,
                  icon: Icons.schedule_rounded,
                )
              else if (isEvaluated)
                AvaStatusBadge(
                  label: 'Avaliado • Nota $scoreText/10',
                  variant: AvaBadgeVariant.success,
                  icon: Icons.check_circle_outline_rounded,
                )
              else if (isInAnalysis)
                const AvaStatusBadge(
                  label: 'Em Análise',
                  variant: AvaBadgeVariant.neutral,
                  icon: Icons.sync_rounded,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activity.title,
            style: jakarta(
              size: 15,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 6),
          if (activity.description?.isNotEmpty == true)
            Text(
              activity.description!,
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
                height: 1.4,
              ),
            ),
          if (activity.feedback?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parecer do Professor:',
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${activity.feedback}"',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w400,
                      color: const Color(0xFF334155),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Color(0xFF71717A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Prazo: ${activity.dueDate} às ${activity.dueHour}',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.balance_rounded,
                        size: 12,
                        color: Color(0xFF71717A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Peso na Média: ${activity.weight.toStringAsFixed(1)}',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isPending)
                ElevatedButton.icon(
                  onPressed: () =>
                      DeliverySubmissionModal.show(context, activity),
                  icon: const Icon(
                    Icons.upload_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Entregar Atividade',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () =>
                      DeliverySubmissionModal.show(context, activity),
                  icon: const Icon(
                    Icons.upload_rounded,
                    size: 14,
                    color: Color(0xFF18181B),
                  ),
                  label: Text(
                    'Reenviar / Atualizar',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
