// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';

/// [AgendaEventCard]
///
/// Cartão individual de compromisso na visualização em Agenda do calendário.
/// Exibe horário, faixa lateral semântica por categoria, título, disciplina,
/// localização e modal de detalhes do evento.
class AgendaEventCard extends StatelessWidget {
  /// Evento acadêmico a ser renderizado.
  final StudentCalendarEvent event;

  /// Cria uma nova instância de [AgendaEventCard].
  const AgendaEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final stripColor = switch (event.type) {
      'Entrega' => const Color(0xFF16A34A),
      'Aula' => const Color(0xFF0D9488),
      'Fórum' => const Color(0xFFD97706),
      _ => const Color(0xFFDC2626),
    };
    final typeIcon = switch (event.type) {
      'Entrega' => Icons.assignment_outlined,
      'Aula' => Icons.video_camera_front_outlined,
      'Fórum' => Icons.forum_outlined,
      _ => Icons.fact_check_outlined,
    };
    final isUrgent = event.type == 'Entrega';
    const description = 'Compromisso acadêmico registrado no calendário.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 6),
              Text(
                event.time,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18181B),
                ),
              ),
              const Text(
                'HORÁRIO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Container(
            width: 4,
            height: 90,
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF18181B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Urgente',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        event.discipline,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF4B5563),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(typeIcon, size: 14, color: const Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      event.type,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.location,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(event.title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${event.type} • ${event.discipline}'),
                    const SizedBox(height: 8),
                    Text('Horário: ${event.time}'),
                    const SizedBox(height: 8),
                    const Text(description),
                    const SizedBox(height: 8),
                    Text('Local: ${event.location}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
            icon: const Text(
              'Detalhes',
              style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
            label: const Icon(
              Icons.open_in_new,
              size: 13,
              color: Color(0xFF6B7280),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
