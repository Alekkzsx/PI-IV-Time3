// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'package:pi_iv_time3/shared/widgets/academic_status_badge.dart';

/// Card e Tabela com os lançamentos de notas de todos os alunos da disciplina
class DocenteGradebookTable extends StatelessWidget {
  final DocenteController controller;
  final List<StudentGrade> gradebook;

  const DocenteGradebookTable({
    super.key,
    required this.controller,
    required this.gradebook,
  });

  static const TextStyle _colHeaderStyle = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF71717A),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth < 1120 ? 1120 : constraints.maxWidth,
          child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF4F4F5), width: 1),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text('R.A.', style: _colHeaderStyle),
                ),
                const Expanded(
                  flex: 3,
                  child: Text('ESTUDANTE', style: _colHeaderStyle),
                ),
                SizedBox(
                  width: 72,
                  child: Center(
                    child: Text('ATIV. N1', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(
                  width: 76,
                  child: Center(
                    child: Text('PROVA P1', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Center(
                    child: Text('TOTAL N1', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Center(
                    child: Text('PROJ. N2', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(
                  width: 76,
                  child: Center(
                    child: Text('PROVA P2', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Center(
                    child: Text('TOTAL N2', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(
                  width: 86,
                  child: Center(
                    child: Text('MÉDIA FINAL', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Center(
                    child: Text('FREQ. (%)', style: _colHeaderStyle),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text('SITUAÇÃO', style: _colHeaderStyle),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gradebook.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFF4F4F5)),
            itemBuilder: (context, index) {
              final student = gradebook[index];
              return _buildStudentRow(context, student);
            },
          ),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          // The current gradebook is client-side mock state, not persisted.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Text(
              'Notas e médias estão nesta sessão; a sincronização oficial requer integração com o servidor.',
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRow(BuildContext context, StudentGrade student) {
    final isOnline = student.studentName == 'Gabriel Soares de Oliveira';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          // R.A.
          SizedBox(
            width: 100,
            child: Text(
              student.ra,
              style: jakarta(
                size: 11.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ),
          // ESTUDANTE
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    student.studentName,
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: const Color(0xFF18181B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOnline) ...[
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
                    child: Text(
                      'DISCENTE CONECTADO',
                      style: jakarta(
                        size: 9,
                        weight: FontWeight.w700,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ATIV. N1 (Input Stepper)
          SizedBox(
            width: 72,
            child: Center(
              child: _buildGradeStepper(
                value: student.assignmentsScore,
                onChanged: (val) {
                  controller.updateStudentGrade(
                    student.studentId,
                    assignments: val,
                  );
                },
              ),
            ),
          ),
          // PROVA P1 (Input Stepper)
          SizedBox(
            width: 76,
            child: Center(
              child: _buildGradeStepper(
                value: student.p1Score,
                onChanged: (val) {
                  controller.updateStudentGrade(student.studentId, p1: val);
                },
              ),
            ),
          ),
          // TOTAL N1 (Calculated)
          SizedBox(
            width: 72,
            child: Center(
              child: Text(
                _formatNumber(student.n1Total),
                style: jakarta(
                  size: 12,
                  weight: FontWeight.w600,
                  color: const Color(0xFF18181B),
                ),
              ),
            ),
          ),
          // PROJ. N2 (Input Stepper)
          SizedBox(
            width: 72,
            child: Center(
              child: _buildGradeStepper(
                value: student.projectsScore,
                onChanged: (val) {
                  controller.updateStudentGrade(
                    student.studentId,
                    projects: val,
                  );
                },
              ),
            ),
          ),
          // PROVA P2 (Input Stepper)
          SizedBox(
            width: 76,
            child: Center(
              child: _buildGradeStepper(
                value: student.p2Score,
                onChanged: (val) {
                  controller.updateStudentGrade(student.studentId, p2: val);
                },
              ),
            ),
          ),
          // TOTAL N2 (Calculated)
          SizedBox(
            width: 72,
            child: Center(
              child: Text(
                _formatNumber(student.n2Total),
                style: jakarta(
                  size: 12,
                  weight: FontWeight.w600,
                  color: const Color(0xFF18181B),
                ),
              ),
            ),
          ),
          // MÉDIA FINAL
          SizedBox(
            width: 86,
            child: Center(
              child: Text(
                _formatNumber(student.finalAverage),
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: _getAverageColor(student),
                ),
              ),
            ),
          ),
          // FREQ. (%)
          SizedBox(
            width: 80,
            child: Center(
              child: Text(
                student.attendanceRate == 100.0
                    ? '100%'
                    : '${student.attendanceRate.toStringAsFixed(1)}%',
                style: jakarta(
                  size: 12,
                  weight: student.attendanceRate < 75.0
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: student.attendanceRate < 75.0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF52525B),
                ),
              ),
            ),
          ),
          // SITUAÇÃO
          SizedBox(
            width: 120,
            child: Center(
              child: AcademicStatusBadge(academicStatus: student.status),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1).replaceAll('.', ',');
  }

  Color _getAverageColor(StudentGrade student) {
    if (student.attendanceRate < 75.0) {
      return const Color(0xFFD97706);
    }
    if (student.finalAverage >= 7.0) {
      return const Color(0xFF16A34A);
    }
    if (student.finalAverage >= 4.0) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFFDC2626);
  }

  Widget _buildGradeStepper({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final display = _formatNumber(value);

    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 8, right: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4D4D8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            display,
            style: jakarta(
              size: 12,
              weight: FontWeight.w500,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  final next = (value + 0.1).clamp(0.0, 10.0);
                  onChanged(double.parse(next.toStringAsFixed(1)));
                },
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 13,
                  color: Color(0xFF71717A),
                ),
              ),
              InkWell(
                onTap: () {
                  final prev = (value - 0.1).clamp(0.0, 10.0);
                  onChanged(double.parse(prev.toStringAsFixed(1)));
                },
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 13,
                  color: Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
