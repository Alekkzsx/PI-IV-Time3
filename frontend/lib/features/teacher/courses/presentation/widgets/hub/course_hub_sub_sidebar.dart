// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

class _SubNavItem {
  final int index;
  final String label;
  final IconData icon;
  final String section;

  const _SubNavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.section,
  });
}

/// Navegação contextual lateral interna da Sala de Aula (AVA Docente).
class CourseHubSubSidebar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelectTab;
  final double attendancePercentage;
  final double averageGrade;
  final bool hasAnyGrades;
  final int pendingSubmissionsCount;
  final int openTopicsCount;

  const CourseHubSubSidebar({
    super.key,
    required this.activeIndex,
    required this.onSelectTab,
    required this.attendancePercentage,
    required this.averageGrade,
    required this.hasAnyGrades,
    required this.pendingSubmissionsCount,
    this.openTopicsCount = 0,
  });

  static const List<_SubNavItem> _items = [
    _SubNavItem(
      index: 0,
      label: 'Visão Geral & Mural',
      icon: Icons.dashboard_outlined,
      section: 'SALA DE AULA',
    ),
    _SubNavItem(
      index: 1,
      label: 'Módulos & Conteúdos',
      icon: Icons.layers_outlined,
      section: 'SALA DE AULA',
    ),
    _SubNavItem(
      index: 2,
      label: 'Tarefas & Submissões',
      icon: Icons.assignment_turned_in_outlined,
      section: 'SALA DE AULA',
    ),
    _SubNavItem(
      index: 3,
      label: 'Fórum da Turma',
      icon: Icons.forum_outlined,
      section: 'SALA DE AULA',
    ),
    _SubNavItem(
      index: 4,
      label: 'Diário de Presença',
      icon: Icons.fact_check_outlined,
      section: 'GESTÃO ACADÊMICA',
    ),
    _SubNavItem(
      index: 5,
      label: 'Livro de Notas (Gradebook)',
      icon: Icons.grading_outlined,
      section: 'GESTÃO ACADÊMICA',
    ),
    _SubNavItem(
      index: 6,
      label: 'Alunos Matriculados',
      icon: Icons.people_outline,
      section: 'GESTÃO ACADÊMICA',
    ),
    _SubNavItem(
      index: 7,
      label: 'Plano de Ensino',
      icon: Icons.menu_book_outlined,
      section: 'PLANEJAMENTO & PROJETOS',
    ),
    _SubNavItem(
      index: 8,
      label: 'Equipes de Projeto',
      icon: Icons.groups_outlined,
      section: 'PLANEJAMENTO & PROJETOS',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final sections = <String, List<_SubNavItem>>{};
    for (final item in _items) {
      (sections[item.section] ??= []).add(item);
    }

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final navList = Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in sections.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(9, 4, 9, 1),
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(
                        size: 9.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFFA1A1AA),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  for (final item in entry.value) _buildNavItem(item),
                  const SizedBox(height: 1),
                ],
              ],
            ),
          );

          final classPanel = _buildRealClassPanel();

          // On compact vertical viewports, scroll nav items and summary together
          // so bottom links can never get obscured behind a pinned card.
          if (!constraints.hasBoundedHeight || constraints.maxHeight < 470) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [navList, classPanel],
              ),
            );
          }

          return Column(
            children: [
              Expanded(child: SingleChildScrollView(child: navList)),
              classPanel,
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem(_SubNavItem item) {
    final isActive = activeIndex == item.index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: InkWell(
        onTap: () => onSelectTab(item.index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFAF8F5) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFFE5E7EB) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 15,
                color: isActive ? InstColors.ink : const Color(0xFF71717A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 12,
                    weight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? InstColors.ink
                        : const Color(0xFF52525B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealClassPanel() {
    final attendanceColor = attendancePercentage >= 85.0
        ? const Color(0xFF166534)
        : attendancePercentage >= 75.0
            ? const Color(0xFFB45309)
            : const Color(0xFFB91C1C);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PAINEL DA TURMA',
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 10,
                    weight: FontWeight.w700,
                    color: const Color(0xFF71717A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.trending_up_rounded,
                size: 14,
                color: Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _metricRow(
            'Assiduidade:',
            '${attendancePercentage.toStringAsFixed(1)}%',
            attendanceColor,
          ),
          const SizedBox(height: 3),
          _metricRow(
            'Média:',
            hasAnyGrades ? averageGrade.toStringAsFixed(1) : '—',
            InstColors.ink,
          ),
          const SizedBox(height: 3),
          _metricRow(
            'Correções:',
            pendingSubmissionsCount == 0
                ? 'Em dia'
                : '$pendingSubmissionsCount pend.',
            pendingSubmissionsCount == 0
                ? const Color(0xFF166534)
                : const Color(0xFFB45309),
          ),
          if (openTopicsCount > 0) ...[
            const SizedBox(height: 3),
            _metricRow(
              'Fórum:',
              '$openTopicsCount aberto${openTopicsCount == 1 ? '' : 's'}',
              const Color(0xFF1D4ED8),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: jakarta(size: 11.5, weight: FontWeight.w700, color: valueColor),
        ),
      ],
    );
  }
}

/// Barra horizontal compacta para telas < 900px no AVA Docente.
class CourseHubCompactTabBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelectTab;

  const CourseHubCompactTabBar({
    super.key,
    required this.activeIndex,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8F5),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        itemCount: CourseHubSubSidebar._items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final item = CourseHubSubSidebar._items[idx];
          final selected = activeIndex == item.index;
          return InkWell(
            onTap: () => onSelectTab(item.index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF18181B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF18181B)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 13,
                    color: selected ? Colors.white : const Color(0xFF52525B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: jakarta(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color:
                          selected ? Colors.white : const Color(0xFF52525B),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
