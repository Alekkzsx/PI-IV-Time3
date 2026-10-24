// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/create_assignment_modal.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/docente_assignments_cards_grid.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/docente_assignments_header.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/docente_submissions_table.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/rubric_evaluation_modal.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';

/// Aba de gestão de tarefas, trabalhos avaliativos, rubricas e submissões discentes do docente.
/// Refatorada e modularizada com arquitetura limpa em `widgets/`.
class DocenteAssignmentsTab extends StatelessWidget {
  final DocenteController controller;

  const DocenteAssignmentsTab({super.key, required this.controller});

  void _openCreateAssignmentModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => CreateAssignmentModal(controller: controller),
    );
  }

  void _openRubricModal(
    BuildContext context,
    AssignmentItem assignment,
    StudentSubmission submission,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => RubricEvaluationModal(
        assignment: assignment,
        submission: submission,
        controller: controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedCourse = controller.selectedCourse;
        final courseAssignments = controller.assignments
            .where((a) => a.courseId == selectedCourse.id)
            .toList();

        final selectedAssignment = courseAssignments.isNotEmpty
            ? courseAssignments.firstWhere(
                (a) => a.id == controller.selectedAssignmentId,
                orElse: () => courseAssignments.first,
              )
            : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth >= 900 ? 40 : 20,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DocenteAssignmentsHeader(
                            controller: controller,
                            selectedCourse: selectedCourse,
                            onOpenCreateAssignment: () =>
                                _openCreateAssignmentModal(context),
                          ),
                          const SizedBox(height: 24),
                          DocenteAssignmentsCardsGrid(
                            assignments: courseAssignments,
                            selectedAssignment: selectedAssignment,
                            selectedCourse: selectedCourse,
                            onSelectAssignment: (id) =>
                                controller.selectAssignment(id),
                          ),
                          const SizedBox(height: 28),
                          if (selectedAssignment != null)
                            DocenteSubmissionsTable(
                              assignment: selectedAssignment,
                              selectedCourse: selectedCourse,
                              onOpenRubric: (asg, sub) =>
                                  _openRubricModal(context, asg, sub),
                              controller: controller,
                            )
                          else
                            _buildEmptySubmissionsCard(),
                        ],
                      ),
                    ),
                    const DocenteFooter(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySubmissionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFA1A1AA)),
            SizedBox(height: 12),
            Text(
              'Nenhuma entrega selecionada',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF27272A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Selecione uma atividade nos cartões acima ou cadastre uma nova para visualizar as submissões.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF71717A)),
            ),
          ],
        ),
      ),
    );
  }
}
