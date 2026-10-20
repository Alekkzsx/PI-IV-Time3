// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import '../widgets/student_calendar_month_grid.dart';
import '../widgets/student_calendar_agenda_view.dart';
import '../widgets/student_calendar_sidebar.dart';
import '../widgets/student_calendar_modals.dart';

/// Tela de Calendário Acadêmico da Visão do Aluno.
/// Suporta alternância dinâmica entre visualização em Mês e visualização em Agenda,
/// filtros por categoria e por disciplina, e modal de criação de novo evento.
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
          // Área Direita: Mini Calendário e Filtros
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (_controller.calendarViewMode == 'Mês') ...[
            _buildDaysOfWeek(),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const StudentCalendarMonthGrid(),
          ] else ...[
            StudentCalendarAgendaView(controller: _controller),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: const Text('Hoje',
                    style: TextStyle(color: Color(0xFF18181B))),
              ),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.chevron_left), onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.chevron_right), onPressed: () {}),
              const SizedBox(width: 12),
              const Text(
                'Outubro de 2026',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Alternador Mês / Agenda
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildModeButton('Mês'),
                    _buildModeButton('Agenda'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    StudentCalendarModals.showCreateEventModal(context, _controller),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Novo Evento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode) {
    final isSelected = _controller.calendarViewMode == mode;
    return InkWell(
      onTap: () => _controller.setCalendarViewMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 2)]
              : null,
        ),
        child: Text(
          mode,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color:
                isSelected ? const Color(0xFF18181B) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    final days = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: days.map((d) {
          return Expanded(
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
