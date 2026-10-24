// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/shared/widgets/academic_status_badge.dart';

/// Aba de Tarefas, Trabalhos & Submissões do curso no Portal Docente.
class CourseHubAssignmentsTab extends StatelessWidget {
  final VoidCallback? onNewAssignment;
  final ValueChanged<String>? onGradeAssignment;

  const CourseHubAssignmentsTab({
    super.key,
    this.onNewAssignment,
    this.onGradeAssignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarefas, Trabalhos & Submissões',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF09090B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Acompanhe os envios dos estudantes, atribua notas e faça apontamentos de rubricas.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (onNewAssignment != null) {
                  onNewAssignment!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Abrindo assistente de nova tarefa...'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text(
                'Nova Atividade',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildAssignmentCardItem(
          context: context,
          title: 'Entrega da Sprint 1: Diagrama de Classes e Sequência do AVA',
          deadline: 'Hoje às 23:59',
          submitted: 28,
          total: 34,
          graded: 18,
          isUrgent: true,
          onTap: () => onGradeAssignment?.call('Entrega da Sprint 1'),
        ),
        const SizedBox(height: 12),
        _buildAssignmentCardItem(
          context: context,
          title: 'Fórum Temático: Arquitetura de Software e Padrões de Projeto',
          deadline: '21/09 às 18:00',
          submitted: 34,
          total: 34,
          graded: 34,
          isUrgent: false,
          onTap: () => onGradeAssignment?.call('Fórum Temático'),
        ),
        const SizedBox(height: 12),
        _buildAssignmentCardItem(
          context: context,
          title: 'Exercício 01: Mapeamento de Requisitos e Casos de Uso',
          deadline: '05/09 às 23:59',
          submitted: 32,
          total: 34,
          graded: 32,
          isUrgent: false,
          onTap: () => onGradeAssignment?.call('Exercício 01'),
        ),
      ],
    );
  }

  static Widget _buildAssignmentCardItem({
    required BuildContext context,
    required String title,
    required String deadline,
    required int submitted,
    required int total,
    required int graded,
    required bool isUrgent,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      const AcademicStatusBadge(
                        label: 'Correção Pendente',
                        type: AcademicStatusType.pendente,
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Prazo: $deadline • $submitted de $total alunos entregaram • $graded corrigidos',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed:
                onTap ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Abrindo submissões para correção: $title'),
                    ),
                  );
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Avaliar Submissões',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
