// Desenvolvido por Guilherme Henrique Moreira
// Atualizado com padronização institucional oficial (AGMRM AVA)

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/shared/layout/institutional_top_header.dart';

/// Barra superior institucional padronizada da Visão do Docente.
class DocenteHeader extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback? onOpenDrawer;

  const DocenteHeader({super.key, required this.controller, this.onOpenDrawer});

  String _getPageTitle(DocenteNavTab tab) {
    switch (tab) {
      case DocenteNavTab.painel:
        return 'Painel Geral';
      case DocenteNavTab.turmas:
        return 'Turmas';
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
    final title = _getPageTitle(controller.activeTab);
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
          onPressed: () => controller.navigateToTab(DocenteNavTab.comunicados),
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
                right: -5,
                top: -4,
                child: Text(
                  '0',
                  style: jakarta(
                    size: 10,
                    weight: FontWeight.w700,
                    color: const Color(0xFF52525B),
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
