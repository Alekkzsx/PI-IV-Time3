// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';

/// Aba de Alunos Matriculados no curso no Portal Docente.
class CourseHubStudentsTab extends StatelessWidget {
  const CourseHubStudentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Discentes Matriculados na Turma (34 alunos)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF09090B),
              ),
            ),
            Text(
              'Semestre 2026/2 • Turno Noturno',
              style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Column(
            children: [
              _buildStudentRow(
                context,
                'Mariana Rios Costa',
                '2024.1.00901',
                'mariana.costa@aluno.universidade.edu.br',
                '100% Presença',
                'Média 9.3',
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              _buildStudentRow(
                context,
                'Gabriel Soares de Oliveira',
                '2024.1.00892',
                'gabriel.oliveira@aluno.universidade.edu.br',
                '94.4% Presença',
                'Média 8.2',
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              _buildStudentRow(
                context,
                'Rodrigo Antunes Nogueira',
                '2024.1.00938',
                'rodrigo.nogueira@aluno.universidade.edu.br',
                '97.2% Presença',
                'Pendente 2ª Cham.',
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              _buildStudentRow(
                context,
                'Lucas Mendes Santos',
                '2024.1.00915',
                'lucas.santos@aluno.universidade.edu.br',
                '91.6% Presença',
                'Média 7.2',
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              _buildStudentRow(
                context,
                'Camila Duarte Fagundes',
                '2024.1.00902',
                'camila.fagundes@aluno.universidade.edu.br',
                '94.4% Presença',
                'Média 8.3',
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildStudentRow(
    BuildContext context,
    String name,
    String ra,
    String email,
    String attendance,
    String grade,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF4F4F5),
                child: Text(
                  name.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF09090B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF09090B),
                    ),
                  ),
                  Text(
                    'RA: $ra • $email',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                attendance,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                grade,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF09090B),
                ),
              ),
              const SizedBox(width: 14),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Abrindo prontuário de $name (RA: $ra)...'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  side: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
                child: const Text(
                  'Prontuário',
                  style: TextStyle(fontSize: 10, color: Color(0xFF09090B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
