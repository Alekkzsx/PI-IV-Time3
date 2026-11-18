// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/attendance_record.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'course_hub_ui.dart';

/// Aba de discentes matriculados na turma com busca, perfil acadêmico e comunicados diretos.
class CourseHubStudentsTab extends StatefulWidget {
  final DocenteCourse course;
  final DocenteController controller;
  final List<StudentGrade> gradebook;
  final ClassSession session;

  const CourseHubStudentsTab({
    super.key,
    required this.course,
    required this.controller,
    required this.gradebook,
    required this.session,
  });

  @override
  State<CourseHubStudentsTab> createState() => _CourseHubStudentsTabState();
}

class _CourseHubStudentsTabState extends State<CourseHubStudentsTab> {
  String _searchQuery = '';
  String _statusFilter = 'Todos';

  static const List<String> _filters = [
    'Todos',
    'Regular',
    'Risco de Falta (<75%)',
  ];

  void _showStudentModal(
    BuildContext context, {
    required String studentId,
    required String ra,
    required String name,
    StudentGrade? grade,
    required double attendanceRate,
  }) {
    final hasEnteredGrades =
        grade != null && grade.status != AcademicStatus.semNotas;
    final avgText = hasEnteredGrades ? grade.finalAverage.toStringAsFixed(1) : '—';
    final statusText = grade?.statusLabel ?? 'Em Curso';

    CourseHubModal.show<void>(
      context: context,
      overlineTag: 'FICHA ACADÊMICA • ${widget.course.code}',
      title: name,
      subtitle: 'Registro Acadêmico (RA): $ra',
      maxWidth: 520,
      actionsBuilder: (ctx) => [
        CourseHubPillButton(
          label: 'Enviar Mensagem',
          icon: Icons.mail_outline_rounded,
          variant: CourseHubButtonVariant.secondary,
          onPressed: () {
            Navigator.of(ctx).pop();
            _openDirectNoticeModal(context, studentId, name, ra);
          },
        ),
        CourseHubPillButton(
          label: 'Fechar',
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CourseHubKpiRow(
            items: [
              CourseHubKpiSpec(
                label: 'Média Parcial',
                value: avgText,
                subtitle: 'Status: $statusText',
              ),
              CourseHubKpiSpec(
                label: 'Assiduidade',
                value: '${attendanceRate.toStringAsFixed(1)}%',
                subtitle: attendanceRate < 75.0
                    ? 'Abaixo do mínimo de 75%'
                    : 'Frequência regular',
                valueColor: attendanceRate < 75.0
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF166534),
              ),
            ],
          ),
          if (grade != null) ...[
            const SizedBox(height: 16),
            CourseHubSurfaceCard(
              overlineTag: 'DETALHAMENTO DE NOTAS',
              bodyPadding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _scoreChip('Ativ. N1', grade.assignmentsScore, hasEnteredGrades),
                  _scoreChip('P1', grade.p1Score, hasEnteredGrades),
                  _scoreChip('Proj. N2', grade.projectsScore, hasEnteredGrades),
                  _scoreChip('P2', grade.p2Score, hasEnteredGrades),
                ],
              ),
            ),
          ],
          if (attendanceRate < 75.0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Color(0xFFB91C1C),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Frequência abaixo do limite regimental de 75%.',
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w600,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CourseHubPillButton(
                    label: 'Notificar Falta',
                    variant: CourseHubButtonVariant.danger,
                    compact: true,
                    onPressed: () {
                      widget.controller.notificarAlunoInfrequencia(
                        studentId,
                        name,
                      );
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Alerta preventivo enviado para $name.',
                          ),
                          backgroundColor: const Color(0xFF18181B),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreChip(String label, double score, bool hasEnteredGrades) {
    return Column(
      children: [
        Text(label, style: jakarta(size: 11, color: const Color(0xFF71717A))),
        const SizedBox(height: 4),
        Text(
          hasEnteredGrades ? score.toStringAsFixed(1) : '—',
          style: jakarta(
            size: 14.5,
            weight: FontWeight.w700,
            color: InstColors.ink,
          ),
        ),
      ],
    );
  }

  Future<void> _openDirectNoticeModal(
    BuildContext context,
    String studentId,
    String studentName,
    String studentRa,
  ) async {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    await CourseHubModal.show<void>(
      context: context,
      overlineTag: 'ATENDIMENTO INDIVIDUAL • ${widget.course.code}',
      title: 'Enviar Comunicado para $studentName',
      subtitle: 'RA $studentRa • Será entregue no Mural/Mensagens do aluno',
      maxWidth: 520,
      disposeOnClose: [titleCtrl, msgCtrl],
      actionsBuilder: (ctx) => [
        CourseHubPillButton(
          label: 'Cancelar',
          variant: CourseHubButtonVariant.secondary,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        CourseHubPillButton(
          label: 'Enviar Mensagem',
          icon: Icons.send_rounded,
          onPressed: () async {
            if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) {
              return;
            }
            final ok = await widget.controller.publishNotice(
              targetCourse: widget.course.code,
              targetAudience: 'Discente: $studentName ($studentRa)',
              classification: NoticeClassification.informativo,
              title: titleCtrl.text.trim(),
              message: msgCtrl.text.trim(),
            );
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? 'Comunicado enviado para $studentName.'
                      : 'Falha ao enviar comunicado.',
                ),
                backgroundColor: ok
                    ? const Color(0xFF166534)
                    : const Color(0xFFB91C1C),
              ),
            );
          },
        ),
      ],
      builder: (_) => Column(
        children: [
          TextField(
            controller: titleCtrl,
            style: jakarta(size: 13, color: InstColors.ink),
            decoration: courseHubInputDecoration(labelText: 'Assunto'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: msgCtrl,
            maxLines: 4,
            style: jakarta(size: 13, color: InstColors.ink),
            decoration: courseHubInputDecoration(labelText: 'Mensagem'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rosterByRa = <String, ({String id, String ra, String name, double attendance})>{};

    for (final st in widget.course.enrolledStudents) {
      final ra = (st['ra'] ?? '').toString();
      final id = (st['studentId'] ?? '').toString();
      final name = (st['name'] ?? '').toString();
      if (ra.isNotEmpty || id.isNotEmpty) {
        rosterByRa[ra.isNotEmpty ? ra : id] = (
          id: id,
          ra: ra,
          name: name,
          attendance: 100.0,
        );
      }
    }

    for (final att in widget.session.attendanceList) {
      rosterByRa[att.ra] = (
        id: att.studentId,
        ra: att.ra,
        name: att.name,
        attendance: att.attendanceRate,
      );
    }

    final gradeByStudentId = {
      for (final g in widget.gradebook) g.studentId: g,
    };

    final roster = rosterByRa.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final filtered = roster.where((entry) {
      final grade = gradeByStudentId[entry.id];
      final attendance = grade?.attendanceRate ?? entry.attendance;
      final matchesFilter = switch (_statusFilter) {
        'Regular' => attendance >= 75.0,
        'Risco de Falta (<75%)' => attendance < 75.0,
        _ => true,
      };
      if (!matchesFilter) return false;
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return entry.name.toLowerCase().contains(q) ||
          entry.ra.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CourseHubSectionHeader(
          overline: 'CORPO DISCENTE • ${widget.course.code}',
          title: 'Alunos Matriculados (${roster.length})',
          subtitle:
              'Consulte situação acadêmica individual, acompanhe riscos de falta e envie comunicações diretas.',
        ),
        const SizedBox(height: 18),

        if (roster.isEmpty)
          const CourseHubEmptyState(
            icon: Icons.people_outline,
            title: 'Nenhum discente matriculado nesta turma',
            subtitle:
                'Os estudantes vinculados pela Secretaria ou Administrador aparecerão aqui automaticamente.',
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
                selected: _statusFilter,
                counts: {
                  'Todos': roster.length,
                  'Regular': roster
                      .where(
                        (e) =>
                            (gradeByStudentId[e.id]?.attendanceRate ??
                                e.attendance) >=
                            75.0,
                      )
                      .length,
                  'Risco de Falta (<75%)': roster
                      .where(
                        (e) =>
                            (gradeByStudentId[e.id]?.attendanceRate ??
                                e.attendance) <
                            75.0,
                      )
                      .length,
                },
                onSelected: (f) => setState(() => _statusFilter = f),
              ),
              CourseHubSearchField(
                hintText: 'Buscar por nome ou RA...',
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty)
            const CourseHubEmptyState(
              icon: Icons.person_search_outlined,
              title: 'Nenhum estudante encontrado',
              subtitle: 'Refine a busca ou altere o filtro acima.',
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF4F4F5)),
                itemBuilder: (context, idx) {
                  final st = filtered[idx];
                  final grade = gradeByStudentId[st.id];
                  final attendance = grade?.attendanceRate ?? st.attendance;
                  final hasGrades =
                      grade != null && grade.status != AcademicStatus.semNotas;
                  final isRisk = attendance < 75.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAF8F5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              st.name.isNotEmpty
                                  ? st.name[0].toUpperCase()
                                  : 'A',
                              style: jakarta(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: InstColors.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                st.name,
                                style: jakarta(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                  color: InstColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'RA: ${st.ra} • Freq.: ${attendance.toStringAsFixed(1)}% • Média: ${hasGrades ? grade.finalAverage.toStringAsFixed(1) : '—'}',
                                style: jakarta(
                                  size: 11.5,
                                  color: const Color(0xFF71717A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        CourseHubBadge(
                          label: isRisk ? 'Risco de Falta' : 'Regular',
                          tone: isRisk
                              ? CourseHubBadgeTone.danger
                              : CourseHubBadgeTone.success,
                        ),
                        const SizedBox(width: 10),
                        CourseHubPillButton(
                          label: 'Ficha Acadêmica',
                          variant: CourseHubButtonVariant.secondary,
                          compact: true,
                          onPressed: () => _showStudentModal(
                            context,
                            studentId: st.id,
                            ra: st.ra,
                            name: st.name,
                            grade: grade,
                            attendanceRate: attendance,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}
