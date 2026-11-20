// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/deliveries/presentation/widgets/modals/delivery_feedback_modal.dart';
import 'package:pi_iv_time3/features/student/deliveries/presentation/widgets/modals/delivery_receipt_modal.dart';
import 'package:pi_iv_time3/features/student/deliveries/presentation/widgets/modals/delivery_submission_modal.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';
import '../../common/ava_common.dart';

/// [AvaAssignmentItemCard]
///
/// Cartão institucional de tarefa e atividade avaliativa no Cockpit AVA.
/// Renderizado no padrão canônico [AvaBannerSurfaceCard] com banner superior [#FAF8F5],
/// status semântico [AvaStatusBadge], prazo, peso regimental e botões em pílula.
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

    final moduleTag = (activity.moduleTag?.isNotEmpty == true
            ? activity.moduleTag!
            : (activity.disciplineCode.isNotEmpty
                ? 'AVALIAÇÃO REGIMENTAL • ${activity.disciplineCode}'
                : 'AVALIAÇÃO REGIMENTAL'))
        .toUpperCase();

    final scoreText = activity.score != null
        ? activity.score!.toStringAsFixed(1)
        : '—';

    final AvaStatusBadge statusBadge;
    if (isPending) {
      statusBadge = const AvaStatusBadge(
        label: 'Pendente de Envio',
        variant: AvaBadgeVariant.warning,
        icon: Icons.schedule_rounded,
      );
    } else if (isEvaluated) {
      statusBadge = AvaStatusBadge(
        label: 'Avaliado • Nota $scoreText/10',
        variant: AvaBadgeVariant.success,
        icon: Icons.check_circle_outline_rounded,
      );
    } else {
      statusBadge = AvaStatusBadge(
        label: isInAnalysis ? 'Em Análise pelo Docente' : 'Submetido',
        variant: AvaBadgeVariant.neutral,
        icon: Icons.sync_rounded,
      );
    }

    return AvaBannerSurfaceCard(
      margin: const EdgeInsets.only(bottom: 16),
      overlineTag: moduleTag,
      title: activity.title,
      headerTrailing: statusBadge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity.description?.isNotEmpty == true) ...[
            Text(
              activity.description!,
              style: jakarta(
                size: 13,
                weight: FontWeight.w400,
                color: const Color(0xFF52525B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Metadados da atividade
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: Color(0xFF71717A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    activity.dueDate.contains('às') ||
                            activity.dueHour.trim().isEmpty
                        ? 'Prazo: ${activity.dueDate}'
                        : 'Prazo: ${activity.dueDate} às ${activity.dueHour}',
                    style: jakarta(
                      size: 11.5,
                      weight: FontWeight.w500,
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
                    size: 13,
                    color: Color(0xFF71717A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Peso na Média: ${activity.weight.toStringAsFixed(1)}',
                    style: jakarta(
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.folder_zip_outlined,
                    size: 13,
                    color: Color(0xFF71717A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    activity.allowedFormats?.isNotEmpty == true
                        ? activity.allowedFormats!
                        : 'PDF / ZIP',
                    style: jakarta(
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
              if (activity.protocol != null && activity.protocol!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    'Protocolo: ${activity.protocol}',
                    style: jakarta(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: const Color(0xFF52525B),
                    ),
                  ),
                ),
            ],
          ),

          if (activity.rubrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Critérios da Rubrica (${activity.rubrics.length})',
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: activity.rubrics.map((r) {
                      final title = (r['title'] ?? r['criterio'] ?? '')
                          .toString();
                      final maxPts = r['maxPoints'] ?? r['pontos'] ?? 0;
                      final ptsNum = maxPts is num ? maxPts.toDouble() : 0.0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          '$title (${ptsNum.toStringAsFixed(1)} pts)',
                          style: jakarta(
                            size: 11,
                            weight: FontWeight.w500,
                            color: const Color(0xFF3F3F46),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          if (activity.feedback?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parecer do Docente:',
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${activity.feedback}"',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w400,
                      color: const Color(0xFF3F3F46),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
          const SizedBox(height: 14),

          // Barra de Ações em Pílula
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isPending)
                AvaActionPillButton(
                  label: 'Realizar Entrega',
                  icon: Icons.upload_rounded,
                  onPressed: () =>
                      DeliverySubmissionModal.show(context, activity),
                )
              else if (isEvaluated)
                AvaActionPillButton(
                  label: 'Ver Devolutiva',
                  icon: Icons.verified_outlined,
                  onPressed: () =>
                      DeliveryFeedbackModal.show(context, activity),
                )
              else
                AvaActionPillButton(
                  label: 'Ver Comprovante',
                  icon: Icons.receipt_long_outlined,
                  onPressed: () =>
                      DeliveryReceiptModal.show(context, activity),
                ),

              AvaActionPillButton(
                label: 'Tirar Dúvida',
                icon: Icons.help_outline_rounded,
                variant: AvaButtonVariant.secondary,
                onPressed: () => _openDoubtModal(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDoubtModal(BuildContext context) {
    final textController = TextEditingController();
    var isSubmitting = false;

    AvaStandardModal.show<void>(
      context: context,
      overlineTag: 'DÚVIDA ACADÊMICA',
      title: 'Tirar Dúvida da Atividade',
      subtitle: activity.title,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envie sua dúvida diretamente ao docente responsável sobre os critérios ou enunciados desta tarefa:',
                  style: jakarta(
                    size: 13,
                    color: const Color(0xFF52525B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  style: jakarta(
                    size: 13,
                    color: const Color(0xFF18181B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escreva sua dúvida pedagógica...',
                    hintStyle: jakarta(
                      size: 12.5,
                      color: const Color(0xFFA1A1AA),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF18181B),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AvaActionPillButton(
                      label: 'Cancelar',
                      variant: AvaButtonVariant.secondary,
                      onPressed: () => Navigator.of(modalCtx).pop(),
                    ),
                    const SizedBox(width: 8),
                    AvaActionPillButton(
                      label: 'Enviar Dúvida',
                      icon: Icons.send_rounded,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final text = textController.text.trim();
                              if (text.length < 3) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Digite sua dúvida antes de enviar.'),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              try {
                                await StudentPortalController.instance.postDoubt(
                                  assignmentId: activity.id,
                                  question: text,
                                );
                                if (!context.mounted) return;
                                Navigator.of(modalCtx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Dúvida enviada ao docente com sucesso.'),
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
