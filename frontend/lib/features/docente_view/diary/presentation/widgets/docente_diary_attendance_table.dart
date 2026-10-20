// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/attendance_record.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Tabela interativa de chamada discente com botões de presença (P, F, J) e alerta de risco.
class DocenteDiaryAttendanceTable extends StatelessWidget {
  final DocenteController controller;
  final ClassSession session;

  const DocenteDiaryAttendanceTable({
    super.key,
    required this.controller,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Registro de Chamada Discente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DocenteColors.textPrimary,
                  ),
                ),
                Text(
                  '${session.attendanceList.length} estudantes listados',
                  style: const TextStyle(
                    fontSize: 13,
                    color: DocenteColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: DocenteColors.border),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(DocenteColors.background),
              dataRowMinHeight: 64,
              dataRowMaxHeight: 74,
              columns: const [
                DataColumn(label: Text('R.A.')),
                DataColumn(label: Text('ESTUDANTE')),
                DataColumn(label: Text('CHAMADA')),
                DataColumn(label: Text('FALTAS ACUMULADAS')),
                DataColumn(label: Text('FREQUÊNCIA')),
                DataColumn(label: Text('SITUAÇÃO')),
              ],
              rows: session.attendanceList.map((student) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        student.ra,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: DocenteColors.textPrimary,
                            ),
                          ),
                          if (student.observation != null)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DocenteColors.infoLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                student.observation!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: DocenteColors.info,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      _buildPresenceButtons(student),
                    ),
                    DataCell(
                      Text(
                        '${student.accumulatedAbsences} / ${student.maxAbsences} máx',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${student.attendanceRate}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: student.attendanceRate < 75.0
                              ? DocenteColors.danger
                              : DocenteColors.textPrimary,
                        ),
                      ),
                    ),
                    DataCell(
                      _buildRiskBadge(student.riskLevel),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresenceButtons(AttendanceStudent student) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPill(
          label: 'P',
          isSelected: student.status == AttendanceStatus.presente,
          activeBg: DocenteColors.success,
          onTap: () => controller.toggleAttendance(
            student.studentId,
            AttendanceStatus.presente,
          ),
          tooltip: 'Marcar Presente',
        ),
        const SizedBox(width: 6),
        _buildPill(
          label: 'F',
          isSelected: student.status == AttendanceStatus.ausente,
          activeBg: DocenteColors.danger,
          onTap: () => controller.toggleAttendance(
            student.studentId,
            AttendanceStatus.ausente,
          ),
          tooltip: 'Marcar Falta',
        ),
        const SizedBox(width: 6),
        _buildPill(
          label: 'J',
          isSelected: student.status == AttendanceStatus.justificada,
          activeBg: DocenteColors.warning,
          onTap: () => controller.toggleAttendance(
            student.studentId,
            AttendanceStatus.justificada,
          ),
          tooltip: 'Marcar Falta Justificada',
        ),
      ],
    );
  }

  Widget _buildPill({
    required String label,
    required bool isSelected,
    required Color activeBg,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? activeBg : DocenteColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? activeBg : DocenteColors.borderDark,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : DocenteColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskBadge(AttendanceRiskLevel risk) {
    String text;
    Color color;
    Color bg;

    switch (risk) {
      case AttendanceRiskLevel.regular:
        text = 'Regular';
        color = DocenteColors.success;
        bg = DocenteColors.successLight;
        break;
      case AttendanceRiskLevel.atencao:
        text = 'Atenção';
        color = DocenteColors.warning;
        bg = DocenteColors.warningLight;
        break;
      case AttendanceRiskLevel.critico:
        text = 'Risco de Reprovação';
        color = DocenteColors.danger;
        bg = DocenteColors.dangerLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
