// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';

/// Grade mensal construída a partir do mês selecionado e dos eventos do aluno.
class StudentCalendarMonthGrid extends StatelessWidget {
  final StudentPortalController controller;

  const StudentCalendarMonthGrid({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final focusedDate = controller.calendarFocusedDate;
    final firstOfMonth = DateTime(focusedDate.year, focusedDate.month);
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday % 7),
    );
    final daysInMonth = DateTime(
      focusedDate.year,
      focusedDate.month + 1,
      0,
    ).day;
    final cellCount = ((firstOfMonth.weekday % 7 + daysInMonth) / 7).ceil() * 7;
    final days = List.generate(
      cellCount,
      (index) => gridStart.add(Duration(days: index)),
    );
    final today = DateTime.now();
    final eventsByDate = <String, List<StudentCalendarEvent>>{};
    for (final event in controller.visibleCalendarEvents) {
      (eventsByDate[event.date] ??= []).add(event);
    }

    return Table(
      border: TableBorder.all(color: const Color(0xFFE5E7EB), width: 1),
      children: List.generate((days.length / 7).ceil(), (rowIndex) {
        return TableRow(
          children: List.generate(7, (colIndex) {
            final date = days[rowIndex * 7 + colIndex];
            final dateKey =
                '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final events = eventsByDate[dateKey] ?? const [];
            final isToday =
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isCurrentMonth = date.month == focusedDate.month;

            return Container(
              height: 100,
              padding: const EdgeInsets.all(6),
              color: isToday ? const Color(0xFFF8FAFC) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: isToday
                        ? Container(
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
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isCurrentMonth
                                  ? const Color(0xFF374151)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                  ),
                  const SizedBox(height: 2),
                  ...events.take(2).map((event) {
                    final color = switch (event.type) {
                      'Entrega' => const Color(0xFF16A34A),
                      'Aula' => const Color(0xFF0D9488),
                      'Fórum' => const Color(0xFFD97706),
                      _ => const Color(0xFF7C3AED),
                    };
                    return Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${event.time} ${event.title}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (events.length > 2)
                    Text(
                      '+${events.length - 2} mais',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            );
          }),
        );
      }),
    );
  }
}
