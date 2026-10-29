// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../domain/entities/protocol_request.dart';

/// Tabela de Protocolos de Requerimento Cadastrados na Secretaria Virtual.
class ProtocolRequestsTable extends StatelessWidget {
  /// Lista de requerimentos protocolados pelo estudante.
  final List<ProtocolRequest> protocols;

  /// Texto informativo com a contagem total de requerimentos.
  final String countLabel;

  /// Callback acionado ao clicar em 'Ver Parecer' de um protocolo específico.
  final ValueChanged<ProtocolRequest> onViewOpinion;

  /// Cria uma instância de [ProtocolRequestsTable].
  const ProtocolRequestsTable({
    super.key,
    required this.protocols,
    required this.countLabel,
    required this.onViewOpinion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da Seção de Protocolos
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 16,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protocolos de Requerimento Cadastrados',
                  style: jakarta(
                    size: 16,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Histórico de solicitações formais submetidas à Secretaria Acadêmica e pareceres emitidos.',
                  style: jakarta(
                    size: 12.5,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
            Text(
              countLabel,
              style: jakarta(
                size: 12,
                weight: FontWeight.w500,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Container da Tabela
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 760) {
                return Column(
                  children: [
                    _buildDesktopTableHeader(),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF4F4F5),
                    ),
                    ...protocols.asMap().entries.map((entry) {
                      final isLast = entry.key == protocols.length - 1;
                      return Column(
                        children: [
                          _buildDesktopTableRow(entry.value),
                          if (!isLast)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF4F4F5),
                            ),
                        ],
                      );
                    }),
                  ],
                );
              }

              // Layout compacto/responsivo em cartões empilhados para telas menores
              return Column(
                children: protocols.asMap().entries.map((entry) {
                  final isLast = entry.key == protocols.length - 1;
                  return Column(
                    children: [
                      _buildCompactProtocolTile(entry.value),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF4F4F5),
                        ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTableHeader() {
    final headerStyle = jakarta(
      size: 10.5,
      weight: FontWeight.w700,
      color: const Color(0xFF71717A),
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: 18, child: Text('PROTOCOLO', style: headerStyle)),
          Expanded(flex: 15, child: Text('DATA DE ENVIO', style: headerStyle)),
          Expanded(flex: 20, child: Text('TIPO / ASSUNTO', style: headerStyle)),
          Expanded(
              flex: 27, child: Text('OBJETO / COMPONENTE', style: headerStyle)),
          Expanded(flex: 12, child: Text('SITUAÇÃO', style: headerStyle)),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('DETALHES', style: headerStyle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableRow(ProtocolRequest item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 18,
            child: Text(
              item.protocolCode,
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              item.submittedAt,
              style: jakarta(
                size: 12.5,
                color: const Color(0xFF52525B),
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildSubjectChip(item.subjectType),
            ),
          ),
          Expanded(
            flex: 27,
            child: Text(
              item.componentObject,
              style: jakarta(
                size: 12.5,
                color: const Color(0xFF3F3F46),
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(item),
            ),
          ),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                key: Key('view_opinion_${item.protocolCode}'),
                onTap: () => onViewOpinion(item),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Ver Parecer',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProtocolTile(ProtocolRequest item) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.protocolCode,
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              _buildStatusBadge(item),
            ],
          ),
          const SizedBox(height: 8),
          _buildSubjectChip(item.subjectType),
          const SizedBox(height: 8),
          Text(
            item.componentObject,
            style: jakarta(
              size: 13,
              color: const Color(0xFF3F3F46),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.submittedAt,
                style: jakarta(
                  size: 12,
                  color: const Color(0xFF71717A),
                ),
              ),
              InkWell(
                key: Key('view_opinion_compact_${item.protocolCode}'),
                onTap: () => onViewOpinion(item),
                child: Text(
                  'Ver Parecer',
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFE4E4E7),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: jakarta(
          size: 11,
          weight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        item.statusLabel,
        style: jakarta(
          size: 10.5,
          weight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }
}
