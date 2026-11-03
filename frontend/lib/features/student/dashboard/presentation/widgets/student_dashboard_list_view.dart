// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../../shared/data/student_remote_data_source.dart';

enum StudentListItemType {
  document,
  forum,
}

class StudentListItemData {
  final String id;
  final StudentListItemType type;
  final String title;
  final String dateHeader;
  final String subtitle;
  final String status;
  final bool hasClockIcon;
  final bool initialCompleted;

  const StudentListItemData({
    required this.id,
    required this.type,
    required this.title,
    required this.dateHeader,
    required this.subtitle,
    required this.status,
    this.hasClockIcon = false,
    this.initialCompleted = false,
  });
}

/// Visão em lista cronológica (Timeline/Agenda) do Painel Geral do Aluno.
///
/// Exibe o histórico de entregas, fóruns e materiais por data, prazos imediatos,
/// o estado vazio com o mascote oficial Sir Nicolau e os marcos semestrais até 2027.
class StudentDashboardListView extends StatefulWidget {
  final StudentDashboardSnapshot dashboard;

  const StudentDashboardListView({super.key, required this.dashboard});

  @override
  State<StudentDashboardListView> createState() => _StudentDashboardListViewState();
}

class _StudentDashboardListViewState extends State<StudentDashboardListView> {
  @override
  Widget build(BuildContext context) {
    final items = <StudentListItemData>[
      for (final delivery in widget.dashboard.deliveries)
        StudentListItemData(
          id: delivery.id,
          type: StudentListItemType.document,
          dateHeader: delivery.dueDate,
          title: delivery.title,
          subtitle: '${delivery.disciplineName} • ${delivery.professor ?? ""}',
          status: delivery.status,
          hasClockIcon: delivery.status == 'Pendente',
          initialCompleted: delivery.status == 'Avaliada',
        ),
      for (final event in widget.dashboard.events)
        StudentListItemData(
          id: event.id,
          type: event.type.toLowerCase().contains('fórum')
              ? StudentListItemType.forum
              : StudentListItemType.document,
          dateHeader: _formatDate(event.date),
          title: event.title,
          subtitle: '${event.discipline} • ${event.location}',
          status: event.time,
          hasClockIcon: true,
        ),
    ]..sort((first, second) => first.dateHeader.compareTo(second.dateHeader));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Nenhuma atividade ou aula cadastrada.')),
            )
          else
            for (var index = 0; index < items.length; index++) ...[
              if (index == 0 || items[index].dateHeader != items[index - 1].dateHeader) ...[
                _buildDateHeader(items[index].dateHeader),
                const SizedBox(height: 14),
              ],
              _buildTaskItem(items[index]),
              const SizedBox(height: 20),
            ],
        ],
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: jakarta(
            size: 14,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
      ],
    );
  }

  Widget _buildTaskItem(StudentListItemData item) {
    final isCompleted = item.initialCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox quadrado (preenchido com check quando concluído, contorno quando pendente)
          Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isCompleted ? const Color(0xFF18181B) : const Color(0xFFD4D4D8),
                  width: 1.5,
                ),
                color: isCompleted ? const Color(0xFF18181B) : Colors.transparent,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
          ),
          const SizedBox(width: 12),

          // Ícone temático: Documento ou Fórum
          Icon(
            item.type == StudentListItemType.document
                ? Icons.description_outlined
                : Icons.chat_bubble_outline_rounded,
            size: 18,
            color: const Color(0xFF52525B),
          ),
          const SizedBox(width: 12),

          // Título e identificador da disciplina / docente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Status / Horário à direita
          if (item.hasClockIcon)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(width: 4),
                Text(
                  item.status,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            )
          else
            Text(
              item.status,
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

}
