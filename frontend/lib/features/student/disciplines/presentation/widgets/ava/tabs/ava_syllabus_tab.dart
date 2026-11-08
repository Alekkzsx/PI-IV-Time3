// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaSyllabusTab]
///
/// Aba 7 do Cockpit AVA: Programa da Disciplina (Syllabus).
/// Apresenta a ementa, metodologia, objetivos pedagógicos e unidades curriculares
/// homologadas para a disciplina utilizando o Design System limpo do AVA.
class AvaSyllabusTab extends StatelessWidget {
  /// Cria uma nova instância de [AvaSyllabusTab].
  const AvaSyllabusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final discipline = StudentPortalController.instance.selectedDiscipline;
    final units = discipline?.syllabusUnits ?? const <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvaOpenSectionHeader(
          title:
              'Programa da Disciplina${discipline == null ? '' : ' • ${discipline.name}'}',
          subtitle:
              'Ementa regimental, competências curriculares e critérios de avaliação homologados.',
        ),
        const SizedBox(height: 20),

        AvaSurfaceCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ementa e Metodologia do Semestre',
                style: jakarta(
                  size: 14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Abordagem teórica e prática com ênfase em modelagem orientada a domínio, padrões de projeto e desenvolvimento de sistemas corporativos.',
                style: jakarta(
                  size: 13,
                  color: const Color(0xFF52525B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'Unidades Previstas:',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),
              if (units.isEmpty)
                Text(
                  'Cronograma detalhado em homologação pela coordenação.',
                  style: jakarta(size: 12, color: const Color(0xFF71717A)),
                )
              else
                for (final u in units)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (u['title'] ?? u['name'] ?? '').toString(),
                            style: jakarta(
                              size: 12.5,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
