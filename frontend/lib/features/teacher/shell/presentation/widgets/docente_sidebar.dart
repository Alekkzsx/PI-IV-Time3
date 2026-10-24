// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/shared/icons/lucide_svg_icons.dart';
import 'package:pi_iv_time3/shared/layout/institutional_sidebar.dart';
import 'package:pi_iv_time3/shared/layout/institutional_sidebar_item.dart';

/// Barra lateral do Portal Docente.
///
/// Especialização de [InstitutionalSidebar] (mesmo padrão visual do aluno),
/// com os itens do professor. O item "Sair" usa `null` como identificador.
class DocenteSidebar extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback onLogout;

  const DocenteSidebar({
    super.key,
    required this.controller,
    required this.onLogout,
  });

  static final List<InstitutionalSidebarItem<DocenteNavTab?>> _items = [
    InstitutionalSidebarItem<DocenteNavTab?>(
      id: DocenteNavTab.painel,
      label: 'Painel Geral',
      iconSvgBuilder: (c) => LucideSvgIcons.layoutDashboard(c),
      key: const Key('docente_sidebar_item_painel'),
    ),
    InstitutionalSidebarItem<DocenteNavTab?>(
      id: DocenteNavTab.turmas,
      label: 'Turmas',
      iconSvgBuilder: (c) => LucideSvgIcons.bookOpen(c),
      key: const Key('docente_sidebar_item_turmas'),
    ),
    InstitutionalSidebarItem<DocenteNavTab?>(
      id: DocenteNavTab.diario,
      label: 'Diário',
      iconSvgBuilder: (c) => LucideSvgIcons.clipboardCheck(c),
      key: const Key('docente_sidebar_item_diario'),
    ),
    InstitutionalSidebarItem<DocenteNavTab?>(
      id: DocenteNavTab.atividades,
      label: 'Atividades',
      iconSvgBuilder: (c) => LucideSvgIcons.inbox(c),
      key: const Key('docente_sidebar_item_atividades'),
    ),
    InstitutionalSidebarItem<DocenteNavTab?>(
      id: DocenteNavTab.notas,
      label: 'Notas',
      iconSvgBuilder: (c) => LucideSvgIcons.graduationCap(c),
      key: const Key('docente_sidebar_item_notas'),
    ),
    InstitutionalSidebarItem<DocenteNavTab?>(
      id: DocenteNavTab.agenda,
      label: 'Calendário',
      iconSvgBuilder: (c) => LucideSvgIcons.calendar(c),
      key: const Key('docente_sidebar_item_agenda'),
    ),
    InstitutionalSidebarItem<DocenteNavTab?>(
      id: DocenteNavTab.comunicados,
      label: 'Mensagens',
      iconSvgBuilder: (c) => LucideSvgIcons.messageSquare(c),
      key: const Key('docente_sidebar_item_comunicados'),
    ),
    InstitutionalSidebarItem<DocenteNavTab?>(
      id: DocenteNavTab.configuracoes,
      label: 'Configurações',
      iconSvgBuilder: (c) => LucideSvgIcons.settings(c),
      showDividerAfter: true,
      key: const Key('docente_sidebar_item_configuracoes'),
    ),
    InstitutionalSidebarItem<DocenteNavTab?>(
      id: null,
      label: 'Sair',
      iconSvgBuilder: (c) => LucideSvgIcons.logOut(c),
      isDanger: true,
      key: const Key('docente_sidebar_item_sair'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return InstitutionalSidebar<DocenteNavTab?>(
      items: _items,
      activeItem: controller.activeTab,
      isCollapsed: controller.isSidebarCollapsed,
      onToggleCollapse: controller.toggleSidebarCollapse,
      logoSubtitle: 'PORTAL DOCENTE',
      onItemSelected: (tab) {
        if (tab == null) {
          onLogout();
        } else {
          controller.navigateToTab(tab);
        }
      },
    );
  }
}
