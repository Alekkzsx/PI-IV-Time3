// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../domain/entities/academic_message.dart';

/// Barra de controles para filtragem por categoria e busca textual na Central de Mensagens.
class MessageFilterBar extends StatelessWidget {
  /// Categoria de filtro atualmente selecionada.
  final MessageFilter activeFilter;

  /// Callback disparado quando o aluno seleciona uma categoria de filtro.
  final ValueChanged<MessageFilter> onFilterChanged;

  /// Callback disparado durante a digitação na caixa de busca.
  final ValueChanged<String> onSearchChanged;

  /// Controlador opcional para o campo de texto de busca.
  final TextEditingController? searchController;

  /// Cria uma instância de [MessageFilterBar].
  const MessageFilterBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        // Abas de Filtro Rápido
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              key: const Key('filter_all'),
              label: 'Todos Os Comunicados',
              isSelected: activeFilter == MessageFilter.all,
              onTap: () => onFilterChanged(MessageFilter.all),
            ),
            _buildFilterChip(
              key: const Key('filter_institutional'),
              label: 'Secretaria & Reitoria',
              isSelected: activeFilter == MessageFilter.institutional,
              onTap: () => onFilterChanged(MessageFilter.institutional),
            ),
            _buildFilterChip(
              key: const Key('filter_discipline'),
              label: 'Disciplinas',
              isSelected: activeFilter == MessageFilter.discipline,
              onTap: () => onFilterChanged(MessageFilter.discipline),
            ),
          ],
        ),
        // Campo de Busca Textual
        SizedBox(
          width: 260,
          height: 36,
          child: TextField(
            key: const Key('messages_search_input'),
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF18181B),
            ),
            decoration: InputDecoration(
              hintText: 'Buscar por termo ou docente...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 34,
                minHeight: 34,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF18181B),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFF18181B) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF18181B)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF52525B),
            ),
          ),
        ),
      ),
    );
  }
}
