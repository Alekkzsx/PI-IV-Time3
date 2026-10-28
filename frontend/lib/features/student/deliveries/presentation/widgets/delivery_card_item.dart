// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';

/// Cartão individual de atividade e entrega da Visão do Aluno.
/// Reproduz fielmente o layout com código, título, descrição didática,
/// metadados em 3 colunas e botão de ação contextual (Pendente, Em Análise ou Avaliada).
class DeliveryCardItem extends StatelessWidget {
  final StudentDeliveryItem item;
  final VoidCallback onSubmit;
  final VoidCallback onReceipt;
  final VoidCallback onFeedback;

  const DeliveryCardItem({
    super.key,
    required this.item,
    required this.onSubmit,
    required this.onReceipt,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabeçalho do Card: Código, Disciplina e Badge de Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        item.activityCode ?? item.disciplineCode,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        item.disciplineName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Título da Atividade
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),

          // 3. Descrição Técnica/Didática
          if (item.description != null && item.description!.isNotEmpty)
            Text(
              item.description!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF475569),
              ),
            ),
          const SizedBox(height: 16),

          // 4. Divisor Hairline Sutil
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // 5. Grid de Metadados em 3 Colunas
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 640;

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaColumn(
                      header: 'DATA LIMITE',
                      value: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text('${item.dueDate}, ${item.dueHour}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMetaColumn(
                      header: 'DOCENTE RESPONSÁVEL',
                      value: Text(item.professor ?? 'Docente Titular'),
                    ),
                    const SizedBox(height: 10),
                    _buildMetaColumn(
                      header: 'CRITÉRIO E PESO',
                      value: Text('Peso ${item.weight.toStringAsFixed(1)} • Nota Máx: ${item.maxScore.toStringAsFixed(1)}'),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildMetaColumn(
                      header: 'DATA LIMITE',
                      value: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text('${item.dueDate}, ${item.dueHour}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetaColumn(
                      header: 'DOCENTE RESPONSÁVEL',
                      value: Text(item.professor ?? 'Docente Titular'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetaColumn(
                      header: 'CRITÉRIO E PESO',
                      value: Text('Peso ${item.weight.toStringAsFixed(1)} • Nota Máx: ${item.maxScore.toStringAsFixed(1)}'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // 6. Rodapé com Especificações de Formato e Ações
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildFooterInfo(),
              ),
              const SizedBox(width: 16),
              _buildActionButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaColumn({required String header, required Widget value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        DefaultTextStyle(
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
          child: value,
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    if (item.status == 'Avaliada') {
      final scoreStr = item.score != null ? item.score!.toStringAsFixed(1) : '10.0';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          border: Border.all(color: const Color(0xFFBBF7D0)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF16A34A)),
            const SizedBox(width: 5),
            Text(
              'Nota: $scoreStr / ${item.maxScore.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      );
    }

    if (item.status == 'Em Análise') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          border: Border.all(color: const Color(0xFFBFDBFE)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.send_outlined, size: 12, color: Color(0xFF2563EB)),
            const SizedBox(width: 5),
            Text(
              'Enviada em ${item.submissionDate ?? '28/09/2026'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      );
    }

    // Pendente
    final isUrgent = item.isUrgent || (item.deadlineBadge?.contains('fatal') ?? false);
    final badgeText = item.deadlineBadge ?? 'Prazo em aberto';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        border: Border.all(color: isUrgent ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.access_time_filled : Icons.access_time,
            size: 12,
            color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 5),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterInfo() {
    if (item.status == 'Avaliada') {
      return Text(
        'Parecer emitido em ${item.feedbackDate ?? '17/09/2026'}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF16A34A),
        ),
      );
    }

    if (item.status == 'Em Análise') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Protocolo: ${item.protocol ?? 'AGR-2026-0928-8472'} (${item.attachmentCount} anexo)',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      item.allowedFormats ?? 'Formatos aceitos: .pdf, .zip • Max: 25MB',
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF64748B),
      ),
    );
  }

  Widget _buildActionButton() {
    if (item.status == 'Avaliada') {
      return ElevatedButton(
        onPressed: onFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14532D), // Verde floresta institucional
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Ver Devolutiva & Nota', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 16),
          ],
        ),
      );
    }

    if (item.status == 'Em Análise') {
      return ElevatedButton(
        onPressed: onReceipt,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14532D), // Verde floresta institucional
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Ver Comprovante', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 16),
          ],
        ),
      );
    }

    // Pendente -> Realizar Entrega
    return ElevatedButton(
      onPressed: onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Realizar Entrega', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 16),
        ],
      ),
    );
  }
}
