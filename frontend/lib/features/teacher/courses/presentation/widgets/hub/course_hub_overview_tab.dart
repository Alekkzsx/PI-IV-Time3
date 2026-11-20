// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'course_hub_ui.dart';

/// Aba inicial do AVA Docente: Visão Geral, Mural da Turma e Fila de Prioridades.
class CourseHubOverviewTab extends StatelessWidget {
  final DocenteCourse course;
  final DocenteController controller;
  final VoidCallback onNewNotice;
  final VoidCallback onNewAssignment;
  final VoidCallback onNewContent;
  final VoidCallback onOpenLive;
  final void Function(int tabIndex) onSelectTab;
  final void Function(AssignmentItem assignment, StudentSubmission submission)
      onEvaluateSubmission;

  const CourseHubOverviewTab({
    super.key,
    required this.course,
    required this.controller,
    required this.onNewNotice,
    required this.onNewAssignment,
    required this.onNewContent,
    required this.onOpenLive,
    required this.onSelectTab,
    required this.onEvaluateSubmission,
  });

  @override
  Widget build(BuildContext context) {
    final grades = controller.gradebook;
    final gradedStudents = grades
        .where((g) => g.status != AcademicStatus.semNotas)
        .toList();
    final hasAnyGrades = gradedStudents.isNotEmpty;
    final avgGrade = hasAnyGrades
        ? gradedStudents.map((g) => g.finalAverage).reduce((a, b) => a + b) /
              gradedStudents.length
        : 0.0;

    final avgAttendance = grades.isNotEmpty
        ? grades.map((g) => g.attendanceRate).reduce((a, b) => a + b) /
              grades.length
        : 100.0;

    final courseAssignments = controller.assignmentsForSelectedCourse;
    final pendingSubmissions =
        <({AssignmentItem assignment, StudentSubmission submission})>[];
    final openDoubts =
        <({AssignmentItem assignment, Map<String, dynamic> doubt})>[];

    for (final asg in courseAssignments) {
      for (final sub in asg.submissions) {
        if (sub.status == SubmissionStatus.aguardandoCorrecao) {
          pendingSubmissions.add((assignment: asg, submission: sub));
        }
      }
      for (final d in asg.doubts) {
        if (d['resolved'] != true &&
            (d['reply'] == null || d['reply'].toString().trim().isEmpty)) {
          openDoubts.add((assignment: asg, doubt: d));
        }
      }
    }

    final unansweredForumTopics = course.forumTopics.where((topic) {
      final replies = topic['replies'];
      final hasReplies = replies is List && replies.isNotEmpty;
      return topic['isResolved'] != true && !hasReplies;
    }).toList();

    final totalPendingCount =
        pendingSubmissions.length +
        openDoubts.length +
        unansweredForumTopics.length;

    final courseNotices = controller.notices.where((notice) {
      final target = notice.targetCourse.trim().toLowerCase();
      return target == course.code.trim().toLowerCase() ||
          target == course.title.trim().toLowerCase() ||
          target == 'todas' ||
          target.contains(course.code.trim().toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CourseHubSectionHeader(
          overline: 'SALA DE AULA VIRTUAL • ${course.code}',
          title: 'Visão Geral & Mural da Turma',
          subtitle:
              'Acompanhe o andamento da disciplina, interaja com os alunos e resolva pendências acadêmicas.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CourseHubPillButton(
                label: 'Diário de Classe',
                icon: Icons.fact_check_outlined,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: () => onSelectTab(4),
              ),
              CourseHubPillButton(
                label: 'Ver Atividades',
                icon: Icons.assignment_outlined,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: () => onSelectTab(2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        CourseHubKpiRow(
          items: [
            CourseHubKpiSpec(
              label: 'Estudantes',
              value: '${course.enrolledCount}',
              subtitle: 'Matriculados ativos na turma',
            ),
            CourseHubKpiSpec(
              label: 'Média geral',
              value: hasAnyGrades ? avgGrade.toStringAsFixed(1) : '—',
              subtitle: hasAnyGrades
                  ? '${gradedStudents.length} discentes avaliados'
                  : 'Nenhuma nota lançada ainda',
            ),
            CourseHubKpiSpec(
              label: 'Assiduidade',
              value: '${avgAttendance.toStringAsFixed(1)}%',
              subtitle: 'Presença consolidada',
              valueColor: avgAttendance >= 75.0
                  ? const Color(0xFF166534)
                  : const Color(0xFFB91C1C),
            ),
            CourseHubKpiSpec(
              label: 'Pendências',
              value: '$totalPendingCount',
              subtitle:
                  '${pendingSubmissions.length} entregas • ${openDoubts.length + unansweredForumTopics.length} dúvidas',
              valueColor: totalPendingCount > 0
                  ? const Color(0xFFB45309)
                  : const Color(0xFF166534),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildClassSessionBanner(),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;
            final noticesCard = _buildNoticesCard(context, courseNotices);
            final queueCard = _buildPriorityQueueCard(
              context,
              pendingSubmissions,
              openDoubts,
              unansweredForumTopics,
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  queueCard,
                  const SizedBox(height: 18),
                  noticesCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: queueCard),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: noticesCard),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildClassSessionBanner() {
    final session = controller.currentSession;
    final hasSession = session.courseId == course.id && session.id.isNotEmpty;
    final progressPct = (course.progress * 100).clamp(0.0, 100.0).round();

    return CourseHubSurfaceCard(
      overlineTag: course.isLive
          ? 'SESSÃO SÍNCRONA EM ANDAMENTO'
          : 'ANDAMENTO DO PLANO LETIVO',
      title: hasSession
          ? 'Aula ${session.sessionNumber.toString().padLeft(2, '0')} • ${session.dateFormatted}'
          : course.schedule,
      subtitle:
          '${course.room} • ${course.workloadCompletedLabel}${course.workloadTotalLabel} ministradas ($progressPct%)',
      headerTrailing: CourseHubBadge(
        label: course.isLive ? 'AO VIVO NA SALA VIRTUAL' : 'SALA RESERVADA',
        tone: course.isLive
            ? CourseHubBadgeTone.success
            : CourseHubBadgeTone.neutral,
        icon: course.isLive ? Icons.sensors_rounded : Icons.meeting_room_outlined,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: course.progress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: const Color(0xFFF4F4F5),
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CourseHubPillButton(
                label: course.isLive ? 'Entrar na Transmissão' : 'Iniciar Transmissão',
                icon: Icons.videocam_rounded,
                compact: true,
                onPressed: onOpenLive,
              ),
              CourseHubPillButton(
                label: 'Registrar Chamada',
                icon: Icons.how_to_reg_outlined,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: () => onSelectTab(4),
              ),
              CourseHubPillButton(
                label: 'Publicar Material',
                icon: Icons.upload_file_outlined,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: onNewContent,
              ),
              CourseHubPillButton(
                label: 'Nova Atividade',
                icon: Icons.add_task_rounded,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: onNewAssignment,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityQueueCard(
    BuildContext context,
    List<({AssignmentItem assignment, StudentSubmission submission})>
        pendingSubmissions,
    List<({AssignmentItem assignment, Map<String, dynamic> doubt})> openDoubts,
    List<Map<String, dynamic>> unansweredForumTopics,
  ) {
    return CourseHubSurfaceCard(
      overlineTag: 'FILA DE CORREÇÃO E INTERAÇÃO',
      title: 'Submissões e Dúvidas Pendentes',
      subtitle:
          'Entregas discentes aguardando nota por rubrica e questionamentos em aberto.',
      headerTrailing: CourseHubPillButton(
        label: 'Abrir Tarefas',
        variant: CourseHubButtonVariant.secondary,
        compact: true,
        onPressed: () => onSelectTab(2),
      ),
      child: pendingSubmissions.isEmpty &&
              openDoubts.isEmpty &&
              unansweredForumTopics.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 30,
                      color: Color(0xFF16A34A),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nenhuma entrega ou dúvida pendente nesta turma.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF18181B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pendingSubmissions.isNotEmpty) ...[
                  Text(
                    'AGUARDANDO AVALIAÇÃO (${pendingSubmissions.length})',
                    style: jakarta(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: const Color(0xFF71717A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final entry in pendingSubmissions.take(4))
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF8F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.submission.studentName,
                                  style: jakarta(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${entry.assignment.title} • ${entry.submission.fileName ?? "Arquivo enviado"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(
                                    size: 11.5,
                                    color: const Color(0xFF52525B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          CourseHubPillButton(
                            label: 'Avaliar',
                            icon: Icons.grading_rounded,
                            compact: true,
                            onPressed: () => onEvaluateSubmission(
                              entry.assignment,
                              entry.submission,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (openDoubts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'DÚVIDAS EM TAREFAS (${openDoubts.length})',
                    style: jakarta(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: const Color(0xFF71717A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in openDoubts.take(3))
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.doubt['studentName']?.toString() ??
                                      'Discente',
                                  style: jakarta(
                                    size: 12.5,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF18181B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.doubt['question']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(
                                    size: 12,
                                    color: const Color(0xFF52525B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          CourseHubPillButton(
                            label: 'Responder',
                            variant: CourseHubButtonVariant.secondary,
                            compact: true,
                            onPressed: () => onSelectTab(2),
                          ),
                        ],
                      ),
                    ),
                ],
                if (unansweredForumTopics.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'FÓRUM SEM RESPOSTA (${unansweredForumTopics.length})',
                    style: jakarta(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: const Color(0xFF71717A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final topic in unansweredForumTopics.take(2))
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              topic['title']?.toString() ?? 'Tópico',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: jakarta(
                                size: 12.5,
                                weight: FontWeight.w600,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CourseHubPillButton(
                            label: 'Abrir Fórum',
                            variant: CourseHubButtonVariant.secondary,
                            compact: true,
                            onPressed: () => onSelectTab(3),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildNoticesCard(
    BuildContext context,
    List<AcademicNotice> courseNotices,
  ) {
    return CourseHubSurfaceCard(
      overlineTag: 'COMUNICAÇÃO COM A TURMA',
      title: 'Mural de Avisos Publicados',
      subtitle:
          'Comunicados direcionados a ${course.code} e confirmação de leitura discente.',
      headerTrailing: CourseHubPillButton(
        label: 'Novo Aviso',
        icon: Icons.campaign_outlined,
        compact: true,
        onPressed: onNewNotice,
      ),
      child: courseNotices.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Nenhum comunicado enviado ainda para ${course.code}.',
                  textAlign: TextAlign.center,
                  style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
                ),
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < courseNotices.take(4).length; i++) ...[
                  if (i > 0)
                    const Divider(height: 18, color: Color(0xFFF4F4F5)),
                  _buildNoticeRow(context, courseNotices[i]),
                ],
              ],
            ),
    );
  }

  Widget _buildNoticeRow(BuildContext context, AcademicNotice notice) {
    final tone = switch (notice.classification) {
      NoticeClassification.urgencia => CourseHubBadgeTone.danger,
      NoticeClassification.convocacao => CourseHubBadgeTone.warning,
      NoticeClassification.informativo => CourseHubBadgeTone.neutral,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CourseHubBadge(label: notice.classificationLabel, tone: tone),
            const Spacer(),
            Text(
              notice.publishedAt,
              style: jakarta(size: 11, color: const Color(0xFF71717A)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          notice.title,
          style: jakarta(
            size: 13,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          notice.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: jakarta(size: 12, color: const Color(0xFF52525B)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 13,
              color: const Color(0xFF71717A),
            ),
            const SizedBox(width: 4),
            Text(
              'Lido por ${notice.readCount}/${notice.totalRecipients}',
              style: jakarta(size: 11, color: const Color(0xFF71717A)),
            ),
            const Spacer(),
            if (!notice.isFromSecretaria)
              TextButton(
                onPressed: () => _showNoticeReadsModal(context, notice),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: const Size(0, 26),
                ),
                child: Text(
                  'Ver leituras',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _showNoticeReadsModal(
    BuildContext context,
    AcademicNotice notice,
  ) async {
    final data = await controller.getNoticeReads(notice.id);
    if (!context.mounted) return;
    final reads = (data?['reads'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];

    CourseHubModal.show<void>(
      context: context,
      overlineTag: 'CONFIRMAÇÃO DE LEITURA • ${course.code}',
      title: notice.title,
      subtitle:
          '${reads.length} de ${data?['totalRecipients'] ?? notice.totalRecipients} discentes confirmaram leitura',
      actionsBuilder: (ctx) => [
        CourseHubPillButton(
          label: 'Fechar',
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
      builder: (_) {
        if (reads.isEmpty) {
          return Text(
            'Nenhum estudante visualizou este comunicado até o momento.',
            style: jakarta(size: 13, color: const Color(0xFF71717A)),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reads.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${r['displayName'] ?? ''} (${r['identity'] ?? ''})',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w500,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
