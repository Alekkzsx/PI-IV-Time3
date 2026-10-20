// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../../domain/models/assignment_model.dart';
import '../controllers/docente_controller.dart';
import '../widgets/create_assignment_modal.dart';
import '../widgets/rubric_evaluation_modal.dart';

/// Tab page for managing course assignments, rubrics, and evaluating student submissions.
class DocenteAssignmentsTab extends StatelessWidget {
  /// Reactive controller for state access and mutations.
  final DocenteController controller;

  const DocenteAssignmentsTab({
    super.key,
    required this.controller,
  });

  void _openCreateAssignmentModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => CreateAssignmentModal(controller: controller),
    );
  }

  void _openRubricModal(BuildContext context, AssignmentItem assignment, StudentSubmission submission) {
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
    final selectedAssignment = controller.selectedAssignment;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(context),
          const SizedBox(height: 24),
          _buildAssignmentsList(context),
          const SizedBox(height: 28),
          _buildSubmissionsSection(context, selectedAssignment),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestão de Atividades & Avaliações',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DocenteColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Critérios de correção, rubricas pedagógicas e entregas dos discentes • ${controller.selectedCourse.name}',
              style: const TextStyle(
                fontSize: 14,
                color: DocenteColors.slate,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openCreateAssignmentModal(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            'Nova Atividade / Avaliação',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: DocenteColors.charcoal,
            foregroundColor: DocenteColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividades Cadastradas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: DocenteColors.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.assignments.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 2 : 1,
                mainAxisExtent: 220,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final asg = controller.assignments[index];
                final isSelected = asg.id == controller.selectedAssignmentId;
                final deliveredCount = asg.submissions.where((s) => s.status != SubmissionStatus.naoEntregue).length;
                final totalStudents = asg.submissions.length;
                final progress = totalStudents > 0 ? deliveredCount / totalStudents : 0.0;

                return InkWell(
                  onTap: () => controller.selectAssignment(asg.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: DocenteColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? DocenteColors.charcoal : DocenteColors.border,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: DocenteColors.offWhite,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: DocenteColors.border),
                              ),
                              child: Text(
                                asg.stage,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: DocenteColors.charcoal,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: DocenteColors.emerald.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Peso: ${(asg.weight * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: DocenteColors.emerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          asg.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: DocenteColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Prazo: ${asg.dueDateFormatted} • ${asg.modality}',
                          style: const TextStyle(fontSize: 12, color: DocenteColors.slate),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$deliveredCount de $totalStudents entregas',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: DocenteColors.charcoal,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: DocenteColors.slate,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: DocenteColors.offWhite,
                            color: DocenteColors.emerald,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubmissionsSection(BuildContext context, AssignmentItem assignment) {
    return Container(
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submissões de Alunos: ${assignment.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DocenteColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${assignment.rubricCriteria.length} critérios na rubrica • Avaliações lançadas computam na nota final',
                      style: const TextStyle(fontSize: 13, color: DocenteColors.slate),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: assignment.rubricCriteria.map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DocenteColors.offWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DocenteColors.border),
                      ),
                      child: Text(
                        '${c.title} (${c.maxScore} pts)',
                        style: const TextStyle(fontSize: 11, color: DocenteColors.charcoal),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: DocenteColors.border),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 900),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(DocenteColors.offWhite),
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Discente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  DataColumn(label: Text('Data Envio', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  DataColumn(label: Text('Arquivo Anexado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  DataColumn(label: Text('Nota Rubrica', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  DataColumn(label: Text('Ações Pedagógicas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                ],
                rows: assignment.submissions.map((sub) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              'RA: ${sub.ra}',
                              style: const TextStyle(fontSize: 11, color: DocenteColors.slate),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          sub.submittedAtFormatted ?? 'Pendente',
                          style: TextStyle(
                            fontSize: 12,
                            color: sub.submittedAtFormatted == null ? DocenteColors.muted : DocenteColors.charcoal,
                          ),
                        ),
                      ),
                      DataCell(
                        sub.fileName != null
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.picture_as_pdf, color: DocenteColors.crimson, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    sub.fileName!,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              )
                            : const Text('-', style: TextStyle(color: DocenteColors.muted)),
                      ),
                      DataCell(_buildStatusBadge(sub.status)),
                      DataCell(
                        sub.grade != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: DocenteColors.emerald.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${sub.grade!.toStringAsFixed(1)} / 10.0',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: DocenteColors.emerald,
                                  ),
                                ),
                              )
                            : const Text('Sem nota', style: TextStyle(color: DocenteColors.muted, fontSize: 12)),
                      ),
                      DataCell(
                        ElevatedButton.icon(
                          onPressed: sub.status == SubmissionStatus.naoEntregue
                              ? null
                              : () => _openRubricModal(context, assignment, sub),
                          icon: Icon(
                            sub.status == SubmissionStatus.corrigido ? Icons.edit_note : Icons.grading_rounded,
                            size: 16,
                          ),
                          label: Text(
                            sub.status == SubmissionStatus.corrigido ? 'Revisar Nota' : 'Avaliar Rubrica',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DocenteColors.charcoal,
                            foregroundColor: DocenteColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SubmissionStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case SubmissionStatus.entregue:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        label = 'Entregue';
        break;
      case SubmissionStatus.corrigido:
        bg = const Color(0xFFECFDF5);
        fg = DocenteColors.emerald;
        label = 'Corrigido';
        break;
      case SubmissionStatus.atrasado:
        bg = const Color(0xFFFFFBEB);
        fg = DocenteColors.amber;
        label = 'Com Atraso';
        break;
      case SubmissionStatus.naoEntregue:
        bg = const Color(0xFFFEF2F2);
        fg = DocenteColors.crimson;
        label = 'Não Entregue';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
