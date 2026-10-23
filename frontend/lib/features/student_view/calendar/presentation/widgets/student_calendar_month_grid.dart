// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';

/// Grade de visualização mensal do calendário acadêmico.
class StudentCalendarMonthGrid extends StatelessWidget {
  const StudentCalendarMonthGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // 35 dias (5 semanas x 7 dias): de 30 de Agosto a 3 de Outubro de 2026
    final days = [
      // Semana 1
      {'num': 30, 'isCurrent': false, 'events': <Map<String, dynamic>>[]},
      {'num': 31, 'isCurrent': false, 'events': <Map<String, dynamic>>[]},
      {'num': 1, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 2, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 3, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 4, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 5, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      // Semana 2
      {'num': 6, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 7, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 8, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 9, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 10, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 11, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 12, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      // Semana 3
      {'num': 13, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 14, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 15, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 16, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 17, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 18, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 19, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      // Semana 4 (com eventos da semana ativa)
      {
        'num': 20,
        'isCurrent': true,
        'isToday': true,
        'events': [
          {'title': '23:59 Entrega: Dia...', 'color': const Color(0xFF16A34A)},
          {'title': '19:00 Aula Ao Vivo: ...', 'color': const Color(0xFF0D9488)},
        ],
      },
      {
        'num': 21,
        'isCurrent': true,
        'events': [
          {'title': '18:00 Fórum Temáti...', 'color': const Color(0xFFD97706)},
        ],
      },
      {
        'num': 22,
        'isCurrent': true,
        'events': [
          {'title': '19:00 Aula Remota...', 'color': const Color(0xFFEA580C)},
        ],
      },
      {'num': 23, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {
        'num': 24,
        'isCurrent': true,
        'events': [
          {'title': '23:59 Atividade Prá...', 'color': const Color(0xFF7C3AED)},
        ],
      },
      {
        'num': 25,
        'isCurrent': true,
        'events': [
          {'title': '20:40 Laboratório...', 'color': const Color(0xFF2563EB)},
        ],
      },
      {'num': 26, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      // Semana 5
      {'num': 27, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 28, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {
        'num': 29,
        'isCurrent': true,
        'events': [
          {'title': '20:40 Avaliação Pa...', 'color': const Color(0xFFEA580C)},
        ],
      },
      {'num': 30, 'isCurrent': true, 'events': <Map<String, dynamic>>[]},
      {'num': 1, 'isCurrent': false, 'events': <Map<String, dynamic>>[]},
      {'num': 2, 'isCurrent': false, 'events': <Map<String, dynamic>>[]},
      {'num': 3, 'isCurrent': false, 'events': <Map<String, dynamic>>[]},
    ];

    return Table(
      border: TableBorder.all(
        color: const Color(0xFFE5E7EB),
        width: 1,
      ),
      children: List.generate(5, (rowIndex) {
        return TableRow(
          children: List.generate(7, (colIndex) {
            final dayData = days[rowIndex * 7 + colIndex];
            final num = dayData['num'] as int;
            final isCurrent = dayData['isCurrent'] as bool;
            final isToday = dayData['isToday'] == true;
            final events = dayData['events'] as List<Map<String, dynamic>>;

            return Container(
              height: 100,
              padding: const EdgeInsets.all(6),
              color: isToday ? const Color(0xFFF8FAFC) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Número do dia alinhado à direita
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
                              '$num',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            '$num',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isCurrent
                                  ? const Color(0xFF374151)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                  ),
                  const SizedBox(height: 2),
                  // Lista de pílulas de eventos
                  ...events.map((ev) {
                    final color = ev['color'] as Color;
                    final title = ev['title'] as String;
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
                              title,
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
                ],
              ),
            );
          }),
        );
      }),
    );
  }
}
