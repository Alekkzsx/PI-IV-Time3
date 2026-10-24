// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';

/// Barra de filtros de status para protocolos da Secretaria Acadêmica
class SecretaryFilterBar extends StatelessWidget {
  final AdminPortalController controller;

  const SecretaryFilterBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      'Todos Os Protocolos',
      'Aguardando Parecer',
      'Deferidos',
      'Indeferidos',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((f) {
        final isSelected = controller.protocolFilter == f ||
            (controller.protocolFilter == 'Todos' &&
                f == 'Todos Os Protocolos') ||
            (controller.protocolFilter == 'Aguardando' &&
                f == 'Aguardando Parecer') ||
            (controller.protocolFilter == 'Deferido' && f == 'Deferidos') ||
            (controller.protocolFilter == 'Indeferido' && f == 'Indeferidos');

        return InkWell(
          onTap: () => controller.setProtocolFilter(f),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF18181B)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              f,
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
  }
}
