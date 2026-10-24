// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_event.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import '../widgets/docente_event_item_card.dart';
import '../widgets/docente_new_appointment_card.dart';

/// Tab page for viewing academic schedule, managing tutoring office hours, and syncing calendar.
class DocenteCalendarTab extends StatefulWidget {
  /// Reactive controller for state access and mutations.
  final DocenteController controller;

  const DocenteCalendarTab({super.key, required this.controller});

  @override
  State<DocenteCalendarTab> createState() => _DocenteCalendarTabState();
}

class _DocenteCalendarTabState extends State<DocenteCalendarTab> {
  final _formKey = GlobalKey<FormState>();

  bool _isFormOpen = true;
  EventType _newEventType = EventType.plantao;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: '06/10/2026',
  );
  final TextEditingController _timeController = TextEditingController(
    text: '17:00 - 18:30',
  );
  final TextEditingController _locationController = TextEditingController(
    text: 'Gabinete Docente 12 - Bloco A',
  );

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _handleAddEvent() {
    if (!_formKey.currentState!.validate()) return;

    widget.controller.addEvent(
      title: _titleController.text.trim(),
      date: _dateController.text.trim(),
      time: _timeController.text.trim(),
      type: _newEventType,
      location: _locationController.text.trim(),
    );

    _titleController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Compromisso agendado e sincronizado com a agenda institucional!',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final events = widget.controller.events;

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          if (_isFormOpen) ...[
                            DocenteNewAppointmentCard(
                              formKey: _formKey,
                              titleController: _titleController,
                              dateController: _dateController,
                              timeController: _timeController,
                              locationController: _locationController,
                              selectedType: _newEventType,
                              onTypeChanged: (val) {
                                if (val != null) {
                                  setState(() => _newEventType = val);
                                }
                              },
                              onCancel: () {
                                setState(() {
                                  _isFormOpen = false;
                                });
                              },
                              onSave: _handleAddEvent,
                            ),
                            const SizedBox(height: 28),
                          ],
                          _buildEventsListCard(events),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agenda Acadêmica & Plantão Docente',
              style: jakarta(
                size: 20,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gerencie o cronograma de aulas, datas de provas regimentais e horários de atendimento presencial aos alunos.',
              style: jakarta(
                size: 13,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isFormOpen = !_isFormOpen;
            });
          },
          icon: Icon(
            _isFormOpen ? Icons.close_rounded : Icons.add_rounded,
            size: 16,
            color: Colors.white,
          ),
          label: Text(
            '+ Agendar Evento / Plantão',
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF18181B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsListCard(List<AcademicEvent> events) {
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Color(0xFFF4F4F5)),
        itemBuilder: (context, index) {
          final event = events[index];
          return DocenteEventItemCard(event: event);
        },
      ),
    );
  }
}
