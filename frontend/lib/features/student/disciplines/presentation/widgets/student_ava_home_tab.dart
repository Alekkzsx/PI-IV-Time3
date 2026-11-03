import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/student_models.dart';
import 'ava_section_card.dart';

class StudentAvaHomeTab extends StatelessWidget {
  final StudentDisciplineModel discipline;
  final VoidCallback onNavigateToAssignments;

  const StudentAvaHomeTab({
    super.key,
    required this.discipline,
    required this.onNavigateToAssignments,
  });

  @override
  Widget build(BuildContext context) {
    final units = discipline.syllabusUnits;
    final materials = discipline.materials;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Módulos & Conteúdos de Aprendizagem',
          style: jakarta(
            size: 18,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Unidades e materiais publicados para ${discipline.name}.',
          style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
        ),
        const SizedBox(height: 20),
        AvaSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unidades didáticas', style: AvaSectionStyles.title),
              if (units.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('Nenhuma unidade foi publicada.'),
                )
              else
                for (final unit in units)
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(
                      (unit['title'] ?? unit['name'] ?? 'Unidade').toString(),
                    ),
                    subtitle: Text(
                      (unit['description'] ?? unit['topics'] ?? '').toString(),
                    ),
                  ),
              const Divider(),
              const Text('Materiais', style: AvaSectionStyles.title),
              if (materials.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('Nenhum material foi publicado.'),
                )
              else
                for (final material in materials)
                  ListTile(
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(material.title),
                    subtitle: Text('${material.fileType} • ${material.size}'),
                    trailing: IconButton(
                      tooltip: 'Baixar ${material.fileName}',
                      icon: const Icon(Icons.download_outlined),
                      onPressed: () async {
                        try {
                          final path = await StudentPortalController.instance
                              .downloadMaterial(material);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                path == null
                                    ? 'Não foi possível salvar o material.'
                                    : 'Material salvo em $path',
                              ),
                            ),
                          );
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                    ),
                  ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: onNavigateToAssignments,
                  child: const Text('Ver atividades'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
