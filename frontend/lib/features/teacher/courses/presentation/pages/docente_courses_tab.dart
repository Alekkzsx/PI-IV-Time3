// Desenvolvido por Guilherme Henrique Moreira e Alex Gabriel Soares Sousa - RA: 24802449
// Aba de Turmas e Componentes Curriculares da Visão do Docente

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import '../widgets/syllabus_materials_modal.dart';

/// Aba de gestão de turmas e componentes curriculares no Portal Docente.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 40 : 20,
                        vertical: isDesktop ? 32 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header da Aba
                          Text(
                            'Minhas Turmas e Componentes Curriculares',
                            style: jakarta(
                              size: 24,
                              weight: FontWeight.w700,
                              color: InstColors.ink,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Gerencie o plano de ensino, acompanhe a carga horária ministrada e disponibilize materiais didáticos.',
                            style: jakarta(
                              size: 13.5,
                              color: InstColors.muted,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Lista dos Cards Detalhados de Turma
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.courses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final course = controller.courses[index];
                              return _buildDetailedCourseCard(context, course);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                DocenteFooter(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailedCourseCard(BuildContext context, DocenteCourse course) {
    final pct = course.progressPercentage.round();

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha Superior: Código e Período
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.code,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: InstColors.ink,
                  ),
                ),
              ),
              Text(
                course.term,
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: InstColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Título da Disciplina
          Text(
            course.title,
            style: jakarta(
              size: 20,
              weight: FontWeight.w700,
              color: InstColors.ink,
            ),
          ),
          const SizedBox(height: 6),

          // Turno, Sala e Horário
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: InstColors.stone,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  course.shift,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: InstColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${course.room} • ${course.schedule}',
                style: jakarta(
                  size: 12.5,
                  color: InstColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Discentes Matriculados
          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 18,
                color: InstColors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                '${course.enrolledCount} discentes matriculados',
                style: jakarta(
                  size: 13.5,
                  weight: FontWeight.w600,
                  color: InstColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de Progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carga Horária: ${course.completedHours}h de ${course.totalHours}h',
                style: jakarta(
                  size: 12.5,
                  color: InstColors.muted,
                ),
              ),
              Text(
                '$pct%',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (course.progressPercentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF4F4F5),
              valueColor: const AlwaysStoppedAnimation<Color>(InstColors.ink),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Este percentual reflete diretamente o progresso visto pelos discentes no portal acadêmico.',
            style: jakarta(size: 11.5, color: InstColors.faint),
          ),
          const SizedBox(height: 22),

          // Botões de Ação
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => onOpenCourseHub(course.id),
                icon: const Icon(Icons.school_rounded, size: 16),
                label: const Text('Acessar Sala de Aula Virtual (AVA)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: InstColors.ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
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
                  foregroundColor: InstColors.ink,
                  side: const BorderSide(color: InstColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                  foregroundColor: InstColors.ink,
                  side: const BorderSide(color: InstColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                  foregroundColor: InstColors.ink,
                  side: const BorderSide(color: InstColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
