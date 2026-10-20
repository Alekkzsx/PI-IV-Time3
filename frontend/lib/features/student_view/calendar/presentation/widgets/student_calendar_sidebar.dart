// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';

/// Painel lateral do calendário acadêmico: mini-calendário e filtros por categoria e disciplina.
class StudentCalendarSidebar extends StatelessWidget {
  final StudentPortalController controller;

  const StudentCalendarSidebar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMiniCalendar(),
        const SizedBox(height: 24),
        _buildFiltersCard(),
      ],
    );
  }

  Widget _buildMiniCalendar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Text(
            'Outubro 2026',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(height: 8),
          Text(
            'Segunda-feira, 20 de Outubro',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    final eventCategories = [
      {'tipo': 'Aula', 'cor': const Color(0xFF16A34A)},
      {'tipo': 'Entrega', 'cor': const Color(0xFFDC2626)},
      {'tipo': 'Avaliação', 'cor': const Color(0xFFD97706)},
      {'tipo': 'Fórum', 'cor': const Color(0xFF2563EB)},
    ];

    final disciplines = ['APS-II', 'BD-II', 'FIS', 'FSO'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por Categoria',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...eventCategories.map((cat) {
            final tipo = cat['tipo'] as String;
            final cor = cat['cor'] as Color;
            final isChecked = controller.activeEventTypes.contains(tipo);
            return InkWell(
              onTap: () => controller.toggleEventTypeFilter(tipo),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: cor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tipo, style: const TextStyle(fontSize: 13)),
                    ),
                    Icon(
                      isChecked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                      color: const Color(0xFF18181B),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text(
            'Filtrar por Disciplina',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...disciplines.map((d) {
            final isChecked = controller.activeDisciplineFilters.contains(d);
            return InkWell(
              onTap: () => controller.toggleDisciplineFilter(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(d, style: const TextStyle(fontSize: 13)),
                    ),
                    Icon(
                      isChecked
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                      color: const Color(0xFF18181B),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

