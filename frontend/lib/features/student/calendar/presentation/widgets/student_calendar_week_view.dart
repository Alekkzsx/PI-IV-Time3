// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';

/// Visualização em grade horária semanal do calendário acadêmico.
class StudentCalendarWeekView extends StatelessWidget {
  final StudentPortalController controller;

  const StudentCalendarWeekView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final hours = [
      '08:00',
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00',
      '20:00',
      '21:00',
      '22:00',
      '23:00',
    ];

    const weekdayLabels = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
    final focusedDate = controller.calendarFocusedDate;
    final sunday = focusedDate.subtract(
      Duration(days: focusedDate.weekday % 7),
    );
    final weekDays = List.generate(
      7,
      (index) => sunday.add(Duration(days: index)),
    );
    final today = DateTime.now();

    return Column(
      children: [
        // Linha de cabeçalho dos dias
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              // Coluna Hora
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: const Text(
                  'HORA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF71717A),
                  ),
                ),
              ),
              // Colunas dos dias
              ...weekDays.asMap().entries.map((entry) {
                final index = entry.key;
                final date = entry.value;
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekdayLabels[index],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF71717A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isToday)
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1D4ED8),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Text(
                                '${date.day}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF18181B),
                                ),
                              ),
                            const SizedBox(width: 4),
                            Text(
                              '${_monthAbbreviation(date.month)}.',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // Linha "dia todo"
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'dia todo',
                  style: TextStyle(fontSize: 10, color: Color(0xFF71717A)),
                ),
              ),
              ...weekDays.map(
                (date) => Expanded(
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tabela horária rolável
        SizedBox(
          height: 460,
          child: SingleChildScrollView(
            child: Column(
              children: hours.map((hour) {
                return Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(top: 4, right: 8),
                        child: Text(
                          hour,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF71717A),
                          ),
                        ),
                      ),
                      ...weekDays.asMap().entries.map((entry) {
                        final date = entry.value;
                        final dateKey =
                            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        final events = controller.visibleCalendarEvents.where(
                          (event) =>
                              event.date == dateKey &&
                              _eventHour(event.time) == hour.substring(0, 2),
                        );
                        return Expanded(
                          child: Container(
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Color(0xFFF1F5F9)),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: events.map((event) {
                                return Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    event.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFF075985),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _monthAbbreviation(int month) => const [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ][month - 1];

  String? _eventHour(String time) {
    final match = RegExp(r'^\s*(\d{2}):\d{2}').firstMatch(time);
    return match?.group(1);
  }
}
