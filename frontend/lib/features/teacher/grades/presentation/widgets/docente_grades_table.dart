// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';

/// Tabela interativa com os lançamentos oficiais de notas da turma.
class DocenteGradesTable extends StatelessWidget {
  final List<StudentGrade> gradebook;
  final ValueChanged<StudentGrade> onEditGrade;

  const DocenteGradesTable({
    super.key,
    required this.gradebook,
    required this.onEditGrade,
  });

  @override
  Widget build(BuildContext context) {
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
                headingRowColor: WidgetStateProperty.all(
                  DocenteColors.offWhite,
                ),
                columnSpacing: 18,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Discente',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Freq.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Ativ. (40%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'P1 (60%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Nota N1',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Proj. (40%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'P2 (60%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Nota N2',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'MS',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Situação',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Editar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'RA: ${grade.ra}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: DocenteColors.slate,
                              ),
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
                                color: grade.attendanceRate < 75.0
                                    ? DocenteColors.crimson
                                    : DocenteColors.charcoal,
                              ),
                            ),
                            if (grade.attendanceRate < 75.0) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: DocenteColors.crimson,
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          grade.assignmentsScore.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Text(
                          grade.p1Score.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Text(
                          grade.n1Score.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DocenteColors.charcoal,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          grade.projectsScore.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Text(
                          grade.p2Score.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Text(
                          grade.n2Score.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DocenteColors.charcoal,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DocenteColors.charcoal.withValues(
                              alpha: 0.06,
                            ),
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
                          onPressed: () => onEditGrade(grade),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: DocenteColors.charcoal,
                          ),
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
