// Componente atômico para exibição da linha de presença discente

import 'package:flutter/material.dart';
import '../../../../shared/domain/models/attendance_record.dart';

class AttendanceStudentTile extends StatelessWidget {
  final AttendanceStudent student;
  final bool isLast;
  final void Function(AttendanceStatus) onToggleAttendance;

  const AttendanceStudentTile({
    super.key,
    required this.student,
    required this.isLast,
    required this.onToggleAttendance,
  });

  @override
  Widget build(BuildContext context) {
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
                        Expanded(
                          child: Text(
                            student.observation!,
                            style: const TextStyle(
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
                    onTap: () => onToggleAttendance(AttendanceStatus.presente),
                  ),
                  const SizedBox(width: 4),
                  _buildAttendancePill(
                    label: 'F',
                    isActive: student.status == AttendanceStatus.ausente,
                    activeBg: const Color(0xFF7F1D1D),
                    onTap: () => onToggleAttendance(AttendanceStatus.ausente),
                  ),
                  const SizedBox(width: 4),
                  _buildAttendancePill(
                    label: 'J',
                    isActive: student.status == AttendanceStatus.justificada,
                    activeBg: const Color(0xFF92400E),
                    onTap: () => onToggleAttendance(AttendanceStatus.justificada),
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
