// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Barra superior institucional compartilhada (54px de altura, fundo #F5F5F5, borda #E5E5E5).
///
/// Reutilizada nos shells das Visões do Aluno, Professor e Administrador.
class InstitutionalTopHeader extends StatelessWidget {
  /// Título da página ativa.
  final String title;

  /// Se deve exibir o botão de menu hambúrguer para abrir o Drawer no mobile.
  final bool showMobileMenuButton;

  /// Callback opcional para abrir o Drawer (se nulo, usa `Scaffold.of(context).openDrawer()`).
  final VoidCallback? onOpenDrawer;

  /// Lista de widgets de ação posicionados à direita do cabeçalho.
  final List<Widget> actions;

  /// Padding horizontal customizável (padrão: 28px em desktop, 16px em mobile).
  final double? horizontalPadding;

  const InstitutionalTopHeader({
    super.key,
    required this.title,
    this.showMobileMenuButton = false,
    this.onOpenDrawer,
    this.actions = const [],
    this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = horizontalPadding ?? (showMobileMenuButton ? 16.0 : 28.0);

    return Container(
      height: InstSidebarMetrics.topHeaderHeight,
      padding: EdgeInsets.symmetric(horizontal: effectivePadding),
      decoration: const BoxDecoration(
        color: InstColors.headerBg,
        border: Border(
          bottom: BorderSide(color: InstColors.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showMobileMenuButton) ...[
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      size: 22,
                      color: Color(0xFF18181B),
                    ),
                    tooltip: 'Abrir Menu',
                    onPressed: onOpenDrawer ?? () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: jakarta(
                  size: 18,
                  weight: FontWeight.w500,
                  color: const Color(0xFF18181B),
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions,
            ),
        ],
      ),
    );
  }
}

