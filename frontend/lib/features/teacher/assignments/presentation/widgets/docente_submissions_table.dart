// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'components/submission_header_metadata.dart';
import 'components/submission_student_row.dart';

/// Callback para acionamento do modal de avaliação por rubricas.
typedef OnOpenRubricCallback =
    void Function(AssignmentItem assignment, StudentSubmission submission);

/// Container de submissões discentes com detalhes do trabalho, tabela de entregas e avaliação com rubrica.
class DocenteSubmissionsTable extends StatelessWidget {
  final AssignmentItem assignment;
  final DocenteCourse selectedCourse;
  final OnOpenRubricCallback onOpenRubric;
  final DocenteController? controller;

  const DocenteSubmissionsTable({
    super.key,
    required this.assignment,
    required this.selectedCourse,
    required this.onOpenRubric,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth < 1120 ? 1120 : constraints.maxWidth,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E4E7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caixa de cabeçalho da atividade selecionada
                SubmissionHeaderMetadata(
                  assignment: assignment,
                  selectedCourse: selectedCourse,
                ),
                const Divider(height: 1, color: Color(0xFFF4F4F5)),
                // Tabela de submissões
                _buildSubmissionsTable(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionsTable(BuildContext context) {
    return Column(
      children: [
        // Cabeçalho da Tabela
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            border: Border(
              bottom: BorderSide(color: Color(0xFFF4F4F5), width: 1),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'R.A.',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'ESTUDANTE',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'ARQUIVO SUBMETIDO',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'DATA / HORA DE ENVIO',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Center(
                  child: Text(
                    'NOTA ATRIBUÍDA',
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w600,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: Center(
                  child: Text(
                    'STATUS',
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w600,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 130,
                child: Center(
                  child: Text(
                    'AÇÃO',
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w600,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Linhas da Tabela
        if (assignment.submissions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'Nenhuma submissão registrada para esta atividade até o momento.',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w400,
                  color: const Color(0xFF71717A),
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assignment.submissions.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFF4F4F5)),
            itemBuilder: (context, index) {
              final sub = assignment.submissions[index];
              return SubmissionStudentRow(
                submission: sub,
                assignment: assignment,
                controller: controller,
                onOpenRubric: onOpenRubric,
              );
            },
          ),
      ],
    );
  }
}
