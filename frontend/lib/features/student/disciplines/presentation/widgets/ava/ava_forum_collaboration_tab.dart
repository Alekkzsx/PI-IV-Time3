// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'tabs/ava_tabs.dart';

/// [AvaForumCollaborationTab]
///
/// Fachada delegadora retrocompatível que encaminha a renderização para os
/// componentes modulares de responsabilidade única em `ava/tabs/`
/// ([AvaForumTab], [AvaPeopleTab], [AvaCollaborationsTab], [AvaNotebookTab] e [AvaChatTab]).
class AvaForumCollaborationTab extends StatelessWidget {
  /// Índice da aba ativa no menu lateral do AVA.
  final int activeTabIndex;

  /// Controlador reativo do portal do estudante.
  final StudentPortalController controller;

  /// Cria uma nova instância de [AvaForumCollaborationTab].
  const AvaForumCollaborationTab({
    super.key,
    required this.activeTabIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return switch (activeTabIndex) {
      3 => AvaForumTab(controller: controller),
      5 => AvaPeopleTab(controller: controller),
      8 => const AvaCollaborationsTab(),
      9 => AvaNotebookTab(controller: controller),
      10 => const AvaChatTab(),
      _ => AvaForumTab(controller: controller),
    };
  }
}

typedef StudentAvaForumCollaborationTab = AvaForumCollaborationTab;
