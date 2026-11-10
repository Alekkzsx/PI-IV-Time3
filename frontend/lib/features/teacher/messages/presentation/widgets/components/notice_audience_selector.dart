// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import '../../../../shared/domain/models/docente_course.dart';
import '../../../../shared/theme/docente_colors.dart';

/// Seletor molecular de turma e público-alvo para despacho de avisos institucionais.
class NoticeAudienceSelector extends StatelessWidget {
  final List<DocenteCourse> courses;
  final String selectedCourse;
  final ValueChanged<String?> onCourseChanged;
  final List<String> audiences;
  final String selectedAudience;
  final ValueChanged<String?> onAudienceChanged;

  const NoticeAudienceSelector({
    super.key,
    required this.courses,
    required this.selectedCourse,
    required this.onCourseChanged,
    required this.audiences,
    required this.selectedAudience,
    required this.onAudienceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Turma / Disciplina',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DocenteColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: DocenteColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCourse,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: DocenteColors.charcoal,
                    ),
                    items: [
                      ...courses.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.code,
                          child: Text('${c.code} - ${c.name}'),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: 'TODAS',
                        child: Text('Todas as Turmas do Semestre'),
                      ),
                    ],
                    onChanged: onCourseChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Público-Alvo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DocenteColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: DocenteColors.offWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedAudience,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: DocenteColors.charcoal,
                    ),
                    items: audiences.map((aud) {
                      return DropdownMenuItem<String>(
                        value: aud,
                        child: Text(aud),
                      );
                    }).toList(),
                    onChanged: onAudienceChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
