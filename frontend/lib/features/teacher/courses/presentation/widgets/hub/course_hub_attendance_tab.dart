// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/diary/presentation/widgets/class_session_picker_modal.dart';
import 'package:pi_iv_time3/features/teacher/diary/presentation/widgets/docente_diary_attendance_table.dart';
import 'package:pi_iv_time3/features/teacher/diary/presentation/widgets/docente_diary_lesson_plan_card.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'course_hub_ui.dart';

/// Aba de Diário de Classe e Chamada integrada diretamente no AVA Docente.
class CourseHubAttendanceTab extends StatelessWidget {
  final DocenteCourse course;
  final DocenteController controller;

  const CourseHubAttendanceTab({
    super.key,
    required this.course,
    required this.controller,
  });

  Future<void> _openSessionPicker(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ClassSessionPickerModal(controller: controller),
    );
  }

  Future<void> _openExtraDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.currentSession.sessionDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      helpText: 'Agendar / Selecionar Data de Aula (Reposição ou Regular)',
    );
    if (picked == null) return;
    await controller.selectSessionByDate(picked, allowExtraDate: true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sessão carregada para ${controller.formatSessionDate(picked)}.',
        ),
        backgroundColor: const Color(0xFF18181B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = controller.currentSession;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CourseHubSectionHeader(
          overline: 'REGISTRO MEC • ${course.code}',
          title: 'Diário de Presença e Chamada',
          subtitle:
              'Navegue entre as aulas, registre conteúdo ministrado, marque P/F/J e homologue no sistema acadêmico.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CourseHubPillButton(
                label: 'Agendar / Nova Aula',
                icon: Icons.event_available_outlined,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: () => _openExtraDatePicker(context),
              ),
              CourseHubPillButton(
                label: 'Trocar Aula',
                icon: Icons.swap_horiz_rounded,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: () => _openSessionPicker(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        DocenteDiaryLessonPlanCard(
          controller: controller,
          session: session,
        ),
        const SizedBox(height: 20),

        DocenteDiaryAttendanceTable(
          controller: controller,
          session: session,
        ),
      ],
    );
  }
}
