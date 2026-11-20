// Desenvolvido por Rafael Henrique Inácio - RA: 25009719 e Alex Gabriel Soares Sousa - RA: 24802449
// Seção "Minhas Turmas" do Painel Geral - Pixel-perfect fiel ao PDF
// Cabeçalho com título "Minhas Turmas" + link "Ver grade →"

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'docente_course_card.dart';

/// Seção que renderiza a grade de turmas ativas do docente no Painel Geral.
/// Fiel ao PDF: cabeçalho "Minhas Turmas" + "Ver grade →" à direita.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ═══════════════════════════════════════════
        // CABEÇALHO: "Minhas Turmas" + "Ver grade →"
        // ═══════════════════════════════════════════
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Minhas Turmas',
              style: jakarta(
                size: 20,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => controller.navigateToTab(DocenteNavTab.turmas),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver grade',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF18181B),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ═══════════════════════════════════════════
        // GRADE DE TURMAS
        // ═══════════════════════════════════════════
        if (courses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
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
          )
        else
          LayoutBuilder(
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

              // Layout de 2 colunas (fiel ao PDF)
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
          ),
      ],
    );
  }
}
