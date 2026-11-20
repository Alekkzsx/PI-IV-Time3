// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/shared/icons/lucide_svg_icons.dart';
import 'package:pi_iv_time3/shared/layout/institutional_sidebar.dart';
import 'package:pi_iv_time3/shared/layout/institutional_sidebar_item.dart';
import 'package:pi_iv_time3/core/router/app_router.dart';
import '../../navigation/nav_item.dart';

export 'package:pi_iv_time3/features/student/shell/presentation/navigation/nav_item.dart';
export 'package:pi_iv_time3/shared/icons/lucide_svg_icons.dart';
export 'package:pi_iv_time3/shared/layout/institutional_sidebar.dart';
export 'package:pi_iv_time3/shared/layout/institutional_sidebar_item.dart';

/// [PortalSidebar]
///
/// Componente de navegação lateral institucional do Portal do Aluno.
/// Especializa o componente base [InstitutionalSidebar] parametrizado com
/// o enum [StudentNavItem], provendo suporte a recolhimento dinâmico,
/// roteamento entre módulos e encerramento de sessão seguro.
class PortalSidebar extends StatelessWidget {
  /// Item de navegação atualmente ativo e destacado no menu.
  final StudentNavItem activeItem;

  /// Callback opcional que intercepta a seleção de um item antes da navegação padrão.
  final ValueChanged<StudentNavItem>? onItemSelected;

  /// Flag que determina se a barra lateral está em modo recolhido (ícones apenas).
  final bool isCollapsed;

  /// Callback acionado pelo usuário ao clicar no botão de expandir/recolher a barra.
  final VoidCallback? onToggleCollapse;

  /// Cria uma nova instância de [PortalSidebar].
  const PortalSidebar({
    super.key,
    required this.activeItem,
    this.onItemSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  /// Lista configurada com os 8 itens institucionais da visão do discente.
  static final List<InstitutionalSidebarItem<StudentNavItem>> _studentItems = [
    InstitutionalSidebarItem<StudentNavItem>(
      id: StudentNavItem.painelGeral,
      label: 'Painel Geral',
      iconSvgBuilder: (c) => LucideSvgIcons.layoutDashboard(c),
      key: const Key('sidebar_item_painelGeral'),
    ),
    InstitutionalSidebarItem<StudentNavItem>(
      id: StudentNavItem.disciplinas,
      label: 'Disciplinas',
      iconSvgBuilder: (c) => LucideSvgIcons.bookOpen(c),
      key: const Key('sidebar_item_disciplinas'),
    ),
    InstitutionalSidebarItem<StudentNavItem>(
      id: StudentNavItem.calendario,
      label: 'Calendário',
      iconSvgBuilder: (c) => LucideSvgIcons.calendar(c),
      key: const Key('sidebar_item_calendario'),
    ),
    InstitutionalSidebarItem<StudentNavItem>(
      id: StudentNavItem.entregas,
      label: 'Entregas',
      iconSvgBuilder: (c) => LucideSvgIcons.clipboardCheck(c),
      key: const Key('sidebar_item_entregas'),
    ),
    InstitutionalSidebarItem<StudentNavItem>(
      id: StudentNavItem.mensagens,
      label: 'Mensagens',
      iconSvgBuilder: (c) => LucideSvgIcons.messageSquare(c),
      key: const Key('sidebar_item_mensagens'),
    ),
    InstitutionalSidebarItem<StudentNavItem>(
      id: StudentNavItem.secretaria,
      label: 'Secretaria',
      iconSvgBuilder: (c) => LucideSvgIcons.landmark(c),
      key: const Key('sidebar_item_secretaria'),
    ),
    InstitutionalSidebarItem<StudentNavItem>(
      id: StudentNavItem.configuracoes,
      label: 'Configurações',
      iconSvgBuilder: (c) => LucideSvgIcons.settings(c),
      showDividerAfter: true,
      key: const Key('sidebar_item_configuracoes'),
    ),
    InstitutionalSidebarItem<StudentNavItem>(
      id: StudentNavItem.sair,
      label: 'Sair',
      iconSvgBuilder: (c) => LucideSvgIcons.logOut(c),
      isDanger: true,
      key: const Key('sidebar_item_sair'),
    ),
  ];

  /// Trata o evento de toque/clique em um item do menu lateral.
  ///
  /// Parâmetros:
  /// - [context]: Contexto de construção para acionamento do [Navigator].
  /// - [item]: Destino acadêmico selecionado.
  ///
  /// Executa:
  /// 1. Delegação ao callback externo [onItemSelected], caso fornecido.
  /// 2. Para itens de navegação acadêmica, aciona a substituição de rota nomeada [pushReplacementNamed].
  /// 3. Para o item [StudentNavItem.sair], invalida a sessão [AppUserSession.logout] e redireciona para login.
  void _handleNavigation(BuildContext context, StudentNavItem item) {
    if (onItemSelected != null) {
      onItemSelected!(item);
      return;
    }

    switch (item) {
      case StudentNavItem.painelGeral:
      case StudentNavItem.disciplinas:
      case StudentNavItem.calendario:
      case StudentNavItem.entregas:
      case StudentNavItem.mensagens:
      case StudentNavItem.secretaria:
      case StudentNavItem.configuracoes:
        final route = _routeFor(item);
        if (route != null && item != activeItem) {
          Navigator.of(context).pushReplacementNamed(route);
        }
        break;
      case StudentNavItem.sair:
        AppUserSession.instance.logout();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        break;
    }
  }

  /// Mapeia cada [StudentNavItem] para sua respectiva rota no catálogo [AppRoutes].
  ///
  /// Parâmetros:
  /// - [item]: Destino selecionado.
  ///
  /// Retorna o caminho da rota registrado ou `null` para ações operacionais.
  String? _routeFor(StudentNavItem item) {
    switch (item) {
      case StudentNavItem.painelGeral:
        return AppRoutes.studentHome;
      case StudentNavItem.disciplinas:
        return AppRoutes.studentDisciplines;
      case StudentNavItem.calendario:
        return AppRoutes.studentCalendar;
      case StudentNavItem.entregas:
        return AppRoutes.studentDeliveries;
      case StudentNavItem.mensagens:
        return AppRoutes.studentMessages;
      case StudentNavItem.secretaria:
        return AppRoutes.studentSecretaria;
      case StudentNavItem.configuracoes:
        return AppRoutes.studentSettings;
      case StudentNavItem.sair:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InstitutionalSidebar<StudentNavItem>(
      items: _studentItems,
      activeItem: activeItem,
      isCollapsed: isCollapsed,
      onToggleCollapse: onToggleCollapse,
      logoTitle: 'AGMRM',
      collapsedLogoTitle: 'AGM',
      logoSubtitle: 'PORTAL AVA',
      onItemSelected: (item) => _handleNavigation(context, item),
    );
  }
}

/// Alias de compatibilidade retroativa para garantir Zero-Breakage.
typedef StudentSidebar = PortalSidebar;
