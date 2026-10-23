// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';

/// Modal para criação e edição de eventos e tarefas acadêmicas.
class StudentCalendarModals {
  StudentCalendarModals._();

  static void showCreateEventModal(
    BuildContext context,
    StudentPortalController controller,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const _CalendarEventDialog(),
    );
  }
}

class _CalendarEventDialog extends StatefulWidget {
  const _CalendarEventDialog();

  @override
  State<_CalendarEventDialog> createState() => _CalendarEventDialogState();
}

class _CalendarEventDialogState extends State<_CalendarEventDialog> {
  int _activeTabIndex = 0; // 0: Evento, 1: Minha lista de tarefas

  // Controllers da aba Evento
  final _eventTitleController = TextEditingController();
  final _eventDateController = TextEditingController(text: 'dom., 20 de set. de 2026');
  final _eventLocationController = TextEditingController();
  String _startTime = '19:00';
  String _endTime = '20:40';
  String _frequency = 'Não se repete';
  String _selectedCalendar =
      '218131 - ANÁLISE E PROJETO DE SISTEMAS II (MAT) 0103-04-26-2s';

  // Controllers da aba Tarefa
  final _taskTitleController = TextEditingController();
  final _taskDateController = TextEditingController(text: 'dom., 20 de set. de 2026');
  final _taskTimeController = TextEditingController(text: '23:59');
  final _taskDetailsController = TextEditingController();

  final List<String> _calendarOptions = [
    '218131 - ANÁLISE E PROJETO DE SISTEMAS II (MAT) 0103-04-26-2s',
    '218131 - ESTUDOS DE BANCO DE DADOS II (MAT) 0103-04-26-2s',
    '218131 - FILOSOFIA, INFORMAÇÃO E SOCIEDADE (MAT) 0103-04-26-2s',
    '218131 - FUNDAMENTOS DE SISTEMAS OPERACIONAIS',
  ];

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventDateController.dispose();
    _eventLocationController.dispose();
    _taskTitleController.dispose();
    _taskDateController.dispose();
    _taskTimeController.dispose();
    _taskDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _activeTabIndex == 0 ? 'Editar Evento' : 'Minha Lista de Tarefas';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do modal com botão Fechar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Segmented Tabs: Evento | Minha lista de tarefas
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF26394A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    _buildTabItem(label: 'Evento', index: 0),
                    _buildTabItem(label: 'Minha lista de tarefas', index: 1),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_activeTabIndex == 0) _buildEventForm() else _buildTaskForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({required String label, required int index}) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF26394A) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Título'),
        _buildTextField(_eventTitleController, hintText: 'Inserir o título do evento...'),
        const SizedBox(height: 12),
        _buildFieldLabel('Data ℹ️'),
        _buildDateField(_eventDateController),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('De'),
                  _buildDropdown(
                    value: _startTime,
                    items: ['18:00', '19:00', '20:00', '21:00'],
                    onChanged: (v) => setState(() => _startTime = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Para'),
                  _buildDropdown(
                    value: _endTime,
                    items: ['19:40', '20:40', '21:40', '22:30'],
                    onChanged: (v) => setState(() => _endTime = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFieldLabel('Frequência'),
        _buildDropdown(
          value: _frequency,
          items: ['Não se repete', 'Semanalmente', 'Quinzenalmente', 'Mensalmente'],
          onChanged: (v) => setState(() => _frequency = v!),
        ),
        const SizedBox(height: 12),
        _buildFieldLabel('Localização'),
        _buildTextField(_eventLocationController, hintText: 'Inserir local do evento...'),
        const SizedBox(height: 12),
        _buildFieldLabel('Calendário'),
        _buildDropdown(
          value: _selectedCalendar,
          items: _calendarOptions,
          onChanged: (v) => setState(() => _selectedCalendar = v!),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Mais opções',
                  style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Enviar',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 70,
              child: Text(
                'Título:',
                style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
            Expanded(child: _buildTextField(_taskTitleController)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(
              width: 70,
              child: Text(
                'Data:',
                style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
            Expanded(child: _buildDateField(_taskDateController)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(
              width: 70,
              child: Text(
                'Horário:',
                style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
            SizedBox(
              width: 100,
              child: _buildTextField(_taskTimeController),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(
              width: 70,
              child: Text(
                'Calendário:',
                style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
            Expanded(
              child: _buildDropdown(
                value: _selectedCalendar,
                items: _calendarOptions,
                onChanged: (v) => setState(() => _selectedCalendar = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 70,
              child: Text(
                'Detalhes:',
                style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 80,
                child: TextField(
                  controller: _taskDetailsController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Enviar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {String? hintText}) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isDense: true,
        isExpanded: true,
        style: const TextStyle(fontSize: 12, color: Color(0xFF18181B)),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
