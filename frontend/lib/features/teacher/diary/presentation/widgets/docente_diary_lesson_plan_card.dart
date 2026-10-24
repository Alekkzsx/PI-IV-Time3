// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/attendance_record.dart';
import 'class_session_picker_modal.dart';

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
    final allowedWeekdays = course.classWeekdays;
    final currentSession = widget.controller.currentSession;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentSession.sessionDate,
      firstDate: DateTime(2026, 8, 1),
      lastDate: DateTime(2026, 12, 20),
      helpText: 'CALENDÁRIO DA TURMA (${course.classDaysLabel.toUpperCase()})',
      confirmText: 'SELECIONAR AULA',
      cancelText: 'CANCELAR',
      selectableDayPredicate: (DateTime day) {
        // Restringe a seleção estritamente aos dias de aula da disciplina
        return allowedWeekdays.contains(day.weekday);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF18181B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF18181B),
            ),
          ),
          child: child!,
        );
      },
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: 'Ver todas as aulas da turma',
                      child: InkWell(
                        onTap: () => _openSessionPicker(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Color(0xFF18181B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'AULA Nº ${session.sessionNumber} • CARGA: ${session.hours}H/AULA',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF71717A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Setas para Aula Anterior / Próxima Aula
                              InkWell(
                                onTap: widget.controller.canGoToPreviousSession
                                    ? () => widget.controller
                                          .goToPreviousSession()
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color:
                                        widget.controller.canGoToPreviousSession
                                        ? const Color(0xFFF4F4F5)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.chevron_left,
                                    size: 16,
                                    color:
                                        widget.controller.canGoToPreviousSession
                                        ? const Color(0xFF18181B)
                                        : const Color(0xFFD4D4D8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              InkWell(
                                onTap: widget.controller.canGoToNextSession
                                    ? () => widget.controller.goToNextSession()
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: widget.controller.canGoToNextSession
                                        ? const Color(0xFFF4F4F5)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: widget.controller.canGoToNextSession
                                        ? const Color(0xFF18181B)
                                        : const Color(0xFFD4D4D8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                session.dateFormatted,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF09090B),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              InkWell(
                                onTap: () => _openSessionPicker(context),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F4F5),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFE4E4E7),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Trocar Aula',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF18181B),
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 12,
                                        color: Color(0xFF18181B),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openCalendarPicker(context),
                    icon: const Icon(
                      Icons.calendar_month,
                      size: 13,
                      color: Color(0xFF18181B),
                    ),
                    label: const Text(
                      'Selecionar Data',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: session.isHomologated
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: session.isHomologated
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Text(
                      session.isHomologated
                          ? 'Homologado no Sistema'
                          : 'Aguardando Homologação',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: session.isHomologated
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Conteúdo Programático Específico Ministrado
          const Text(
            'Conteúdo Programático Específico Ministrado (Exigência Regimental MEC)',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: Color(0xFF18181B)),
            onChanged: (val) {
              widget.controller.updateSessionContent(
                val,
                _methodologyController.text,
                _locationController.text,
              );
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF18181B),
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Metodologia e Recursos Aplicados + Local Real de Realização (2 Colunas)
          LayoutBuilder(
            builder: (context, c) {
              final isNarrow = c.maxWidth < 650;

              final methodologyField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metodologia e Recursos Aplicados',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _methodologyController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF18181B),
                    ),
                    onChanged: (val) {
                      widget.controller.updateSessionContent(
                        _contentController.text,
                        val,
                        _locationController.text,
                      );
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF18181B),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              );

              final locationField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Local Real de Realização',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _locationController,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF18181B),
                    ),
                    onChanged: (val) {
                      widget.controller.updateSessionContent(
                        _contentController.text,
                        _methodologyController.text,
                        val,
                      );
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF18181B),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    methodologyField,
                    const SizedBox(height: 14),
                    locationField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: methodologyField),
                  const SizedBox(width: 16),
                  Expanded(child: locationField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
