// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';
import '../widgets/docente_grade_editor_dialog.dart';
import '../widgets/docente_grades_kpis_row.dart';
import '../widgets/docente_grades_table.dart';

/// Tab page for managing student official gradebook, PPC formula calculations, and issuing minutes.
class DocenteGradesTab extends StatelessWidget {
  /// Reactive controller for state access and mutations.
  final DocenteController controller;

  const DocenteGradesTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final gradebook = controller.gradebook;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          DocenteGradesKpisRow(gradebook: gradebook),
          const SizedBox(height: 20),
          _buildFormulaBanner(),
          const SizedBox(height: 24),
          DocenteGradesTable(
            gradebook: gradebook,
            onEditGrade: (grade) {
              DocenteGradeEditorDialog.show(
                context,
                controller: controller,
                grade: grade,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Livro de Notas & Gradebook Oficial',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DocenteColors.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cálculo automático de N1, N2 e Média Semestral segundo PPC • ${controller.selectedCourse.name}',
              style: const TextStyle(
                fontSize: 14,
                color: DocenteColors.slate,
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exportação da planilha (CSV) concluída.'),
                    backgroundColor: DocenteColors.charcoal,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Exportar CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DocenteColors.charcoal,
                side: const BorderSide(color: DocenteColors.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ata Semestral da Turma homologada e gerada em PDF.',
                    ),
                    backgroundColor: DocenteColors.emerald,
                  ),
                );
              },
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('Emitir Ata da Turma'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DocenteColors.charcoal,
                foregroundColor: DocenteColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormulaBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocenteColors.offWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DocenteColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.functions, color: DocenteColors.charcoal, size: 22),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Regra de Avaliação PPC: N1 = (Atividades × 0.4) + (P1 × 0.6)  |  N2 = (Projetos × 0.4) + (P2 × 0.6)  |  Média Semestral (MS) = (N1 × 0.4) + (N2 × 0.6)\n'
              'Critérios de Aprovação: Frequência ≥ 75% e MS ≥ 7.0 (Aprovado)  •  4.0 ≤ MS < 7.0 (Exame)  •  MS < 4.0 (Reprovado por Nota)  •  Freq < 75% (Reprovado por Falta)',
              style: TextStyle(
                fontSize: 12,
                color: DocenteColors.charcoal,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
