// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
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
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Summary Bar + Botão Marcar Todos
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
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    Text(
                      'Presentes: $presentCount',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      'Faltas: $absentCount',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    Text(
                      'Justificadas: $justifiedCount',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
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
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Marcar Todos como Presentes',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4E4E7)),

          // Table with Horizontal Scroll
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
        border: Border(bottom: BorderSide(color: Color(0xFFE4E4E7))),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 140,
            child: Text(
              'R.A.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF71717A),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'ESTUDANTE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF71717A),
                letterSpacing: 0.3,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Center(
              child: Text(
                'PRESENÇA NA AULA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF71717A),
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF71717A),
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF71717A),
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF71717A),
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
