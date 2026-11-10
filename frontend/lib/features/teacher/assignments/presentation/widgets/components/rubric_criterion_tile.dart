// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/rubric_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';

/// Card atômico com slider isolado para atribuição de nota a um critério da rubrica.
class RubricCriterionTile extends StatelessWidget {
  final RubricCriterion criterion;
  final double currentScore;
  final ValueChanged<double> onScoreChanged;

  const RubricCriterionTile({
    super.key,
    required this.criterion,
    required this.currentScore,
    required this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      criterion.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DocenteColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      criterion.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DocenteColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DocenteColors.offWhite,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: Text(
                  '${currentScore.toStringAsFixed(1)} / ${criterion.maxScore.toStringAsFixed(1)} pts',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DocenteColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: DocenteColors.emerald,
              inactiveTrackColor: DocenteColors.border,
              thumbColor: DocenteColors.emerald,
              overlayColor: DocenteColors.emerald.withValues(alpha: 0.12),
              trackHeight: 6,
            ),
            child: Slider(
              value: currentScore.clamp(0.0, criterion.maxScore),
              min: 0.0,
              max: criterion.maxScore,
              divisions: (criterion.maxScore * 10).round().clamp(1, 1000),
              onChanged: onScoreChanged,
            ),
          ),
        ],
      ),
    );
  }
}
