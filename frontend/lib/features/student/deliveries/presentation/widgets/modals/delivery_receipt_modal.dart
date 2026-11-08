// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';

/// [DeliveryReceiptModal]
///
/// Modal de exibição do Comprovante Digital de Entrega de atividade acadêmica.
/// Apresenta o código alfanumérico do protocolo de submissão, data/hora do recebimento
/// no servidor, botão para cópia do protocolo na área de transferência e atalho para download.
class DeliveryReceiptModal extends StatelessWidget {
  /// Atividade acadêmica submetida com protocolo registrado.
  final StudentDeliveryItem item;

  /// Cria uma nova instância de [DeliveryReceiptModal].
  const DeliveryReceiptModal({
    super.key,
    required this.item,
  });

  /// Exibe o diálogo modal na árvore de widgets.
  ///
  /// Parâmetros:
  /// - [context]: Contexto de construção para acionamento do [showDialog].
  /// - [item]: Entrega submetida contendo protocolo a exibir.
  static Future<void> show(BuildContext context, StudentDeliveryItem item) {
    return showDialog<void>(
      context: context,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Comprovante Digital de Entrega',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Documento oficial de confirmação de recebimento da submissão.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card com o Protocolo em Destaque
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CÓDIGO DO PROTOCOLO INSTITUCIONAL',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText(
                        item.protocol ?? '—',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: Color(0xFF64748B)),
                        tooltip: 'Copiar código',
                        onPressed: item.protocol == null
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: item.protocol!),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Protocolo copiado.')),
                                );
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tabela com Informações do Registro
            _buildDetailRow('Atividade:', '${item.activityCode ?? item.disciplineCode} - ${item.title}'),
            const SizedBox(height: 10),
            _buildDetailRow('Disciplina:', item.disciplineName),
            const SizedBox(height: 10),
            _buildDetailRow('Docente Titular:', item.professor ?? 'Docente Titular'),
            const SizedBox(height: 10),
            _buildDetailRow('Data da Submissão:', item.submissionDate ?? '—'),
            const SizedBox(height: 10),
            _buildDetailRow('Anexos Vinculados:', '${item.attachmentCount} arquivo(s) protocolado(s)'),
            const SizedBox(height: 10),
            _buildDetailRow('Status do Processo:', item.status),
            const SizedBox(height: 24),

            // Ações
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: item.submissionId == null
                        ? null
                        : () => _download(context),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Baixar submissão'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
