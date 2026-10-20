// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Guilherme Henrique Moreira e Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin_view/audit/presentation/pages/audit_page.dart';
import 'package:pi_iv_time3/features/admin_view/calendar/presentation/pages/calendar_page.dart';
import 'package:pi_iv_time3/features/admin_view/classes/presentation/pages/classes_page.dart';
import 'package:pi_iv_time3/features/admin_view/courses/presentation/pages/courses_page.dart';
import 'package:pi_iv_time3/features/admin_view/dashboard/presentation/pages/painel_geral_page.dart';
import 'package:pi_iv_time3/features/admin_view/secretary/presentation/pages/secretary_page.dart';
import 'package:pi_iv_time3/features/admin_view/settings/presentation/pages/admin_configure_page.dart';
import 'package:pi_iv_time3/features/admin_view/users/presentation/pages/users_page.dart';
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
        return const PainelGeralPage();
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
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          backgroundColor: const Color(0xFFFAF9F6),
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
                            Icons.schedule_rounded,
                            size: 22,
                            color: Color(0xFF525252),
                          ),
                          tooltip: 'Prazos Regimentais',
                          onPressed: () {},
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            size: 24,
                            color: Color(0xFF525252),
                          ),
                          tooltip: 'Notificações Institucionais',
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Expanded(
                      child: Container(
                        color: const Color(0xFFFAF9F6),
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
