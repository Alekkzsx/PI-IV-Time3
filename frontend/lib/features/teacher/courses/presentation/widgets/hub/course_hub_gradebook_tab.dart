// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Aba de Livro de Notas (Gradebook) no Cockpit da Disciplina (Course Hub)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/shared/widgets/academic_status_badge.dart';

class CourseHubGradebookTab extends StatelessWidget {
  final DocenteController controller;

  const CourseHubGradebookTab({super.key, required this.controller});

  Future<void> _export(BuildContext context) async {
    final rows = [
      ['RA', 'Discente', 'N1', 'N2', 'Média', 'Frequência', 'Situação'],
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
        content: Text(path == null ? 'Não foi possível exportar.' : 'Arquivo salvo: $path'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _homologate(BuildContext context) async {
    await controller.homologarPautaComChancela(controller.selectedCourse.id);
    if (context.mounted && controller.remoteError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.remoteError!),
          behavior: SnackBarBehavior.floating,
        ),
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
        // Métricas Superiores
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _metric('Estudantes', '${grades.length}', 'Matriculados ativos'),
            _metric('Média geral', average.toStringAsFixed(1), 'Média aritmética PPC'),
            _metric('Aprovados', '$approved / ${grades.length}', 'Aproveitamento geral'),
            _metric('Regra de Cálculo', 'N1 40% + N2 60%', 'Aprovação: média ≥ 6.0'),
          ],
        ),
        const SizedBox(height: 22),

        // Barra de Ações
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _export(context),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Exportar CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: InstColors.ink,
                side: const BorderSide(color: InstColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: grades.isEmpty ? null : () => _homologate(context),
              icon: const Icon(Icons.verified_outlined, size: 16),
              label: const Text('Homologar pauta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: InstColors.ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Lista de Notas dos Estudantes
        if (grades.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: InstColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: InstColors.border),
            ),
            child: Center(
              child: Text(
                'Nenhuma nota cadastrada para esta turma.',
                style: jakarta(size: 13, color: InstColors.muted),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: InstColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: InstColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: grades.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              itemBuilder: (context, index) {
                final grade = grades[index];
                final isApproved = grade.statusLabel == 'Aprovado';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              grade.studentName,
                              style: jakarta(
                                size: 14,
                                weight: FontWeight.w700,
                                color: InstColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'RA: ${grade.ra} • N1: ${grade.n1Total.toStringAsFixed(1)} • N2: ${grade.n2Total.toStringAsFixed(1)} • Frequência: ${grade.attendanceRate.toStringAsFixed(1)}%',
                              style: jakarta(size: 12, color: InstColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            grade.finalAverage.toStringAsFixed(1),
                            style: jakarta(
                              size: 16,
                              weight: FontWeight.w700,
                              color: isApproved ? InstColors.ink : InstColors.danger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AcademicStatusBadge(
                            label: grade.statusLabel,
                            type: isApproved
                                ? AcademicStatusType.aprovado
                                : AcademicStatusType.reprovado,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _metric(String label, String value, String subtitle) => Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: InstColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: InstColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: jakarta(
                size: 11,
                weight: FontWeight.w700,
                color: InstColors.faint,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: jakarta(
                size: 22,
                weight: FontWeight.w700,
                color: InstColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: jakarta(size: 11, color: InstColors.muted),
            ),
          ],
        ),
      );
}
