// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import '../widgets/student_calendar_month_grid.dart';
import '../widgets/student_calendar_week_view.dart';
import '../widgets/student_calendar_agenda_view.dart';
import '../widgets/student_calendar_sidebar.dart';
import '../widgets/student_calendar_modals.dart';

/// Tela de Calendário Acadêmico da Visão do Aluno.
/// Suporta alternância dinâmica entre Semana, Mês e Agenda,
/// visualização de prazos regimentais e modal de novo evento/tarefa.
class StudentCalendarPage extends StatefulWidget {
  const StudentCalendarPage({super.key});

  @override
  State<StudentCalendarPage> createState() => _StudentCalendarPageState();
}

class _StudentCalendarPageState extends State<StudentCalendarPage> {
  final StudentPortalController _controller = StudentPortalController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área Esquerda: Calendário Principal
          Expanded(flex: 3, child: _buildMainCalendarArea()),
          const SizedBox(width: 24),
          // Área Direita: Mini Calendário e Lista de Calendários
          Expanded(
            flex: 1,
            child: StudentCalendarSidebar(controller: _controller),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ÁREA PRINCIPAL DO CALENDÁRIO
  // ==========================================
  Widget _buildMainCalendarArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (_controller.calendarViewMode == 'Mês') ...[
            _buildDaysOfWeek(),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            StudentCalendarMonthGrid(controller: _controller),
          ] else if (_controller.calendarViewMode == 'Semana') ...[
            StudentCalendarWeekView(controller: _controller),
          ] else ...[
            StudentCalendarAgendaView(controller: _controller),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              OutlinedButton(
                key: const Key('calendar_today'),
                onPressed: _controller.goToCalendarToday,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Hoje',
                  style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    InkWell(
                      key: const Key('calendar_previous'),
                      onTap: () => _controller.shiftCalendarFocus(-1),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          size: 18,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 18,
                      color: const Color(0xFFD1D5DB),
                    ),
                    InkWell(
                      key: const Key('calendar_next'),
                      onTap: () => _controller.shiftCalendarFocus(1),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                _calendarHeaderLabel(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Alternador Semana / Mês / Agenda
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Row(
                  children: [
                    _buildModeButton('Semana'),
                    _buildModeButton('Mês'),
                    _buildModeButton('Agenda'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Botão '+' para novo evento
              InkWell(
                onTap: () => StudentCalendarModals.showCreateEventModal(
                  context,
                  _controller,
                ),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Tooltip(
                    message: 'Novo Evento',
                    child: Icon(Icons.add, size: 18, color: Color(0xFF374151)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthLabel(DateTime date) {
    const months = [
      'JANEIRO',
      'FEVEREIRO',
      'MARÇO',
      'ABRIL',
      'MAIO',
      'JUNHO',
      'JULHO',
      'AGOSTO',
      'SETEMBRO',
      'OUTUBRO',
      'NOVEMBRO',
      'DEZEMBRO',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _calendarHeaderLabel() {
    final date = _controller.calendarFocusedDate;
    if (_controller.calendarViewMode == 'Mês') return _monthLabel(date);
    if (_controller.calendarViewMode == 'Agenda') {
      return '${date.day} DE ${_monthLabel(date)}';
    }
    final start = date.subtract(Duration(days: date.weekday % 7));
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month) {
      return '${start.day}–${end.day} DE ${_monthLabel(start)}';
    }
    return '${start.day} DE ${_monthLabel(start)} – ${end.day} DE ${_monthLabel(end)}';
  }

  Widget _buildModeButton(String mode) {
    final isSelected = _controller.calendarViewMode == mode;
    return InkWell(
      onTap: () => _controller.setCalendarViewMode(mode),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF26394A) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          mode,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: days.map((d) {
          return Expanded(
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF71717A),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
