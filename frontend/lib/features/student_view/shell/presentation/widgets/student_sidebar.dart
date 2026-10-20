// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Especialização do componente compartilhado InstitutionalSidebar para o Portal do Aluno

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/shared/icons/lucide_svg_icons.dart';
import 'package:pi_iv_time3/shared/layout/institutional_sidebar.dart';
import 'package:pi_iv_time3/shared/layout/institutional_sidebar_item.dart';

// Reexporta os componentes compartilhados para fácil acesso em módulos externos
export 'package:pi_iv_time3/shared/icons/lucide_svg_icons.dart';
export 'package:pi_iv_time3/shared/layout/institutional_sidebar.dart';
export 'package:pi_iv_time3/shared/layout/institutional_sidebar_item.dart';

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

/// Barra lateral de navegação institucional do Portal AVA (Visão do Aluno).
///
/// Utiliza a arquitetura compartilhada [InstitutionalSidebar] parametrizada com [StudentNavItem],
/// garantindo desacoplamento estrutural, suporte a testes com chaves fixas e comportamento padronizado.
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

  /// Lista configurada dos 8 itens institucionais do aluno.
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
      iconSvgBuilder: (c) => LucideSvgIcons.inbox(c),
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
      iconSvgBuilder: (c) => LucideSvgIcons.fileText(c),
      key: const Key('sidebar_item_secretaria'),
    ),
    InstitutionalSidebarItem<StudentNavItem>(
      id: StudentNavItem.configuracoes,
      label: 'Configurações',
      iconSvgBuilder: (c) => LucideSvgIcons.settings(c),
      showDividerAfter: true, // Renderiza divisor de 1px entre configurações e sair
      key: const Key('sidebar_item_configuracoes'),
    ),
    InstitutionalSidebarItem<StudentNavItem>(
      id: StudentNavItem.sair,
      label: 'Sair',
      iconSvgBuilder: (c) => LucideSvgIcons.logOut(c),
      isDanger: true, // Hover com destaque em vermelho #b91c1c e fundo #fef2f2
      key: const Key('sidebar_item_sair'),
    ),
  ];

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
    return InstitutionalSidebar<StudentNavItem>(
      items: _studentItems,
      activeItem: activeItem,
      isCollapsed: isCollapsed,
      onToggleCollapse: onToggleCollapse,
      logoTitle: 'ALEX',
      collapsedLogoTitle: 'ALE',
      logoSubtitle: 'PORTAL AVA',
      onItemSelected: (item) => _handleNavigation(context, item),
    );
  }
}
