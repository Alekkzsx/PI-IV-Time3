// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';

/// Linha de indicadores e estatísticas gerais da turma (Total, Média, Aprovados, Exame, Reprovados).
class DocenteGradesKpisRow extends StatelessWidget {
  final List<StudentGrade> gradebook;

  const DocenteGradesKpisRow({super.key, required this.gradebook});

  @override
  Widget build(BuildContext context) {
    final total = gradebook.length;
    final approved = gradebook
        .where((g) => g.status == AcademicStatus.aprovado)
        .length;
    final exam = gradebook
        .where((g) => g.status == AcademicStatus.exame)
        .length;
    final absentFails = gradebook
        .where((g) => g.status == AcademicStatus.reprovadoPorFalta)
        .length;
    final avg = total > 0
        ? gradebook.fold(0.0, (acc, g) => acc + g.finalAverage) / total
        : 0.0;

    return Row(
      children: [
        _buildStatCard(
          'Total de Discentes',
          '$total',
          Icons.groups_outlined,
          DocenteColors.charcoal,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Média da Turma',
          avg.toStringAsFixed(1),
          Icons.bar_chart_rounded,
          DocenteColors.emerald,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Aprovados Estimados',
          '$approved',
          Icons.check_circle_outline,
          DocenteColors.emerald,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Em Exame',
          '$exam',
          Icons.help_outline_rounded,
          DocenteColors.amber,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Reprovados Falta',
          '$absentFails',
          Icons.warning_amber_rounded,
          DocenteColors.crimson,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DocenteColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DocenteColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DocenteColors.charcoal,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: DocenteColors.slate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
