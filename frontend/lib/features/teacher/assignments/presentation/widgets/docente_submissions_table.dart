// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/docente_assignment_feedback_dialog.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/shared/widgets/academic_status_badge.dart';

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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFE4E4E7),
                                  ),
                                ),
                                child: Text(
                                  assignment.courseCode.isNotEmpty
                                      ? assignment.courseCode
                                      : selectedCourse.code,
                                  style: jakarta(
                                    size: 11.5,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedCourse.title.isNotEmpty
                                    ? selectedCourse.title
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
                      if (assignment.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          assignment.description,
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w400,
                            color: const Color(0xFF52525B),
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildMetadataChip(
                            'Modalidade: ${assignment.modality}',
                          ),
                          _buildMetadataChip(
                            'Critérios na rubrica: ${assignment.rubricCriteria.length}',
                          ),
                          _buildMetadataChip(
                            assignment.allowLateWithPenalty
                                ? 'Entregas atrasadas permitidas com penalidade'
                                : 'Prazo sem tolerância para atraso',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF4F4F5)),
                // Table of submissions
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
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFF4F4F5)),
            itemBuilder: (context, index) {
              final sub = assignment.submissions[index];
              final isOnline = sub.studentName == 'Gabriel Soares de Oliveira';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
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
                          sub.grade != null
                              ? '${sub.grade!.toStringAsFixed(1)} / 10.0'
                              : '—',
                          style: jakarta(
                            size: 12.5,
                            weight: sub.grade != null
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: sub.grade != null
                                ? const Color(0xFF18181B)
                                : const Color(0xFFA1A1AA),
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    SizedBox(
                      width: 150,
                      child: Center(child: _buildStatusBadge(sub.status)),
                    ),
                    // Ação Button
                    SizedBox(
                      width: 130,
                      child: Center(child: _buildActionButton(context, sub)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMetadataChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Text(
        label,
        style: jakarta(
          size: 11,
          weight: FontWeight.w500,
          color: const Color(0xFF52525B),
        ),
      ),
    );
  }

  String _truncateFileName(String name) {
    if (name.length > 26) {
      return '${name.substring(0, 23)}...';
    }
    return name;
  }

  Widget _buildStatusBadge(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.corrigido:
        return const AcademicStatusBadge(
          label: 'Corrigido',
          type: AcademicStatusType.aprovado,
        );
      case SubmissionStatus.aguardandoCorrecao:
        return const AcademicStatusBadge(
          label: 'Aguardando Correção',
          type: AcademicStatusType.pendente,
        );
      case SubmissionStatus.entregue:
        return const AcademicStatusBadge(
          label: 'Entregue',
          type: AcademicStatusType.aberto,
        );
      case SubmissionStatus.atrasado:
        return const AcademicStatusBadge(
          label: 'Atrasado',
          type: AcademicStatusType.reprovado,
        );
      case SubmissionStatus.naoEntregue:
        return const AcademicStatusBadge(
          label: 'Não Entregue',
          type: AcademicStatusType.custom,
        );
    }
  }

  Widget _buildActionButton(BuildContext context, StudentSubmission sub) {
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

    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        // Botão Feedback Individual & Canal de Dúvidas
        if (controller != null) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => DocenteAssignmentFeedbackDialog.show(
                context: context,
                assignment: assignment,
                submission: sub,
                controller: controller!,
              ),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Feedback',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w600,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Botão Avaliar Rubrica
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onOpenRubric(assignment, sub),
            borderRadius: BorderRadius.circular(6),
            child: Ink(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isCorrigido ? Colors.white : const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCorrigido
                      ? const Color(0xFFD4D4D8)
                      : const Color(0xFF18181B),
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
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w600,
                        color: isCorrigido
                            ? const Color(0xFF18181B)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
