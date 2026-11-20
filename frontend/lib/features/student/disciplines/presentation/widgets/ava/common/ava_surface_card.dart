// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';

/// [AvaSurfaceCard]
///
/// Cartão de superfície branco desacoplado do Design System do AVA.
/// Padroniza cantos arredondados de 12px, borda institucional `#E5E7EB`,
/// sombra suave e suporte opcional a toque via [InkWell].
class AvaSurfaceCard extends StatelessWidget {
  /// Conteúdo interno do cartão.
  final Widget child;

  /// Espaçamento interno do cartão (padrão: `EdgeInsets.all(16)`).
  final EdgeInsetsGeometry padding;

  /// Espaçamento externo opcional do cartão.
  final EdgeInsetsGeometry? margin;

  /// Callback de clique opcional para cartões interativos.
  final VoidCallback? onTap;

  /// Cor de fundo do cartão (padrão: `Colors.white`).
  final Color backgroundColor;

  /// Cria uma nova instância de [AvaSurfaceCard].
  const AvaSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.015),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}
