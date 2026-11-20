// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Cards de estatísticas do Painel Geral do Docente (dados 100% do backend/MongoDB)
// Padrão estético minimalista idêntico às imagens de referência

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/teacher_dashboard_overview.dart';

/// Linha de 4 cards KPI com dados processados no backend.
class DocenteStatsCardsRow extends StatelessWidget {
  final DocenteController controller;

  const DocenteStatsCardsRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final stats = controller.dashboard.stats;
    final items = [
      stats.activeClasses,
      stats.monthlyAssignments,
      stats.workload,
      stats.averageAttendance,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isFourCols = constraints.maxWidth >= 900;
        final isTwoCols = constraints.maxWidth >= 500;

        final cards = items.map((item) => _buildKpiCard(item)).toList();

        if (isFourCols) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        if (isTwoCols) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              cards[i],
            ],
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(TeacherDashboardKpiItem item) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            item.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jakarta(
              size: 11,
              weight: FontWeight.w700,
              letterSpacing: 0.6,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                item.valueFormatted,
                style: jakarta(
                  size: 28,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.unitLabel,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 12,
                    color: const Color(0xFF71717A),
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  item.footerLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 12,
                    color: const Color(0xFF71717A),
                    weight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.footerValue,
                style: jakarta(
                  size: 12,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progress.clamp(0.0, 1.0),
              minHeight: 3.5,
              backgroundColor: const Color(0xFFF4F4F5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF18181B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
