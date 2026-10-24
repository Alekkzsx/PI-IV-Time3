// Desenvolvido por Murillo Caravita - RA: 25014012
// Componente compartilhado e desacoplado da Barra Lateral (Sidebar) Institucional

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/shared/icons/lucide_svg_icons.dart';
import 'institutional_sidebar_item.dart';

/// Barra Lateral Institucional Reutilizável (Componente Base Compartilhado).
///
/// Implementa a especificação dimensional do design system AGMRM:
/// - Largura: 280px expandido / 76px recolhido com transição de 300ms ease-in-out.
/// - Botão flutuante na borda direita: 31px × 50px rounded-full com shadow-md e hover scale-105.
/// - Logo institucional com container flexível my-auto (AGMRM 24px / AGM 18px).
/// - Itens de navegação com 124px (expandido) e 52px (recolhido), ícones 28px × 28px,
///   gap de 4px, fundo ativo #f2f0eb, inativo transparente (hover #faf9f6),
///   e variante danger (hover #fef2f2 / #b91c1c).
/// - Linha divisória horizontal de 1px com 64px (expandido) e 32px (recolhido).
class InstitutionalSidebar<T> extends StatelessWidget {
  /// Lista dos itens de navegação renderizados na barra.
  final List<InstitutionalSidebarItem<T>> items;

  /// Identificador do item atualmente selecionado.
  final T activeItem;

  /// Callback disparado ao selecionar um item de navegação.
  final ValueChanged<T>? onItemSelected;

  /// Indica se a barra lateral está recolhida.
  final bool isCollapsed;

  /// Callback para alternar entre os modos expandido e recolhido.
  final VoidCallback? onToggleCollapse;

  /// Título do topo da barra no modo expandido (padrão: "AGMRM").
  final String logoTitle;

  /// Título do topo da barra no modo recolhido (padrão: "AGM").
  final String collapsedLogoTitle;

  /// Subtítulo institucional exibido apenas no modo expandido (ex: "PORTAL AVA").
  final String? logoSubtitle;

  const InstitutionalSidebar({
    super.key,
    required this.items,
    required this.activeItem,
    this.onItemSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.logoTitle = 'AGMRM',
    this.collapsedLogoTitle = 'AGM',
    this.logoSubtitle = 'PORTAL AVA',
  });

  @override
  Widget build(BuildContext context) {
    // Dimensões Globais: 280px expandido / 76px recolhido
    final sidebarWidth = isCollapsed ? 76.0 : 280.0;
    // Padding Horizontal do <nav>: 16px expandido / 8px recolhido
    final navHorizontalPadding = isCollapsed ? 8.0 : 16.0;
    // Padding Lateral do Logo: 32px expandido / 8px recolhido
    final logoHorizontalPadding = isCollapsed ? 8.0 : 32.0;

    return _UnclippedHitTestStack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: sidebarWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: InstColors.surface,
            border: Border(
              right: BorderSide(color: InstColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 32).clamp(0.0, double.infinity),
                    ),
                    // my-auto: centraliza verticalmente quando há espaço livre
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ==========================================
                        // SEÇÃO DO LOGO INSTITUCIONAL (TOPO)
                        // ==========================================
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: 16,
                            left: logoHorizontalPadding,
                            right: logoHorizontalPadding,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isCollapsed ? collapsedLogoTitle : logoTitle,
                                style: InstText.logo(collapsed: isCollapsed),
                              ),
                              const SizedBox(height: 4), // mb-1
                              if (!isCollapsed && logoSubtitle != null)
                                Text(
                                  logoSubtitle!,
                                  style: InstText.logoSubtitle(),
                                ),
                            ],
                          ),
                        ),

                        // ==========================================
                        // LISTA DOS ITENS DE NAVEGAÇÃO (<nav>)
                        // ==========================================
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: navHorizontalPadding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < items.length; i++) ...[
                                if (i > 0) const SizedBox(height: 4), // space-y-1 (4px)
                                _InstitutionalNavItemTile<T>(
                                  item: items[i],
                                  isSelected: items[i].id == activeItem,
                                  isCollapsed: isCollapsed,
                                  onTap: () => onItemSelected?.call(items[i].id),
                                ),
                                if (items[i].showDividerAfter) ...[
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4), // my-1 (4px)
                                    child: Center(
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        width: isCollapsed ? 32 : 64, // w-8 vs w-16
                                        height: 1, // border-t 1px
                                        color: InstColors.border,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ==========================================
        // BOTÃO FLUTUANTE DE ABRIR / FECHAR (ABA NA BORDA)
        // ==========================================
        if (onToggleCollapse != null)
          Positioned(
            right: -15.5,
            top: 0,
            bottom: 0,
            child: Center(
              child: _SidebarFloatingToggleButton(
                isCollapsed: isCollapsed,
                onTap: onToggleCollapse!,
              ),
            ),
          ),
      ],
    );
  }
}

/// Item de navegação individual com suporte a hover, transições e modos expandido/recolhido.
class _InstitutionalNavItemTile<T> extends StatefulWidget {
  final InstitutionalSidebarItem<T> item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _InstitutionalNavItemTile({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_InstitutionalNavItemTile<T>> createState() => _InstitutionalNavItemTileState<T>();
}

class _InstitutionalNavItemTileState<T> extends State<_InstitutionalNavItemTile<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Largura: 124px expandido / 52px recolhido
    final itemWidth = widget.isCollapsed ? 52.0 : 124.0;
    // Padding: py-2 px-2 (expandido) / py-2 px-1 (recolhido)
    final paddingHorizontal = widget.isCollapsed ? 4.0 : 8.0;

    // Cores de acordo com o estado
    Color backgroundColor;
    Color iconColor;
    Color textColor;

    if (widget.isSelected) {
      backgroundColor = InstColors.stoneActive; // bege institucional suave
      iconColor = InstColors.ink;
      textColor = InstColors.ink;
    } else if (widget.item.isDanger) {
      backgroundColor = _isHovered ? InstColors.dangerBg : Colors.transparent;
      iconColor = _isHovered ? InstColors.danger : InstColors.faint;
      textColor = _isHovered ? InstColors.danger : InstColors.muted;
    } else {
      backgroundColor = _isHovered ? InstColors.stone : Colors.transparent;
      iconColor = _isHovered ? InstColors.ink : InstColors.faint;
      textColor = _isHovered ? InstColors.ink : InstColors.muted;
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: itemWidth,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: paddingHorizontal),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6), // rounded-md (6px)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone vetorial SVG: 28px × 28px
          SvgPicture.string(
            widget.item.iconSvgBuilder(iconColor),
            width: 28,
            height: 28,
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(height: 4), // gap-1 (4px)
            Text(
              widget.item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: InstText.navLabel(textColor),
            ),
          ],
        ],
      ),
    );

    // No modo recolhido: exibe tooltip nativo ao passar o mouse
    if (widget.isCollapsed) {
      content = Tooltip(
        message: widget.item.label,
        waitDuration: const Duration(milliseconds: 300),
        child: content,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        key: widget.item.key,
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}

/// Botão flutuante na borda direita: 31px × 50px rounded-full com shadow-md e hover scale-105.
class _SidebarFloatingToggleButton extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarFloatingToggleButton({
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarFloatingToggleButton> createState() => _SidebarFloatingToggleButtonState();
}

class _SidebarFloatingToggleButtonState extends State<_SidebarFloatingToggleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = _isHovered ? InstColors.ink : InstColors.toggleIcon;

    return Tooltip(
      message: widget.isCollapsed ? 'Expandir barra lateral' : 'Recolher barra lateral',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          key: const Key('sidebar_toggle_collapse_btn'),
          onTap: widget.onTap,
          child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0, // hover:scale-105
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 31, // w-[31px]
            height: 50, // h-[50px]
            decoration: BoxDecoration(
              color: _isHovered ? InstColors.hoverSurface : InstColors.surface,
              borderRadius: BorderRadius.circular(25), // rounded-full
              border: Border.all(
                color: _isHovered ? InstColors.faint : InstColors.borderStrong,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000), // shadow-md
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.string(
                widget.isCollapsed
                    ? LucideSvgIcons.chevronRight(iconColor)
                    : LucideSvgIcons.chevronLeft(iconColor),
                width: 20, // 20px × 20px
                height: 20,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

/// Stack customizado que permite hit-testing em filhos que transbordam (overflow),
/// como o botão flutuante posicionado na borda direita (right: -15.5px).
class _UnclippedHitTestStack extends Stack {
  const _UnclippedHitTestStack({
    super.clipBehavior = Clip.none,
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return _RenderUnclippedHitTestStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }
}

class _RenderUnclippedHitTestStack extends RenderStack {
  _RenderUnclippedHitTestStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (RenderBox? child = lastChild; child != null; child = childBefore(child)) {
      final StackParentData childParentData = child.parentData! as StackParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
    }
    return false;
  }
}


