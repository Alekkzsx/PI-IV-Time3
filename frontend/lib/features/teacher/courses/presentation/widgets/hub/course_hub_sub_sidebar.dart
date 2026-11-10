// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Barra lateral de navegação interna da disciplina na visão do docente

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Barra lateral de navegação interna da disciplina na visão do docente.
class CourseHubSubSidebar extends StatelessWidget {
  final int activeTabIndex;
  final ValueChanged<int> onTabSelected;
  final List<Map<String, dynamic>> items;

  const CourseHubSubSidebar({
    super.key,
    required this.activeTabIndex,
    required this.onTabSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: InstColors.surface,
        border: Border(right: BorderSide(color: InstColors.border)),
      ),
      child: Column(
        children: [
          // Seção Superior: Menu de Abas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == activeTabIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () => onTabSelected(index),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? InstColors.stoneActive
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? InstColors.ink
                                : InstColors.muted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: jakarta(
                                size: 12,
                                weight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? InstColors.ink
                                    : const Color(0xFF27272A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item['badge'] != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : (item['badgeColor'] as Color? ??
                                          const Color(0xFFF4F4F5)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item['badge'] as String,
                                style: jakarta(
                                  size: 9.5,
                                  weight: FontWeight.w700,
                                  color: isSelected
                                      ? InstColors.ink
                                      : (item['badgeTextColor'] as Color? ??
                                            InstColors.muted),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Widget Inferior: Card Rápido de Saúde da Turma
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: InstColors.stone,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: InstColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PAINEL DA TURMA',
                        style: jakarta(
                          size: 10,
                          weight: FontWeight.w700,
                          color: InstColors.muted,
                          letterSpacing: 0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.insights, size: 13, color: InstColors.success),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Assiduidade:',
                        style: jakarta(
                          size: 11,
                          color: InstColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '94.8%',
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w700,
                        color: InstColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Média:',
                        style: jakarta(
                          size: 11,
                          color: InstColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '7.8',
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Envios:',
                        style: jakarta(
                          size: 11,
                          color: InstColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '6 pend.',
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w700,
                        color: InstColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
