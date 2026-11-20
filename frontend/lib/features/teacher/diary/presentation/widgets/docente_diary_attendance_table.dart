// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/attendance_record.dart';
import 'components/attendance_student_tile.dart';

/// Tabela interativa de chamada discente com botões de presença (P, F, J) e estatísticas regimentais.
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
    final list = session.attendanceList;
    final totalCount = list.length;
    final presentCount = list
        .where((s) => s.status == AttendanceStatus.presente)
        .length;
    final absentCount = list
        .where((s) => s.status == AttendanceStatus.ausente)
        .length;
    final justifiedCount = list
        .where((s) => s.status == AttendanceStatus.justificada)
        .length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: InstColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de Resumo Superior + Botão Marcar Todos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 10,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    Text(
                      'Total: $totalCount',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                      ),
                    ),
                    Text(
                      'Presentes: $presentCount',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: InstColors.success,
                      ),
                    ),
                    Text(
                      'Faltas: $absentCount',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: InstColors.danger,
                      ),
                    ),
                    Text(
                      'Justificadas: $justifiedCount',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: InstColors.muted,
                      ),
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: () {
                    controller.markAllPresent();
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Todos os estudantes foram marcados como presentes!',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: InstColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    'Marcar Todos como Presentes',
                    style: jakarta(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: InstColors.border),

          // Tabela com Rolagem Horizontal
          LayoutBuilder(
            builder: (context, constraints) {
              const minWidth = 1000.0;
              final tableWidth = constraints.maxWidth < minWidth
                  ? minWidth
                  : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      for (int i = 0; i < list.length; i++)
                        AttendanceStudentTile(
                          student: list[i],
                          isLast: i == list.length - 1,
                          onToggleAttendance: (status) => controller
                              .toggleAttendance(list[i].studentId, status),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: InstColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              'R.A.',
              style: jakarta(
                size: 11,
                weight: FontWeight.w700,
                color: InstColors.faint,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'ESTUDANTE',
              style: jakarta(
                size: 11,
                weight: FontWeight.w700,
                color: InstColors.faint,
                letterSpacing: 0.3,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Center(
              child: Text(
                'PRESENÇA NA AULA',
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  color: InstColors.faint,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Center(
              child: Text(
                'FALTAS ACUMULADAS',
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  color: InstColors.faint,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Center(
              child: Text(
                'FREQUÊNCIA (%)',
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  color: InstColors.faint,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'SITUAÇÃO REGIMENTAL',
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  color: InstColors.faint,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
