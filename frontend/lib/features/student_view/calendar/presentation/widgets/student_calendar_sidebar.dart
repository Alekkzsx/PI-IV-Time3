// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';

/// Painel lateral do calendário acadêmico: mini-calendário e lista de calendários.
class StudentCalendarSidebar extends StatefulWidget {
  final StudentPortalController controller;

  const StudentCalendarSidebar({
    super.key,
    required this.controller,
  });

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

    final miniDays = [
      {'num': 30, 'curr': false},
      {'num': 31, 'curr': false},
      {'num': 1, 'curr': true},
      {'num': 2, 'curr': true},
      {'num': 3, 'curr': true},
      {'num': 4, 'curr': true},
      {'num': 5, 'curr': true},
      {'num': 6, 'curr': true},
      {'num': 7, 'curr': true},
      {'num': 8, 'curr': true},
      {'num': 9, 'curr': true},
      {'num': 10, 'curr': true},
      {'num': 11, 'curr': true},
      {'num': 12, 'curr': true},
      {'num': 13, 'curr': true},
      {'num': 14, 'curr': true},
      {'num': 15, 'curr': true},
      {'num': 16, 'curr': true},
      {'num': 17, 'curr': true},
      {'num': 18, 'curr': true},
      {'num': 19, 'curr': true},
      {'num': 20, 'curr': true, 'isToday': true},
      {'num': 21, 'curr': true},
      {'num': 22, 'curr': true},
      {'num': 23, 'curr': true},
      {'num': 24, 'curr': true},
      {'num': 25, 'curr': true},
      {'num': 26, 'curr': true},
      {'num': 27, 'curr': true},
      {'num': 28, 'curr': true},
      {'num': 29, 'curr': true},
      {'num': 30, 'curr': true},
      {'num': 1, 'curr': false},
      {'num': 2, 'curr': false},
      {'num': 3, 'curr': false},
    ];

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
                onTap: () {},
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left, size: 18, color: Color(0xFF6B7280)),
                ),
              ),
              const Text(
                'SETEMBRO 2026',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF18181B),
                ),
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right, size: 18, color: Color(0xFF6B7280)),
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
            itemCount: 35,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final item = miniDays[index];
              final num = item['num'] as int;
              final curr = item['curr'] as bool;
              final isToday = item['isToday'] == true;

              if (isToday) {
                return Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D4ED8),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$num',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }

              return Center(
                child: Text(
                  '$num',
                  style: TextStyle(
                    fontSize: 10,
                    color: curr ? const Color(0xFF18181B) : const Color(0xFFD1D5DB),
                    fontWeight: curr ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
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
            onTap: () => setState(() => _isCalendarsExpanded = !_isCalendarsExpanded),
            child: Row(
              children: [
                Icon(
                  _isCalendarsExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
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
              final isChecked = _calendarChecks[title] ?? true;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _calendarChecks[title] = !isChecked),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isChecked ? const Color(0xFF1D4ED8) : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isChecked ? const Color(0xFF1D4ED8) : const Color(0xFFD1D5DB),
                          ),
                        ),
                        child: isChecked
                            ? const Icon(Icons.check, size: 10, color: Colors.white)
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
                    const Icon(Icons.more_vert, size: 14, color: Color(0xFF9CA3AF)),
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
                  _isNoDateExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
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
          const SizedBox(height: 16),
          // Link Feed do calendário
          InkWell(
            onTap: () {},
            child: const Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF1D4ED8)),
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
