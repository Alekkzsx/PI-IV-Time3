// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../../domain/models/academic_event.dart';
import '../controllers/docente_controller.dart';

/// Tab page for viewing academic schedule, managing tutoring office hours, and syncing calendar.
class DocenteCalendarTab extends StatefulWidget {
  /// Reactive controller for state access and mutations.
  final DocenteController controller;

  const DocenteCalendarTab({
    super.key,
    required this.controller,
  });

  @override
  State<DocenteCalendarTab> createState() => _DocenteCalendarTabState();
}

class _DocenteCalendarTabState extends State<DocenteCalendarTab> {
  final _formKey = GlobalKey<FormState>();

  EventType? _filterType;
  EventType _newEventType = EventType.plantao;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(text: '25/09/2026');
  final TextEditingController _timeController = TextEditingController(text: '17:00 - 18:30');
  final TextEditingController _locationController = TextEditingController(text: 'Sala Virtual Meet / Lab 04');

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
        content: Text('Compromisso agendado e sincronizado com a agenda institucional!'),
        backgroundColor: DocenteColors.emerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _filterType == null
        ? widget.controller.events
        : widget.controller.events.where((e) => e.type == _filterType).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSyncNotice(),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 950;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildEventsListSection(filteredEvents),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: _buildScheduleForm(),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildEventsListSection(filteredEvents),
                    const SizedBox(height: 24),
                    _buildScheduleForm(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agenda Acadêmica & Plantões de Dúvidas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: DocenteColors.charcoal,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Sincronização com Google Calendar, horários de aulas, reuniões e atendimento discente',
          style: TextStyle(
            fontSize: 14,
            color: DocenteColors.slate,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: DocenteColors.emerald.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.sync_rounded, color: DocenteColors.emerald, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sincronização ativa com o Google Workspace da Universidade: helena.bittencourt@universidade.edu.br',
              style: TextStyle(fontSize: 13, color: DocenteColors.charcoal, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DocenteColors.offWhite,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: DocenteColors.border),
            ),
            child: const Text('Status: Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsListSection(List<AcademicEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(null, 'Todos os Eventos'),
              _buildFilterChip(EventType.aula, 'Aulas Regulares'),
              _buildFilterChip(EventType.plantao, 'Plantões de Dúvidas'),
              _buildFilterChip(EventType.avaliacao, 'Avaliações'),
              _buildFilterChip(EventType.reuniao, 'Reuniões'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DocenteColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DocenteColors.border),
            ),
            child: const Text(
              'Nenhum evento agendado para esta categoria.',
              style: TextStyle(color: DocenteColors.slate, fontSize: 13),
            ),
          )
        else
          ...events.map((event) => _buildEventCard(event)),
      ],
    );
  }

  Widget _buildFilterChip(EventType? type, String label) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _filterType = type;
          });
        },
        backgroundColor: DocenteColors.white,
        selectedColor: DocenteColors.charcoal.withOpacity(0.1),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? DocenteColors.charcoal : DocenteColors.slate,
        ),
        side: BorderSide(
          color: isSelected ? DocenteColors.charcoal : DocenteColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildEventCard(AcademicEvent event) {
    Color typeColor;
    String typeLabel;

    switch (event.type) {
      case EventType.aula:
        typeColor = const Color(0xFF2563EB); // Blue
        typeLabel = 'Aula Regular';
        break;
      case EventType.avaliacao:
        typeColor = DocenteColors.crimson;
        typeLabel = 'Avaliação Oficial';
        break;
      case EventType.plantao:
        typeColor = DocenteColors.emerald;
        typeLabel = 'Plantão de Dúvidas';
        break;
      case EventType.colegiado:
      case EventType.reuniao:
        typeColor = DocenteColors.amber;
        typeLabel = 'Colegiado / Reunião';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: DocenteColors.offWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DocenteColors.border),
            ),
            child: Column(
              children: [
                Text(
                  event.date.split(',').first,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DocenteColors.slate),
                ),
                Text(
                  event.date.contains(',') ? event.date.split(',').last.trim() : '',
                  style: const TextStyle(fontSize: 10, color: DocenteColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: typeColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.time,
                      style: const TextStyle(fontSize: 12, color: DocenteColors.slate, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: DocenteColors.slate),
                    const SizedBox(width: 4),
                    Text(event.location, style: const TextStyle(fontSize: 12, color: DocenteColors.slate)),
                  ],
                ),
              ],
            ),
          ),
          if (event.type == EventType.aula || event.type == EventType.plantao)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/video-call');
              },
              icon: const Icon(Icons.videocam_outlined, size: 16),
              label: const Text('Sala Virtual', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: DocenteColors.emerald,
                foregroundColor: DocenteColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.add_alarm_rounded, color: DocenteColors.charcoal, size: 20),
                SizedBox(width: 10),
                Text(
                  'Agendar Novo Evento / Plantão',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DocenteColors.charcoal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Título do Evento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              validator: (v) => v == null || v.trim().isEmpty ? 'Insira o título do evento' : null,
              decoration: InputDecoration(
                hintText: 'Ex: Plantão Extra - Dúvidas sobre Docker',
                filled: true,
                fillColor: DocenteColors.offWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: DocenteColors.border),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Tipo de Evento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: DocenteColors.offWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DocenteColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<EventType>(
                  value: _newEventType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: EventType.plantao, child: Text('Plantão de Dúvidas')),
                    DropdownMenuItem(value: EventType.aula, child: Text('Aula Regular / Reposição')),
                    DropdownMenuItem(value: EventType.avaliacao, child: Text('Avaliação Oficial')),
                    DropdownMenuItem(value: EventType.reuniao, child: Text('Reunião de Colegiado')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _newEventType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: DocenteColors.offWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: DocenteColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Horário', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _timeController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: DocenteColors.offWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: DocenteColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Local / Link da Sala', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                filled: true,
                fillColor: DocenteColors.offWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: DocenteColors.border),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleAddEvent,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Agendar e Notificar Turma', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DocenteColors.charcoal,
                  foregroundColor: DocenteColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
