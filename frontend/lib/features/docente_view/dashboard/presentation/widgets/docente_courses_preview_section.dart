// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Seção com a grade de turmas e disciplinas ativas do docente.
class DocenteCoursesPreviewSection extends StatelessWidget {
  final DocenteController controller;

  const DocenteCoursesPreviewSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Minhas Turmas e Disciplinas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: DocenteColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => controller.navigateToTab(DocenteNavTab.turmas),
              child: const Text('Ver todas as turmas →'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            return isWide
                ? Row(
                    children: controller.courses.map((course) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _buildCourseCard(course),
                        ),
                      );
                    }).toList(),
                  )
                : Column(
                    children: controller.courses.map((course) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCourseCard(course),
                      );
                    }).toList(),
                  );
          },
        ),
      ],
    );
  }

  Widget _buildCourseCard(DocenteCourse course) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  course.code,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DocenteColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${course.enrolledCount} alunos',
                style: const TextStyle(
                  fontSize: 12,
                  color: DocenteColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DocenteColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            course.schedule,
            style: const TextStyle(
              fontSize: 12,
              color: DocenteColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (course.progressPercentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF0EEE9),
              valueColor: const AlwaysStoppedAnimation<Color>(DocenteColors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Carga Horária: ${course.completedHours}h / ${course.totalHours}h',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: DocenteColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${course.progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.selectCourse(course.id);
                    controller.navigateToTab(DocenteNavTab.diario);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Diário', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.selectCourse(course.id);
                    controller.navigateToTab(DocenteNavTab.notas);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Notas', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
