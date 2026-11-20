// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../../../shared/domain/models/assignment_model.dart';
import '../../../../shared/domain/models/docente_course.dart';

/// Cabeçalho institucional com metadados detalhados da atividade avaliativa selecionada.
class SubmissionHeaderMetadata extends StatelessWidget {
  final AssignmentItem assignment;
  final DocenteCourse selectedCourse;

  const SubmissionHeaderMetadata({
    super.key,
    required this.assignment,
    required this.selectedCourse,
  });

  Widget _buildMetadataChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Text(
        label,
        style: jakarta(
          size: 11,
          weight: FontWeight.w500,
          color: const Color(0xFF52525B),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: Text(
                      assignment.courseCode.isNotEmpty
                          ? assignment.courseCode
                          : selectedCourse.code,
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    selectedCourse.title.isNotEmpty
                        ? selectedCourse.title
                        : 'Análise e Projeto de Sistemas II',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w400,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Prazo Final de Entrega',
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w400,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    assignment.dueDateFormatted,
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            assignment.title,
            style: jakarta(
              size: 18,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          if (assignment.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              assignment.description,
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w400,
                color: const Color(0xFF52525B),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetadataChip(
                'Modalidade: ${assignment.modality}',
              ),
              _buildMetadataChip(
                'Critérios na rubrica: ${assignment.rubricCriteria.length}',
              ),
              _buildMetadataChip(
                assignment.allowLateWithPenalty
                    ? 'Entregas atrasadas permitidas com penalidade'
                    : 'Prazo sem tolerância para atraso',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
