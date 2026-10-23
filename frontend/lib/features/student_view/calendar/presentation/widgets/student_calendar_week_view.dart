// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';

/// Visualização em grade horária semanal do calendário acadêmico.
class StudentCalendarWeekView extends StatelessWidget {
  const StudentCalendarWeekView({super.key});

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
    ];

    final weekDays = [
      {'day': 'DOM', 'num': '20', 'isToday': true},
      {'day': 'SEG', 'num': '21', 'isToday': false},
      {'day': 'TER', 'num': '22', 'isToday': false},
      {'day': 'QUA', 'num': '23', 'isToday': false},
      {'day': 'QUI', 'num': '24', 'isToday': false},
      {'day': 'SEX', 'num': '25', 'isToday': false},
      {'day': 'SÁB', 'num': '26', 'isToday': false},
    ];

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
              ...weekDays.map((wd) {
                final isToday = wd['isToday'] as bool;
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: Column(
                      children: [
                        Text(
                          wd['day'] as String,
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
                                  wd['num'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Text(
                                wd['num'] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF18181B),
                                ),
                              ),
                            const SizedBox(width: 4),
                            const Text(
                              'set.',
                              style: TextStyle(
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
              ...List.generate(
                7,
                (i) => Expanded(
                  child: Container(
                    height: 32,
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
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
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
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
                      ...List.generate(
                        7,
                        (index) => Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(color: Color(0xFFF1F5F9)),
                              ),
                            ),
                          ),
                        ),
                      ),
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
}

