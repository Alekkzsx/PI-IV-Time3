// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/calendar/presentation/pages/student_calendar_page.dart';
import 'package:pi_iv_time3/features/student/dashboard/presentation/pages/student_dashboard_page.dart';
import 'package:pi_iv_time3/features/student/deliveries/presentation/pages/student_deliveries_page.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/pages/student_disciplines_page.dart';
import 'package:pi_iv_time3/features/student/messages/presentation/pages/student_messages_page.dart';
import 'package:pi_iv_time3/features/student/secretariat/presentation/pages/student_secretariat_page.dart';
import 'package:pi_iv_time3/features/student/settings/presentation/pages/student_settings_page.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/shared/layout/institutional_top_header.dart';
import '../widgets/student_footer.dart';
import '../widgets/student_sidebar.dart';

/// Estrutura base compartilhada (Shell) da Visão do Aluno do Portal AVA AGMRM.
///
/// Integra a barra lateral [StudentSidebar], cabeçalho superior institucional,
/// área principal de conteúdo e rodapé institucional.
class StudentPortalShell extends StatefulWidget {
  /// Título exibido na barra superior do portal.
  final String headerTitle;

  /// Item atualmente selecionado na barra lateral inicialmente.
  final StudentNavItem activeNavItem;

  /// Conteúdo principal da tela do Painel Geral.
  final Widget child;

  /// Callback opcional ao selecionar um item da barra lateral.
  final ValueChanged<StudentNavItem>? onNavItemSelected;

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
  late StudentNavItem _currentNavItem;
  late String _currentHeaderTitle;

  @override
  void initState() {
    super.initState();
    _currentNavItem = widget.activeNavItem;
    StudentPortalController.instance.activeNavItem = _currentNavItem;
    _currentHeaderTitle = widget.headerTitle;
    StudentPortalController.instance.addListener(_onPortalControllerChanged);
  }

  @override
  void dispose() {
    StudentPortalController.instance.removeListener(_onPortalControllerChanged);
    super.dispose();
  }

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

  void _onMenuItemSelected(StudentNavItem item) {
    if (item == StudentNavItem.sair) {
      Navigator.of(context).pushReplacementNamed('/');
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
                        isDesktop) ...[
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
