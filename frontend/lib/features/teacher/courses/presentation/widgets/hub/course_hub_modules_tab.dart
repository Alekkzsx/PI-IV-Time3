// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Aba de Módulos & Conteúdos no Cockpit da Disciplina (Course Hub)

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';

class CourseHubModulesTab extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback? onNewUnit;
  final VoidCallback? onUploadSlides;
  final VoidCallback onPublishAssignment;
  final VoidCallback onQuickNotice;
  final VoidCallback onReviewSyllabus;
  final VoidCallback onNavigateToAssignments;

  const CourseHubModulesTab({
    super.key,
    required this.controller,
    this.onNewUnit,
    this.onUploadSlides,
    required this.onPublishAssignment,
    required this.onQuickNotice,
    required this.onReviewSyllabus,
    required this.onNavigateToAssignments,
  });

  @override
  Widget build(BuildContext context) {
    final course = controller.selectedCourse;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Conteúdos e materiais didáticos',
                style: jakarta(
                  size: 18,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onReviewSyllabus,
              icon: const Icon(Icons.upload_file_outlined, size: 16),
              label: const Text('Enviar material'),
              style: OutlinedButton.styleFrom(
                foregroundColor: InstColors.ink,
                side: const BorderSide(color: InstColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Unidades de Ensino
        if (course.syllabusUnits.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: InstColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: InstColors.border),
            ),
            child: Center(
              child: Text(
                'Nenhuma unidade de conteúdo cadastrada.',
                style: jakarta(size: 13, color: InstColors.muted),
              ),
            ),
          )
        else
          ...course.syllabusUnits.map(
            (unit) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: InstColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: InstColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: InstColors.stoneActive,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${unit.unitNumber}',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.title,
                          style: jakarta(
                            size: 14,
                            weight: FontWeight.w700,
                            color: InstColors.ink,
                          ),
                        ),
                        if (unit.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            unit.description,
                            style: jakarta(size: 12, color: InstColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${unit.completedClasses}/${unit.totalClasses} aulas',
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w600,
                        color: InstColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),

        // Materiais Publicados
        Text(
          'Materiais publicados para download',
          style: jakarta(
            size: 15,
            weight: FontWeight.w700,
            color: InstColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        if (course.materials.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: InstColors.stone,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: InstColors.border),
            ),
            child: Text(
              'Nenhum material publicado para esta turma.',
              style: jakarta(size: 12.5, color: InstColors.muted),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: InstColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: InstColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: course.materials.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              itemBuilder: (context, index) {
                final material = course.materials[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: InstColors.muted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material.title,
                              style: jakarta(
                                size: 13,
                                weight: FontWeight.w600,
                                color: InstColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${material.type} • ${material.size} • ${material.date}',
                              style: jakarta(size: 11.5, color: InstColors.faint),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),

        // Botões de Ação Rápida
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: onPublishAssignment,
              icon: const Icon(Icons.assignment_add, size: 16),
              label: const Text('Nova atividade'),
              style: ElevatedButton.styleFrom(
                backgroundColor: InstColors.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onQuickNotice,
              icon: const Icon(Icons.campaign_outlined, size: 16),
              label: const Text('Novo comunicado'),
              style: OutlinedButton.styleFrom(
                foregroundColor: InstColors.ink,
                side: const BorderSide(color: InstColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            TextButton(
              onPressed: onNavigateToAssignments,
              child: Text(
                'Ver todas as atividades →',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: InstColors.ink,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
