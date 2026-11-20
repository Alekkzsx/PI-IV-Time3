// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';

/// [AvaSectionCard]
///
/// Componente de cartão container padronizado para as seções do Cockpit AVA.
/// Aplica as bordas institucionais, sombreamento sutil e preenchimento configurável.
class AvaSectionCard extends StatelessWidget {
  /// Conteúdo filho a ser envelopado pelo container visual.
  final Widget child;

  /// Espaçamento interno (padding) das bordas do cartão.
  final EdgeInsetsGeometry padding;

  /// Cria uma nova instância de [AvaSectionCard].
  const AvaSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: InstColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
        boxShadow: [
          BoxShadow(
            color: InstColors.ink.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// [AvaSectionStyles]
///
/// Coleção utilitária de estilos tipográficos padronizados para cabeçalhos do AVA.
class AvaSectionStyles {
  const AvaSectionStyles._();

  /// Estilo de título de seção em Plus Jakarta Sans 16px bold.
  static const TextStyle title = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: InstColors.ink,
  );
}
