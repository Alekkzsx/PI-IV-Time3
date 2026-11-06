// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../../shared/data/student_remote_data_source.dart';

/// Visão em linha/lista cronológica do Painel Geral do Aluno.
///
/// Renderiza a timeline acadêmica validada e gerada pelo backend MongoDB,
/// incluindo cabeçalhos por data, entregas, fóruns, materiais, o intervalo de 45 dias
/// com o Sir Nicolau (exibido estritamente uma única vez) e os marcos institucionais.
class StudentDashboardListView extends StatefulWidget {
  final StudentDashboardSnapshot dashboard;
  final StudentTimelineResponse? timeline;

  const StudentDashboardListView({
    super.key,
    required this.dashboard,
    this.timeline,
  });

  @override
  State<StudentDashboardListView> createState() => _StudentDashboardListViewState();
}

class _StudentDashboardListViewState extends State<StudentDashboardListView> {
  // Controle local para interação do checkbox visual em tempo de execução
  final Map<String, bool> _completedOverrides = {};

  @override
  Widget build(BuildContext context) {
    if (widget.timeline != null && widget.timeline!.blocks.isNotEmpty) {
      return _buildTimelineBlocks(widget.timeline!.blocks);
    }

    return _buildFallbackList();
  }

  // -------------------------------------------------------------
  // RENDERIZAÇÃO OFICIAL VIA BACKEND TIMELINE BLOCKS
  // -------------------------------------------------------------
  Widget _buildTimelineBlocks(List<StudentTimelineBlock> blocks) {
    final widgets = <Widget>[];

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      switch (block.type) {
        case 'day':
          widgets.add(_buildDateHeader(block.label));
          widgets.add(const SizedBox(height: 14));
          for (final item in block.items) {
            widgets.add(_buildTimelineItemRow(item));
            widgets.add(const SizedBox(height: 14));
          }
          widgets.add(const SizedBox(height: 10));
          break;

        case 'gap':
          widgets.add(_buildDateHeader(block.label));
          if (block.mascot) {
            widgets.add(const SizedBox(height: 36));
            widgets.add(_buildNicolauMascot(block.message));
            widgets.add(const SizedBox(height: 36));
          }
          break;

        case 'milestone':
          widgets.add(_buildDateHeader(block.label));
          widgets.add(const SizedBox(height: 14));
          widgets.add(
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  block.description,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
          widgets.add(const SizedBox(height: 24));
          break;
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
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
            size: 13.5,
            weight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
      ],
    );
  }

  Widget _buildTimelineItemRow(StudentTimelineItem item) {
    final isCompleted = _completedOverrides[item.id] ?? item.completed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox quadrado com cantos arredondados (16x16)
          GestureDetector(
            onTap: () {
              setState(() {
                _completedOverrides[item.id] = !isCompleted;
              });
            },
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2.5),
                border: Border.all(
                  color: isCompleted ? const Color(0xFF18181B) : const Color(0xFFD4D4D8),
                  width: 1.5,
                ),
                color: isCompleted ? const Color(0xFF18181B) : Colors.transparent,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Ícone temático: Documento ou Fórum
          Icon(
            item.kind == 'forum'
                ? Icons.chat_bubble_outline_rounded
                : Icons.description_outlined,
            size: 16,
            color: const Color(0xFF52525B),
          ),
          const SizedBox(width: 12),

          // Título e Subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Trailing: Deadline com ícone de relógio ou Texto livre
          if (item.trailingType == 'deadline')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(width: 4),
                Text(
                  item.trailingText,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            )
          else
            Text(
              item.trailingText,
              style: jakarta(
                size: 11,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNicolauMascot([String? message]) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Image.asset(
          'images/SirNicolau.png',
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.golf_course_rounded,
            size: 140,
            color: Color(0xFFA1A1AA),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // FALLBACK PARA COMPATIBILIDADE QUANDO TIMELINE FOR NULA
  // -------------------------------------------------------------
  Widget _buildFallbackList() {
    final rawItems = <_FallbackItem>[
      for (final delivery in widget.dashboard.deliveries)
        _FallbackItem(
          id: delivery.id,
          dateHeader: delivery.dueDate,
          title: delivery.title,
          subtitle: '${delivery.disciplineName} • ${delivery.professor ?? ""}',
          status: delivery.status == 'Pendente'
              ? 'até ${delivery.dueHour}'
              : (delivery.status == 'Avaliada' ? 'Concluído' : delivery.status),
          hasClockIcon: delivery.status == 'Pendente',
          isCompleted: delivery.status == 'Avaliada',
        ),
      for (final event in widget.dashboard.events)
        _FallbackItem(
          id: event.id,
          dateHeader: event.date,
          title: event.title,
          subtitle: '${event.discipline} • ${event.location}',
          status: event.time,
          hasClockIcon: event.time.toLowerCase().contains('até'),
          isCompleted: false,
        ),
    ];

    if (rawItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Nenhuma atividade ou aula cadastrada.')),
      );
    }

    final groups = <String, List<_FallbackItem>>{};
    for (final item in rawItems) {
      groups.putIfAbsent(item.dateHeader, () => []).add(item);
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(_buildDateHeader(entry.key));
      widgets.add(const SizedBox(height: 14));
      for (final item in entry.value) {
        widgets.add(_buildFallbackItemRow(item));
        widgets.add(const SizedBox(height: 14));
      }
      widgets.add(const SizedBox(height: 10));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  Widget _buildFallbackItemRow(_FallbackItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.5),
              border: Border.all(
                color: item.isCompleted ? const Color(0xFF18181B) : const Color(0xFFD4D4D8),
                width: 1.5,
              ),
              color: item.isCompleted ? const Color(0xFF18181B) : Colors.transparent,
            ),
            child: item.isCompleted
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.description_outlined,
            size: 16,
            color: Color(0xFF52525B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            item.status,
            style: jakarta(
              size: 11,
              weight: FontWeight.w400,
              color: const Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackItem {
  final String id;
  final String dateHeader;
  final String title;
  final String subtitle;
  final String status;
  final bool hasClockIcon;
  final bool isCompleted;

  const _FallbackItem({
    required this.id,
    required this.dateHeader,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.hasClockIcon,
    required this.isCompleted,
  });
}
