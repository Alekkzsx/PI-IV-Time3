import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';

class DocenteCoursesPreviewSection extends StatelessWidget {
  final DocenteController controller;
  final void Function(String courseId)? onOpenCourseHub;

  const DocenteCoursesPreviewSection({
    super.key,
    required this.controller,
    this.onOpenCourseHub,
  });

  @override
  Widget build(BuildContext context) {
    final courses = controller.courses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Minhas Turmas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => controller.navigateToTab(DocenteNavTab.turmas),
              child: const Text('Ver grade'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (courses.isEmpty)
          const Text('Nenhuma turma vinculada à sua conta.')
        else
          ...courses.map(
            (course) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(course.title),
                subtitle: Text(
                  '${course.code} · ${course.shift} · ${course.enrolledCount} discentes · ${course.progressPercentage.toStringAsFixed(0)}% do plano',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  if (onOpenCourseHub != null) {
                    onOpenCourseHub!(course.id);
                  } else {
                    controller.navigateToTab(DocenteNavTab.turmas);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}
