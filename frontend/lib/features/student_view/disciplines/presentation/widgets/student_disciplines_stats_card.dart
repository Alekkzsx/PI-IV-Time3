// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';

/// Card consolidado com estatísticas gerais do estudante (Carga Horária, Média e Frequência).
class StudentDisciplinesStatsCard extends StatelessWidget {
  const StudentDisciplinesStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Carga Horária do Semestre',
              '190h / 280h cursadas (68%)',
              Icons.timelapse_outlined,
              const Color(0xFF18181B),
            ),
          ),
          Container(width: 1, height: 48, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: _buildStatItem(
              'Média Ponderada Consolidada',
              '8.63 / 10.0',
              Icons.analytics_outlined,
              const Color(0xFF16A34A),
            ),
          ),
          Container(width: 1, height: 48, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: _buildStatItem(
              'Frequência Global Registrada',
              '95.7% (12 faltas acumuladas)',
              Icons.check_circle_outline,
              const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18181B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
