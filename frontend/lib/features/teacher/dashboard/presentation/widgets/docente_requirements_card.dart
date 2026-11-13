// Desenvolvido por Rafael Henrique Inácio - RA: 25009719 e Alex Gabriel Soares Sousa - RA: 24802449
// Card "Requerimentos Acadêmicos das Turmas" do Painel Geral - Padrão estético fiel às referências
// Dados 100% vindos do backend/MongoDB

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/teacher_protocol.dart';
import 'docente_protocol_details_modal.dart';

/// Card de exibição dos protocolos de atestados, segundas chamadas e revisões discentes.
/// Posicionado na coluna esquerda abaixo de Minhas Turmas, fiel às capturas de referência.
class DocenteRequirementsCard extends StatelessWidget {
  final DocenteController controller;

  const DocenteRequirementsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final protocols = controller.protocols;
    final countLabel = '${protocols.length} solicitações';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Ícone + Título + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: Color(0xFF18181B),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Requerimentos Acadêmicos das Turmas',
                        style: jakarta(
                          size: 16,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                    size: 11,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // DESCRIÇÃO
          Text(
            'Atestados médicos, pedidos de 2ª chamada e revisões de notas protocolados por discentes das suas disciplinas.',
            style: jakarta(
              size: 12,
              color: const Color(0xFF71717A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // LISTA DE PROTOCOLOS
          if (protocols.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Nenhum protocolo discente registrado.',
                  style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
                ),
              ),
            )
          else
            for (int i = 0; i < protocols.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _buildProtocolTile(context, protocols[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildProtocolTile(BuildContext context, TeacherProtocol protocol) {
    final isDeferido = protocol.status == TeacherProtocolStatus.deferido;
    final isIndeferido = protocol.status == TeacherProtocolStatus.indeferido;
    final badgeBg = isDeferido
        ? const Color(0xFFDCFCE7)
        : isIndeferido
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFFEF3C7);
    final badgeText = isDeferido
        ? const Color(0xFF166534)
        : isIndeferido
            ? const Color(0xFFB91C1C)
            : const Color(0xFFD97706);
    final badgeLabel = isDeferido
        ? 'DEFERIDO'
        : isIndeferido
            ? 'INDEFERIDO'
            : 'PENDENTE';

    // Remove duplicidade caso description já comece com requestType
    String cleanDetail = protocol.description;
    if (cleanDetail.toLowerCase().startsWith(protocol.requestType.toLowerCase())) {
      cleanDetail = cleanDetail
          .substring(protocol.requestType.length)
          .replaceFirst(RegExp(r'^[:\s-]+'), '')
          .trim();
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => DocenteProtocolDetailsModal.show(
          context,
          protocol,
          controller: controller,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          protocol.studentName,
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        Text(
                          '[${protocol.studentRa}]',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF71717A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeLabel,
                            style: jakarta(
                              size: 9,
                              weight: FontWeight.w800,
                              color: badgeText,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${protocol.requestType}: ',
                            style: jakarta(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          TextSpan(
                            text: cleanDetail,
                            style: jakarta(
                              size: 11.5,
                              weight: FontWeight.w400,
                              color: const Color(0xFF52525B),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                protocol.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF71717A),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
