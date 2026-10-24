// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';

/// Linha de indicadores de desempenho (KPIs) da Central de Entregas do Aluno.
/// Exibe quantitativos de atividades pendentes, em análise, avaliadas e média ponderada.
class DeliveriesKpiRow extends StatelessWidget {
  final List<StudentDeliveryItem> deliveries;

  const DeliveriesKpiRow({super.key, required this.deliveries});

  @override
  Widget build(BuildContext context) {
    final pendingItems = deliveries
        .where((d) => d.status == 'Pendente')
        .toList();
    final pendingCount = pendingItems.length;
    final urgentCount = pendingItems
        .where(
          (d) => d.isUrgent || (d.deadlineBadge?.contains('fatal') ?? false),
        )
        .length;

    final inReviewCount = deliveries
        .where((d) => d.status == 'Em Análise')
        .length;
    final evaluatedItems = deliveries
        .where((d) => d.status == 'Avaliada' && d.score != null)
        .toList();
    final evaluatedCount = evaluatedItems.length;

    double weightedAverage = 0.0;
    if (evaluatedItems.isNotEmpty) {
      double totalWeightedScore = 0.0;
      double totalWeight = 0.0;
      for (final item in evaluatedItems) {
        final weight = item.weight > 0 ? item.weight : 1.0;
        totalWeightedScore += (item.score ?? 0.0) * weight;
        totalWeight += weight;
      }
      weightedAverage = totalWeight > 0
          ? totalWeightedScore / totalWeight
          : 0.0;
    } else {
      weightedAverage = 9.7; // Padrão de referência do semestre
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final isTwoColumn = constraints.maxWidth < 1300;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPendingCard(pendingCount, urgentCount),
              const SizedBox(height: 16),
              _buildInReviewCard(inReviewCount),
              const SizedBox(height: 16),
              _buildEvaluatedCard(evaluatedCount),
              const SizedBox(height: 16),
              _buildAverageCard(weightedAverage),
            ],
          );
        }

        if (isTwoColumn) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPendingCard(pendingCount, urgentCount)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInReviewCard(inReviewCount)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildEvaluatedCard(evaluatedCount)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAverageCard(weightedAverage)),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildPendingCard(pendingCount, urgentCount)),
            const SizedBox(width: 16),
            Expanded(child: _buildInReviewCard(inReviewCount)),
            const SizedBox(width: 16),
            Expanded(child: _buildEvaluatedCard(evaluatedCount)),
            const SizedBox(width: 16),
            Expanded(child: _buildAverageCard(weightedAverage)),
          ],
        );
      },
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  Widget _buildPendingCard(int count, int urgentCount) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'PENDENTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              Icon(Icons.access_time, size: 18, color: Color(0xFF334155)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'atividades',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              if (urgentCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border.all(color: const Color(0xFFFECACA)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 12,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$urgentCount urgente',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Há entregas com prazo fatal nos próximos 2 dias.',
            style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
          ),
        ],
      ),
    );
  }

  Widget _buildInReviewCard(int count) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'EM ANÁLISE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              Icon(Icons.send_outlined, size: 18, color: Color(0xFF334155)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'aguardando correção',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Submissões com protocolo emitido aguardando parecer.',
            style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluatedCard(int count) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'AVALIADAS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              Icon(Icons.bookmark_border, size: 18, color: Color(0xFF334155)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'concluídas no semestre',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Com notas consolidadas e devolutiva do docente.',
            style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageCard(double average) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MÉDIA PONDERADA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Excelente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/ 10.0',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Média das notas de trabalhos entregues até o momento.',
            style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
          ),
        ],
      ),
    );
  }
}
