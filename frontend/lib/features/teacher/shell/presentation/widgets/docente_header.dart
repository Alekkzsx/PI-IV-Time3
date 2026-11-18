// Desenvolvido por Guilherme Henrique Moreira
// Atualizado com padronização institucional oficial (AGMRM AVA)

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/shared/layout/institutional_top_header.dart';

/// Barra superior institucional padronizada da Visão do Docente.
class DocenteHeader extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback? onOpenDrawer;
  final String? titleOverride;
  final VoidCallback? onNavigateToCommunications;

  const DocenteHeader({
    super.key,
    required this.controller,
    this.onOpenDrawer,
    this.titleOverride,
    this.onNavigateToCommunications,
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
        return 'Atividades';
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
    final title = titleOverride ?? _getPageTitle(controller.activeTab);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    return InstitutionalTopHeader(
      title: title,
      showMobileMenuButton: !isDesktop && onOpenDrawer != null,
      onOpenDrawer: onOpenDrawer,
      horizontalPadding: isDesktop ? 40 : 20,
      actions: [
        IconButton(
          onPressed: () {
            controller.loadRemote(force: true);
          },
          tooltip: 'Atualizar dados',
          icon: const Icon(
            Icons.refresh_rounded,
            size: 19,
            color: Color(0xFF52525B),
          ),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('O histórico recente ainda não está disponível.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          },
          tooltip: 'Histórico Recente',
          icon: const Icon(
            Icons.access_time_outlined,
            size: 19,
            color: Color(0xFF52525B),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed:
              onNavigateToCommunications ??
              () => controller.navigateToTab(DocenteNavTab.comunicados),
          tooltip: 'Comunicados e Notificações',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: Color(0xFF52525B),
              ),
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF18181B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
