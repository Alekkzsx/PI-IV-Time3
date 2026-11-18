// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'course_hub_ui.dart';

/// Cabeçalho institucional da sala de aula virtual (AVA) da turma selecionada.
class CourseHubHeader extends StatelessWidget {
  final DocenteCourse course;
  final List<DocenteCourse> courses;
  final VoidCallback onBack;
  final ValueChanged<DocenteCourse>? onSwitchCourse;
  final VoidCallback onNewNotice;
  final VoidCallback? onNewContent;
  final VoidCallback? onNewAssignment;
  final VoidCallback onLiveStream;

  const CourseHubHeader({
    super.key,
    required this.course,
    this.courses = const [],
    required this.onBack,
    this.onSwitchCourse,
    required this.onNewNotice,
    this.onNewContent,
    this.onNewAssignment,
    required this.onLiveStream,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPad = screenWidth >= 1000 ? 32.0 : 16.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 860;

          final leftInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back,
                            size: 13,
                            color: Color(0xFF71717A),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Minhas Turmas',
                            style: jakarta(
                              size: 12,
                              weight: FontWeight.w500,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: Color(0xFFA1A1AA),
                  ),
                  Text(
                    course.code,
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                    ),
                  ),
                  if (courses.length > 1 && onSwitchCourse != null)
                    PopupMenuButton<DocenteCourse>(
                      tooltip: 'Alternar turma no AVA',
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      onSelected: onSwitchCourse,
                      itemBuilder: (_) => courses.map((item) {
                        final isCurrent = item.id == course.id;
                        return PopupMenuItem<DocenteCourse>(
                          value: item,
                          child: Row(
                            children: [
                              Icon(
                                isCurrent
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                size: 15,
                                color: isCurrent
                                    ? InstColors.ink
                                    : const Color(0xFFA1A1AA),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.code} — ${item.title}',
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(
                                    size: 12,
                                    weight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: InstColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF8F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Trocar turma',
                              style: jakarta(
                                size: 11,
                                weight: FontWeight.w600,
                                color: const Color(0xFF52525B),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.unfold_more_rounded,
                              size: 13,
                              color: Color(0xFF52525B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (course.isLive)
                    const CourseHubBadge(
                      label: 'Ao Vivo',
                      tone: CourseHubBadgeTone.success,
                      icon: Icons.sensors_rounded,
                    ),
                  if (course.pautaHomologated)
                    const CourseHubBadge(
                      label: 'Pauta Homologada',
                      tone: CourseHubBadgeTone.info,
                      icon: Icons.verified_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                course.title,
                style: jakarta(
                  size: 20,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Turma ${course.code} • ${course.enrolledCount} discentes • ${course.shift} • ${course.term} • ${course.room}',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
            ],
          );

          final actionsBar = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment:
                isCompact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              CourseHubPillButton(
                label: 'Aviso à Turma',
                icon: Icons.campaign_outlined,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: onNewNotice,
              ),
              CourseHubPillButton(
                label: 'Novo Conteúdo',
                icon: Icons.add_rounded,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: onNewContent,
              ),
              if (onNewAssignment != null)
                CourseHubPillButton(
                  label: 'Nova Atividade',
                  icon: Icons.add_task_rounded,
                  variant: CourseHubButtonVariant.secondary,
                  compact: true,
                  onPressed: onNewAssignment,
                ),
              CourseHubPillButton(
                label: 'Transmissão ao Vivo',
                icon: Icons.videocam_rounded,
                compact: true,
                onPressed: onLiveStream,
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftInfo,
                const SizedBox(height: 14),
                actionsBar,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: leftInfo),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: actionsBar,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
