// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../../domain/models/docente_course.dart';
import '../controllers/docente_controller.dart';
import '../widgets/syllabus_materials_modal.dart';

/// Classes and curriculum management tab in the Docente Portal.
class DocenteCoursesTab extends StatelessWidget {
  final DocenteController controller;
  final void Function(String courseId) onOpenCourseHub;

  const DocenteCoursesTab({
    super.key,
    required this.controller,
    required this.onOpenCourseHub,
  });

  void _showSyllabusModal(BuildContext context, DocenteCourse course) {
    showDialog(
      context: context,
      builder: (ctx) => SyllabusMaterialsModal(
        course: course,
        controller: controller,
        onOpenCourseHub: onOpenCourseHub,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Minhas Turmas e Componentes Curriculares',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gerencie o plano de ensino, acompanhe a carga horária ministrada e disponibilize materiais didáticos.',
                style: TextStyle(
                  fontSize: 14,
                  color: DocenteColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Course Cards List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.courses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final course = controller.courses[index];
                  return _buildDetailedCourseCard(context, course);
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedCourseCard(BuildContext context, DocenteCourse course) {
    final pct = course.progressPercentage.round();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DocenteColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top line: Code and Term tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DocenteColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.code,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: DocenteColors.textPrimary,
                  ),
                ),
              ),
              Text(
                course.term,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DocenteColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Course Title
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DocenteColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Shift, Room and Schedule
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DocenteColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  course.shift,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${course.room} • ${course.schedule}',
                style: const TextStyle(fontSize: 13, color: DocenteColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Enrolled count
          Row(
            children: [
              const Icon(Icons.people_outline_rounded, size: 18, color: DocenteColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                '${course.enrolledCount} discentes matriculados',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DocenteColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carga Horária: ${course.completedHours}h de ${course.totalHours}h',
                style: const TextStyle(fontSize: 13, color: DocenteColors.textSecondary),
              ),
              Text(
                '$pct%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (course.progressPercentage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF0EEE9),
              valueColor: const AlwaysStoppedAnimation<Color>(DocenteColors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este percentual reflete diretamente o progresso visto pelos discentes.',
            style: TextStyle(fontSize: 12, color: DocenteColors.textMuted),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => onOpenCourseHub(course.id),
                icon: const Icon(Icons.school_rounded, size: 16),
                label: const Text('Acessar Sala de Aula Virtual (AVA)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DocenteColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showSyllabusModal(context, course),
                icon: const Icon(Icons.menu_book_outlined, size: 16),
                label: const Text('Plano de Ensino & Materiais'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DocenteColors.textPrimary,
                  side: const BorderSide(color: DocenteColors.borderDark),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  controller.selectCourse(course.id);
                  controller.navigateToTab(DocenteNavTab.diario);
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Diário'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DocenteColors.textPrimary,
                  side: const BorderSide(color: DocenteColors.borderDark),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  controller.selectCourse(course.id);
                  controller.navigateToTab(DocenteNavTab.notas);
                },
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text('Notas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DocenteColors.textPrimary,
                  side: const BorderSide(color: DocenteColors.borderDark),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

