// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'tabs/ava_tabs.dart';

/// [AvaSyllabusMaterialsTab]
///
/// Fachada delegadora retrocompatível que encaminha a renderização para os
/// componentes modulares de responsabilidade única em `ava/tabs/`
/// ([AvaFilesTab], [AvaSyllabusTab] e [AvaCollaborationsTab]).
class AvaSyllabusMaterialsTab extends StatelessWidget {
  /// Índice da aba ativa no menu lateral do AVA.
  final int activeTabIndex;

  /// Cria uma nova instância de [AvaSyllabusMaterialsTab].
  const AvaSyllabusMaterialsTab({super.key, required this.activeTabIndex});

  @override
  Widget build(BuildContext context) {
    return switch (activeTabIndex) {
      6 => const AvaFilesTab(),
      7 => const AvaSyllabusTab(),
      8 => const AvaCollaborationsTab(),
      _ => const AvaFilesTab(),
    };
  }
}

typedef StudentAvaSyllabusMaterialsTab = AvaSyllabusMaterialsTab;
