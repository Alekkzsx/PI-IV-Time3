// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/features/admin/audit/presentation/pages/audit_page.dart';
import 'package:pi_iv_time3/features/admin/calendar/presentation/pages/calendar_page.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/pages/classes_page.dart';
import 'package:pi_iv_time3/features/admin/courses/presentation/pages/courses_page.dart';
import 'package:pi_iv_time3/features/admin/dashboard/presentation/pages/painel_geral_page.dart';
import 'package:pi_iv_time3/features/admin/secretary/presentation/pages/secretary_page.dart';
import 'package:pi_iv_time3/features/admin/settings/presentation/pages/admin_configure_page.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/pages/users_page.dart';
import 'package:pi_iv_time3/shared/layout/institutional_top_header.dart';
import '../widgets/admin_sidebar.dart';

/// Shell principal da Visão Administrativa / Gestão do Campus.
///
/// Integra a [AdminSidebar] desacoplada e responsiva, cabeçalho de 54px,
/// e renderização reativa das abas do portal.
class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  AdminNavTab _activeTab = AdminNavTab.painelGeral;
  bool _isSidebarCollapsed = false;

  Widget _buildCurrentPage(AdminNavTab tab) {
    switch (tab) {
      case AdminNavTab.painelGeral:
        return PainelGeralPage(
          onNavigateTab: (targetTab) => setState(() => _activeTab = targetTab),
        );
      case AdminNavTab.usuarios:
        return const UsersPage();
      case AdminNavTab.cursos:
        return const CoursesPage();
      case AdminNavTab.turmas:
        return const ClassesPage();
      case AdminNavTab.secretaria:
        return const SecretaryPage();
      case AdminNavTab.calendario:
        return const CalendarPage();
      case AdminNavTab.auditoria:
        return const AuditPage();
      case AdminNavTab.configuracoes:
        return const AdminConfigurePage();
    }
  }

  String _getPageTitle(AdminNavTab tab) {
    switch (tab) {
      case AdminNavTab.painelGeral:
        return 'Painel Geral';
      case AdminNavTab.usuarios:
        return 'Usuários';
      case AdminNavTab.cursos:
        return 'Cursos';
      case AdminNavTab.turmas:
        return 'Turmas';
      case AdminNavTab.secretaria:
        return 'Secretaria';
      case AdminNavTab.calendario:
        return 'Calendário';
      case AdminNavTab.auditoria:
        return 'Auditoria';
      case AdminNavTab.configuracoes:
        return 'Configurações';
    }
  }

  void _onLogout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          backgroundColor: InstColors.stone,
          drawer: isDesktop
              ? null
              : Drawer(
                  width: 280,
                  backgroundColor: Colors.white,
                  child: AdminSidebar(
                    activeTab: _activeTab,
                    isCollapsed: false,
                    onTabSelected: (tab) {
                      Navigator.of(context).pop();
                      setState(() => _activeTab = tab);
                    },
                    onLogout: () {
                      Navigator.of(context).pop();
                      _onLogout();
                    },
                  ),
                ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop)
                AdminSidebar(
                  activeTab: _activeTab,
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                  onTabSelected: (tab) => setState(() => _activeTab = tab),
                  onLogout: _onLogout,
                ),
              Expanded(
                child: Column(
                  children: [
                    InstitutionalTopHeader(
                      title: _getPageTitle(_activeTab),
                      showMobileMenuButton: !isDesktop,
                      actions: [
                        IconButton(
                          icon: const Icon(
                            Icons.access_time_outlined,
                            size: 20,
                            color: Color(0xFF18181B),
                          ),
                          tooltip: 'Prazos Regimentais',
                          onPressed: () => setState(
                            () => _activeTab = AdminNavTab.calendario,
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none_outlined,
                                size: 20,
                                color: Color(0xFF18181B),
                              ),
                              tooltip: 'Notificações Institucionais',
                              onPressed: () => _showInfo(
                                'Não há novas notificações institucionais.',
                              ),
                            ),
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF18181B),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: const Text(
                                  '0',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: _buildCurrentPage(_activeTab),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
