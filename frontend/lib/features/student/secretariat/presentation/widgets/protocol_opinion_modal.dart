// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../domain/entities/protocol_request.dart';

/// Modal para exibição detalhada do parecer oficial de um protocolo de requerimento.
class ProtocolOpinionModal extends StatelessWidget {
  /// Dados completos do protocolo acadêmico.
  final ProtocolRequest protocol;

  /// Cria uma instância de [ProtocolOpinionModal].
  const ProtocolOpinionModal({super.key, required this.protocol});

  /// Método estático utilitário para exibir o parecer na tela.
  static Future<void> show(
    BuildContext context, {
    required ProtocolRequest protocol,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ProtocolOpinionModal(protocol: protocol),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topo: Código do Protocolo, Status Badge e Botão Fechar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          size: 20,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            protocol.protocolCode,
                            style: jakarta(
                              size: 16,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Protocolado em ${protocol.submittedAt}',
                            style: jakarta(
                              size: 11.5,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildStatusBadge(protocol),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: const Color(0xFF71717A),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              const SizedBox(height: 20),

              // Dados da Solicitação
              _buildSectionTitle('Dados da Solicitação Acadêmica'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [_buildSubjectChip(protocol.subjectType)]),
                    const SizedBox(height: 10),
                    Text(
                      protocol.componentObject,
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Justificativa do Discente:',
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      protocol.justification,
                      style: jakarta(
                        size: 12.5,
                        color: const Color(0xFF3F3F46),
                        height: 1.45,
                      ),
                    ),
                    if (protocol.attachmentName != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 18,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                protocol.attachmentName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: jakarta(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF18181B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Parecer Oficial e Despacho
              _buildSectionTitle(
                'Despacho Oficial da Secretaria / Coordenação',
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: protocol.status == ProtocolStatus.approved
                      ? const Color(0xFFF0FDF4)
                      : protocol.status == ProtocolStatus.rejected
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: protocol.status == ProtocolStatus.approved
                        ? const Color(0xFFBBF7D0)
                        : protocol.status == ProtocolStatus.rejected
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          protocol.status == ProtocolStatus.approved
                              ? Icons.check_circle_outline_rounded
                              : protocol.status == ProtocolStatus.rejected
                              ? Icons.cancel_outlined
                              : Icons.hourglass_top_rounded,
                          size: 18,
                          color: protocol.status == ProtocolStatus.approved
                              ? const Color(0xFF16A34A)
                              : protocol.status == ProtocolStatus.rejected
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Parecer Formal:',
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      protocol.officialOpinion,
                      style: jakarta(
                        size: 13,
                        color: const Color(0xFF27272A),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0x22000000),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            protocol.approverName ??
                                'Secretaria Acadêmica Geral',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: jakarta(
                              size: 11,
                              weight: FontWeight.w600,
                              color: const Color(0xFF52525B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          protocol.responseDate ?? 'Data de Despacho',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // Botão de Fechar
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Fechar',
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: jakarta(
        size: 12.5,
        weight: FontWeight.w700,
        color: const Color(0xFF18181B),
      ),
    );
  }

  Widget _buildSubjectChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
      ),
      child: Text(
        label,
        style: jakarta(
          size: 11,
          weight: FontWeight.w600,
          color: const Color(0xFF3F3F46),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ProtocolRequest item) {
    final (Color bg, Color text) = switch (item.status) {
      ProtocolStatus.approved => (
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
      ),
      ProtocolStatus.pending => (
        const Color(0xFFFFFBEB),
        const Color(0xFFD97706),
      ),
      ProtocolStatus.rejected => (
        const Color(0xFFFEF2F2),
        const Color(0xFFDC2626),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item.statusLabel,
        style: jakarta(size: 11, weight: FontWeight.w700, color: text),
      ),
    );
  }
}
