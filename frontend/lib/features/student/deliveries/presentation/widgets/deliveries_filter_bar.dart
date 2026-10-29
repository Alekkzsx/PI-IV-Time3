// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';

/// Barra de filtros e pesquisa da Central de Entregas do Aluno.
/// Contém as abas com contadores por status, campo de busca textual e dropdown por disciplina.
class DeliveriesFilterBar extends StatelessWidget {
  final String activeTab; // 'Todas', 'Pendente', 'Em Análise', 'Avaliada'
  final int totalCount;
  final int pendingCount;
  final int inReviewCount;
  final int evaluatedCount;
  final ValueChanged<String> onTabChanged;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String selectedDiscipline;
  final List<String> disciplinesList;
  final ValueChanged<String> onDisciplineChanged;

  const DeliveriesFilterBar({
    super.key,
    required this.activeTab,
    required this.totalCount,
    required this.pendingCount,
    required this.inReviewCount,
    required this.evaluatedCount,
    required this.onTabChanged,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedDiscipline,
    required this.disciplinesList,
    required this.onDisciplineChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Linha de Abas de Status com Contadores
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTabItem(
                key: 'Todas',
                label: 'Todas as Atividades',
                count: totalCount,
              ),
              const SizedBox(width: 24),
              _buildTabItem(
                key: 'Pendente',
                label: 'Pendentes',
                count: pendingCount,
              ),
              const SizedBox(width: 24),
              _buildTabItem(
                key: 'Em Análise',
                label: 'Em Análise / Enviadas',
                count: inReviewCount,
              ),
              const SizedBox(width: 24),
              _buildTabItem(
                key: 'Avaliada',
                label: 'Avaliadas com Nota',
                count: evaluatedCount,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Linha de Busca e Seleção de Disciplina
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 720;

            if (isNarrow) {
              return Column(
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildDisciplineDropdown(),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildSearchField(),
                ),
                const SizedBox(width: 16),
                _buildDisciplineDropdown(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabItem({
    required String key,
    required String label,
    required int count,
  }) {
    final isSelected = activeTab == key;

    return InkWell(
      onTap: () => onTabChanged(key),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Buscar por título, código ou palavra-chave...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () => onSearchChanged(''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDisciplineDropdown() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          const Text(
            'Disciplina:',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedDiscipline,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              onChanged: (val) {
                if (val != null) onDisciplineChanged(val);
              },
              items: disciplinesList.map((d) {
                return DropdownMenuItem<String>(
                  value: d,
                  child: Text(d),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
