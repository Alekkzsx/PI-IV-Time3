// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/ava/common/ava_common.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';

/// [DeliveryFeedbackModal]
///
/// Modal institucional canônico de exibição da Devolutiva Pedagógica e Avaliação por Rubricas.
/// Unificado ao Design System claro do AVA (`AvaStandardModal`, `#FAF8F5`, `#FFFFFF`, `#E5E7EB`, `jakarta`).
class DeliveryFeedbackModal extends StatelessWidget {
  /// Atividade acadêmica avaliada.
  final StudentDeliveryItem item;

  /// Cria uma nova instância de [DeliveryFeedbackModal].
  const DeliveryFeedbackModal({super.key, required this.item});

  /// Exibe o diálogo modal na árvore de widgets.
  static Future<void> show(BuildContext context, StudentDeliveryItem item) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => DeliveryFeedbackModal(item: item),
    );
  }

  Future<void> _exportFeedbackReport(BuildContext context) async {
    final scoreStr = item.score?.toStringAsFixed(1) ?? '—';
    final buffer = StringBuffer()
      ..writeln('PARECER PEDAGÓGICO E DEVOLUTIVA OFICIAL — AGMRM AVA')
      ..writeln('====================================================')
      ..writeln('Disciplina: ${item.disciplineCode} — ${item.disciplineName}')
      ..writeln('Atividade: ${item.title}')
      ..writeln('Docente: ${item.professor ?? "Docente Titular"}')
      ..writeln('Protocolo: ${item.protocol ?? "—"}')
      ..writeln('Nota Homologada: $scoreStr / ${item.maxScore.toStringAsFixed(1)}')
      ..writeln('')
      ..writeln('PARECER DESCRITIVO:')
      ..writeln(item.feedback ?? 'Nenhum parecer descritivo informado.')
      ..writeln('');

    if (item.rubrics.isNotEmpty) {
      buffer.writeln('DETALHAMENTO POR RUBRICA:');
      for (final r in item.rubrics) {
        buffer.writeln(
          '- ${r['criterio']}: ${r['nota']} / ${r['pontos']} pts',
        );
      }
    }

    final safeCode = item.disciplineCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final savedPath = await PlatformFileHelper.saveAndLaunchFile(
      bytes: bytes,
      fileName: 'parecer_pedagogico_$safeCode.txt',
      mimeType: 'text/plain; charset=utf-8',
    );
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedPath == null
              ? 'Não foi possível exportar o parecer pedagógico.'
              : 'Parecer pedagógico exportado: $savedPath',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreStr = item.score?.toStringAsFixed(1) ?? '—';

    return AvaStandardModal(
      overlineTag: 'DEVOLUTIVA HOMOLOGADA • ${item.disciplineCode}',
      title: 'Devolutiva & Parecer Pedagógico',
      subtitle: '${item.activityCode ?? item.disciplineCode} • ${item.title}',
      maxWidth: 640,
      actions: [
        AvaActionPillButton(
          label: 'Exportar Parecer (.txt)',
          icon: Icons.download_rounded,
          variant: AvaButtonVariant.secondary,
          onPressed: () => _exportFeedbackReport(context),
        ),
        AvaActionPillButton(
          label: 'Fechar',
          variant: AvaButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7).withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF166534),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Nota Oficial Atribuída',
                          style: jakarta(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$scoreStr / ${item.maxScore.toStringAsFixed(1)}',
                  style: jakarta(
                    size: 20,
                    weight: FontWeight.w800,
                    color: const Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Parecer Descritivo do Docente',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              if (item.feedbackDate != null)
                Text(
                  'Emitido em ${item.feedbackDate}',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w500,
                    color: const Color(0xFF71717A),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              item.feedback ?? 'Nenhum parecer descritivo foi informado.',
              style: jakarta(
                size: 13,
                weight: FontWeight.w400,
                color: const Color(0xFF3F3F46),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Detalhamento por Rubrica Avaliativa',
            style: jakarta(
              size: 13,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 8),
          if (item.rubrics.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(9),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            'CRITÉRIO',
                            style: jakarta(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF71717A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'PESO MÁX.',
                            style: jakarta(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF71717A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'OBTIDA',
                            textAlign: TextAlign.right,
                            style: jakarta(
                              size: 10.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF71717A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < item.rubrics.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        border: i < item.rubrics.length - 1
                            ? const Border(
                                bottom: BorderSide(color: Color(0xFFE5E7EB)),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              '${item.rubrics[i]['criterio'] ?? ''}',
                              style: jakarta(
                                size: 12.5,
                                weight: FontWeight.w500,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.rubrics[i]['pontos']} pts',
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w500,
                                color: const Color(0xFF71717A),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.rubrics[i]['nota']} pts',
                              textAlign: TextAlign.right,
                              style: jakarta(
                                size: 12.5,
                                weight: FontWeight.w700,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                'Nota atribuída globalmente pelo docente titular.',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w400,
                  color: const Color(0xFF71717A),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  'Protocolo Oficial: ${item.protocol ?? "—"}',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFF52525B),
                  ),
                ),
                Text(
                  'Submetido em ${item.submissionDate ?? item.dueDate}',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
