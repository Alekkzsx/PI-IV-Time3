// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Variantes visuais canônicas de [AvaActionPillButton].
enum AvaButtonVariant {
  /// Pílula sólida primária `#18181B` com texto branco `#FFFFFF`.
  primary,

  /// Pílula secundária `#FFFFFF` com borda `1px #E5E7EB` e texto `#18181B`.
  secondary,

  /// Pílula suave `#FAF8F5` com borda `1px #E5E7EB` e texto `#18181B`.
  subtle,
}

/// [AvaActionPillButton]
///
/// Botão de ação institucional unificado do Cockpit AVA e Catálogo de Disciplinas.
class AvaActionPillButton extends StatelessWidget {
  /// Rótulo textual do botão.
  final String label;

  /// Ícone opcional exibido à esquerda do rótulo.
  final IconData? icon;

  /// Callback de clique (`null` desabilita o botão).
  final VoidCallback? onPressed;

  /// Variante estética do botão.
  final AvaButtonVariant variant;

  /// Indica operação assíncrona em andamento.
  final bool isLoading;

  /// Se `true`, ocupa 100% da largura disponível.
  final bool fullWidth;

  /// Se `true`, aplica espaçamento compacto (altura ~32px, ideal para cards/tabelas).
  final bool compact;

  /// Se `true`, usa bordas em pílula (`20px`); se `false`, usa raio `8px`.
  final bool isPill;

  /// Cria uma nova instância de [AvaActionPillButton].
  const AvaActionPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AvaButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = false,
    this.compact = false,
    this.isPill = true,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, borderColor) = switch (variant) {
      AvaButtonVariant.primary => (
        const Color(0xFF18181B),
        Colors.white,
        const Color(0xFF18181B),
      ),
      AvaButtonVariant.secondary => (
        Colors.white,
        const Color(0xFF18181B),
        const Color(0xFFE5E7EB),
      ),
      AvaButtonVariant.subtle => (
        const Color(0xFFFAF8F5),
        const Color(0xFF18181B),
        const Color(0xFFE5E7EB),
      ),
    };

    final radius = BorderRadius.circular(isPill ? 20 : 8);
    final effectiveEnabled = onPressed != null && !isLoading;

    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: fgColor,
            ),
          ),
          const SizedBox(width: 7),
        ] else if (icon != null) ...[
          Icon(icon, size: compact ? 14 : 15, color: fgColor),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: jakarta(
              size: compact ? 11.5 : 12.5,
              weight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ),
      ],
    );

    final button = Opacity(
      opacity: effectiveEnabled ? 1.0 : 0.55,
      child: Material(
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: effectiveEnabled ? onPressed : null,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 7 : 9,
            ),
            child: content,
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

