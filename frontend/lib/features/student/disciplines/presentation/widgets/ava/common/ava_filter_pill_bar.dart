// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// [AvaFilterPillBar]
///
/// Barra horizontal rolável de pílulas de filtro do Cockpit AVA.
/// Estado ativo: fundo `#18181B` e texto `#FFFFFF`.
/// Estado inativo: fundo `#FFFFFF`, borda `1px #E5E7EB` e texto `#52525B`.
class AvaFilterPillBar extends StatelessWidget {
  /// Lista de rótulos das opções de filtro.
  final List<String> options;

  /// Opção atualmente selecionada.
  final String selected;

  /// Callback acionado ao selecionar uma opção.
  final ValueChanged<String> onSelected;

  /// Contadores opcionais por opção (ex.: `{'Todas': 4, 'Pendentes': 1}`).
  final Map<String, int>? counts;

  /// Construtor opcional de [Key] para cada pílula.
  final Key Function(String option)? itemKeyBuilder;

  /// Cria uma nova instância de [AvaFilterPillBar].
  const AvaFilterPillBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.counts,
    this.itemKeyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _buildPill(options[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildPill(String option) {
    final isActive = option == selected;
    final count = counts?[option];

    return Material(
      color: isActive ? const Color(0xFF18181B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive ? const Color(0xFF18181B) : const Color(0xFFE5E7EB),
        ),
      ),
      child: InkWell(
        key: itemKeyBuilder?.call(option),
        borderRadius: BorderRadius.circular(20),
        onTap: () => onSelected(option),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                option,
                style: jakarta(
                  size: 12,
                  weight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF52525B),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF3F3F46)
                        : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: jakarta(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFF71717A),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

