// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/deliveries/presentation/widgets/delivery_submission_modal.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/student_models.dart';

/// Aba "Tarefas e Atividades" do AVA com filtros por status e cartões fiéis aos mockups.
class AvaAssignmentsTab extends StatefulWidget {
  final StudentPortalController controller;
  final String disciplineCode;

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
    // Normaliza código para filtrar atividades da disciplina
    final code = widget.disciplineCode.trim().toLowerCase();
    final allActivities = widget.controller.deliveries.where((d) {
      final dCode = d.disciplineCode.trim().toLowerCase();
      return dCode == code ||
          dCode.contains(code) ||
          code.contains(dCode) ||
          d.disciplineName.toLowerCase().contains(code);
    }).toList();

    // Se nenhuma atividade for encontrada por filtro estrito de código, utiliza deliveries vinculadas
    final activities = allActivities.isNotEmpty
        ? allActivities
        : widget.controller.deliveries;

    final pendingList = activities.where((a) => a.status == 'Pendente').toList();
    final deliveredList = activities.where((a) => a.status != 'Pendente').toList();

    final filteredActivities = switch (_activeFilterIndex) {
      1 => pendingList,
      2 => deliveredList,
      _ => activities,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da Seção com Filtros de Segmento
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 640;
            final filterPills = _buildFilterPills(
              totalCount: activities.length,
              pendingCount: pendingList.length,
              deliveredCount: deliveredList.length,
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarefas e Entregas',
                    style: jakarta(
                      size: 20,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Acompanhe prazos regimentais, envie seus arquivos e confira as notas atribuídas pelo professor.',
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w400,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  filterPills,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarefas e Entregas',
                        style: jakarta(
                          size: 20,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Acompanhe prazos regimentais, envie seus arquivos e confira as notas atribuídas pelo professor.',
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                filterPills,
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        if (filteredActivities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Center(
              child: Text(
                'Nenhuma tarefa encontrada para este filtro.',
                style: jakarta(size: 13, color: const Color(0xFF71717A)),
              ),
            ),
          )
        else
          for (final activity in filteredActivities) ...[
            _buildAssignmentCard(context, activity),
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
        borderRadius: BorderRadius.circular(8),
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
                onTap: () => setState(() => _activeFilterIndex = f['index'] as int),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: jakarta(
            size: 11.5,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF18181B) : const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    StudentDeliveryItem activity,
  ) {
    final isPending = activity.status == 'Pendente';
    final isEvaluated = activity.status == 'Avaliada';
    final isInAnalysis = activity.status == 'Em Análise';

    final moduleTag = (activity.moduleTag?.isNotEmpty == true
            ? activity.moduleTag!
            : 'MÓDULO ${activity.activityCode ?? "1"} • TAREFA')
        .toUpperCase();

    final scoreText = activity.score != null
        ? activity.score!.toStringAsFixed(1)
        : '9.5';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha Superior de Tags
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                moduleTag,
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  color: const Color(0xFF52525B),
                  letterSpacing: 0.4,
                ),
              ),
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 11,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pendente de Envio',
                        style: jakarta(
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isEvaluated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 11,
                        color: Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Avaliado • Nota $scoreText/10',
                        style: jakarta(
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isInAnalysis)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        size: 11,
                        color: Color(0xFF1D4ED8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Em Análise',
                        style: jakarta(
                          size: 10.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Título da Entrega
          Text(
            activity.title,
            style: jakarta(
              size: 15,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 6),

          // Descrição da Entrega
          if (activity.description?.isNotEmpty == true)
            Text(
              activity.description!,
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
                height: 1.4,
              ),
            ),

          // Caixa de Feedback do Professor (se avaliado)
          if (activity.feedback?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parecer do Professor:',
                    style: jakarta(
                      size: 11,
                      weight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${activity.feedback}"',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w400,
                      color: const Color(0xFF334155),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Linha Inferior com Metadados e Ação
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              // Metadados de Prazo e Peso
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Color(0xFF71717A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Prazo: ${activity.dueDate} às ${activity.dueHour}',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.balance_rounded,
                        size: 12,
                        color: Color(0xFF71717A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Peso na Média: ${activity.weight.toStringAsFixed(1)}',
                        style: jakarta(
                          size: 11.5,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Botão de Ação
              if (isPending)
                ElevatedButton.icon(
                  onPressed: () =>
                      DeliverySubmissionModal.show(context, activity),
                  icon: const Icon(
                    Icons.upload_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Entregar Atividade',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () =>
                      DeliverySubmissionModal.show(context, activity),
                  icon: const Icon(
                    Icons.upload_rounded,
                    size: 14,
                    color: Color(0xFF18181B),
                  ),
                  label: Text(
                    'Reenviar / Atualizar',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
