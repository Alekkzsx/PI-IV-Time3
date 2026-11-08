// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'common/ava_common.dart';
import 'tabs/components/ava_assignment_item_card.dart';

/// [AvaAssignmentsTab]
///
/// Aba 1 do Cockpit AVA: Tarefas e Atividades.
/// Filtra tarefas por status (Todas, Pendentes, Entregues), exibe o cabeçalho
/// responsivo [AvaOpenSectionHeader] e delega cada item para [AvaAssignmentItemCard].
class AvaAssignmentsTab extends StatefulWidget {
  /// Instância do controlador do portal.
  final StudentPortalController controller;

  /// Código da disciplina associada à listagem de atividades.
  final String disciplineCode;

  /// Cria uma nova instância de [AvaAssignmentsTab].
  const AvaAssignmentsTab({
    super.key,
    required this.controller,
    required this.disciplineCode,
  });

  @override
  State<AvaAssignmentsTab> createState() => _AvaAssignmentsTabState();
}

class _AvaAssignmentsTabState extends State<AvaAssignmentsTab> {
  int _activeFilterIndex = 0; // 0: Todas, 1: Pendentes, 2: Entregues

  @override
  Widget build(BuildContext context) {
    final code = widget.disciplineCode.trim().toLowerCase();
    final allActivities = widget.controller.deliveries.where((d) {
      final dCode = d.disciplineCode.trim().toLowerCase();
      return dCode == code ||
          dCode.contains(code) ||
          code.contains(dCode) ||
          d.disciplineName.toLowerCase().contains(code);
    }).toList();

    final activities = allActivities.isNotEmpty
        ? allActivities
        : widget.controller.deliveries;

    final pendingList = activities
        .where((a) => a.status == 'Pendente')
        .toList();
    final deliveredList = activities
        .where((a) => a.status != 'Pendente')
        .toList();

    final filteredActivities = switch (_activeFilterIndex) {
      1 => pendingList,
      2 => deliveredList,
      _ => activities,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvaOpenSectionHeader(
          title: 'Tarefas e Entregas',
          subtitle:
              'Acompanhe prazos regimentais, envie seus arquivos e confira as notas atribuídas pelo professor.',
          trailing: _buildFilterPills(
            totalCount: activities.length,
            pendingCount: pendingList.length,
            deliveredCount: deliveredList.length,
          ),
        ),
        const SizedBox(height: 20),

        if (filteredActivities.isEmpty)
          const AvaEmptyStateCard(
            icon: Icons.assignment_outlined,
            title: 'Nenhuma tarefa encontrada para este filtro.',
            subtitle:
                'Altere o filtro selecionado acima para visualizar outras atividades da disciplina.',
          )
        else
          for (final activity in filteredActivities) ...[
            AvaAssignmentItemCard(activity: activity),
            const SizedBox(height: 16),
          ],
      ],
    );
  }

  Widget _buildFilterPills({
    required int totalCount,
    required int pendingCount,
    required int deliveredCount,
  }) {
    final filters = [
      {'title': 'Todas ($totalCount)', 'index': 0},
      {'title': 'Pendentes ($pendingCount)', 'index': 1},
      {'title': 'Entregues ($deliveredCount)', 'index': 2},
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in filters)
              _buildFilterButton(
                title: f['title'] as String,
                isSelected: _activeFilterIndex == (f['index'] as int),
                onTap: () =>
                    setState(() => _activeFilterIndex = f['index'] as int),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18181B) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: jakarta(
            size: 11.5,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }
}
