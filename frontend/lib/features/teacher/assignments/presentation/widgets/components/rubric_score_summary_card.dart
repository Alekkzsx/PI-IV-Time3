// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';

/// Card atômico com informações do arquivo entregue e metadados de submissão discente.
class RubricScoreSummaryCard extends StatelessWidget {
  final StudentSubmission submission;

  const RubricScoreSummaryCard({
    super.key,
    required this.submission,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = submission.fileName;
    final fileSize = submission.fileSize;
    final submittedAt = submission.submittedAtFormatted;
    final submissionMetadata = [
      if (submittedAt != null) 'Entregue em: $submittedAt',
      if (fileSize != null) 'Tamanho: $fileSize',
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocenteColors.offWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DocenteColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DocenteColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: Icon(
                  fileName == null
                      ? Icons.insert_drive_file_outlined
                      : Icons.picture_as_pdf,
                  color: fileName == null
                      ? DocenteColors.slate
                      : DocenteColors.crimson,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName ?? 'Arquivo não disponível',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DocenteColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      submissionMetadata.isEmpty
                          ? 'Esta entrega não possui arquivo anexado.'
                          : submissionMetadata,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DocenteColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final downloadButton = OutlinedButton.icon(
            onPressed: fileName == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'O download ainda não está disponível sem integração ao armazenamento de entregas.',
                        ),
                        backgroundColor: DocenteColors.charcoal,
                      ),
                    );
                  },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Baixar Entrega'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DocenteColors.charcoal,
              side: const BorderSide(color: DocenteColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                if (fileName != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: downloadButton,
                  ),
                ],
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              if (fileName != null) ...[
                const SizedBox(width: 12),
                downloadButton,
              ],
            ],
          );
        },
      ),
    );
  }
}
