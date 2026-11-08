// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// [AvaEmptyStateCard]
///
/// Componente padronizado para estados vazios no Cockpit AVA quando uma disciplina
/// não possui registros no banco de dados (materiais, tópicos de fórum, módulos ou tarefas).
class AvaEmptyStateCard extends StatelessWidget {
  /// Ícone ilustrativo do estado vazio.
  final IconData icon;

  /// Título principal do estado vazio.
  final String title;

  /// Subtítulo orientativo opcional.
  final String? subtitle;

  /// Cria uma nova instância de [AvaEmptyStateCard].
  const AvaEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: const Color(0xFFA1A1AA)),
          const SizedBox(height: 12),
          Text(
            title,
            style: jakarta(
              size: 14,
              weight: FontWeight.w600,
              color: const Color(0xFF18181B),
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: jakarta(size: 12, color: const Color(0xFF71717A)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
