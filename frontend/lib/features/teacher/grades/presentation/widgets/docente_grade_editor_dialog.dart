// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';

/// Diálogo modal para edição das notas parciais (Atividades, P1, Projetos, P2) de um discente.
class DocenteGradeEditorDialog {
  DocenteGradeEditorDialog._();

  static void show(
    BuildContext context, {
    required DocenteController controller,
    required StudentGrade grade,
  }) {
    final ativController = TextEditingController(
      text: grade.assignmentsScore.toStringAsFixed(1),
    );
    final p1Controller = TextEditingController(
      text: grade.p1Score.toStringAsFixed(1),
    );
    final projController = TextEditingController(
      text: grade.projectsScore.toStringAsFixed(1),
    );
    final p2Controller = TextEditingController(
      text: grade.p2Score.toStringAsFixed(1),
    );

    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: DocenteColors.charcoal),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar Notas: ${grade.studentName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'RA: ${grade.ra} • Freq: ${grade.attendanceRate}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: DocenteColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGradeInputField(
                  'Atividades N1 (Peso 40%)',
                  ativController,
                ),
                const SizedBox(height: 12),
                _buildGradeInputField('Prova P1 (Peso 60%)', p1Controller),
                const SizedBox(height: 12),
                _buildGradeInputField('Projetos N2 (Peso 40%)', projController),
                const SizedBox(height: 12),
                _buildGradeInputField('Prova P2 (Peso 60%)', p2Controller),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: DocenteColors.slate),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                double parseInput(String raw, double fallback) {
                  final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
                  if (parsed == null || !parsed.isFinite) return fallback;
                  return double.parse(parsed.clamp(0.0, 10.0).toStringAsFixed(1));
                }

                final ativ = parseInput(ativController.text, grade.assignmentsScore);
                final p1 = parseInput(p1Controller.text, grade.p1Score);
                final proj = parseInput(projController.text, grade.projectsScore);
                final p2 = parseInput(p2Controller.text, grade.p2Score);

                Navigator.of(ctx).pop();
                final ok = await controller.updateStudentGrade(
                  grade.studentId,
                  assignments: ativ,
                  p1: p1,
                  projects: proj,
                  p2: p2,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Notas de ${grade.studentName} salvas e recalculadas com sucesso!'
                          : (controller.remoteError ?? 'Não foi possível salvar as notas.'),
                    ),
                    backgroundColor: ok ? DocenteColors.emerald : const Color(0xFFDC2626),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DocenteColors.charcoal,
                foregroundColor: DocenteColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Salvar e Recalcular'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildGradeInputField(
    String label,
    TextEditingController textController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DocenteColors.charcoal,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: DocenteColors.offWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DocenteColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
