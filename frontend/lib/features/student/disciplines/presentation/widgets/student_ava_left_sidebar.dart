// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Menu lateral de navegação vertical interna da disciplina no AVA.
/// Reproduz fielmente os 11 itens pedagógicos com pills de status e contadores de badge.
class StudentAvaLeftSidebar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelectTab;

  const StudentAvaLeftSidebar({
    super.key,
    required this.activeIndex,
    required this.onSelectTab,
  });

  static const List<Map<String, dynamic>> menuItems = [
    {'title': 'Página inicial', 'badge': null},
    {'title': 'Tarefas e Atividades', 'badge': 1},
    {'title': 'Sala Virtual', 'badge': null},
    {'title': 'Fóruns', 'badge': 2},
    {'title': 'Notas', 'badge': null},
    {'title': 'Pessoas', 'badge': null},
    {'title': 'Arquivos', 'badge': 8},
    {'title': 'Programa', 'badge': null},
    {'title': 'Colaborações', 'badge': null},
    {'title': 'Caderno', 'badge': null},
    {'title': 'Chat', 'badge': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(menuItems.length, (index) {
          final item = menuItems[index];
          final isSelected = activeIndex == index;
          final title = item['title'] as String;
          final badge = item['badge'] as int?;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('btn_ava_tab_${title.replaceAll(' ', '_')}'),
                onTap: () => onSelectTab(index),
                borderRadius: BorderRadius.circular(8),
                hoverColor: const Color(0xFFF4F4F5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF18181B) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 13,
                            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF52525B),
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge.toString(),
                            style: jakarta(
                              size: 11,
                              weight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF71717A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

