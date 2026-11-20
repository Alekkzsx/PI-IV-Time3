// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../../../../shared/domain/models/docente_course.dart';
import '../../../../shared/theme/docente_colors.dart';

/// Card atômico que exibe uma unidade do plano de ensino e o progresso das aulas ministradas.
class SyllabusUnitCard extends StatelessWidget {
  final SyllabusUnit unit;
  final VoidCallback onAdvanceClasses;

  const SyllabusUnitCard({
    super.key,
    required this.unit,
    required this.onAdvanceClasses,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (unit.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DocenteColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UNIDADE ${unit.unitNumber.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              OutlinedButton(
                onPressed: onAdvanceClasses,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  side: const BorderSide(color: DocenteColors.borderDark),
                ),
                child: const Text(
                  'Avançar Aulas',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            unit.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DocenteColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tópicos previstos no PPC:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DocenteColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ...unit.topics.map(
            (topic) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: DocenteColors.textMuted),
                  ),
                  Expanded(
                    child: Text(
                      topic,
                      style: const TextStyle(
                        fontSize: 13,
                        color: DocenteColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: unit.progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E5E5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                DocenteColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aulas ministradas: ${unit.completedClasses} de ${unit.totalClasses}',
                style: const TextStyle(
                  fontSize: 12,
                  color: DocenteColors.textSecondary,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
