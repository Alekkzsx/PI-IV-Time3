// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/grade_record.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    'Atividades N1 (Peso 40%)', ativController),
                const SizedBox(height: 12),
                _buildGradeInputField('Prova P1 (Peso 60%)', p1Controller),
                const SizedBox(height: 12),
                _buildGradeInputField(
                    'Projetos N2 (Peso 40%)', projController),
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
              onPressed: () {
                final ativ = double.tryParse(ativController.text) ??
                    grade.assignmentsScore;
                final p1 =
                    double.tryParse(p1Controller.text) ?? grade.p1Score;
                final proj = double.tryParse(projController.text) ??
                    grade.projectsScore;
                final p2 =
                    double.tryParse(p2Controller.text) ?? grade.p2Score;

                controller.updateStudentGrade(
                  grade.studentId,
                  assignments: ativ.clamp(0.0, 10.0),
                  p1: p1.clamp(0.0, 10.0),
                  projects: proj.clamp(0.0, 10.0),
                  p2: p2.clamp(0.0, 10.0),
                );

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Notas de ${grade.studentName} recalculadas com sucesso!',
                    ),
                    backgroundColor: DocenteColors.emerald,
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
      String label, TextEditingController textController) {
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

