// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/calendar/presentation/pages/calendar_page.dart';
import 'package:pi_iv_time3/features/student/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pi_iv_time3/features/student/deliveries/presentation/pages/deliveries_page.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/pages/disciplines_page.dart';
import 'package:pi_iv_time3/features/student/messages/presentation/pages/messages_page.dart';
import 'package:pi_iv_time3/features/student/secretariat/presentation/pages/secretariat_page.dart';
import 'package:pi_iv_time3/features/student/settings/presentation/pages/settings_page.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/shared/layout/institutional_top_header.dart';
import '../widgets/widgets.dart';

/// [PortalShell]
///
/// Shell estrutural mestre (Scaffold) da visão discente do Portal AVA AGMRM.
/// Gerencia a barra lateral retrátil [PortalSidebar], o cabeçalho institucional superior
/// [InstitutionalTopHeader], o roteamento dinâmico de subpáginas em memória sem destruir
/// o estado global e o rodapé [PortalFooter].
class PortalShell extends StatefulWidget {
  /// Título padrão inicial a ser exibido no cabeçalho superior.
  final String headerTitle;

  /// Destino de navegação pré-selecionado no ciclo de montagem inicial.
  final StudentNavItem activeNavItem;

  /// Conteúdo filho alternativo caso o item de navegação não esteja mapeado.
  final Widget child;

  /// Callback opcional disparado quando um item do menu é acionado.
  final ValueChanged<StudentNavItem>? onNavItemSelected;

  /// Construtor imutável de [PortalShell].
  const PortalShell({
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
  late StudentNavItem _currentNavItem;
  late String _currentHeaderTitle;

  @override
  void initState() {
    super.initState();
    _currentNavItem = widget.activeNavItem;
    StudentPortalController.instance.activeNavItem = _currentNavItem;
    StudentPortalController.instance.loadRemote();
    _currentHeaderTitle = widget.headerTitle;
    StudentPortalController.instance.addListener(_onPortalControllerChanged);
  }

  @override
  void dispose() {
    StudentPortalController.instance.removeListener(_onPortalControllerChanged);
    super.dispose();
  }

  /// Sincroniza o item de navegação ativo quando modificado externamente no controlador.
  void _onPortalControllerChanged() {
    if (!mounted) return;
    final controller = StudentPortalController.instance;
    if (_currentNavItem != controller.activeNavItem) {
      setState(() {
        _currentNavItem = controller.activeNavItem;
        _updateHeaderTitle(_currentNavItem);
      });
    } else {
      setState(() {});
    }
  }

  /// Retorna o widget de página correspondente ao item de menu selecionado.
  Widget _buildSelectedPage() {
    switch (_currentNavItem) {
      case StudentNavItem.entregas:
        return const StudentDeliveriesPage();
      case StudentNavItem.mensagens:
        return const StudentMessagesPage();
      case StudentNavItem.secretaria:
        return const StudentSecretariatPage();
      case StudentNavItem.painelGeral:
        return const StudentDashboardPage();
      case StudentNavItem.disciplinas:
        return const StudentDisciplinesPage();
      case StudentNavItem.calendario:
        return const StudentCalendarPage();
      case StudentNavItem.configuracoes:
        return const StudentSettingsPage();
      default:
        return widget.child;
    }
  }

  /// Atualiza o título exibido na barra superior de acordo com a seção ativa.
  void _updateHeaderTitle(StudentNavItem item) {
    switch (item) {
      case StudentNavItem.entregas:
        _currentHeaderTitle = 'Entregas';
        break;
      case StudentNavItem.mensagens:
        _currentHeaderTitle = 'Mensagens';
        break;
      case StudentNavItem.secretaria:
        _currentHeaderTitle = 'Secretaria Virtual';
        break;
      case StudentNavItem.painelGeral:
        _currentHeaderTitle = 'Painel Geral';
        break;
      case StudentNavItem.disciplinas:
        _currentHeaderTitle = 'Disciplinas';
        break;
      case StudentNavItem.calendario:
        _currentHeaderTitle = 'Calendário';
        break;
      case StudentNavItem.configuracoes:
        _currentHeaderTitle = 'Configurações';
        break;
      default:
        _currentHeaderTitle = widget.headerTitle;
    }
  }

  /// Executa a troca de seção discente com suporte a logout seguro.
  void _onMenuItemSelected(StudentNavItem item) {
    if (item == StudentNavItem.sair) {
      AppUserSession.instance.logout();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      return;
    }

    StudentPortalController.instance.setNavItem(item);

    setState(() {
      _currentNavItem = item;
      _updateHeaderTitle(item);
    });

    if (widget.onNavItemSelected != null) {
      widget.onNavItemSelected!(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isDesktop
          ? null
          : Drawer(
              width: 280,
              backgroundColor: Colors.white,
              child: StudentSidebar(
                activeItem: _currentNavItem,
                onItemSelected: (item) {
                  _onMenuItemSelected(item);
                  Navigator.of(context).pop();
                },
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            StudentSidebar(
              activeItem: _currentNavItem,
              onItemSelected: _onMenuItemSelected,
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
                InstitutionalTopHeader(
                  title: _currentHeaderTitle,
                  showMobileMenuButton: !isDesktop,
                  horizontalPadding: isDesktop ? 40 : 20,
                  actions: [
                    if (_currentNavItem == StudentNavItem.painelGeral &&
                        screenWidth >= 1024) ...[
                      OutlinedButton.icon(
                        key: const Key('btn_toggle_dashboard_view'),
                        onPressed: () {
                          StudentPortalController.instance.toggleDashboardView(
                            !StudentPortalController.instance.isGridView,
                          );
                        },
                        icon: Icon(
                          StudentPortalController.instance.isGridView
                              ? Icons.format_list_bulleted_rounded
                              : Icons.grid_view_rounded,
                          size: 16,
                          color: const Color(0xFF525252),
                        ),
                        label: Text(
                          StudentPortalController.instance.isGridView
                              ? 'Alterar para visualização em lista'
                              : 'Alterar para visualização em bloco',
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w500,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE5E5E5)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'O histórico recente ainda não está disponível.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      tooltip: 'Histórico Recente',
                      icon: const Icon(
                        Icons.access_time_outlined,
                        size: 19,
                        color: Color(0xFF52525B),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _onMenuItemSelected(StudentNavItem.mensagens),
                      tooltip: 'Notificações',
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            size: 20,
                            color: Color(0xFF52525B),
                          ),
                          Positioned(
                            right: -5,
                            top: -4,
                            child: Text(
                              '0',
                              style: jakarta(
                                size: 10,
                                weight: FontWeight.w700,
                                color: const Color(0xFF52525B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                   horizontal: isDesktop ? 40 : 20,
                                  vertical: isDesktop ? 32 : 20,
                                ),
                                child: _buildSelectedPage(),
                              ),
                              StudentFooter(isDesktop: isDesktop),
                            ],
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
}

/// Alias de compatibilidade retroativa para garantir Zero-Breakage.
typedef StudentPortalShell = PortalShell;
