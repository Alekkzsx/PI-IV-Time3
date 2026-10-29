// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';

/// Aba do AVA que exibe o Boletim de Avaliações Contínuas (PPC), pesos e médias parciais.
class AvaEvaluationsGradesTab extends StatelessWidget {
  final StudentDisciplineModel discipline;

  const AvaEvaluationsGradesTab({super.key, required this.discipline});

  @override
  Widget build(BuildContext context) {
    if (!AppUserSession.instance.hasPermission('view_own_grades')) {
      return const Center(
        child: Text('Você não tem permissão para consultar este boletim.'),
      );
    }

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
            'Boletim de Avaliações Contínuas (PPC)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fórmula de Homologação: Média = (N1 x 0.4) + (N2 x 0.6) • Presença Mínima: 75%',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Table(
            border: TableBorder.all(color: const Color(0xFFE5E7EB)),
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'AVALIAÇÃO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'PESO REGIMENTAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'NOTA LANÇADA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              _buildGradeRow(
                'Prova Teórica N1 (P1)',
                'Componente N1',
                '${discipline.p1.toStringAsFixed(1)} / 10.0',
                'Consolidado',
              ),
              _buildGradeRow(
                'Trabalho Prático N1 (TRAB)',
                'Componente N1',
                '${discipline.trab.toStringAsFixed(1)} / 10.0',
                'Consolidado',
              ),
              _buildGradeRow(
                'Prova Teórica N2 (P2)',
                'Componente N2',
                '${discipline.p2.toStringAsFixed(1)} / 10.0',
                'Consolidado',
              ),
              _buildGradeRow(
                'Média consolidada de N1 e N2',
                'Parcial',
                '${discipline.partialAverage.toStringAsFixed(1)} / 10.0',
                'Consolidado',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final result = Text(
                  '${discipline.partialAverage.toStringAsFixed(2)} / 10.0 (Situação: Regular)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF16A34A),
                  ),
                );
                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Média Parcial Consolidada:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      result,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Média Parcial Consolidada:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    result,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildGradeRow(
    String name,
    String weight,
    String score,
    String status,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(name, style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            weight,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            score,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            status,
            style: TextStyle(
              color: status == 'Consolidado'
                  ? const Color(0xFF16A34A)
                  : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
