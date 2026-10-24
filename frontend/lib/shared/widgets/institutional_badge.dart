// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Variantes visuais da tag semântica institucional.
enum InstitutionalBadgeVariant {
  neutral,
  dark,
  live,
  success,
  warning,
  danger,
}

/// Pílula/tag semântica reutilizável nas visões do Aluno, Professor e Admin.
class InstitutionalBadge extends StatelessWidget {
  final String label;
  final InstitutionalBadgeVariant variant;
  final bool showDot;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const InstitutionalBadge({
    super.key,
    required this.label,
    this.variant = InstitutionalBadgeVariant.neutral,
    this.showDot = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, borderColor, dotColor) = _resolveColors();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: jakarta(
              size: 11,
              weight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color?, Color) _resolveColors() {
    switch (variant) {
      case InstitutionalBadgeVariant.dark:
        return (InstColors.ink, Colors.white, null, Colors.white);
      case InstitutionalBadgeVariant.live:
      case InstitutionalBadgeVariant.danger:
        return (const Color(0xFFFEF2F2), InstColors.danger, const Color(0xFFFECACA), InstColors.danger);
      case InstitutionalBadgeVariant.success:
        return (const Color(0xFFECFDF5), InstColors.success, const Color(0xFFA7F3D0), InstColors.success);
      case InstitutionalBadgeVariant.warning:
        return (const Color(0xFFFFFBEB), InstColors.warning, const Color(0xFFFDE68A), InstColors.warning);
      case InstitutionalBadgeVariant.neutral:
        return (const Color(0xFFF4F4F5), const Color(0xFF3F3F46), const Color(0xFFE4E4E7), InstColors.ink);
    }
  }
}

