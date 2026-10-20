// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../controllers/docente_controller.dart';

/// Top sticky header for the Docente Portal.
class DocenteHeader extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback? onOpenDrawer;

  const DocenteHeader({
    super.key,
    required this.controller,
    this.onOpenDrawer,
  });

  String _getPageTitle(DocenteNavTab tab) {
    switch (tab) {
      case DocenteNavTab.painel:
        return 'Painel Geral';
      case DocenteNavTab.turmas:
        return 'Disciplinas';
      case DocenteNavTab.diario:
        return 'Diário';
      case DocenteNavTab.atividades:
        return 'Entregas';
      case DocenteNavTab.notas:
        return 'Notas';
      case DocenteNavTab.agenda:
        return 'Calendário';
      case DocenteNavTab.comunicados:
        return 'Mensagens';
      case DocenteNavTab.configuracoes:
        return 'Configurações';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _getPageTitle(controller.activeTab);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: DocenteColors.headerBackground,
        border: Border(
          bottom: BorderSide(color: DocenteColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Mobile Menu + Page Title
          Row(
            children: [
              if (isMobile && onOpenDrawer != null)
                IconButton(
                  onPressed: onOpenDrawer,
                  icon: const Icon(Icons.menu_rounded),
                  color: DocenteColors.textSecondary,
                  tooltip: 'Abrir Menu',
                ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: DocenteColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Right: Action Buttons (Agenda + Comunicados with dot)
          Row(
            children: [
              IconButton(
                onPressed: () => controller.navigateToTab(DocenteNavTab.agenda),
                icon: const Icon(Icons.calendar_month_outlined, size: 22),
                color: DocenteColors.textSecondary,
                tooltip: 'Abrir Agenda Docente',
              ),
              const SizedBox(width: 4),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () =>
                        controller.navigateToTab(DocenteNavTab.comunicados),
                    icon: const Icon(Icons.notifications_none_rounded, size: 24),
                    color: DocenteColors.textSecondary,
                    tooltip: 'Abrir Comunicados Acadêmicos',
                  ),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: DocenteColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
