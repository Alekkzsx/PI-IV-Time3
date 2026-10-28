// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/attendance_record.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';

/// Exibe somente os alunos presentes no diário da turma selecionada.
class CourseHubStudentsTab extends StatelessWidget {
  final DocenteCourse course;
  final List<AttendanceStudent> students;
  final List<StudentGrade> grades;

  const CourseHubStudentsTab({
    super.key,
    required this.course,
    required this.students,
    required this.grades,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Alunos registrados no diário (${students.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF09090B),
                ),
              ),
            ),
            Text(
              course.code,
              style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'A lista reflete os registros de frequência disponíveis para esta turma.',
          style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
        ),
        const SizedBox(height: 16),
        if (students.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Ainda não há alunos registrados no diário desta turma.'),
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E4E7)),
            ),
            child: Column(
              children: [
                for (var index = 0; index < students.length; index++) ...[
                  _buildStudentRow(context, students[index]),
                  if (index < students.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF4F4F5),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStudentRow(BuildContext context, AttendanceStudent student) {
    final grade = grades
        .where((record) => record.studentId == student.studentId)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 300,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFF4F4F5),
                  child: Text(
                    student.name.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF09090B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                        ),
                      ),
                      Text(
                        'RA: ${student.ra}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Frequência ${student.attendanceRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
              Text(
                grade == null
                    ? 'Notas não lançadas'
                    : 'Média ${grade.finalAverage.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF09090B),
                ),
              ),
              OutlinedButton(
                key: Key('btn_prontuario_${student.studentId}'),
                onPressed: () => _showAcademicRecord(context, student, grade),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  side: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
                child: const Text(
                  'Prontuário',
                  style: TextStyle(fontSize: 10, color: Color(0xFF09090B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAcademicRecord(
    BuildContext context,
    AttendanceStudent student,
    StudentGrade? grade,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumo acadêmico da turma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.name),
            Text('RA: ${student.ra}'),
            Text('Disciplina: ${course.title}'),
            Text(
              'Frequência registrada: ${student.attendanceRate.toStringAsFixed(1)}%',
            ),
            Text(
              grade == null
                  ? 'Notas: ainda não lançadas'
                  : 'Média atual: ${grade.finalAverage.toStringAsFixed(1)}',
            ),
            const SizedBox(height: 8),
            const Text(
              'Este resumo contém apenas dados acadêmicos desta turma.',
              style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
