// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'assignment_rubric_criterion_card.dart';

/// Seção molecular da matriz de rubrica avaliativa na criação de atividade.
class AssignmentRubricMatrixEditor extends StatelessWidget {
  final List<Map<String, TextEditingController>> rubricControllers;
  final double totalRubricSum;
  final VoidCallback onAddCriterion;
  final ValueChanged<int> onRemoveCriterion;
  final VoidCallback onPointsChanged;

  const AssignmentRubricMatrixEditor({
    super.key,
    required this.rubricControllers,
    required this.totalRubricSum,
    required this.onAddCriterion,
    required this.onRemoveCriterion,
    required this.onPointsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF4F4F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Matriz de Correção (Rubrica Avaliativa)',
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  'Soma: ${totalRubricSum.toStringAsFixed(1)} pts',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFF3F3F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Critérios transparentes que o discente consulta antes e depois da entrega.',
            style: jakarta(
              size: 12,
              weight: FontWeight.w400,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 16),

          // Cartões de Critérios
          ...List.generate(rubricControllers.length, (idx) {
            final c = rubricControllers[idx];
            return AssignmentRubricCriterionCard(
              titleController: c['title']!,
              pointsController: c['points']!,
              descController: c['desc']!,
              onRemove: rubricControllers.length > 1
                  ? () => onRemoveCriterion(idx)
                  : null,
              onPointsChanged: onPointsChanged,
            );
          }),

          const SizedBox(height: 6),
          // Botão Adicionar Critério Avaliativo
          OutlinedButton.icon(
            onPressed: onAddCriterion,
            icon: const Icon(
              Icons.add_rounded,
              size: 16,
              color: Color(0xFF3F3F46),
            ),
            label: Text(
              'Adicionar Critério Avaliativo',
              style: jakarta(
                size: 12,
                weight: FontWeight.w500,
                color: const Color(0xFF3F3F46),
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3F3F46),
              side: const BorderSide(color: Color(0xFFE4E4E7)),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
