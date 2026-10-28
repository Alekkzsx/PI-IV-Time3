// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';

/// Barra superior de gestão de atividades avaliativas com seletor de turmas e ação de novo cadastro.
class DocenteAssignmentsHeader extends StatelessWidget {
  final DocenteController controller;
  final DocenteCourse selectedCourse;
  final VoidCallback onOpenCreateAssignment;

  const DocenteAssignmentsHeader({
    super.key,
    required this.controller,
    required this.selectedCourse,
    required this.onOpenCreateAssignment,
  });

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestão de Atividades Avaliativas & Correção',
          style: jakarta(
            size: 20,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Crie tarefas com critérios formais, acompanhe submissões discentes e aplique rubricas com parecer pedagógico.',
          style: jakarta(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF71717A),
          ),
        ),
      ],
    );
    final actions = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 10,
      children: [
        // Seletor de Matéria / Disciplina
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E4E7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 16,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCourse.id,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF71717A),
                      ),
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                      onChanged: (newCourseId) {
                        if (newCourseId != null) {
                          controller.selectCourse(newCourseId);
                          final list = controller.assignments
                              .where((a) => a.courseId == newCourseId)
                              .toList();
                          if (list.isNotEmpty) {
                            controller.selectAssignment(list.first.id);
                          }
                        }
                      },
                      items: controller.courses.map((course) {
                        return DropdownMenuItem<String>(
                          value: course.id,
                          child: Text(
                            '${course.code} • ${course.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: jakarta(
                              size: 12.5,
                              weight: FontWeight.w500,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Botão Cadastrar Nova Atividade
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenCreateAssignment,
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF18181B).withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Cadastrar Nova Atividade',
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1050) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 16), actions],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 20),
            actions,
          ],
        );
      },
    );
  }
}
