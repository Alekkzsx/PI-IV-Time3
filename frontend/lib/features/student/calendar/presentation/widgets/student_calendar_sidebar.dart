// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';

/// Painel lateral do calendário acadêmico: mini-calendário e lista de calendários.
class StudentCalendarSidebar extends StatefulWidget {
  final StudentPortalController controller;

  const StudentCalendarSidebar({super.key, required this.controller});

  @override
  State<StudentCalendarSidebar> createState() => _StudentCalendarSidebarState();
}

class _StudentCalendarSidebarState extends State<StudentCalendarSidebar> {
  bool _isCalendarsExpanded = true;
  bool _isNoDateExpanded = false;

  final Map<String, bool> _calendarChecks = {
    'ALEX GABRIEL SOARES SOUSA': true,
    '218131 - ANÁLISE E PROJETO DE SISTEMAS II (MAT) 0103-04-26-2s': true,
    '218131 - ESTUDOS DE BANCO DE DADOS II (MAT) 0103-04-26-2s': true,
    '218131 - FILOSOFIA, INFORMAÇÃO E SOCIEDADE (MAT) 0103-04-26-2s': true,
    '218131 - FUNDAMENTOS DE SISTEMAS OPERACIONAIS': true,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMiniCalendar(),
        const SizedBox(height: 16),
        _buildCalendarsCard(),
      ],
    );
  }

  Widget _buildMiniCalendar() {
    final daysOfWeek = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    final focusedDate = widget.controller.calendarFocusedDate;
    final firstOfMonth = DateTime(focusedDate.year, focusedDate.month);
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday % 7),
    );
    final daysInGrid =
        ((firstOfMonth.weekday % 7 +
                    DateTime(focusedDate.year, focusedDate.month + 1, 0).day) /
                7)
            .ceil() *
        7;
    final miniDays = List.generate(
      daysInGrid,
      (index) => gridStart.add(Duration(days: index)),
    );
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Cabeçalho com navegação de mês
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => widget.controller.shiftCalendarMonth(-1),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Text(
                _monthLabel(focusedDate),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF18181B),
                ),
              ),
              InkWell(
                onTap: () => widget.controller.shiftCalendarMonth(1),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dias da semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek.map((d) {
              return SizedBox(
                width: 24,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF71717A),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Grade de números
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: miniDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final date = miniDays[index];
              final isFocused =
                  date.year == focusedDate.year &&
                  date.month == focusedDate.month &&
                  date.day == focusedDate.day;
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isCurrentMonth = date.month == focusedDate.month;
              return InkWell(
                onTap: () => widget.controller.setCalendarFocusedDate(date),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isFocused || isToday
                          ? const Color(0xFF1D4ED8)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isFocused || isToday
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isFocused || isToday
                            ? Colors.white
                            : isCurrentMonth
                            ? const Color(0xFF18181B)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                ),
              );
            },
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

  String? _disciplineCodeForCalendar(String title) {
    if (title.contains('ANÁLISE E PROJETO DE SISTEMAS II')) return 'APS-II';
    if (title.contains('ESTUDOS DE BANCO DE DADOS II')) return 'BD-II';
    if (title.contains('FILOSOFIA, INFORMAÇÃO E SOCIEDADE')) return 'FIS';
    if (title.contains('FUNDAMENTOS DE SISTEMAS OPERACIONAIS')) return 'FSO';
    return null;
  }

  Widget _buildCalendarsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção CALENDÁRIOS com sanfona
          InkWell(
            onTap: () =>
                setState(() => _isCalendarsExpanded = !_isCalendarsExpanded),
            child: Row(
              children: [
                Icon(
                  _isCalendarsExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 18,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                const Text(
                  'CALENDÁRIOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          if (_isCalendarsExpanded) ...[
            const SizedBox(height: 10),
            ..._calendarChecks.keys.map((title) {
              final disciplineCode = _disciplineCodeForCalendar(title);
              final isChecked = disciplineCode == null
                  ? _calendarChecks[title] ?? true
                  : widget.controller.activeDisciplineFilters.contains(
                      disciplineCode,
                    );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    InkWell(
                      key: Key(
                        'calendar_filter_${disciplineCode ?? 'personal'}',
                      ),
                      onTap: () {
                        if (disciplineCode == null) {
                          setState(() => _calendarChecks[title] = !isChecked);
                        } else {
                          widget.controller.toggleDisciplineFilter(
                            disciplineCode,
                          );
                        }
                      },
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isChecked
                              ? const Color(0xFF1D4ED8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isChecked
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        child: isChecked
                            ? const Icon(
                                Icons.check,
                                size: 10,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.more_vert,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 14),
          // Seção SEM DATA
          InkWell(
            onTap: () => setState(() => _isNoDateExpanded = !_isNoDateExpanded),
            child: Row(
              children: [
                Icon(
                  _isNoDateExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                const Text(
                  'SEM DATA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          if (_isNoDateExpanded)
            const Padding(
              padding: EdgeInsets.only(left: 22, top: 8),
              child: Text(
                'Nenhum compromisso sem data.',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF71717A)),
              ),
            ),
          const SizedBox(height: 16),
          // Link Feed do calendário
          InkWell(
            key: const Key('student_calendar_feed'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'A assinatura do feed do calendário ainda não está disponível.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF1D4ED8),
                ),
                SizedBox(width: 6),
                Text(
                  'Feed do calendário',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
