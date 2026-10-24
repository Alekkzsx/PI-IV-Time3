// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/attendance_record.dart';

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
                        _buildTableRow(list[i], isLast: i == list.length - 1),
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

  Widget _buildTableRow(AttendanceStudent student, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF4F4F5))),
      ),
      child: Row(
        children: [
          // R.A.
          SizedBox(
            width: 140,
            child: Text(
              student.ra,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF52525B),
                fontFamily: 'monospace',
              ),
            ),
          ),

          // ESTUDANTE + Badge ou Observação
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (student.isConnected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Text(
                          'DISCENTE CONECTADO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (student.observation != null) ...[
                  const SizedBox(height: 3),
                  if (student.observation!.contains('Atestado'))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            size: 11,
                            color: Color(0xFF047857),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Falta Abonada (Secretaria Prot. 2026/8841)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF047857),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      student.observation!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF71717A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ],
            ),
          ),

          // PRESENÇA NA AULA [P] [F] [J]
          SizedBox(
            width: 150,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAttendancePill(
                    label: 'P',
                    isActive: student.status == AttendanceStatus.presente,
                    activeBg: const Color(0xFF18181B),
                    onTap: () => controller.toggleAttendance(
                      student.studentId,
                      AttendanceStatus.presente,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildAttendancePill(
                    label: 'F',
                    isActive: student.status == AttendanceStatus.ausente,
                    activeBg: const Color(0xFF7F1D1D),
                    onTap: () => controller.toggleAttendance(
                      student.studentId,
                      AttendanceStatus.ausente,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildAttendancePill(
                    label: 'J',
                    isActive: student.status == AttendanceStatus.justificada,
                    activeBg: const Color(0xFF92400E),
                    onTap: () => controller.toggleAttendance(
                      student.studentId,
                      AttendanceStatus.justificada,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FALTAS ACUMULADAS (2 / 20 máx)
          SizedBox(
            width: 160,
            child: Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${student.accumulatedAbsences} ',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF09090B),
                      ),
                    ),
                    TextSpan(
                      text: '/ ${student.maxAbsences} máx',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF60A5FA),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // FREQUÊNCIA (%)
          SizedBox(
            width: 140,
            child: Center(
              child: Text(
                '${student.attendanceRate}%',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: student.attendanceRate < 75.0
                      ? const Color(0xFFDC2626)
                      : (student.attendanceRate < 80.0
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF09090B)),
                ),
              ),
            ),
          ),

          // SITUAÇÃO REGIMENTAL
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildRiskBadge(student.riskLevel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancePill({
    required String label,
    required bool isActive,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? activeBg : const Color(0xFFE4E4E7),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : const Color(0xFF27272A),
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
    Color border;

    switch (risk) {
      case AttendanceRiskLevel.regular:
        text = 'Regular';
        color = const Color(0xFF059669);
        bg = const Color(0xFFECFDF5);
        border = const Color(0xFFA7F3D0);
        break;
      case AttendanceRiskLevel.atencao:
        text = 'Atenção (>15%)';
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFDE68A);
        break;
      case AttendanceRiskLevel.critico:
        text = 'Risco de Reprovação';
        color = const Color(0xFFDC2626);
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFFECACA);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
