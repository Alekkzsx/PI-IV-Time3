// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../common/ava_common.dart';

/// [AvaChatTab]
///
/// Aba 10 do Cockpit AVA: Canal de Avisos e Chat da Turma.
/// Apresenta o espaço reservado para interações síncronas de aula
/// utilizando os componentes do Design System compartilhado do AVA.
class AvaChatTab extends StatelessWidget {
  /// Cria uma nova instância de [AvaChatTab].
  const AvaChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvaOpenSectionHeader(
          title: 'Canal de Avisos e Chat da Turma',
          subtitle: 'Mensagens rápidas e comunicados síncronos da turma.',
        ),
        SizedBox(height: 20),
        AvaEmptyStateCard(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Canal reservado para interações síncronas de aula.',
          subtitle:
              'Utilize a aba Fóruns para publicar dúvidas formais para o professor.',
        ),
      ],
    );
  }
}
