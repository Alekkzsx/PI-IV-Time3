// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaCollaborationsTab]
///
/// Aba 8 do Cockpit AVA: Projetos e Colaborações em Equipe.
/// Espaço dedicado para acompanhamento de grupos de estudo e entregas conjuntas
/// vinculadas à disciplina selecionada.
class AvaCollaborationsTab extends StatelessWidget {
  /// Cria uma nova instância de [AvaCollaborationsTab].
  const AvaCollaborationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final discipline = StudentPortalController.instance.selectedDiscipline;
    final courseName = discipline?.name ?? 'Disciplina';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AvaOpenSectionHeader(
          title: 'Projetos e Colaborações em Equipe',
          subtitle:
              'Espaço dedicado para formação de grupos, squads e acompanhamento de entregas conjuntas.',
        ),
        const SizedBox(height: 20),
        AvaSurfaceCard(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 40,
                  color: Color(0xFFA1A1AA),
                ),
                const SizedBox(height: 12),
                Text(
                  'Grupos de Trabalho • $courseName',
                  style: jakarta(
                    size: 14,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Acompanhe as entregas em equipe na aba "Tarefas e Atividades".',
                  style: jakarta(size: 12, color: const Color(0xFF71717A)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
