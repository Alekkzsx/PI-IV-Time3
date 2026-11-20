// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../../../../shared/domain/models/docente_course.dart';
import '../../../../shared/theme/docente_colors.dart';

/// Item atômico de material didático disponível para download no AVA.
class CourseMaterialItemTile extends StatelessWidget {
  final CourseMaterial material;

  const CourseMaterialItemTile({
    super.key,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DocenteColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 22,
              color: DocenteColors.danger,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DocenteColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Publicado em ${material.date} • ${material.size} • ${material.type}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DocenteColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: DocenteColors.successLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Disponível no AVA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: DocenteColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
