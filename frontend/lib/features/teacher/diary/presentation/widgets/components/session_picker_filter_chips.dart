// Desenvolvido por Marcelo Zarpelon - RA: 25015323
// Componente atômico para filtros de status de sessões de aula

import 'package:flutter/material.dart';

class SessionPickerFilterChips extends StatelessWidget {
  final int selectedIndex;
  final int totalCount;
  final int homologatedCount;
  final int pendingCount;
  final ValueChanged<int> onSelected;

  const SessionPickerFilterChips({
    super.key,
    required this.selectedIndex,
    required this.totalCount,
    required this.homologatedCount,
    required this.pendingCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(0, 'Todas ($totalCount)'),
        _buildChip(1, 'Homologadas ($homologatedCount)'),
        _buildChip(2, 'Aguardando ($pendingCount)'),
      ],
    );
  }

  Widget _buildChip(int index, String label) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onSelected(index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18181B) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF18181B)
                : const Color(0xFFE4E4E7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }
}
