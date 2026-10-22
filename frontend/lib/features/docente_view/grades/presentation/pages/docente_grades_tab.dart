// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/grade_record.dart';
import 'package:pi_iv_time3/features/docente_view/shell/presentation/widgets/docente_footer.dart';

/// Tab page for managing student official gradebook, PPC formula calculations, and issuing minutes.
class DocenteGradesTab extends StatelessWidget {
  /// Reactive controller for state access and mutations.
  final DocenteController controller;

  const DocenteGradesTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedCourse = controller.selectedCourse;
        final gradebook = controller.gradebook;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, selectedCourse),
                          const SizedBox(height: 20),
                          _buildFormulaBanner(),
                          const SizedBox(height: 24),
                          _buildGradebookCard(context, gradebook),
                        ],
                      ),
                    ),
                    const DocenteFooter(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DocenteCourse selectedCourse) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Livro de Notas & Gradebook Oficial',
              style: jakarta(
                size: 20,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Consolidação de avaliações, cálculo automatizado de médias pelo PPC e emissão de atas.',
              style: jakarta(
                size: 13,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown Seletor de Disciplina
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E4E7)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCourse.id,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Color(0xFF71717A),
                  ),
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                  onChanged: (newCourseId) {
                    if (newCourseId != null) {
                      controller.selectCourse(newCourseId);
                    }
                  },
                  items: controller.courses.map((course) {
                    return DropdownMenuItem<String>(
                      value: course.id,
                      child: Text(
                        '${course.code} - ${course.title}',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botão Emitir Ata da Turma
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ata Semestral da Turma homologada e gerada com sucesso.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.description_outlined, size: 15, color: Color(0xFF18181B)),
              label: Text(
                'Emitir Ata da Turma',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: const Color(0xFF18181B),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF18181B),
                side: const BorderSide(color: Color(0xFFD4D4D8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormulaBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF4F4F5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: Color(0xFF52525B), size: 18),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fórmula Regimental de Avaliação (PPC da Disciplina)',
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w700,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Média Semestral = (N1 x 0.4) + (N2 x 0.6) • Onde N1 e N2 são compostas por: 40% Atividades/Entregas + 60% Provas Regimentais.',
                    style: jakarta(
                      size: 11.5,
                      weight: FontWeight.w400,
                      color: const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Badge Aprovação Direta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  'Aprovação Direta: Média ≥ 7.0 e Freq. ≥ 75%',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Badge Exame
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Text(
                  'Exame: 4.0 ≤ Média < 7.0',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradebookCard(BuildContext context, List<StudentGrade> gradebook) {
    return Container(
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
                  child: Center(child: Text('ATIV. N1', style: _colHeaderStyle)),
                ),
                SizedBox(
                  width: 76,
                  child: Center(child: Text('PROVA P1', style: _colHeaderStyle)),
                ),
                SizedBox(
                  width: 72,
                  child: Center(child: Text('TOTAL N1', style: _colHeaderStyle)),
                ),
                SizedBox(
                  width: 72,
                  child: Center(child: Text('PROJ. N2', style: _colHeaderStyle)),
                ),
                SizedBox(
                  width: 76,
                  child: Center(child: Text('PROVA P2', style: _colHeaderStyle)),
                ),
                SizedBox(
                  width: 72,
                  child: Center(child: Text('TOTAL N2', style: _colHeaderStyle)),
                ),
                SizedBox(
                  width: 86,
                  child: Center(child: Text('MÉDIA FINAL', style: _colHeaderStyle)),
                ),
                SizedBox(
                  width: 80,
                  child: Center(child: Text('FREQ. (%)', style: _colHeaderStyle)),
                ),
                SizedBox(
                  width: 120,
                  child: Center(child: Text('SITUAÇÃO', style: _colHeaderStyle)),
                ),
              ],
            ),
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gradebook.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF4F4F5)),
            itemBuilder: (context, index) {
              final student = gradebook[index];
              return _buildStudentRow(context, student);
            },
          ),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          // Bottom sync note and Save Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Todas as notas estão sincronizadas com o banco de dados oficial.',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Médias e frequências atualizadas com sucesso.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFF16A34A),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 15, color: Colors.white),
                  label: Text(
                    'Salvar e Atualizar Médias',
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _colHeaderStyle = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF71717A),
  );

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
              style: jakarta(size: 11.5, weight: FontWeight.w400, color: const Color(0xFF71717A)),
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
                    style: jakarta(size: 12.5, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOnline) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  controller.updateStudentGrade(student.studentId, assignments: val);
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
                style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF18181B)),
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
                  controller.updateStudentGrade(student.studentId, projects: val);
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
                style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF18181B)),
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
                student.attendanceRate == 100.0 ? '100%' : '${student.attendanceRate.toStringAsFixed(1)}%',
                style: jakarta(
                  size: 12,
                  weight: student.attendanceRate < 75.0 ? FontWeight.w700 : FontWeight.w500,
                  color: student.attendanceRate < 75.0 ? const Color(0xFFDC2626) : const Color(0xFF52525B),
                ),
              ),
            ),
          ),
          // SITUAÇÃO
          SizedBox(
            width: 120,
            child: Center(
              child: _buildSituationBadge(student),
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

  Widget _buildSituationBadge(StudentGrade student) {
    Color bg;
    Color fg;
    Color border;
    String label;

    switch (student.status) {
      case AcademicStatus.aprovado:
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        border = const Color(0xFFBBF7D0);
        label = 'Aprovado';
        break;
      case AcademicStatus.exame:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        border = const Color(0xFFFDE68A);
        label = 'Em Exame';
        break;
      case AcademicStatus.reprovadoPorFalta:
        bg = const Color(0xFFFFF1F2);
        fg = const Color(0xFFE11D48);
        border = const Color(0xFFFECDD3);
        label = 'Reprovado por Falta';
        break;
      case AcademicStatus.reprovadoPorNota:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        border = const Color(0xFFFECACA);
        label = 'Reprovado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: jakarta(
          size: 10.5,
          weight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
