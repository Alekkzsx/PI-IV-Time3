// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/widgets/docente_chancela_dialog.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/widgets/docente_gradebook_table.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/widgets/docente_retificacao_dialog.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'course_hub_ui.dart';

/// Aba de Livro de Notas integrado ao AVA Docente com edição inline e chancela digital.
class CourseHubGradebookTab extends StatefulWidget {
  final DocenteCourse course;
  final DocenteController controller;
  final List<StudentGrade> gradebook;

  const CourseHubGradebookTab({
    super.key,
    required this.course,
    required this.controller,
    required this.gradebook,
  });

  @override
  State<CourseHubGradebookTab> createState() => _CourseHubGradebookTabState();
}

class _CourseHubGradebookTabState extends State<CourseHubGradebookTab> {
  String _selectedFilter = 'Todos';
  String _searchQuery = '';

  static const List<String> _filters = [
    'Todos',
    'Aprovado',
    'Em Exame',
    'Em Curso',
    'Crítico',
  ];

  Future<void> _exportCsv(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln('RA,Estudante,Ativ N1,P1,N1,Proj N2,P2,N2,Media Final,Frequencia,Situacao');
    for (final s in widget.gradebook) {
      buffer.writeln(
        '${s.ra},"${s.studentName}",${s.assignmentsScore.toStringAsFixed(1)},${s.p1Score.toStringAsFixed(1)},${s.n1Total.toStringAsFixed(1)},${s.projectsScore.toStringAsFixed(1)},${s.p2Score.toStringAsFixed(1)},${s.n2Total.toStringAsFixed(1)},${s.finalAverage.toStringAsFixed(1)},${s.attendanceRate.toStringAsFixed(1)}%,${s.statusLabel}',
      );
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final safeCode = widget.course.code.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    await PlatformFileHelper.saveAndLaunchFile(
      bytes: bytes,
      fileName: 'pauta_${safeCode}_2026.csv',
      mimeType: 'text/csv; charset=utf-8',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pauta exportada (pauta_${safeCode}_2026.csv).'),
          backgroundColor: const Color(0xFF18181B),
        ),
      );
    }
  }

  void _openChancelaDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    DocenteChancelaDialog.show(
      context: context,
      course: widget.course,
      onConfirm: () {
        widget.controller.homologarPautaComChancela(widget.course.id);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Pauta oficial homologada com chancela digital.'),
            backgroundColor: Color(0xFF166534),
          ),
        );
      },
    );
  }

  void _openRetificacaoDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    DocenteRetificacaoDialog.show(
      context: context,
      course: widget.course,
      gradebook: widget.gradebook,
      onConfirm: ({
        required String studentRa,
        required String studentName,
        required String avaliacao,
        required double notaAnterior,
        required double novaNota,
        required String justificativa,
      }) {
        widget.controller.solicitarRetificacaoNota(
          courseId: widget.course.id,
          studentRa: studentRa,
          studentName: studentName,
          avaliacao: avaliacao,
          notaAnterior: notaAnterior,
          novaNota: novaNota,
          justificativa: justificativa,
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Solicitação de retificação registrada para $studentName.',
            ),
            backgroundColor: const Color(0xFF18181B),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grades = widget.gradebook;
    final gradedStudents = grades
        .where((g) => g.status != AcademicStatus.semNotas)
        .toList();
    final hasAnyGrades = gradedStudents.isNotEmpty;
    final avgGrade = hasAnyGrades
        ? gradedStudents.map((g) => g.finalAverage).reduce((a, b) => a + b) /
              gradedStudents.length
        : 0.0;
    final approvedCount = grades
        .where((g) => g.status == AcademicStatus.aprovado)
        .length;

    final filtered = grades.where((g) {
      final matchesFilter = switch (_selectedFilter) {
        'Aprovado' => g.status == AcademicStatus.aprovado,
        'Em Exame' => g.status == AcademicStatus.exame,
        'Em Curso' => g.status == AcademicStatus.semNotas,
        'Crítico' =>
          g.status == AcademicStatus.reprovadoPorNota ||
              g.status == AcademicStatus.reprovadoPorFalta,
        _ => true,
      };
      if (!matchesFilter) return false;
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return g.studentName.toLowerCase().contains(q) ||
          g.ra.toLowerCase().contains(q);
    }).toList();

    final isHomologada = widget.controller.isPautaHomologada(widget.course.id);
    final chancelaCode = widget.controller.getChancelaCode(widget.course.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CourseHubSectionHeader(
          overline: 'PAUTA OFICIAL PPC • ${widget.course.code}',
          title: 'Livro de Notas (Gradebook)',
          subtitle:
              'Edite avaliações inline nas colunas N1 e N2 ou sincronize automaticamente ao corrigir tarefas por rubrica.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CourseHubBadge(
                label: isHomologada
                    ? 'Chancela: ${chancelaCode ?? "Ativa"}'
                    : 'Pauta Aberta',
                tone: isHomologada
                    ? CourseHubBadgeTone.success
                    : CourseHubBadgeTone.info,
                icon: isHomologada
                    ? Icons.lock_rounded
                    : Icons.edit_note_rounded,
              ),
              CourseHubPillButton(
                label: 'Exportar CSV',
                icon: Icons.download_outlined,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: () => _exportCsv(context),
              ),
              if (isHomologada)
                CourseHubPillButton(
                  label: 'Solicitar Retificação',
                  icon: Icons.history_edu_outlined,
                  variant: CourseHubButtonVariant.secondary,
                  compact: true,
                  onPressed: () => _openRetificacaoDialog(context),
                ),
              CourseHubPillButton(
                label: isHomologada ? 'Pauta Homologada' : 'Homologar pauta',
                icon: isHomologada
                    ? Icons.verified_rounded
                    : Icons.verified_user_outlined,
                compact: true,
                onPressed: isHomologada
                    ? null
                    : () => _openChancelaDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // KPIs com altura uniforme via IntrinsicHeight
        CourseHubKpiRow(
          items: [
            CourseHubKpiSpec(
              label: 'Estudantes',
              value: '${grades.length}',
              subtitle: 'Matriculados ativos',
            ),
            CourseHubKpiSpec(
              label: 'Média geral',
              value: hasAnyGrades ? avgGrade.toStringAsFixed(1) : '—',
              subtitle: hasAnyGrades
                  ? 'Média aritmética PPC (${gradedStudents.length} aval.)'
                  : 'Aguardando lançamentos',
            ),
            CourseHubKpiSpec(
              label: 'Aprovados',
              value: '$approvedCount / ${grades.length}',
              subtitle: 'Aproveitamento geral',
              valueColor: approvedCount > 0
                  ? const Color(0xFF166534)
                  : InstColors.ink,
            ),
            CourseHubKpiSpec(
              label: 'Regra de Cálculo',
              value: 'N1·0.4 + N2·0.6',
              subtitle: 'Aprovação: média ≥ 6.0',
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Filtros e Busca
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
                'Todos': grades.length,
                'Aprovado': grades
                    .where((g) => g.status == AcademicStatus.aprovado)
                    .length,
                'Em Exame': grades
                    .where((g) => g.status == AcademicStatus.exame)
                    .length,
                'Em Curso': grades
                    .where((g) => g.status == AcademicStatus.semNotas)
                    .length,
                'Crítico': grades
                    .where(
                      (g) =>
                          g.status == AcademicStatus.reprovadoPorNota ||
                          g.status == AcademicStatus.reprovadoPorFalta,
                    )
                    .length,
              },
              onSelected: (f) => setState(() => _selectedFilter = f),
            ),
            CourseHubSearchField(
              hintText: 'Buscar aluno ou RA...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          const CourseHubEmptyState(
            icon: Icons.grading_outlined,
            title: 'Nenhum discente encontrado para este filtro',
            subtitle:
                'Ajuste o filtro de situação ou a busca para visualizar outros alunos da pauta.',
          )
        else
          DocenteGradebookTable(
            controller: widget.controller,
            gradebook: filtered,
          ),
      ],
    );
  }
}
