// Desenvolvido por Rafael Henrique Inácio - RA: 25009719 e Alex Gabriel Soares Sousa - RA: 24802449
// Card institucional de Requerimentos Acadêmicos das Turmas

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/teacher_protocol.dart';
import 'docente_protocol_details_modal.dart';

/// Card de exibição dos protocolos de atestados, segundas chamadas e revisões discentes.
class DocenteRequirementsCard extends StatelessWidget {
  final DocenteController controller;

  const DocenteRequirementsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final protocols = controller.protocols;
    final countLabel = '${protocols.length} solicitações';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da Seção
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: InstColors.ink,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Requerimentos Acadêmicos das Turmas',
                    style: jakarta(
                      size: 16.5,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  countLabel,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: InstColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Subtítulo descritivo
          Text(
            'Atestados médicos, pedidos de 2ª chamada e revisões de notas protocolados por discentes das suas disciplinas.',
            style: jakarta(
              size: 12.5,
              color: InstColors.muted,
            ),
          ),
          const SizedBox(height: 18),

          // Lista dos protocolos acadêmicos
          if (protocols.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Nenhum protocolo discente pendente de homologação.',
                  style: jakarta(size: 13, color: InstColors.faint),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: protocols.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final protocol = protocols[index];
                return _buildProtocolTile(context, protocol);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProtocolTile(BuildContext context, TeacherProtocol protocol) {
    final isDeferido = protocol.status == TeacherProtocolStatus.deferido;
    final badgeBg = isDeferido ? InstColors.successBg : InstColors.warningBg;
    final badgeText = isDeferido ? InstColors.success : InstColors.warning;
    final badgeLabel = isDeferido ? 'DEFERIDO' : 'PENDENTE';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => DocenteProtocolDetailsModal.show(context, protocol),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: InstColors.stone,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF4F4F5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            protocol.studentName,
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w700,
                              color: InstColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${protocol.studentRa})',
                          style: jakarta(
                            size: 12,
                            color: InstColors.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeLabel,
                            style: jakarta(
                              size: 9.5,
                              weight: FontWeight.w700,
                              color: badgeText,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      protocol.description,
                      style: jakarta(
                        size: 12,
                        color: const Color(0xFF52525B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                protocol.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: InstColors.muted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
