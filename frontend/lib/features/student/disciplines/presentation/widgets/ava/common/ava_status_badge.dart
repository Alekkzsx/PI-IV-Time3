// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Variantes semânticas de cor para [AvaStatusBadge].
enum AvaBadgeVariant {
  /// Verde institucional (`#DCFCE7` / `#166534`): Respondido, Consolidado, Matriculado.
  success,

  /// Âmbar (`#FEF3C7` / `#B45309`): Pendente, Em Avaliação.
  warning,

  /// Cinza suave (`#F4F4F5` / `#52525B`): Categorias de materiais, cargos e tags neutras.
  neutral,
}

/// [AvaStatusBadge]
///
/// Pílula ou tag semântica padronizada do Cockpit AVA para exibição de status
/// de tópicos de fórum, categorias de materiais e consolidação de avaliações.
class AvaStatusBadge extends StatelessWidget {
  /// Texto exibido dentro da badge.
  final String label;

  /// Variante semântica de cores.
  final AvaBadgeVariant variant;

  /// Ícone opcional exibido à esquerda do texto.
  final IconData? icon;

  /// Se `true`, usa cantos totalmente arredondados (pílula); caso contrário, raio 6px.
  final bool isPill;

  /// Cria uma nova instância de [AvaStatusBadge].
  const AvaStatusBadge({
    super.key,
    required this.label,
    this.variant = AvaBadgeVariant.neutral,
    this.icon,
    this.isPill = true,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, textColor) = switch (variant) {
      AvaBadgeVariant.success => (
        const Color(0xFFDCFCE7),
        const Color(0xFFBBF7D0),
        const Color(0xFF166534),
      ),
      AvaBadgeVariant.warning => (
        const Color(0xFFFEF3C7),
        const Color(0xFFFDE68A),
        const Color(0xFFB45309),
      ),
      AvaBadgeVariant.neutral => (
        const Color(0xFFF4F4F5),
        const Color(0xFFE4E4E7),
        const Color(0xFF52525B),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        border: variant == AvaBadgeVariant.success
            ? Border.all(color: borderColor)
            : null,
        borderRadius: BorderRadius.circular(isPill ? 12 : 6),
      ),
      child: icon == null
          ? Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: jakarta(
                size: 10.5,
                weight: FontWeight.w600,
                color: textColor,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: textColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
