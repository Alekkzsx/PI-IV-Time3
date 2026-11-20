// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/ava/common/ava_common.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';

/// [DeliveryReceiptModal]
///
/// Modal institucional canônico de exibição do Comprovante Digital de Entrega.
/// Unificado ao Design System claro do AVA (`AvaStandardModal`, `#FAF8F5`, `#FFFFFF`, `#E5E7EB`, `jakarta`).
class DeliveryReceiptModal extends StatelessWidget {
  /// Atividade acadêmica submetida com protocolo registrado.
  final StudentDeliveryItem item;

  /// Cria uma nova instância de [DeliveryReceiptModal].
  const DeliveryReceiptModal({
    super.key,
    required this.item,
  });

  /// Exibe o diálogo modal na árvore de widgets.
  static Future<void> show(BuildContext context, StudentDeliveryItem item) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => DeliveryReceiptModal(item: item),
    );
  }

  Future<void> _download(BuildContext context) async {
    final id = item.submissionId;
    if (id == null || id.isEmpty) return;
    try {
      final path = await StudentPortalController.instance.downloadSubmission(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Não foi possível salvar a submissão.'
                : 'Submissão salva em $path',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AvaStandardModal(
      overlineTag: 'AUTENTICAÇÃO DIGITAL • ${item.disciplineCode}',
      title: 'Comprovante Digital de Entrega',
      subtitle: 'Documento oficial de confirmação de recebimento da submissão.',
      maxWidth: 580,
      actions: [
        AvaActionPillButton(
          label: 'Baixar submissão',
          icon: Icons.download_rounded,
          variant: AvaButtonVariant.secondary,
          onPressed:
              item.submissionId == null ? null : () => _download(context),
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
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CÓDIGO DO PROTOCOLO INSTITUCIONAL',
                  style: jakarta(
                    size: 10,
                    weight: FontWeight.w700,
                    color: const Color(0xFF71717A),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SelectableText(
                        item.protocol ?? '—',
                        style: jakarta(
                          size: 17,
                          weight: FontWeight.w800,
                          color: const Color(0xFF166534),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Color(0xFF52525B),
                      ),
                      tooltip: 'Copiar código',
                      onPressed: item.protocol == null
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: item.protocol!),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Protocolo copiado.'),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  'Atividade',
                  '${item.activityCode ?? item.disciplineCode} — ${item.title}',
                ),
                _buildDetailRow('Disciplina', item.disciplineName),
                _buildDetailRow(
                  'Docente Titular',
                  item.professor ?? 'Docente Titular',
                ),
                _buildDetailRow(
                  'Data da Submissão',
                  item.submissionDate ?? '—',
                ),
                _buildDetailRow(
                  'Anexos Vinculados',
                  '${item.attachmentCount} arquivo(s) protocolado(s)',
                ),
                _buildDetailRow(
                  'Status do Processo',
                  item.status,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: jakarta(
                size: 12,
                weight: FontWeight.w600,
                color: const Color(0xFF71717A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: jakarta(
                size: 12,
                weight: FontWeight.w600,
                color: const Color(0xFF18181B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
