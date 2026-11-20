// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';

/// [DisciplineNoticesCard]
///
/// Componente de mural de avisos e comunicados docentes específico das matérias cursadas.
/// Exibe os comunicados publicados pelos professores das disciplinas com data, título e corpo.
class DisciplineNoticesCard extends StatelessWidget {
  /// Cria uma nova instância de [DisciplineNoticesCard].
  const DisciplineNoticesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = StudentPortalController.instance;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final courseCodes = controller.disciplines.map((d) => d.code).toSet();
        final notices = controller.messages.where((message) {
          final classCode = message['classCode']?.toString();
          return classCode == null || courseCodes.contains(classCode);
        }).toList();
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mural de Avisos & Comunicados Docentes',
                          style: jakarta(
                            size: 16,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Orientações publicadas para suas disciplinas.',
                          style: jakarta(
                            size: 11.5,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${notices.length} avisos',
                    style: jakarta(size: 11, color: const Color(0xFF71717A)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
              if (notices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Nenhum aviso publicado para suas disciplinas.',
                    style: jakarta(size: 12, color: const Color(0xFF71717A)),
                  ),
                )
              else
                for (var i = 0; i < notices.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F4F5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                notices[i]['classCode'] as String? ??
                                    'Institucional',
                                style: jakarta(
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF71717A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notices[i]['sender'] as String? ??
                                    'Coordenação Institucional',
                                overflow: TextOverflow.ellipsis,
                                style: jakarta(
                                  size: 11.5,
                                  color: const Color(0xFF71717A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notices[i]['dateLabel'] as String? ?? '',
                              style: jakarta(
                                size: 11,
                                color: const Color(0xFF71717A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notices[i]['title'] as String? ?? '',
                          style: jakarta(
                            size: 13,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notices[i]['body'] as String? ?? '',
                          style: jakarta(
                            size: 11.5,
                            color: const Color(0xFF71717A),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < notices.length - 1)
                    const Divider(height: 1, color: Color(0xFFF4F4F5)),
                ],
            ],
          ),
        );
      },
    );
  }
}


typedef StudentNoticesCard = DisciplineNoticesCard;
