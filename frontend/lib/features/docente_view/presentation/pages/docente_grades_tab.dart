// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../../domain/models/grade_record.dart';
import '../controllers/docente_controller.dart';

/// Tab page for managing student official gradebook, PPC formula calculations, and issuing minutes.
class DocenteGradesTab extends StatelessWidget {
  /// Reactive controller for state access and mutations.
  final DocenteController controller;

  const DocenteGradesTab({
    super.key,
    required this.controller,
  });

  void _openGradeEditorDialog(BuildContext context, StudentGrade grade) {
    final ativController = TextEditingController(text: grade.assignmentsScore.toStringAsFixed(1));
    final p1Controller = TextEditingController(text: grade.p1Score.toStringAsFixed(1));
    final projController = TextEditingController(text: grade.projectsScore.toStringAsFixed(1));
    final p2Controller = TextEditingController(text: grade.p2Score.toStringAsFixed(1));

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'RA: ${grade.ra} • Freq: ${grade.attendanceRate}%',
                      style: const TextStyle(fontSize: 12, color: DocenteColors.slate),
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
                _buildGradeInputField('Atividades N1 (Peso 40%)', ativController),
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
              child: const Text('Cancelar', style: TextStyle(color: DocenteColors.slate)),
            ),
            ElevatedButton(
              onPressed: () {
                final ativ = double.tryParse(ativController.text) ?? grade.assignmentsScore;
                final p1 = double.tryParse(p1Controller.text) ?? grade.p1Score;
                final proj = double.tryParse(projController.text) ?? grade.projectsScore;
                final p2 = double.tryParse(p2Controller.text) ?? grade.p2Score;

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
                    content: Text('Notas de ${grade.studentName} recalculadas com sucesso!'),
                    backgroundColor: DocenteColors.emerald,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DocenteColors.charcoal,
                foregroundColor: DocenteColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Salvar e Recalcular'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGradeInputField(String label, TextEditingController textController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DocenteColors.charcoal),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  @override
  Widget build(BuildContext context) {
    final gradebook = controller.gradebook;
    final totalStudents = gradebook.length;
    final approvedCount = gradebook.where((g) => g.status == AcademicStatus.aprovado).length;
    final examCount = gradebook.where((g) => g.status == AcademicStatus.exame).length;
    final absentFailCount = gradebook.where((g) => g.status == AcademicStatus.reprovadoPorFalta).length;
    final classAverage = totalStudents > 0
        ? gradebook.fold(0.0, (acc, g) => acc + g.finalAverage) / totalStudents
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildKpisRow(totalStudents, approvedCount, examCount, absentFailCount, classAverage),
          const SizedBox(height: 20),
          _buildFormulaBanner(),
          const SizedBox(height: 24),
          _buildGradebookTable(context, gradebook),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ata Semestral da Turma homologada e gerada em PDF.'),
                    backgroundColor: DocenteColors.emerald,
                  ),
                );
              },
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('Emitir Ata da Turma'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DocenteColors.charcoal,
                foregroundColor: DocenteColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpisRow(
    int total,
    int approved,
    int exam,
    int absentFails,
    double avg,
  ) {
    return Row(
      children: [
        _buildStatCard('Total de Discentes', '$total', Icons.groups_outlined, DocenteColors.charcoal),
        const SizedBox(width: 12),
        _buildStatCard('Média da Turma', avg.toStringAsFixed(1), Icons.bar_chart_rounded, DocenteColors.emerald),
        const SizedBox(width: 12),
        _buildStatCard('Aprovados Estimados', '$approved', Icons.check_circle_outline, DocenteColors.emerald),
        const SizedBox(width: 12),
        _buildStatCard('Em Exame', '$exam', Icons.help_outline_rounded, DocenteColors.amber),
        const SizedBox(width: 12),
        _buildStatCard('Reprovados Falta', '$absentFails', Icons.warning_amber_rounded, DocenteColors.crimson),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DocenteColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DocenteColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DocenteColors.charcoal,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: DocenteColors.slate),
                ),
              ],
            ),
          ],
        ),
      ),
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
              'Regra de Avaliação PPC: N1 = (Atividades × 0.4) + (P1 × 0.6)  |  N2 = (Projetos × 0.4) + (P2 × 0.6)  |  Média Semestral (MS) = (N1 × 0.4) + (N2 × 0.6)\nCritérios de Aprovação: Frequência ≥ 75% e MS ≥ 7.0 (Aprovado)  •  4.0 ≤ MS < 7.0 (Exame)  •  MS < 4.0 (Reprovado por Nota)  •  Freq < 75% (Reprovado por Falta)',
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

  Widget _buildGradebookTable(BuildContext context, List<StudentGrade> gradebook) {
    return Container(
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Lançamentos Oficiais da Turma',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DocenteColors.charcoal,
              ),
            ),
          ),
          const Divider(height: 1, color: DocenteColors.border),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1080),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(DocenteColors.offWhite),
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('Discente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Freq.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Ativ. (40%)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('P1 (60%)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Nota N1', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Proj. (40%)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('P2 (60%)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Nota N2', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('MS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Situação', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                  DataColumn(label: Text('Editar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                ],
                rows: gradebook.map((grade) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              grade.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              'RA: ${grade.ra}',
                              style: const TextStyle(fontSize: 11, color: DocenteColors.slate),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${grade.attendanceRate}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: grade.attendanceRate < 75.0 ? DocenteColors.crimson : DocenteColors.charcoal,
                              ),
                            ),
                            if (grade.attendanceRate < 75.0) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.warning_amber_rounded, size: 14, color: DocenteColors.crimson),
                            ],
                          ],
                        ),
                      ),
                      DataCell(Text(grade.assignmentsScore.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
                      DataCell(Text(grade.p1Score.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
                      DataCell(
                        Text(
                          grade.n1Score.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
                        ),
                      ),
                      DataCell(Text(grade.projectsScore.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
                      DataCell(Text(grade.p2Score.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
                      DataCell(
                        Text(
                          grade.n2Score.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DocenteColors.charcoal),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: DocenteColors.charcoal.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            grade.finalAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: DocenteColors.charcoal,
                            ),
                          ),
                        ),
                      ),
                      DataCell(_buildStatusBadge(grade.status)),
                      DataCell(
                        IconButton(
                          onPressed: () => _openGradeEditorDialog(context, grade),
                          icon: const Icon(Icons.edit_outlined, size: 18, color: DocenteColors.charcoal),
                          tooltip: 'Editar notas',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AcademicStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case AcademicStatus.aprovado:
        bg = const Color(0xFFECFDF5);
        fg = DocenteColors.emerald;
        label = 'Aprovado';
        break;
      case AcademicStatus.exame:
        bg = const Color(0xFFFFFBEB);
        fg = DocenteColors.amber;
        label = 'Em Exame';
        break;
      case AcademicStatus.reprovadoPorNota:
        bg = const Color(0xFFFEF2F2);
        fg = DocenteColors.crimson;
        label = 'Reprov. Nota';
        break;
      case AcademicStatus.reprovadoPorFalta:
        bg = const Color(0xFFFEF2F2);
        fg = DocenteColors.crimson;
        label = 'Reprov. Falta';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
