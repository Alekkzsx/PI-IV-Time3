import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';

class CourseHubGradebookTab extends StatelessWidget {
  final DocenteController controller;

  const CourseHubGradebookTab({super.key, required this.controller});

  Future<void> _export(BuildContext context) async {
    final rows = [
      ['RA', 'Discente', 'N1', 'N2', 'M?dia', 'Frequ?ncia', 'Situa??o'],
      ...controller.gradebook.map((grade) => [
            grade.ra,
            grade.studentName,
            grade.n1Total.toStringAsFixed(1),
            grade.n2Total.toStringAsFixed(1),
            grade.finalAverage.toStringAsFixed(1),
            grade.attendanceRate.toStringAsFixed(1),
            grade.statusLabel,
          ]),
    ];
    final csv = rows
        .map((row) => row.map((field) => '"${field.replaceAll('"', '""')}"').join(';'))
        .join('\n');
    final path = await PlatformFileHelper.saveOrDownloadFile(
      fileName: 'notas-${controller.selectedCourse.code}.csv',
      bytes: utf8.encode(csv),
      mimeType: 'text/csv',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(path == null ? 'N?o foi poss?vel exportar.' : 'Arquivo salvo: $path'),
      ));
    }
  }

  Future<void> _homologate(BuildContext context) async {
    await controller.homologarPautaComChancela(controller.selectedCourse.id);
    if (context.mounted && controller.remoteError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.remoteError!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grades = controller.gradebook;
    final average = grades.isEmpty
        ? 0.0
        : grades.map((grade) => grade.finalAverage).reduce((a, b) => a + b) /
              grades.length;
    final approved = grades.where((grade) => grade.statusLabel == 'Aprovado').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 12, runSpacing: 12, children: [
          _metric('Estudantes', '${grades.length}'),
          _metric('M?dia geral', average.toStringAsFixed(1)),
          _metric('Aprovados', '$approved / ${grades.length}'),
          _metric('Regra', 'N1 40% ? N2 60% ? aprova??o ? 6'),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          OutlinedButton.icon(
            onPressed: () => _export(context),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Exportar CSV'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: grades.isEmpty ? null : () => _homologate(context),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Homologar pauta'),
          ),
        ]),
        const SizedBox(height: 16),
        if (grades.isEmpty)
          const Text('Nenhuma nota cadastrada para esta turma.')
        else
          ...grades.map((grade) => Card(
                child: ListTile(
                  title: Text(grade.studentName),
                  subtitle: Text('${grade.ra} ? N1 ${grade.n1Total.toStringAsFixed(1)} ? N2 ${grade.n2Total.toStringAsFixed(1)} ? frequ?ncia ${grade.attendanceRate.toStringAsFixed(1)}%'),
                  trailing: Text('${grade.finalAverage.toStringAsFixed(1)} ? ${grade.statusLabel}'),
                ),
              )),
      ],
    );
  }

  Widget _metric(String label, String value) => SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );
}
