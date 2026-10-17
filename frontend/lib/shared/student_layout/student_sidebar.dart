// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
/// Reproduz fielmente o layout vertical com ícone superior, rótulo centralizado
/// e destaque em tom pedra suave (`#EFECE6`) para o item ativo.
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
      case StudentNavItem.sair:
        Navigator.of(context).pushReplacementNamed('/');
        break;
      default:
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Módulo "${_labelFor(item)}" disponível no Painel Geral.'),
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

  IconData _iconFor(StudentNavItem item) {
    switch (item) {
      case StudentNavItem.painelGeral:
        return Icons.grid_view_outlined;
      case StudentNavItem.disciplinas:
        return Icons.menu_book_outlined;
      case StudentNavItem.calendario:
        return Icons.calendar_today_outlined;
      case StudentNavItem.entregas:
        return Icons.inbox_outlined;
      case StudentNavItem.mensagens:
        return Icons.chat_bubble_outline_rounded;
      case StudentNavItem.secretaria:
        return Icons.description_outlined;
      case StudentNavItem.configuracoes:
        return Icons.settings_outlined;
      case StudentNavItem.sair:
        return Icons.logout_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = isCollapsed ? 72.0 : 124.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: sidebarWidth,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            border: Border(
              right: BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                // Identidade Visual AGMRM - PORTAL AVA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Text(
                        isCollapsed ? 'AVA' : 'AGMRM',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18181B),
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (!isCollapsed) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'PORTAL AVA',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Lista de Navegação
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        _buildNavTile(context, StudentNavItem.painelGeral),
                        _buildNavTile(context, StudentNavItem.disciplinas),
                        _buildNavTile(context, StudentNavItem.calendario),
                        _buildNavTile(context, StudentNavItem.entregas),
                        _buildNavTile(context, StudentNavItem.mensagens),
                        _buildNavTile(context, StudentNavItem.secretaria),
                        _buildNavTile(context, StudentNavItem.configuracoes),
                        const SizedBox(height: 8),
                        _buildNavTile(context, StudentNavItem.sair),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        if (onToggleCollapse != null)
          Positioned(
            right: -12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(
                  side: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
                elevation: 1,
                child: InkWell(
                  onTap: onToggleCollapse,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavTile(BuildContext context, StudentNavItem item) {
    final isSelected = item == activeItem;
    final label = _labelFor(item);
    final icon = _iconFor(item);

    final Color iconColor =
        isSelected ? const Color(0xFF18181B) : const Color(0xFF71717A);
    final Color textColor =
        isSelected ? const Color(0xFF18181B) : const Color(0xFF71717A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? const Color(0xFFEFECE6) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: Key('sidebar_item_${item.name}'),
          onTap: () => _handleNavigation(context, item),
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0xFFF5F4F0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(height: 5),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

