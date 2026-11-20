// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Cabeçalho de saudação principal (Hero) reutilizado nos Painéis Gerais (Aluno, Professor, Admin).
class InstitutionalHeroHeader extends StatelessWidget {
  /// Saudação principal (ex: 'Bem-vindo, Lucas.', 'Bem-vinda, Helena.', 'Bem-vindo, Carlos.').
  final String greeting;

  /// Rótulo opcional acima da saudação (ex: 'Painel Geral').
  final String? eyebrow;

  /// Lista de metadados exibidos no subtítulo separados por '•' (ex: ['Engenharia de Software', 'Semestre 2026/2']).
  final List<String> subtitleItems;

  /// Widget opcional de ação exibido à direita do cabeçalho (ex: botão 'Emitir Comunicado Institucional').
  final Widget? trailingAction;

  const InstitutionalHeroHeader({
    super.key,
    required this.greeting,
    required this.subtitleItems,
    this.eyebrow,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: jakarta(size: 13, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          greeting,
          style: jakarta(
            size: 36,
            weight: FontWeight.w700,
            color: InstColors.ink,
            letterSpacing: -0.9,
            height: 1.15,
          ),
        ),
        if (subtitleItems.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (int i = 0; i < subtitleItems.length; i++) ...[
                if (i > 0)
                  Text(
                    '•',
                    style: jakarta(size: 14, color: InstColors.faint),
                  ),
                Text(
                  subtitleItems[i],
                  style: jakarta(
                    size: 14,
                    weight: FontWeight.w500,
                    color: InstColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );

    if (trailingAction == null) {
      return content;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: content),
        const SizedBox(width: 16),
        trailingAction!,
      ],
    );
  }
}

