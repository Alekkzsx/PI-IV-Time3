// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/docente_submissions_table.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'course_hub_ui.dart';

/// Aba de Tarefas e Submissões reais integrada diretamente no AVA da disciplina.
class CourseHubAssignmentsTab extends StatefulWidget {
  final DocenteCourse course;
  final DocenteController controller;
  final VoidCallback onNewAssignment;
  final void Function(AssignmentItem assignment, StudentSubmission submission)
      onOpenRubric;

  const CourseHubAssignmentsTab({
    super.key,
    required this.course,
    required this.controller,
    required this.onNewAssignment,
    required this.onOpenRubric,
  });

  @override
  State<CourseHubAssignmentsTab> createState() =>
      _CourseHubAssignmentsTabState();
}

class _CourseHubAssignmentsTabState extends State<CourseHubAssignmentsTab> {
  String _selectedFilter = 'Todas';
  String _searchQuery = '';

  static const List<String> _filters = [
    'Todas',
    'Aguardando Correção',
    'Com Dúvidas',
    'Finalizadas',
  ];

  int _pendingGradingCount(AssignmentItem asg) => asg.submissions
      .where((s) => s.status == SubmissionStatus.aguardandoCorrecao)
      .length;

  int _openDoubtsCount(AssignmentItem asg) => asg.doubts
      .where(
        (d) =>
            d['resolved'] != true &&
            (d['reply'] == null || d['reply'].toString().trim().isEmpty),
      )
      .length;

  Future<void> _confirmDeleteAssignment(
    BuildContext context,
    AssignmentItem asg,
  ) async {
    final confirmed = await CourseHubModal.show<bool>(
      context: context,
      overlineTag: 'EXCLUSÃO DE ATIVIDADE',
      title: 'Remover tarefa avaliativa',
      subtitle: asg.title,
      maxWidth: 460,
      actionsBuilder: (ctx) => [
        CourseHubPillButton(
          label: 'Cancelar',
          variant: CourseHubButtonVariant.secondary,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        CourseHubPillButton(
          label: 'Excluir atividade',
          variant: CourseHubButtonVariant.danger,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
      builder: (_) => Text(
        'Esta ação remove a atividade e eventuais submissões vinculadas tanto para o docente quanto para os alunos matriculados.',
        style: jakarta(size: 13, color: const Color(0xFF52525B)),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await widget.controller.deleteAssignment(asg.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Atividade removida com sucesso.'
              : (widget.controller.remoteError ??
                    'Erro ao remover atividade.'),
        ),
        backgroundColor: deleted
            ? const Color(0xFF18181B)
            : const Color(0xFFB91C1C),
      ),
    );
  }

  Future<void> _openReplyDoubtModal(
    BuildContext context,
    AssignmentItem asg,
    Map<String, dynamic> doubt,
  ) async {
    final replyCtrl = TextEditingController(
      text: doubt['reply']?.toString() ?? '',
    );
    var isSending = false;

    await CourseHubModal.show<void>(
      context: context,
      overlineTag: 'DÚVIDA DE DISCENTE • ${asg.courseCode}',
      title: 'Responder Questionamento',
      subtitle: asg.title,
      maxWidth: 540,
      disposeOnClose: [replyCtrl],
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${doubt['studentName'] ?? 'Estudante'} (${doubt['studentRa'] ?? doubt['ra'] ?? ''})',
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doubt['question']?.toString() ?? '',
                    style: jakarta(size: 13, color: const Color(0xFF3F3F46)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sua Resposta / Orientação Pedagógica',
              style: jakarta(
                size: 12,
                weight: FontWeight.w600,
                color: const Color(0xFF52525B),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: replyCtrl,
              maxLines: 4,
              style: jakarta(size: 13, color: InstColors.ink),
              decoration: courseHubInputDecoration(
                hintText: 'Digite os esclarecimentos para o discente...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CourseHubPillButton(
                  label: 'Cancelar',
                  variant: CourseHubButtonVariant.secondary,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                const SizedBox(width: 8),
                CourseHubPillButton(
                  label: 'Enviar Resposta',
                  icon: Icons.send_rounded,
                  isLoading: isSending,
                  onPressed: isSending
                      ? null
                      : () async {
                          final text = replyCtrl.text.trim();
                          if (text.isEmpty) return;
                          setModalState(() => isSending = true);
                          final ok = await widget.controller.replyDoubtById(
                            assignmentId: asg.id,
                            doubtId: doubt['id']?.toString() ?? '',
                            reply: text,
                          );
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Resposta enviada ao discente.'
                                    : (widget.controller.remoteError ??
                                          'Falha ao responder dúvida.'),
                              ),
                              backgroundColor: ok
                                  ? const Color(0xFF166534)
                                  : const Color(0xFFB91C1C),
                            ),
                          );
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAssignments = widget.controller.assignmentsForSelectedCourse;

    final filtered = allAssignments.where((asg) {
      final matchesFilter = switch (_selectedFilter) {
        'Aguardando Correção' => _pendingGradingCount(asg) > 0,
        'Com Dúvidas' => _openDoubtsCount(asg) > 0,
        'Finalizadas' =>
          asg.submissions.isNotEmpty &&
              _pendingGradingCount(asg) == 0 &&
              asg.submissions.every(
                (s) => s.status == SubmissionStatus.corrigido,
              ),
        _ => true,
      };
      if (!matchesFilter) return false;
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return asg.title.toLowerCase().contains(q) ||
          asg.description.toLowerCase().contains(q);
    }).toList();

    final selected = filtered.any(
      (a) => a.id == widget.controller.selectedAssignmentId,
    )
        ? filtered.firstWhere(
            (a) => a.id == widget.controller.selectedAssignmentId,
          )
        : (filtered.isNotEmpty ? filtered.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CourseHubSectionHeader(
          overline: 'ATIVIDADES AVALIATIVAS • ${widget.course.code}',
          title: 'Tarefas & Submissões',
          subtitle:
              'Publique atividades com prazo real e rubricas, corrija entregas e responda dúvidas dos discentes.',
          trailing: CourseHubPillButton(
            label: 'Nova Atividade',
            icon: Icons.add_rounded,
            onPressed: widget.onNewAssignment,
          ),
        ),
        const SizedBox(height: 18),

        if (allAssignments.isEmpty)
          CourseHubEmptyState(
            icon: Icons.assignment_outlined,
            title: 'Nenhuma atividade cadastrada para ${widget.course.code}',
            subtitle:
                'Crie a primeira atividade avaliativa com critérios de rubrica para aparecer imediatamente no AVA dos discentes.',
            actionLabel: 'Publicar Primeira Atividade',
            onAction: widget.onNewAssignment,
          )
        else ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              CourseHubFilterBar(
                options: _filters,
                selected: _selectedFilter,
                counts: {
                  'Todas': allAssignments.length,
                  'Aguardando Correção': allAssignments
                      .where((a) => _pendingGradingCount(a) > 0)
                      .length,
                  'Com Dúvidas': allAssignments
                      .where((a) => _openDoubtsCount(a) > 0)
                      .length,
                  'Finalizadas': allAssignments
                      .where(
                        (a) =>
                            a.submissions.isNotEmpty &&
                            _pendingGradingCount(a) == 0 &&
                            a.submissions.every(
                              (s) => s.status == SubmissionStatus.corrigido,
                            ),
                      )
                      .length,
                },
                onSelected: (f) => setState(() => _selectedFilter = f),
              ),
              CourseHubSearchField(
                hintText: 'Filtrar atividades...',
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty)
            const CourseHubEmptyState(
              icon: Icons.filter_alt_off_outlined,
              title: 'Nenhuma atividade encontrada para este filtro',
              subtitle:
                  'Limpe o texto pesquisado ou selecione "Todas" acima para visualizar as entregas da turma.',
            )
          else ...[
            // Lista selecionável de cards de atividades
            for (final asg in filtered)
              _buildAssignmentCard(
                context,
                asg,
                isSelected: selected?.id == asg.id,
              ),

            if (selected != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Submissões — ${selected.title}',
                      style: jakarta(
                        size: 15,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                      ),
                    ),
                  ),
                  CourseHubPillButton(
                    label: 'Excluir Atividade',
                    icon: Icons.delete_outline_rounded,
                    variant: CourseHubButtonVariant.danger,
                    compact: true,
                    onPressed: () =>
                        _confirmDeleteAssignment(context, selected),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DocenteSubmissionsTable(
                assignment: selected,
                selectedCourse: widget.course,
                onOpenRubric: widget.onOpenRubric,
                controller: widget.controller,
              ),
              const SizedBox(height: 18),
              _buildDoubtsSection(context, selected),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    AssignmentItem asg, {
    required bool isSelected,
  }) {
    final pendingCount = _pendingGradingCount(asg);
    final openDoubts = _openDoubtsCount(asg);

    return GestureDetector(
      onTap: () => widget.controller.selectAssignment(asg.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF8F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? InstColors.ink : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        asg.title,
                        style: jakarta(
                          size: 14,
                          weight: FontWeight.w700,
                          color: InstColors.ink,
                        ),
                      ),
                      CourseHubBadge(
                        label: '${asg.stage} • Peso ${asg.weight.toStringAsFixed(1)}',
                        tone: CourseHubBadgeTone.neutral,
                      ),
                      if (pendingCount > 0)
                        CourseHubBadge(
                          label: '$pendingCount aguard. correção',
                          tone: CourseHubBadgeTone.warning,
                        ),
                      if (openDoubts > 0)
                        CourseHubBadge(
                          label: '$openDoubts dúvida${openDoubts > 1 ? 's' : ''}',
                          tone: CourseHubBadgeTone.info,
                        ),
                    ],
                  ),
                  if (asg.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      asg.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(size: 12, color: const Color(0xFF52525B)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Prazo: ${asg.dueDateFormatted} • ${asg.modality} • Entregues: ${asg.deliveredCount}/${asg.totalCount} • Rubrica: ${asg.rubricCriteria.length} critérios',
                    style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CourseHubPillButton(
              label: isSelected ? 'Visualizando' : 'Ver Submissões',
              variant: isSelected
                  ? CourseHubButtonVariant.primary
                  : CourseHubButtonVariant.secondary,
              compact: true,
              onPressed: () => widget.controller.selectAssignment(asg.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoubtsSection(BuildContext context, AssignmentItem asg) {
    final doubts = asg.doubts;
    return CourseHubSurfaceCard(
      overlineTag: 'DÚVIDAS DA ATIVIDADE',
      title: 'Esclarecimentos dos Discentes (${doubts.length})',
      subtitle:
          'Dúvidas enviadas diretamente pelos alunos sobre o enunciado ou rubrica desta tarefa.',
      child: doubts.isEmpty
          ? Text(
              'Nenhuma dúvida registrada para esta atividade até o momento.',
              style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
            )
          : Column(
              children: [
                for (int i = 0; i < doubts.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 20, color: Color(0xFFF4F4F5)),
                  _buildDoubtTile(context, asg, doubts[i]),
                ],
              ],
            ),
    );
  }

  Widget _buildDoubtTile(
    BuildContext context,
    AssignmentItem asg,
    Map<String, dynamic> doubt,
  ) {
    final replyText = doubt['reply']?.toString() ?? '';
    final isResolved = doubt['resolved'] == true || replyText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${doubt['studentName'] ?? 'Estudante'} (${doubt['studentRa'] ?? doubt['ra'] ?? ''})',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
            ),
            CourseHubBadge(
              label: isResolved ? 'Respondida' : 'Aguardando Resposta',
              tone: isResolved
                  ? CourseHubBadgeTone.success
                  : CourseHubBadgeTone.warning,
            ),
            const SizedBox(width: 8),
            CourseHubPillButton(
              label: isResolved ? 'Editar Resposta' : 'Responder',
              variant: CourseHubButtonVariant.secondary,
              compact: true,
              onPressed: () => _openReplyDoubtModal(context, asg, doubt),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          doubt['question']?.toString() ?? doubt['body']?.toString() ?? '',
          style: jakarta(size: 12.5, color: const Color(0xFF3F3F46)),
        ),
        if (replyText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              'Sua resposta: $replyText',
              style: jakarta(size: 12, color: InstColors.ink),
            ),
          ),
        ],
      ],
    );
  }
}
