// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Seção "Prazos e Entregas" do Painel Geral - Padrão estético fiel às referências
// Dados 100% tratados no backend/MongoDB

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/teacher_dashboard_overview.dart';

/// Card "Prazos e Entregas" na coluna direita do Painel Geral.
/// Segue exatamente o estilo de barra vertical lateral de 3px (sem ícones coloridos).
class DocenteAssessmentPreviewCard extends StatelessWidget {
  final DocenteController controller;

  const DocenteAssessmentPreviewCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final upcoming = controller.dashboard.upcomingDeadlines;
    final items = upcoming.items;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prazos e Entregas',
                style: jakarta(
                  size: 16,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  upcoming.totalCountFormatted,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Nenhuma entrega pendente no momento.',
                  style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
                ),
              ),
            )
          else
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 18),
              _buildDeadlineRow(items[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildDeadlineRow(TeacherDeadlinePreviewItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 52,
          decoration: BoxDecoration(
            color: item.isUrgent
                ? const Color(0xFF18181B)
                : const Color(0xFFE4E4E7),
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.courseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: jakarta(
                  size: 11,
                  color: const Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: Color(0xFFA1A1AA),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.dueLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: jakarta(
                        size: 10.5,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
