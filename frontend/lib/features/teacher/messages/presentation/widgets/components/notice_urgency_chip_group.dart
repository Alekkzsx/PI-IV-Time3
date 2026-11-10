// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import '../../../../shared/domain/models/academic_notice.dart';
import '../../../../shared/theme/docente_colors.dart';

/// Seletor atômico de classificação de urgência do comunicado (Informativo, Urgência, Convocação).
class NoticeUrgencyChipGroup extends StatelessWidget {
  final NoticeClassification selectedClassification;
  final ValueChanged<NoticeClassification> onClassificationChanged;

  const NoticeUrgencyChipGroup({
    super.key,
    required this.selectedClassification,
    required this.onClassificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classificação do Comunicado',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DocenteColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: NoticeClassification.values.map((classification) {
            final isSelected = selectedClassification == classification;
            Color activeColor;
            String label;

            switch (classification) {
              case NoticeClassification.informativo:
                activeColor = const Color(0xFF2563EB); // Blue
                label = 'Informativo';
                break;
              case NoticeClassification.urgencia:
                activeColor = DocenteColors.amber;
                label = 'Urgência';
                break;
              case NoticeClassification.convocacao:
                activeColor = DocenteColors.crimson;
                label = 'Convocação';
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => onClassificationChanged(classification),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.12)
                        : DocenteColors.offWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? activeColor : DocenteColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? activeColor
                              : DocenteColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
