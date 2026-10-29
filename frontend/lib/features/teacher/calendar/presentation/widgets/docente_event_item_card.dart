// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_event.dart';

/// Card para item da lista de compromissos da agenda docente.
class DocenteEventItemCard extends StatelessWidget {
  final AcademicEvent event;

  const DocenteEventItemCard({super.key, required this.event});

  Widget _buildEventTypeBadge(EventType type) {
    Color bg;
    Color fg;
    Color border;
    String label;

    switch (type) {
      case EventType.aula:
        bg = const Color(0xFFF4F4F5);
        fg = const Color(0xFF3F3F46);
        border = const Color(0xFFE4E4E7);
        label = 'Aula / Laboratório';
        break;
      case EventType.avaliacao:
        bg = const Color(0xFFFFF1F2);
        fg = const Color(0xFFE11D48);
        border = const Color(0xFFFECDD3);
        label = 'Avaliação Regimental';
        break;
      case EventType.plantao:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        border = const Color(0xFFBBF7D0);
        label = 'Plantão Docente';
        break;
      case EventType.colegiado:
      case EventType.reuniao:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        border = const Color(0xFFFDE68A);
        label = 'Colegiado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: jakarta(size: 10.5, weight: FontWeight.w600, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag de Tipo + Data (estilo da captura)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEventTypeBadge(event.type),
                    const SizedBox(width: 8),
                    Text(
                      event.date,
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Título
                Text(
                  event.title,
                  style: jakarta(
                    size: 14,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 6),
                // Horário e Local
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Color(0xFF71717A),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      event.time,
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF71717A),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      event.location,
                      style: jakarta(
                        size: 12,
                        weight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Badge "Sincronizado no Calendário AVA"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Text(
              'Sincronizado no Calendário AVA',
              style: jakarta(
                size: 11,
                weight: FontWeight.w500,
                color: const Color(0xFF52525B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
