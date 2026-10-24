// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Barra de busca e filtros de perfil para a gestão institucional de usuários.
class UserFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final bool isDesktop;

  const UserFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    const filterOptions = ['Todos', 'Discentes', 'Docentes', 'Administração'];

    final searchBox = Container(
      width: isDesktop ? 360 : double.infinity,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: jakarta(size: 13.5, color: const Color(0xFF18181B)),
        decoration: InputDecoration(
          hintText: 'Buscar por nome, R.A. ou e-mail...',
          hintStyle: jakarta(size: 13, color: const Color(0xFFA3A3A3)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFFA3A3A3),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );

    final filterPills = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filterOptions.map((p) {
        final isSelected = activeFilter == p;
        return InkWell(
          onTap: () => onFilterChanged(p),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF18181B)
                    : const Color(0xFFE5E5E5),
              ),
            ),
            child: Text(
              p,
              style: jakarta(
                size: 13,
                weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF525252),
              ),
            ),
          ),
        );
      }).toList(),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                searchBox,
                filterPills,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchBox,
                const SizedBox(height: 12),
                filterPills,
              ],
            ),
    );
  }
}
