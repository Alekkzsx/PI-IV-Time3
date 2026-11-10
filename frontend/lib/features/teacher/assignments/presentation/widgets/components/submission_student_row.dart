// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import '../docente_assignment_feedback_dialog.dart';
import 'submission_status_badge.dart';

/// Linha atômica que representa a submissão de um discente na tabela.
class SubmissionStudentRow extends StatelessWidget {
  final StudentSubmission submission;
  final AssignmentItem assignment;
  final DocenteController? controller;
  final void Function(AssignmentItem, StudentSubmission) onOpenRubric;

  const SubmissionStudentRow({
    super.key,
    required this.submission,
    required this.assignment,
    this.controller,
    required this.onOpenRubric,
  });

  String _truncateFileName(String name) {
    if (name.length > 26) {
      return '${name.substring(0, 23)}...';
    }
    return name;
  }

  Widget _buildActionButton(BuildContext context) {
    if (submission.status == SubmissionStatus.naoEntregue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Text(
          'Sem Submissão',
          style: jakarta(
            size: 11,
            weight: FontWeight.w500,
            color: const Color(0xFFA1A1AA),
          ),
        ),
      );
    }

    final isCorrigido = submission.status == SubmissionStatus.corrigido;
    final label = isCorrigido ? 'Revisar Nota' : 'Avaliar Rubrica';
    final icon = isCorrigido ? Icons.edit_note_rounded : Icons.grading_rounded;

    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        // Botão Feedback Individual & Canal de Dúvidas
        if (controller != null) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => DocenteAssignmentFeedbackDialog.show(
                context: context,
                assignment: assignment,
                submission: submission,
                controller: controller!,
              ),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Feedback',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w600,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Botão Avaliar Rubrica
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onOpenRubric(assignment, submission),
            borderRadius: BorderRadius.circular(6),
            child: Ink(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isCorrigido ? Colors.white : const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCorrigido
                      ? const Color(0xFFD4D4D8)
                      : const Color(0xFF18181B),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isCorrigido ? const Color(0xFF18181B) : Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w600,
                        color: isCorrigido
                            ? const Color(0xFF18181B)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sub = submission;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 14,
      ),
      color: Colors.white,
      child: Row(
        children: [
          // R.A.
          SizedBox(
            width: 120,
            child: Text(
              sub.ra,
              style: jakarta(
                size: 12,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ),
          // Estudante
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    sub.studentName,
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Arquivo Submetido
          Expanded(
            flex: 3,
            child: sub.fileName != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 15,
                        color: Color(0xFF71717A),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _truncateFileName(sub.fileName!),
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w400,
                            color: const Color(0xFF27272A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (controller != null)
                        IconButton(
                          tooltip: 'Baixar submissão',
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            final result = await controller!
                                .downloadSubmission(sub);
                            if (context.mounted && result == null) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    controller!.remoteError ??
                                        'Não foi possível baixar o arquivo.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.download_outlined,
                            size: 16,
                          ),
                        ),
                    ],
                  )
                : Text(
                    'Nenhum arquivo enviado',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w400,
                      color: const Color(0xFFA1A1AA),
                    ),
                  ),
          ),
          // Data / Hora de Envio
          Expanded(
            flex: 2,
            child: Text(
              sub.submittedAtFormatted ?? '—',
              style: jakarta(
                size: 12,
                weight: FontWeight.w400,
                color: sub.submittedAtFormatted != null
                    ? const Color(0xFF71717A)
                    : const Color(0xFFA1A1AA),
              ),
            ),
          ),
          // Nota Atribuída
          SizedBox(
            width: 120,
            child: Center(
              child: Text(
                sub.grade != null
                    ? '${sub.grade!.toStringAsFixed(1)} / 10.0'
                    : '—',
                style: jakarta(
                  size: 12.5,
                  weight: sub.grade != null
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: sub.grade != null
                      ? const Color(0xFF18181B)
                      : const Color(0xFFA1A1AA),
                ),
              ),
            ),
          ),
          // Status Badge
          SizedBox(
            width: 150,
            child: Center(
              child: SubmissionStatusBadge(status: sub.status),
            ),
          ),
          // Ação Button
          SizedBox(
            width: 130,
            child: Center(child: _buildActionButton(context)),
          ),
        ],
      ),
    );
  }
}
