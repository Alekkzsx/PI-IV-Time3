// Desenvolvido por Marcelo Zarpelon - RA: 25015323
// Componente atômico para exibição da linha de presença discente

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
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
        color: InstColors.surface,
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
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w700,
                          color: InstColors.ink,
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
                          color: InstColors.warningBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          'DISCENTE CONECTADO',
                          style: jakarta(
                            size: 9,
                            weight: FontWeight.w700,
                            color: InstColors.warning,
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
                      color: InstColors.successBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 11,
                          color: InstColors.success,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            student.observation!,
                            style: jakarta(
                              size: 10,
                              weight: FontWeight.w700,
                              color: InstColors.success,
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
                    activeBg: InstColors.successBg,
                    activeBorder: InstColors.success,
                    activeText: InstColors.success,
                    onTap: () => onToggleAttendance(AttendanceStatus.presente),
                  ),
                  const SizedBox(width: 4),
                  _buildAttendancePill(
                    label: 'F',
                    isActive: student.status == AttendanceStatus.ausente,
                    activeBg: InstColors.dangerBg,
                    activeBorder: InstColors.danger,
                    activeText: InstColors.danger,
                    onTap: () => onToggleAttendance(AttendanceStatus.ausente),
                  ),
                  const SizedBox(width: 4),
                  _buildAttendancePill(
                    label: 'J',
                    isActive: student.status == AttendanceStatus.justificada,
                    activeBg: InstColors.warningBg,
                    activeBorder: InstColors.warning,
                    activeText: InstColors.warning,
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
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: InstColors.ink,
                      ),
                    ),
                    TextSpan(
                      text: '/ ${student.maxAbsences} máx',
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w500,
                        color: InstColors.muted,
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
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: student.attendanceRate < 75.0
                      ? InstColors.danger
                      : InstColors.ink,
                ),
              ),
            ),
          ),

          // SITUAÇÃO REGIMENTAL
          SizedBox(
            width: 160,
            child: Center(
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
    required Color activeBorder,
    required Color activeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? activeBorder : InstColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: jakarta(
              size: 11,
              weight: FontWeight.w700,
              color: isActive ? activeText : const Color(0xFF52525B),
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
        color = InstColors.success;
        bg = InstColors.successBg;
        border = const Color(0xFFA7F3D0);
        break;
      case AttendanceRiskLevel.atencao:
        text = 'Atenção (>15%)';
        color = InstColors.warning;
        bg = InstColors.warningBg;
        border = const Color(0xFFFDE68A);
        break;
      case AttendanceRiskLevel.critico:
        text = 'Risco de Reprovação';
        color = InstColors.danger;
        bg = InstColors.dangerBg;
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
        style: jakarta(
          size: 10.5,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
