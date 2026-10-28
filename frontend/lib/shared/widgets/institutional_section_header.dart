// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Cabeçalho de seção padronizado com título à esquerda e badge/ação opcional à direita.
class InstitutionalSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final double titleSize;

  const InstitutionalSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.titleSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: jakarta(
              size: titleSize,
              weight: FontWeight.w700,
              color: InstColors.ink,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

