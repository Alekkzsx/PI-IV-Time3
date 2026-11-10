// Desenvolvido por Rafael Henrique Inácio - RA: 25009719 e Alex Gabriel Soares Sousa - RA: 24802449
// Grid de Cards de Turmas do Docente fiel à imagem de referência

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'docente_course_card.dart';

/// Seção que renderiza a grade de turmas ativas do docente no Painel Geral.
class DocenteCoursesPreviewSection extends StatelessWidget {
  final DocenteController controller;
  final void Function(String courseId)? onOpenCourseHub;

  const DocenteCoursesPreviewSection({
    super.key,
    required this.controller,
    this.onOpenCourseHub,
  });

  void _handleOpenCourse(String courseId) {
    if (onOpenCourseHub != null) {
      onOpenCourseHub!(courseId);
    } else {
      controller.selectCourse(courseId);
      controller.navigateToTab(DocenteNavTab.turmas);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = controller.courses;
    if (courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: InstColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: InstColors.border),
        ),
        child: Center(
          child: Text(
            'Nenhuma turma vinculada à sua matrícula docente.',
            style: jakarta(size: 13, color: InstColors.muted),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoCols = constraints.maxWidth >= 600;

        if (!isTwoCols) {
          return Column(
            children: [
              for (int i = 0; i < courses.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                DocenteCourseCard(
                  course: courses[i],
                  onOpenCourseHub: () => _handleOpenCourse(courses[i].id),
                ),
              ],
            ],
          );
        }

        // Layout de 2 colunas para espelhar a imagem com precisão
        final rows = <Widget>[];
        for (int i = 0; i < courses.length; i += 2) {
          final first = courses[i];
          final hasSecond = i + 1 < courses.length;
          final second = hasSecond ? courses[i + 1] : null;

          if (i > 0) rows.add(const SizedBox(height: 16));

          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DocenteCourseCard(
                    course: first,
                    onOpenCourseHub: () => _handleOpenCourse(first.id),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: second != null
                      ? DocenteCourseCard(
                          course: second,
                          onOpenCourseHub: () => _handleOpenCourse(second.id),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }
}
