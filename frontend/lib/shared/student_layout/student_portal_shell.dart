// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'student_sidebar.dart';

/// Estrutura base compartilhada (Shell) da Visão do Aluno do Portal AVA AGMRM.
///
/// Integra a barra lateral [StudentSidebar], cabeçalho superior com ícones de
/// histórico e notificações, área principal de conteúdo e rodapé institucional.
class StudentPortalShell extends StatefulWidget {
  /// Título exibido na barra superior do portal (ex: 'Mensagens' ou 'Secretaria Virtual').
  final String headerTitle;

  /// Item atualmente selecionado na barra lateral.
  final StudentNavItem activeNavItem;

  /// Conteúdo principal da tela.
  final Widget child;

  /// Callback opcional ao selecionar um item da barra lateral.
  final ValueChanged<StudentNavItem>? onNavItemSelected;

  /// Cria uma instância de [StudentPortalShell].
  const StudentPortalShell({
    super.key,
    required this.headerTitle,
    required this.activeNavItem,
    required this.child,
    this.onNavItemSelected,
  });

  @override
  State<StudentPortalShell> createState() => _StudentPortalShellState();
}

class _StudentPortalShellState extends State<StudentPortalShell> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 820;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      drawer: isDesktop
          ? null
          : Drawer(
              width: 160,
              backgroundColor: Colors.white,
              child: StudentSidebar(
                activeItem: widget.activeNavItem,
                onItemSelected: widget.onNavItemSelected,
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            StudentSidebar(
              activeItem: widget.activeNavItem,
              onItemSelected: widget.onNavItemSelected,
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(context, isDesktop: isDesktop),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 1120,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isDesktop ? 48 : 20,
                                          vertical: isDesktop ? 36 : 24,
                                        ),
                                        child: widget.child,
                                      ),
                                    ),
                                  ),
                                ),
                                _buildFooter(isDesktop: isDesktop),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, {required bool isDesktop}) {
    return Container(
      height: 58,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F1ED),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isDesktop) ...[
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      size: 22,
                      color: Color(0xFF18181B),
                    ),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.headerTitle,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                tooltip: 'Histórico Recente',
                icon: const Icon(
                  Icons.access_time_outlined,
                  size: 19,
                  color: Color(0xFF52525B),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {},
                    tooltip: 'Notificações',
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: Color(0xFF52525B),
                    ),
                  ),
                  Positioned(
                    right: 11,
                    top: 11,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF18181B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter({required bool isDesktop}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: const [
              Text(
                '© 2026 AGMRM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
              Text(
                '|',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFD4D4D8),
                ),
              ),
              Text(
                'Portal AVA AGMRM • Ambiente Virtual de Aprendizagem Universitário',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF71717A),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Ajuda',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF71717A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Privacidade',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF71717A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
