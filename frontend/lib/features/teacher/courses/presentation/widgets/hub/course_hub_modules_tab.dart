import 'package:flutter/material.dart';
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
        Row(children: [
          const Expanded(
            child: Text('Conte?dos e materiais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          OutlinedButton.icon(
            onPressed: onReviewSyllabus,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Enviar material'),
          ),
        ]),
        const SizedBox(height: 16),
        if (course.syllabusUnits.isEmpty)
          const Text('Nenhuma unidade de conte?do cadastrada.')
        else
          ...course.syllabusUnits.map((unit) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${unit.unitNumber}')),
                  title: Text(unit.title),
                  subtitle: Text(unit.description),
                  trailing: Text('${unit.completedClasses}/${unit.totalClasses} aulas'),
                ),
              )),
        const SizedBox(height: 20),
        const Text('Materiais publicados',
            style: TextStyle(fontWeight: FontWeight.bold)),
        if (course.materials.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nenhum material publicado para esta turma.'),
          )
        else
          ...course.materials.map((material) => ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(material.title),
                subtitle: Text('${material.type} ? ${material.size} ? ${material.date}'),
              )),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            onPressed: onPublishAssignment,
            icon: const Icon(Icons.assignment_add),
            label: const Text('Nova atividade'),
          ),
          OutlinedButton.icon(
            onPressed: onQuickNotice,
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Novo comunicado'),
          ),
          TextButton(
            onPressed: onNavigateToAssignments,
            child: const Text('Ver atividades'),
          ),
        ]),
      ],
    );
  }
}
