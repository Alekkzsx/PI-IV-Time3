import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';

class DocenteDeadlinesNoticesSection extends StatelessWidget {
  final DocenteController controller;

  const DocenteDeadlinesNoticesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _buildCard(
        title: 'Prazos e Entregas',
        emptyMessage: 'Nenhuma atividade cadastrada.',
        children: controller.assignments
            .map(
              (assignment) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(assignment.title),
                subtitle: Text(
                  '${assignment.courseCode} · ${assignment.dueDateFormatted}',
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 24),
      _buildCard(
        title: 'Mensagens e Avisos',
        emptyMessage: 'Nenhum comunicado recebido ou publicado.',
        children: controller.notices
            .take(5)
            .map(
              (notice) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(notice.title),
                subtitle: Text(
                  '${notice.author} · ${notice.targetCourse} · ${notice.publishedAt}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget _buildCard({
    required String title,
    required String emptyMessage,
    required List<Widget> children,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE4E4E7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (children.isEmpty) Text(emptyMessage) else ...children,
      ],
    ),
  );
}
