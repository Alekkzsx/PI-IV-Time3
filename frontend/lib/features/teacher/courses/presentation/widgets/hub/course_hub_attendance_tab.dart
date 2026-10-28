// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/attendance_record.dart';

/// Aba de Diário de Presença & Frequência Eletrônica do curso no Portal Docente.
class CourseHubAttendanceTab extends StatelessWidget {
  final DocenteController controller;

  const CourseHubAttendanceTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final session = controller.currentSession;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diário de Presença & Frequência Eletrônica',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF09090B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Controle diário de assiduidade e lançamento regimental de faltas.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(session.dateFormatted)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    '${session.dateFormatted} (Aula ${session.sessionNumber})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF09090B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    controller.markAllPresent();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Presença marcada para toda a turma.'),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Marcar Todos Presentes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Column(
            children: [
              for (final student in session.attendanceList) ...[
                _buildAttendanceItem(student),
                if (student != session.attendanceList.last)
                  const Divider(height: 20, color: Color(0xFFF4F4F5)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(AttendanceStudent student) {
    final isPresent = student.status == AttendanceStatus.presente;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF09090B),
              ),
            ),
            Text(
              'RA: ${student.ra} • ${student.accumulatedAbsences} faltas acumuladas (${student.attendanceRate}% de presença)',
              style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => controller.toggleAttendance(
                student.studentId,
                AttendanceStatus.presente,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDCFCE7),
                foregroundColor: const Color(0xFF16A34A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Presente',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPresent
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF71717A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => controller.toggleAttendance(
                student.studentId,
                AttendanceStatus.ausente,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF71717A),
                side: const BorderSide(color: Color(0xFFE4E4E7)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('Falta', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }
}
