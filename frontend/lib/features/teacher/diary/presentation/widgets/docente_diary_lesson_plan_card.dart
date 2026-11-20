// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/attendance_record.dart';
import 'package:pi_iv_time3/features/teacher/shared/utils/academic_session_date_picker.dart';
import 'class_session_picker_modal.dart';
import 'components/lesson_plan_content_editor.dart';
import 'components/lesson_plan_mec_header.dart';

/// Card de plano de aula, data e preenchimento de conteúdo programático (exigência MEC).
class DocenteDiaryLessonPlanCard extends StatefulWidget {
  final DocenteController controller;
  final ClassSession session;

  const DocenteDiaryLessonPlanCard({
    super.key,
    required this.controller,
    required this.session,
  });

  @override
  State<DocenteDiaryLessonPlanCard> createState() =>
      _DocenteDiaryLessonPlanCardState();
}

class _DocenteDiaryLessonPlanCardState
    extends State<DocenteDiaryLessonPlanCard> {
  late TextEditingController _contentController;
  late TextEditingController _methodologyController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.session.contentProgram,
    );
    _methodologyController = TextEditingController(
      text: widget.session.methodology,
    );
    _locationController = TextEditingController(text: widget.session.location);
  }

  @override
  void didUpdateWidget(covariant DocenteDiaryLessonPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _contentController.text = widget.session.contentProgram;
      _methodologyController.text = widget.session.methodology;
      _locationController.text = widget.session.location;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _methodologyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _openCalendarPicker(BuildContext context) async {
    final course = widget.controller.selectedCourse;
    final currentSession = widget.controller.currentSession;

    final picked = await showAcademicSessionDatePicker(
      context: context,
      initialDate: currentSession.sessionDate,
      course: course,
    );

    if (picked == null || !mounted) return;
    widget.controller.selectSessionByDate(picked);
    ScaffoldMessenger.of(this.context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Aula carregada: ${widget.controller.formatSessionDate(picked)}',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openSessionPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ClassSessionPickerModal(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Calendário + Aula + Data + Navegação + Badge
          LessonPlanMecHeader(
            session: session,
            canGoPrevious: widget.controller.canGoToPreviousSession,
            canGoNext: widget.controller.canGoToNextSession,
            onPrevious: widget.controller.goToPreviousSession,
            onNext: widget.controller.goToNextSession,
            onOpenSessionPicker: () => _openSessionPicker(context),
            onOpenCalendarPicker: () => _openCalendarPicker(context),
          ),
          const SizedBox(height: 20),

          // Campos de Edição de Conteúdo, Metodologia e Local
          LessonPlanContentEditor(
            contentController: _contentController,
            methodologyController: _methodologyController,
            locationController: _locationController,
            onContentChanged: (val) {
              widget.controller.updateSessionContent(
                val,
                _methodologyController.text,
                _locationController.text,
              );
            },
            onMethodologyChanged: (val) {
              widget.controller.updateSessionContent(
                _contentController.text,
                val,
                _locationController.text,
              );
            },
            onLocationChanged: (val) {
              widget.controller.updateSessionContent(
                _contentController.text,
                _methodologyController.text,
                val,
              );
            },
          ),
        ],
      ),
    );
  }
}
