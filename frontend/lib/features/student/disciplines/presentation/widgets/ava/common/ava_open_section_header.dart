// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// [AvaOpenSectionHeader]
///
/// Cabeçalho aberto padronizado do Cockpit AVA do estudante.
/// Segue a identidade visual de referência (título em 20px Bold `#18181B`,
/// subtítulo descritivo em 13px `#71717A` e slot `trailing` para ações ou busca).
/// Utiliza [LayoutBuilder] para empilhar em telas estreitas (< 640px),
/// garantindo zero overflow horizontal em dispositivos móveis.
class AvaOpenSectionHeader extends StatelessWidget {
  /// Título principal da seção ativa.
  final String title;

  /// Subtítulo explicativo ou regimental da seção.
  final String subtitle;

  /// Widget opcional posicionado à direita em desktop ou abaixo em mobile.
  final Widget? trailing;

  /// Cria uma nova instância de [AvaOpenSectionHeader].
  const AvaOpenSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: jakarta(
            size: 20,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: jakarta(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF71717A),
          ),
        ),
      ],
    );

    if (trailing == null) {
      return titleColumn;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleColumn,
              const SizedBox(height: 12),
              trailing!,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleColumn),
            const SizedBox(width: 16),
            trailing!,
          ],
        );
      },
    );
  }
}
