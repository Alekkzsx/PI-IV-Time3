// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';

/// Grade de visualização mensal do calendário acadêmico.
class StudentCalendarMonthGrid extends StatelessWidget {
  const StudentCalendarMonthGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 480,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 35,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) {
          final dayNumber = index - 3;
          final isCurrentMonth = dayNumber >= 1 && dayNumber <= 31;
          final isToday = dayNumber == 20;

          // Eventos demonstrativos para o dia 20 e dia 22
          List<Widget> dayEvents = [];
          if (dayNumber == 20 && isCurrentMonth) {
            dayEvents.add(
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '19:00 Aula APS-II',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
            dayEvents.add(
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '23:59 Entrega Adapter',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          } else if (dayNumber == 22 && isCurrentMonth) {
            dayEvents.add(
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '20:50 Prova BD-II',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF1F5F9)),
              color: isToday ? const Color(0xFFF8FAFC) : Colors.white,
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCurrentMonth)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: isToday
                        ? const BoxDecoration(
                            color: Color(0xFF18181B),
                            shape: BoxShape.circle,
                          )
                        : null,
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w500,
                        color:
                            isToday ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ...dayEvents,
              ],
            ),
          );
        },
      ),
    );
  }
}
