// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';

/// Grid de cards de atividades avaliativas com pesos, prazos e indicadores de submissões pendentes.
class DocenteAssignmentsCardsGrid extends StatelessWidget {
  final List<AssignmentItem> assignments;
  final AssignmentItem? selectedAssignment;
  final DocenteCourse selectedCourse;
  final ValueChanged<String> onSelectAssignment;

  const DocenteAssignmentsCardsGrid({
    super.key,
    required this.assignments,
    required this.selectedAssignment,
    required this.selectedCourse,
    required this.onSelectAssignment,
  });

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_late_outlined,
              size: 40,
              color: Color(0xFFA1A1AA),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma atividade cadastrada para esta disciplina',
              style: jakarta(
                size: 14,
                weight: FontWeight.w600,
                color: const Color(0xFF27272A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Clique no botão acima para cadastrar a primeira atividade avaliativa.',
              style: jakarta(
                size: 12,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 1200
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth >= 760
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final assignment in assignments)
              SizedBox(
                width: cardWidth,
                child: _buildAssignmentCard(
                  context,
                  assignment,
                  isSelected: assignment.id == selectedAssignment?.id,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    AssignmentItem asg, {
    required bool isSelected,
  }) {
    final total = asg.submissions.length;
    final corrigidas = asg.submissions
        .where((s) => s.status == SubmissionStatus.corrigido)
        .length;
    final pendentes = asg.submissions
        .where((s) => s.status == SubmissionStatus.aguardandoCorrecao)
        .length;
    final weightStr = asg.weight > 0 ? asg.weight.toStringAsFixed(1) : '3.0';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectAssignment(asg.id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF18181B)
                  : const Color(0xFFE4E4E7),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF18181B).withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF4F4F5)
                          : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD4D4D8)
                            : const Color(0xFFE4E4E7),
                      ),
                    ),
                    child: Text(
                      asg.courseCode.isNotEmpty
                          ? asg.courseCode
                          : selectedCourse.code,
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w600,
                        color: const Color(0xFF27272A),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Peso: $weightStr pts (${asg.stage})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w500,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                asg.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: Color(0xFF71717A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Prazo: ${asg.dueDateFormatted}',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w400,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$corrigidas corrigidas / $total submissões',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ),
                  if (pendentes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Text(
                        '$pendentes pendentes',
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w600,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
