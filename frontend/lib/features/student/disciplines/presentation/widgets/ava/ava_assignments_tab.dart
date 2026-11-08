// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'common/ava_common.dart';
import 'tabs/components/ava_assignment_item_card.dart';

/// [AvaAssignmentsTab]
///
/// Aba 1 do Cockpit AVA: Tarefas e Atividades.
/// Apresenta o cabeçalho canônico [AvaOpenSectionHeader], a barra de filtros
/// em pílula [AvaFilterPillBar] ('Todas', 'Pendentes', 'Em Análise', 'Avaliadas')
/// com contadores em tempo real e delega cada tarefa para [AvaAssignmentItemCard].
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
  String _selectedFilter = 'Todas';

  static const List<String> _filterOptions = [
    'Todas',
    'Pendentes',
    'Em Análise',
    'Avaliadas',
  ];

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
    final inAnalysisList = activities
        .where((a) => a.status == 'Em Análise')
        .toList();
    final evaluatedList = activities
        .where((a) => a.status == 'Avaliada')
        .toList();

    final filteredActivities = switch (_selectedFilter) {
      'Pendentes' => pendingList,
      'Em Análise' => inAnalysisList,
      'Avaliadas' => evaluatedList,
      _ => activities,
    };

    final counts = <String, int>{
      'Todas': activities.length,
      'Pendentes': pendingList.length,
      'Em Análise': inAnalysisList.length,
      'Avaliadas': evaluatedList.length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvaOpenSectionHeader(
          title: 'Tarefas e Entregas',
          subtitle:
              'Acompanhe prazos regimentais, envie seus arquivos e confira as notas atribuídas pelo professor.',
          trailing: AvaFilterPillBar(
            options: _filterOptions,
            selected: _selectedFilter,
            counts: counts,
            onSelected: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
        ),
        const SizedBox(height: 20),

        if (filteredActivities.isEmpty)
          const AvaEmptyStateCard(
            icon: Icons.assignment_outlined,
            title: 'Nenhuma tarefa encontrada para este filtro.',
            subtitle:
                'Altere a pílula de filtro selecionada acima para visualizar outras atividades da disciplina.',
          )
        else
          for (final activity in filteredActivities)
            AvaAssignmentItemCard(activity: activity),
      ],
    );
  }
}
