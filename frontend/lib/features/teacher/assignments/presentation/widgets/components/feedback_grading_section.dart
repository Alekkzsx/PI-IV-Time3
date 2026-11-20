// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../../../shared/domain/models/assignment_model.dart';

/// Seção molecular de atribuição de nota e parecer pedagógico individual.
class FeedbackGradingSection extends StatelessWidget {
  final TextEditingController gradeController;
  final TextEditingController feedbackController;
  final AssignmentItem assignment;

  const FeedbackGradingSection({
    super.key,
    required this.gradeController,
    required this.feedbackController,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nota da Atividade',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: gradeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: jakarta(
                        size: 16,
                        weight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        suffixText: '/ 10,0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E4E7),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E4E7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rubrica Aplicada',
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${assignment.rubricCriteria.length} critérios regimentais vinculados • Peso N1 (${assignment.weight} pontos)',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Parecer Pedagógico Individual (Devolutiva com orientações de melhoria)',
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w600,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: feedbackController,
            maxLines: 7,
            style: jakarta(
              size: 13,
              color: const Color(0xFF18181B),
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'Escreva orientações detalhadas sobre o trabalho entregue pelo estudante...',
              hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
