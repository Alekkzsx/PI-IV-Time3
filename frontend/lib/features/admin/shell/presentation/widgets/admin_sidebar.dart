// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/shared/icons/lucide_svg_icons.dart';
import 'package:pi_iv_time3/shared/layout/institutional_sidebar.dart';
import 'package:pi_iv_time3/shared/layout/institutional_sidebar_item.dart';

/// Enumeração das abas de navegação da Visão Administrativa / Gestão do Campus.
enum AdminNavTab {
  painelGeral,
  usuarios,
  cursos,
  turmas,
  secretaria,
  calendario,
  auditoria,
  configuracoes,
}

/// Barra Lateral (Sidebar) especializada para o Portal de Gestão / Admin.
///
/// Conectada ao componente compartilhado [InstitutionalSidebar], implementando:
/// - 280px expandida / 76px recolhida com transição de 300ms.
/// - Botão flutuante na borda (31px × 50px, rounded-full, shadow-md, hover scale-105).
/// - 8 itens verticais + linha divisória horizontal + ação de Sair (danger).
/// - Vetores SVG Lucide Icons oficiais com preenchimento e traço dinâmico.
class AdminSidebar extends StatelessWidget {
  /// Aba atualmente selecionada.
  final AdminNavTab activeTab;

  /// Callback acionado ao selecionar uma aba.
  final ValueChanged<AdminNavTab> onTabSelected;

  /// Callback para logout / encerramento de sessão.
  final VoidCallback onLogout;

  /// Estado de colapso da barra.
  final bool isCollapsed;

  /// Alternador de expansão/recolhimento da barra lateral.
  final VoidCallback? onToggleCollapse;

  /// Título institucional expandido (padrão: "AGMRM").
  final String logoTitle;

  /// Título institucional recolhido (padrão: "AGM").
  final String collapsedLogoTitle;

  /// Subtítulo institucional (padrão: "PORTAL GESTÃO").
  final String logoSubtitle;

  const AdminSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.onLogout,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.logoTitle = 'AGMRM',
    this.collapsedLogoTitle = 'AGM',
    this.logoSubtitle = 'PORTAL GESTÃO',
  });

  static final List<InstitutionalSidebarItem<AdminNavTab?>> _items = [
    InstitutionalSidebarItem<AdminNavTab?>(
      id: AdminNavTab.painelGeral,
      label: 'Painel Geral',
      iconSvgBuilder: (c) => LucideSvgIcons.layoutDashboard(c),
      key: const Key('admin_nav_painel_geral'),
    ),
    InstitutionalSidebarItem<AdminNavTab?>(
      id: AdminNavTab.usuarios,
      label: 'Usuários',
      iconSvgBuilder: (c) => LucideSvgIcons.users(c),
      key: const Key('admin_nav_usuarios'),
    ),
    InstitutionalSidebarItem<AdminNavTab?>(
      id: AdminNavTab.cursos,
      label: 'Cursos',
      iconSvgBuilder: (c) => LucideSvgIcons.graduationCap(c),
      key: const Key('admin_nav_cursos'),
    ),
    InstitutionalSidebarItem<AdminNavTab?>(
      id: AdminNavTab.turmas,
      label: 'Turmas',
      iconSvgBuilder: (c) => LucideSvgIcons.bookOpen(c),
      key: const Key('admin_nav_turmas'),
    ),
    InstitutionalSidebarItem<AdminNavTab?>(
      id: AdminNavTab.secretaria,
      label: 'Secretaria',
      iconSvgBuilder: (c) => LucideSvgIcons.fileText(c),
      key: const Key('admin_nav_secretaria'),
    ),
    InstitutionalSidebarItem<AdminNavTab?>(
      id: AdminNavTab.calendario,
      label: 'Calendário',
      iconSvgBuilder: (c) => LucideSvgIcons.calendar(c),
      key: const Key('admin_nav_calendario'),
    ),
    InstitutionalSidebarItem<AdminNavTab?>(
      id: AdminNavTab.auditoria,
      label: 'Auditoria',
      iconSvgBuilder: (c) => LucideSvgIcons.shieldCheck(c),
      key: const Key('admin_nav_auditoria'),
    ),
    InstitutionalSidebarItem<AdminNavTab?>(
      id: AdminNavTab.configuracoes,
      label: 'Configurações',
      iconSvgBuilder: (c) => LucideSvgIcons.settings(c),
      showDividerAfter: true,
      key: const Key('admin_nav_configuracoes'),
    ),
    InstitutionalSidebarItem<AdminNavTab?>(
      id: null,
      label: 'Sair',
      iconSvgBuilder: (c) => LucideSvgIcons.logOut(c),
      isDanger: true,
      key: const Key('admin_nav_sair'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return InstitutionalSidebar<AdminNavTab?>(
      items: _items,
      activeItem: activeTab,
      isCollapsed: isCollapsed,
      onToggleCollapse: onToggleCollapse,
      logoTitle: logoTitle,
      collapsedLogoTitle: collapsedLogoTitle,
      logoSubtitle: logoSubtitle,
      onItemSelected: (tab) {
        if (tab == null) {
          onLogout();
        } else {
          onTabSelected(tab);
        }
      },
    );
  }
}
