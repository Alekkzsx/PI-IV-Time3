// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/docente_view/shell/presentation/widgets/docente_footer.dart';
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
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(context, selectedCourse),
                          const SizedBox(height: 24),
                          _buildAssignmentsCards(context, courseAssignments, selectedAssignment),
                          const SizedBox(height: 28),
                          if (selectedAssignment != null)
                            _buildSubmissionsCard(context, selectedAssignment)
                          else
                            _buildEmptySubmissionsCard(context, selectedCourse),
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

  Widget _buildTopBar(BuildContext context, DocenteCourse selectedCourse) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
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
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seletor de Matéria / Disciplina
            Container(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 16,
                    color: Color(0xFF71717A),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
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
                          // Atualiza também a atividade selecionada para a primeira da nova turma (se houver)
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
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Botão Cadastrar Nova Atividade com feedback institucional
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openCreateAssignmentModal(context),
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
        ),
      ],
    );
  }

  Widget _buildAssignmentsCards(
    BuildContext context,
    List<AssignmentItem> assignments,
    AssignmentItem? selectedAssignment,
  ) {
    if (assignments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_late_outlined,
              size: 40,
              color: Color(0xFFA1A1AA),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma atividade cadastrada para esta disciplina',
              style: jakarta(
                size: 14,
                weight: FontWeight.w600,
                color: const Color(0xFF27272A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Clique no botão acima para cadastrar a primeira atividade avaliativa.',
              style: jakarta(
                size: 12,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < assignments.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(
                child: _buildAssignmentCard(
                  context,
                  assignments[i],
                  isSelected: assignments[i].id == selectedAssignment?.id,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    AssignmentItem asg, {
    required bool isSelected,
  }) {
    final total = asg.submissions.length;
    final corrigidas = asg.submissions.where((s) => s.status == SubmissionStatus.corrigido).length;
    final pendentes = asg.submissions.where((s) => s.status == SubmissionStatus.aguardandoCorrecao).length;

    final weightStr = asg.weight > 0 ? asg.weight.toStringAsFixed(1) : '3.0';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.selectAssignment(asg.id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF18181B).withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF4F4F5) : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFD4D4D8) : const Color(0xFFE4E4E7),
                      ),
                    ),
                    child: Text(
                      asg.courseCode.isNotEmpty ? asg.courseCode : controller.selectedCourse.code,
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w600,
                        color: const Color(0xFF27272A),
                      ),
                    ),
                  ),
                  Text(
                    'Peso: $weightStr pts (${asg.stage})',
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w500,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                asg.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF71717A)),
                  const SizedBox(width: 4),
                  Text(
                    'Prazo: ${asg.dueDateFormatted}',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w400,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$corrigidas corrigidas / $total submissões',
                    style: jakarta(
                      size: 11.5,
                      weight: FontWeight.w400,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                  if (pendentes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: Text(
                        '$pendentes pendentes',
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w600,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySubmissionsCard(BuildContext context, DocenteCourse course) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFA1A1AA)),
            const SizedBox(height: 12),
            Text(
              'Nenhuma entrega selecionada',
              style: jakarta(size: 15, weight: FontWeight.w600, color: const Color(0xFF27272A)),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecione uma atividade nos cartões acima ou cadastre uma nova para visualizar as submissões.',
              style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionsCard(BuildContext context, AssignmentItem assignment) {
    return Container(
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
          // Header box of selected assignment
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                          ),
                          child: Text(
                            assignment.courseCode.isNotEmpty
                                ? assignment.courseCode
                                : controller.selectedCourse.code,
                            style: jakarta(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          controller.selectedCourse.title.isNotEmpty
                              ? controller.selectedCourse.title
                              : 'Análise e Projeto de Sistemas II',
                          style: jakarta(
                            size: 12,
                            weight: FontWeight.w400,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Prazo Final de Entrega',
                          style: jakarta(
                            size: 11,
                            weight: FontWeight.w400,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          assignment.dueDateFormatted,
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  assignment.title,
                  style: jakarta(
                    size: 18,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elaboração completa do modelo de domínio e do diagrama de sequência referente ao caso de uso de Checkout e Faturamento. O trabalho deve seguir estritamente o padrão UML 2.5 e apresentar rastreabilidade com a matriz de requisitos.',
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF52525B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Modalidade: ',
                      style: jakarta(size: 11.5, weight: FontWeight.w400, color: const Color(0xFF71717A)),
                    ),
                    Text(
                      'Individual',
                      style: jakarta(size: 11.5, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(
                      'Formatos aceitos: ',
                      style: jakarta(size: 11.5, weight: FontWeight.w400, color: const Color(0xFF71717A)),
                    ),
                    Text(
                      '.pdf, .zip',
                      style: jakarta(size: 11.5, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFFD4D4D8), fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(
                      'Critérios na Rubrica: ',
                      style: jakarta(size: 11.5, weight: FontWeight.w400, color: const Color(0xFF71717A)),
                    ),
                    Text(
                      '${assignment.rubricCriteria.length} parâmetros',
                      style: jakarta(size: 11.5, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          // Table of submissions
          _buildSubmissionsTable(context, assignment),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTable(BuildContext context, AssignmentItem assignment) {
    return Column(
      children: [
        // Table Header
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
                  style: jakarta(size: 11, weight: FontWeight.w600, color: const Color(0xFF71717A)),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'ESTUDANTE',
                  style: jakarta(size: 11, weight: FontWeight.w600, color: const Color(0xFF71717A)),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'ARQUIVO SUBMETIDO',
                  style: jakarta(size: 11, weight: FontWeight.w600, color: const Color(0xFF71717A)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'DATA / HORA DE ENVIO',
                  style: jakarta(size: 11, weight: FontWeight.w600, color: const Color(0xFF71717A)),
                ),
              ),
              SizedBox(
                width: 120,
                child: Center(
                  child: Text(
                    'NOTA ATRIBUÍDA',
                    style: jakarta(size: 11, weight: FontWeight.w600, color: const Color(0xFF71717A)),
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: Center(
                  child: Text(
                    'STATUS',
                    style: jakarta(size: 11, weight: FontWeight.w600, color: const Color(0xFF71717A)),
                  ),
                ),
              ),
              SizedBox(
                width: 130,
                child: Center(
                  child: Text(
                    'AÇÃO',
                    style: jakarta(size: 11, weight: FontWeight.w600, color: const Color(0xFF71717A)),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Table Rows
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
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF4F4F5)),
            itemBuilder: (context, index) {
              final sub = assignment.submissions[index];
              final isOnline = sub.studentName == 'Gabriel Soares de Oliveira';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: Colors.white,
                child: Row(
                  children: [
                    // R.A.
                    SizedBox(
                      width: 120,
                      child: Text(
                        sub.ra,
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ),
                    // Estudante
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              sub.studentName,
                              style: jakarta(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: const Color(0xFF18181B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOnline) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Text(
                                'DISCENTE CONECTADO',
                                style: jakarta(
                                  size: 9,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Arquivo Submetido
                    Expanded(
                      flex: 3,
                      child: sub.fileName != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 15,
                                  color: Color(0xFF71717A),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _truncateFileName(sub.fileName!),
                                    style: jakarta(
                                      size: 12,
                                      weight: FontWeight.w400,
                                      color: const Color(0xFF27272A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Nenhum arquivo enviado',
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w400,
                                color: const Color(0xFFA1A1AA),
                              ),
                            ),
                    ),
                    // Data / Hora de Envio
                    Expanded(
                      flex: 2,
                      child: Text(
                        sub.submittedAtFormatted ?? '—',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w400,
                          color: sub.submittedAtFormatted != null
                              ? const Color(0xFF71717A)
                              : const Color(0xFFA1A1AA),
                        ),
                      ),
                    ),
                    // Nota Atribuída
                    SizedBox(
                      width: 120,
                      child: Center(
                        child: Text(
                          sub.grade != null ? '${sub.grade!.toStringAsFixed(1)} / 10.0' : '—',
                          style: jakarta(
                            size: 12.5,
                            weight: sub.grade != null ? FontWeight.w700 : FontWeight.w400,
                            color: sub.grade != null ? const Color(0xFF18181B) : const Color(0xFFA1A1AA),
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    SizedBox(
                      width: 150,
                      child: Center(
                        child: _buildStatusPill(sub.status),
                      ),
                    ),
                    // Ação Button
                    SizedBox(
                      width: 130,
                      child: Center(
                        child: _buildActionButton(context, assignment, sub),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _truncateFileName(String name) {
    if (name.length > 26) {
      return '${name.substring(0, 23)}...';
    }
    return name;
  }

  Widget _buildStatusPill(SubmissionStatus status) {
    Color bg;
    Color fg;
    Color border;
    String label;

    switch (status) {
      case SubmissionStatus.corrigido:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        border = const Color(0xFFBBF7D0);
        label = 'Corrigido';
        break;
      case SubmissionStatus.aguardandoCorrecao:
        bg = const Color(0xFFFFF1F2);
        fg = const Color(0xFFE11D48);
        border = const Color(0xFFFECDD3);
        label = 'Aguardando Correção';
        break;
      case SubmissionStatus.entregue:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        border = const Color(0xFFBFDBFE);
        label = 'Entregue';
        break;
      case SubmissionStatus.atrasado:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        border = const Color(0xFFFDE68A);
        label = 'Atrasado';
        break;
      case SubmissionStatus.naoEntregue:
        bg = const Color(0xFFF4F4F5);
        fg = const Color(0xFF71717A);
        border = const Color(0xFFE4E4E7);
        label = 'Não Entregue';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: jakarta(
          size: 11,
          weight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, AssignmentItem assignment, StudentSubmission sub) {
    if (sub.status == SubmissionStatus.naoEntregue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Text(
          'Sem Submissão',
          style: jakarta(
            size: 11,
            weight: FontWeight.w500,
            color: const Color(0xFFA1A1AA),
          ),
        ),
      );
    }

    final isCorrigido = sub.status == SubmissionStatus.corrigido;
    final label = isCorrigido ? 'Revisar Nota' : 'Avaliar Rubrica';
    final icon = isCorrigido ? Icons.edit_note_rounded : Icons.grading_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openRubricModal(context, assignment, sub),
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isCorrigido ? Colors.white : const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCorrigido ? const Color(0xFFD4D4D8) : const Color(0xFF18181B),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isCorrigido ? const Color(0xFF18181B) : Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w600,
                  color: isCorrigido ? const Color(0xFF18181B) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
