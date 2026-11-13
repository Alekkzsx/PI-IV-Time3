// Desenvolvido por Guilherme Henrique Moreira e Alex Gabriel Soares Sousa - RA: 24802449
// Aba de Turmas e Componentes Curriculares da Visão do Docente
// Dados 100% tratados e entregues pelo backend/MongoDB

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
    return ColoredBox(
      color: InstColors.surface,
      child: LayoutBuilder(
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
                          horizontal: isDesktop ? 48 : 20,
                          vertical: isDesktop ? 36 : 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header da Aba
                            Text(
                              'Minhas Turmas e Componentes Curriculares',
                              style: jakarta(
                                size: 20,
                                weight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gerencie o plano de ensino, acompanhe a carga horária ministrada e disponibilize materiais didáticos.',
                              style: jakarta(
                                size: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Grade Responsiva de 3 Colunas dos Cards de Turma
                            _buildResponsiveCoursesGrid(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DocenteFooter(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48 : 20,
                      vertical: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveCoursesGrid(BuildContext context) {
    final courses = controller.courses;
    if (courses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
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
      builder: (context, gridConstraints) {
        final width = gridConstraints.maxWidth;
        final columns = width >= 980
            ? 3
            : width >= 640
                ? 2
                : 1;

        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < courses.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _buildDetailedCourseCard(context, courses[i]),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (int i = 0; i < courses.length; i += columns) {
          if (i > 0) rows.add(const SizedBox(height: 20));
          final rowChildren = <Widget>[];
          for (int col = 0; col < columns; col++) {
            if (col > 0) rowChildren.add(const SizedBox(width: 20));
            final idx = i + col;
            if (idx < courses.length) {
              rowChildren.add(
                Expanded(
                  child: _buildDetailedCourseCard(context, courses[idx]),
                ),
              );
            } else {
              rowChildren.add(const Expanded(child: SizedBox.shrink()));
            }
          }
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowChildren,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }

  Widget _buildDetailedCourseCard(BuildContext context, DocenteCourse course) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Linha Superior: Código (badge com borda) + Semestre à direita
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  course.code,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  course.term,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Título da Disciplina + Turno abaixo
          Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: jakarta(
              size: 16.5,
              weight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            course.shift,
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // 3. Metadados Empilhados (Sala, Horário e Discentes Matriculados)
          _buildMetadataRow(
            icon: Icons.location_on_outlined,
            text: course.room,
          ),
          const SizedBox(height: 8),
          _buildMetadataRow(
            icon: Icons.access_time_rounded,
            text: course.schedule,
          ),
          const SizedBox(height: 8),
          _buildMetadataRow(
            icon: Icons.people_outline_rounded,
            text: course.enrolledStudentsLabel,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // 4. Barra de Progresso de Carga Horária (tratada no backend)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: jakarta(
                      size: 12,
                      color: const Color(0xFF64748B),
                    ),
                    children: [
                      const TextSpan(text: 'Carga Horária: '),
                      TextSpan(
                        text: course.workloadCompletedLabel,
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      TextSpan(text: course.workloadTotalLabel),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                course.progressPercentageFormatted,
                style: jakarta(
                  size: 12,
                  weight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: course.progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.progressCaption,
            style: jakarta(
              size: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),

          // 5. Pilha Vertical de Botões de Ação
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              key: Key('btn_ava_course_${course.id}'),
              onPressed: () => onOpenCourseHub(course.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 15,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Acessar Sala de Aula Virtual (AVA)',
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              key: Key('btn_syllabus_course_${course.id}'),
              onPressed: () => _showSyllabusModal(context, course),
              icon: const Icon(
                Icons.menu_book_outlined,
                size: 15,
                color: Color(0xFF0F172A),
              ),
              label: Text(
                'Plano de Ensino & Materiais',
                overflow: TextOverflow.ellipsis,
                style: jakarta(
                  size: 12,
                  weight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE4E4E7)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    key: Key('btn_diario_course_${course.id}'),
                    onPressed: () {
                      controller.selectCourse(course.id);
                      controller.navigateToTab(DocenteNavTab.diario);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Diário',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    key: Key('btn_notas_course_${course.id}'),
                    onPressed: () {
                      controller.selectCourse(course.id);
                      controller.navigateToTab(DocenteNavTab.notas);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Notas',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w400,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
