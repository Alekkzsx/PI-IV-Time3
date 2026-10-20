// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';

/// Tabela de quadro semanal de horários e ensalamento físico presencial.
class StudentDisciplinesScheduleTable extends StatelessWidget {
  const StudentDisciplinesScheduleTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quadro Semanal de Horários & Ensalamento Físico',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Locais de aula presenciais homologados pela DTI e Conselho Universitário para 2026/2.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Table(
            border: TableBorder.all(color: const Color(0xFFE5E7EB)),
            children: const [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'DIA',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      '1º HORÁRIO (19:00 - 20:40)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      '2º HORÁRIO (20:50 - 22:30)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Segunda-feira',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Análise e Projeto de Sistemas II\nLab 04 - Bloco C',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Fundamentos de Sist. Operacionais\nLab 01 - Bloco C',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Terça-feira',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Fundamentos de I.A.\nSala 302 - Bloco A',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Banco de Dados II\nLab 02 - Bloco B',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Quarta-feira',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Análise e Projeto de Sistemas II\nLab 04 - Bloco C',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Fundamentos de Sist. Operacionais\nLab 01 - Bloco C',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Quinta-feira',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Fundamentos de I.A.\nSala 302 - Bloco A',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Banco de Dados II\nLab 02 - Bloco B',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
