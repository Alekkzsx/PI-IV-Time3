// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Atualizado rigorosamente com ícones vetoriais SVG lucide-react e tipografia Plus Jakarta Sans

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identificadores dos itens de navegação da barra lateral da visão do aluno.
enum StudentNavItem {
  painelGeral,
  disciplinas,
  calendario,
  entregas,
  mensagens,
  secretaria,
  configuracoes,
  sair,
}

/// Helper para obter a tipografia Plus Jakarta Sans com segurança para todos os ambientes.
TextStyle _plusJakartaSans({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double? letterSpacing,
  double? height,
}) {
  try {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  } catch (_) {
    return TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

/// Vetores SVG originais da biblioteca lucide-react.
class LucideSvg {
  static String _hex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static String forItem(StudentNavItem item, Color color) {
    switch (item) {
      case StudentNavItem.painelGeral:
        return layoutDashboard(color);
      case StudentNavItem.disciplinas:
        return bookOpen(color);
      case StudentNavItem.calendario:
        return calendar(color);
      case StudentNavItem.entregas:
        return inbox(color);
      case StudentNavItem.mensagens:
        return messageSquare(color);
      case StudentNavItem.secretaria:
        return fileText(color);
      case StudentNavItem.configuracoes:
        return settings(color);
      case StudentNavItem.sair:
        return logOut(color);
    }
  }

  // LayoutDashboard
  static String layoutDashboard(Color color) {
    final h = _hex(color);
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="$h" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <rect width="7" height="9" x="3" y="3" rx="1"/>
      <rect width="7" height="5" x="14" y="3" rx="1"/>
      <rect width="7" height="9" x="14" y="12" rx="1"/>
      <rect width="7" height="5" x="3" y="16" rx="1"/>
    </svg>''';
  }

  // BookOpen
  static String bookOpen(Color color) {
    final h = _hex(color);
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="$h" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M12 7v14"/>
      <path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"/>
    </svg>''';
  }

  // Calendar
  static String calendar(Color color) {
    final h = _hex(color);
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="$h" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M8 2v4"/>
      <path d="M16 2v4"/>
      <rect width="18" height="18" x="3" y="4" rx="2"/>
      <path d="M3 10h18"/>
    </svg>''';
  }

  // Inbox
  static String inbox(Color color) {
    final h = _hex(color);
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="$h" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/>
      <path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>
    </svg>''';
  }

  // MessageSquare
  static String messageSquare(Color color) {
    final h = _hex(color);
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="$h" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
    </svg>''';
  }

  // FileText
  static String fileText(Color color) {
    final h = _hex(color);
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="$h" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/>
      <path d="M14 2v4a2 2 0 0 0 2 2h4"/>
      <path d="M10 9H8"/>
      <path d="M16 13H8"/>
      <path d="M16 17H8"/>
    </svg>''';
  }

  // Settings
  static String settings(Color color) {
    final h = _hex(color);
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="$h" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/>
      <circle cx="12" cy="12" r="3"/>
    </svg>''';
  }

  // LogOut
  static String logOut(Color color) {
    final h = _hex(color);
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="$h" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
      <polyline points="16 17 21 12 16 7"/>
      <line x1="21" x2="9" y1="12" y2="12"/>
    </svg>''';
  }

  // ChevronLeft
  static String chevronLeft(Color color) {
    final h = _hex(color);
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="$h" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
      <path d="m15 18-6-6 6-6"/>
    </svg>''';
  }

  // ChevronRight
  static String chevronRight(Color color) {
    final h = _hex(color);
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="$h" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
      <path d="m9 18 6-6-6-6"/>
    </svg>''';
  }
}

/// Barra lateral de navegação institucional do Portal AVA (Visão do Aluno).
class StudentSidebar extends StatelessWidget {
  /// Item atualmente ativo na barra lateral.
  final StudentNavItem activeItem;

  /// Callback opcional para interceptar a seleção de um item de menu.
  final ValueChanged<StudentNavItem>? onItemSelected;

  /// Indica se a barra lateral está recolhida.
  final bool isCollapsed;

  /// Callback acionado ao clicar no botão de recolher/expandir a barra lateral.
  final VoidCallback? onToggleCollapse;

  /// Cria uma instância de [StudentSidebar].
  const StudentSidebar({
    super.key,
    required this.activeItem,
    this.onItemSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  void _handleNavigation(BuildContext context, StudentNavItem item) {
    if (onItemSelected != null) {
      onItemSelected!(item);
      return;
    }

    switch (item) {
      case StudentNavItem.mensagens:
        if (activeItem != StudentNavItem.mensagens) {
          Navigator.of(context).pushReplacementNamed('/student/messages');
        }
        break;
      case StudentNavItem.secretaria:
        if (activeItem != StudentNavItem.secretaria) {
          Navigator.of(context).pushReplacementNamed('/student/secretaria');
        }
        break;
      case StudentNavItem.entregas:
        if (activeItem != StudentNavItem.entregas) {
          Navigator.of(context).pushReplacementNamed('/student/entregas');
        }
        break;
      case StudentNavItem.sair:
        Navigator.of(context).pushReplacementNamed('/');
        break;
      default:
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Módulo "${_labelFor(item)}" disponível no Painel Geral.',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  String _labelFor(StudentNavItem item) {
    switch (item) {
      case StudentNavItem.painelGeral:
        return 'Painel Geral';
      case StudentNavItem.disciplinas:
        return 'Disciplinas';
      case StudentNavItem.calendario:
        return 'Calendário';
      case StudentNavItem.entregas:
        return 'Entregas';
      case StudentNavItem.mensagens:
        return 'Mensagens';
      case StudentNavItem.secretaria:
        return 'Secretaria';
      case StudentNavItem.configuracoes:
        return 'Configurações';
      case StudentNavItem.sair:
        return 'Sair';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dimensões Globais: 280px expandido / 76px recolhido
    final sidebarWidth = isCollapsed ? 76.0 : 280.0;
    // Padding Horizontal do <nav>: 16px expandido / 8px recolhido
    final navHorizontalPadding = isCollapsed ? 8.0 : 16.0;
    // Padding Lateral do Logo: 32px expandido / 8px recolhido
    final logoHorizontalPadding = isCollapsed ? 8.0 : 32.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: sidebarWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            border: Border(
              right: BorderSide(color: Color(0xFFE5E5E5), width: 1),
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
                        // 3. SEÇÃO DO LOGO INSTITUCIONAL (TOPO)
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
                                isCollapsed ? 'AGM' : 'AGMRM',
                                style: _plusJakartaSans(
                                  fontSize: isCollapsed ? 18 : 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 4), // mb-1
                              if (!isCollapsed)
                                Text(
                                  'PORTAL AVA',
                                  style: _plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF737373),
                                    letterSpacing: 0.8, // tracking-[0.08em]
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ==========================================
                        // 4. LISTA DOS ITENS DE NAVEGAÇÃO (<nav>)
                        // ==========================================
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: navHorizontalPadding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNavItem(context, StudentNavItem.painelGeral),
                              const SizedBox(height: 4), // space-y-1 (4px)
                              _buildNavItem(context, StudentNavItem.disciplinas),
                              const SizedBox(height: 4),
                              _buildNavItem(context, StudentNavItem.calendario),
                              const SizedBox(height: 4),
                              _buildNavItem(context, StudentNavItem.entregas),
                              const SizedBox(height: 4),
                              _buildNavItem(context, StudentNavItem.mensagens),
                              const SizedBox(height: 4),
                              _buildNavItem(context, StudentNavItem.secretaria),
                              const SizedBox(height: 4),
                              _buildNavItem(context, StudentNavItem.configuracoes),
                              const SizedBox(height: 4),

                              // ==========================================
                              // 6. LINHA DIVISÓRIA (ENTRE CONFIGURAÇÕES E SAIR)
                              // ==========================================
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4), // my-1 (4px)
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: isCollapsed ? 32 : 64, // w-8 vs w-16
                                    height: 1, // border-t 1px
                                    color: const Color(0xFFE5E5E5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),

                              _buildNavItem(context, StudentNavItem.sair, isDanger: true),
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
        // 2. BOTÃO FLUTUANTE DE ABRIR / FECHAR (ABA NA BORDA)
        // ==========================================
        if (onToggleCollapse != null)
          Positioned(
            right: -15.5,
            top: 0,
            bottom: 0,
            child: Center(
              child: _SidebarFloatingToggle(
                isCollapsed: isCollapsed,
                onTap: onToggleCollapse!,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    StudentNavItem item, {
    bool isDanger = false,
  }) {
    return _NavItemTile(
      key: Key('sidebar_item_${item.name}'),
      item: item,
      label: _labelFor(item),
      isSelected: item == activeItem,
      isCollapsed: isCollapsed,
      isDanger: isDanger,
      onTap: () => _handleNavigation(context, item),
    );
  }
}

/// Item de navegação individual com suporte a hover, transições e modos expandido/recolhido.
class _NavItemTile extends StatefulWidget {
  final StudentNavItem item;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final bool isDanger;
  final VoidCallback onTap;

  const _NavItemTile({
    super.key,
    required this.item,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  State<_NavItemTile> createState() => _NavItemTileState();
}

class _NavItemTileState extends State<_NavItemTile> {
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
      backgroundColor = const Color(0xFFF2F0EB); // bege institucional suave
      iconColor = const Color(0xFF1A1A1A);
      textColor = const Color(0xFF1A1A1A);
    } else if (widget.isDanger) {
      backgroundColor = _isHovered ? const Color(0xFFFEF2F2) : Colors.transparent;
      iconColor = _isHovered ? const Color(0xFFB91C1C) : const Color(0xFFA3A3A3);
      textColor = _isHovered ? const Color(0xFFB91C1C) : const Color(0xFF737373);
    } else {
      backgroundColor = _isHovered ? const Color(0xFFFAF9F6) : Colors.transparent;
      iconColor = _isHovered ? const Color(0xFF1A1A1A) : const Color(0xFFA3A3A3);
      textColor = _isHovered ? const Color(0xFF1A1A1A) : const Color(0xFF737373);
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
          // Ícone vetorial SVG lucide-react: 28px × 28px
          SvgPicture.string(
            LucideSvg.forItem(widget.item, iconColor),
            width: 28,
            height: 28,
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(height: 4), // gap-1 (4px)
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _plusJakartaSans(
                fontSize: 12.5, // text-[12.5px]
                fontWeight: FontWeight.w400, // font-normal (400)
                color: textColor,
                height: 1.15,
              ),
            ),
          ],
        ],
      ),
    );

    // No modo recolhido: exibe tooltip nativo ao passar o mouse
    if (widget.isCollapsed) {
      content = Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 300),
        child: content,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}

/// Botão flutuante na borda direita: 31px × 50px rounded-full com shadow-md e hover scale-105.
class _SidebarFloatingToggle extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarFloatingToggle({
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarFloatingToggle> createState() => _SidebarFloatingToggleState();
}

class _SidebarFloatingToggleState extends State<_SidebarFloatingToggle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = _isHovered ? const Color(0xFF1A1A1A) : const Color(0xFF525252);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0, // hover:scale-105
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 31, // w-[31px]
            height: 50, // h-[50px]
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFFFAFAFA) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(25), // rounded-full
              border: Border.all(
                color: _isHovered ? const Color(0xFFA3A3A3) : const Color(0xFFD4D4D4),
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
                    ? LucideSvg.chevronRight(iconColor)
                    : LucideSvg.chevronLeft(iconColor),
                width: 20, // 20px × 20px
                height: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
