// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';

/// Visualização em lista/agenda dos compromissos e prazos do estudante.
class StudentCalendarAgendaView extends StatelessWidget {
  final StudentPortalController controller;

  const StudentCalendarAgendaView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final filteredEvents = controller.events.where((e) {
      return controller.activeEventTypes.contains(e.type) &&
          controller.activeDisciplineFilters.contains(e.discipline);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compromissos e Prazos do Semestre',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 16),
          if (filteredEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Nenhum evento correspondente aos filtros selecionados.',
                ),
              ),
            )
          else
            ...filteredEvents.map((e) {
              Color tagColor = const Color(0xFF18181B);
              if (e.type == 'Entrega') tagColor = const Color(0xFFDC2626);
              if (e.type == 'Aula') tagColor = const Color(0xFF16A34A);
              if (e.type == 'Avaliação') tagColor = const Color(0xFFD97706);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tagColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${e.discipline} • ${e.date} • ${e.time} • ${e.location}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Chip(
                      label: Text(
                        e.type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: tagColor,
                        ),
                      ),
                      backgroundColor: tagColor.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
