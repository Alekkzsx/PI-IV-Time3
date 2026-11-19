// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import '../../../shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
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
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
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
  final _portal = AdminPortalController.instance;
  @override
  void initState() {
    super.initState();
    _portal.loadRemote(clear: true);
    _portal.addListener(_portalChanged);
  }

  void _portalChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _portal.removeListener(_portalChanged);
    super.dispose();
  }

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
    AppUserSession.instance.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _openNotificationsModal() {
    final notifications = _portal.institutionalNotifications;
    AcademicModalDialog.show<void>(
      context: context,
      builder: (dialogCtx) => AcademicModalDialog(
        title: 'Central de Alertas da Gestão',
        subtitle: notifications.isEmpty
            ? 'Nenhuma pendência operacional aberta no momento.'
            : '${notifications.length} aviso(s) operacional(is) requerendo atenção.',
        icon: Icons.notifications_none_outlined,
        cancelLabel: 'Fechar',
        confirmLabel: 'Atualizar',
        onConfirm: () {
          Navigator.of(dialogCtx).pop();
          _portal.loadRemote();
        },
        child: notifications.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Protocolos de secretaria, solicitações de retificação pós-lacração e prazos do calendário estão em dia.',
                  style: jakarta(size: 13.5, color: InstColors.muted),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < notifications.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.of(dialogCtx).pop();
                        final target = notifications[i]['tab']?.toString();
                        final targetTab = switch (target) {
                          'secretaria' => AdminNavTab.secretaria,
                          'turmas' => AdminNavTab.turmas,
                          'calendario' => AdminNavTab.calendario,
                          _ => AdminNavTab.painelGeral,
                        };
                        setState(() => _activeTab = targetTab);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: InstColors.stone,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: InstColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: InstColors.ink,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notifications[i]['title']?.toString() ?? '',
                                    style: jakarta(
                                      size: 13.5,
                                      weight: FontWeight.w600,
                                      color: InstColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    notifications[i]['subtitle']?.toString() ?? '',
                                    style: jakarta(
                                      size: 12,
                                      color: InstColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
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
                      _portal.clearSupervisionError(notify: false);
                      if (_portal.users.isNotEmpty ||
                          _portal.classes.isNotEmpty) {
                        _portal.clearRemoteError(notify: false);
                      }
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
                  onTabSelected: (tab) {
                    _portal.clearSupervisionError(notify: false);
                    if (_portal.users.isNotEmpty ||
                        _portal.classes.isNotEmpty) {
                      _portal.clearRemoteError(notify: false);
                    }
                    setState(() => _activeTab = tab);
                  },
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
                          onPressed: () {
                            _portal.clearSupervisionError(notify: false);
                            if (_portal.users.isNotEmpty ||
                                _portal.classes.isNotEmpty) {
                              _portal.clearRemoteError(notify: false);
                            }
                            setState(() => _activeTab = AdminNavTab.calendario);
                          },
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
                              onPressed: _openNotificationsModal,
                            ),
                            if (_portal.institutionalNotifications.isNotEmpty)
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
                                  child: Text(
                                    _portal.institutionalNotifications.length
                                        .toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
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
                        child: Column(
                          children: [
                            if (_portal.isLoadingRemote ||
                                _portal.isSavingRemote)
                              const LinearProgressIndicator(),
                            if (_portal.remoteError != null)
                              MaterialBanner(
                                content: Text(_portal.remoteError!),
                                actions: [
                                  TextButton(
                                    onPressed: () => _portal.clearRemoteError(),
                                    child: const Text('Fechar'),
                                  ),
                                  TextButton(
                                    onPressed: () => _portal.loadRemote(),
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            Expanded(child: _buildCurrentPage(_activeTab)),
                          ],
                        ),
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
