// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../controllers/docente_controller.dart';

/// Collapsible sidebar for the Docente Portal.
class DocenteSidebar extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback onLogout;

  const DocenteSidebar({
    super.key,
    required this.controller,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isCollapsed = controller.isSidebarCollapsed;
    final width = isCollapsed ? 76.0 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: DocenteColors.surface,
        border: Border(
          right: BorderSide(color: DocenteColors.border),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              const SizedBox(height: 24),
              // Brand Logo and Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'AGMRM',
                      style: TextStyle(
                        fontSize: isCollapsed ? 18 : 24,
                        fontWeight: FontWeight.bold,
                        color: DocenteColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (!isCollapsed)
                      const Text(
                        'PORTAL DOCENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: DocenteColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Navigation Items List
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 8 : 16,
                  ),
                  child: Column(
                    children: [
                      _buildNavItem(
                        icon: Icons.grid_view_rounded,
                        label: 'Painel Geral',
                        tab: DocenteNavTab.painel,
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 4),
                      _buildNavItem(
                        icon: Icons.school_outlined,
                        label: 'Turmas',
                        tab: DocenteNavTab.turmas,
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 4),
                      _buildNavItem(
                        icon: Icons.menu_book_outlined,
                        label: 'Diário',
                        tab: DocenteNavTab.diario,
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 4),
                      _buildNavItem(
                        icon: Icons.assignment_outlined,
                        label: 'Atividades',
                        tab: DocenteNavTab.atividades,
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 4),
                      _buildNavItem(
                        icon: Icons.fact_check_outlined,
                        label: 'Notas',
                        tab: DocenteNavTab.notas,
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 4),
                      _buildNavItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Calendário',
                        tab: DocenteNavTab.agenda,
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 4),
                      _buildNavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Mensagens',
                        tab: DocenteNavTab.comunicados,
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 4),
                      _buildNavItem(
                        icon: Icons.settings_outlined,
                        label: 'Configurações',
                        tab: DocenteNavTab.configuracoes,
                        isCollapsed: isCollapsed,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: isCollapsed ? 32 : 64,
                        height: 1,
                        color: DocenteColors.border,
                      ),
                      const SizedBox(height: 12),
                      _buildLogoutItem(isCollapsed: isCollapsed),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

          // Collapse/Expand Floating Pill Button
          Positioned(
            right: -15.5,
            top: 240,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.toggleSidebarCollapse,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  width: 31,
                  height: 50,
                  decoration: BoxDecoration(
                    color: DocenteColors.surface,
                    border: Border.all(color: DocenteColors.borderDark),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      size: 20,
                      color: DocenteColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required DocenteNavTab tab,
    required bool isCollapsed,
  }) {
    final isActive = controller.activeTab == tab;

    return Tooltip(
      message: isCollapsed ? label : '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.navigateToTab(tab),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isCollapsed ? 52 : 124,
            padding: EdgeInsets.symmetric(
              vertical: isCollapsed ? 10 : 8,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? DocenteColors.navActiveBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isActive
                      ? DocenteColors.textPrimary
                      : DocenteColors.textMuted,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? DocenteColors.textPrimary
                          : DocenteColors.textSecondary,
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

  Widget _buildLogoutItem({required bool isCollapsed}) {
    return Tooltip(
      message: isCollapsed ? 'Sair' : '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onLogout,
          borderRadius: BorderRadius.circular(8),
          hoverColor: DocenteColors.dangerLight,
          child: Container(
            width: isCollapsed ? 52 : 124,
            padding: EdgeInsets.symmetric(
              vertical: isCollapsed ? 10 : 8,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 26,
                  color: DocenteColors.textMuted,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Sair',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DocenteColors.textSecondary,
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

