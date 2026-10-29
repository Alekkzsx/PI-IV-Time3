// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/deliveries/presentation/widgets/delivery_submission_modal.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';
import 'ava_section_card.dart';

/// Aba do AVA que exibe as atividades avaliativas e o modal de submissão de entregas.
class AvaAssignmentsTab extends StatelessWidget {
  final StudentPortalController controller;
  final String disciplineCode;

  const AvaAssignmentsTab({
    super.key,
    required this.controller,
    required this.disciplineCode,
  });

  @override
  Widget build(BuildContext context) {
    final activities = controller.deliveries
        .where((delivery) => delivery.disciplineCode == disciplineCode)
        .toList();

    return AvaSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atividades Avaliativas da Disciplina',
            style: AvaSectionStyles.title,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhuma atividade publicada para esta disciplina.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ),
            )
          else
            for (var index = 0; index < activities.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              _buildTaskItem(context, activities[index]),
            ],
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, StudentDeliveryItem activity) {
    final isPending = activity.status == 'Pendente';
    final statusColor = switch (activity.status) {
      'Avaliada' => const Color(0xFF16A34A),
      'Em Análise' => const Color(0xFF2563EB),
      _ => const Color(0xFFD97706),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prazo: ${activity.dueDate} às ${activity.dueHour} • Peso ${activity.weight.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isPending)
            ElevatedButton.icon(
              onPressed: () => DeliverySubmissionModal.show(context, activity),
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Enviar Atividade'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                foregroundColor: Colors.white,
              ),
            )
          else
            Chip(
              label: Text(
                activity.status == 'Avaliada' && activity.score != null
                    ? 'Nota ${activity.score!.toStringAsFixed(1)}'
                    : activity.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: statusColor.withValues(alpha: 0.12),
            ),
        ],
      ),
    );
  }
}
