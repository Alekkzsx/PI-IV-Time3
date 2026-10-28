// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Item de filtro para o seletor de abas/chips horizontais.
class AcademicFilterOption<T> {
  final T value;
  final String label;
  final int? count;

  const AcademicFilterOption({
    required this.value,
    required this.label,
    this.count,
  });
}

/// Barra de busca universal integrada com seletor de filtros/chips horizontais e botão de ação.
class AcademicSearchFilterBar<T> extends StatelessWidget {
  final TextEditingController? searchController;
  final String hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final List<AcademicFilterOption<T>>? filterOptions;
  final T? selectedFilter;
  final ValueChanged<T>? onFilterSelected;
  final Widget? trailingAction;
  final EdgeInsetsGeometry padding;

  const AcademicSearchFilterBar({
    super.key,
    this.searchController,
    this.hintText = 'Pesquisar...',
    this.onSearchChanged,
    this.onSearchClear,
    this.filterOptions,
    this.selectedFilter,
    this.onFilterSelected,
    this.trailingAction,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: InstColors.border),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: jakarta(size: 13.5, color: const Color(0xFF18181B)),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: jakarta(size: 13.5, color: const Color(0xFFA1A1AA)),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Color(0xFF71717A),
                      ),
                      suffixIcon: searchController != null && searchController!.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Color(0xFF71717A)),
                              onPressed: () {
                                searchController!.clear();
                                onSearchClear?.call();
                                onSearchChanged?.call('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
              if (trailingAction != null) ...[
                const SizedBox(width: 12),
                trailingAction!,
              ],
            ],
          ),
          if (filterOptions != null && filterOptions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterOptions!.map((option) {
                  final isSelected = selectedFilter == option.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => onFilterSelected?.call(option.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? InstColors.ink : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? InstColors.ink : InstColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              option.label,
                              style: jakarta(
                                size: 12.5,
                                weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF52525B),
                              ),
                            ),
                            if (option.count != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${option.count}',
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
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
