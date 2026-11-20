// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/widgets/docente_grade_editor_dialog.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';
import 'package:pi_iv_time3/shared/widgets/academic_status_badge.dart';

/// Card e Tabela com lançamento fluido estilo planilha e salvamento em lote.
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

  Future<void> _handleSavePending(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await controller.savePendingGradeChanges();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Notas salvas e médias consolidadas com sucesso!'
              : (controller.remoteError ?? 'Não foi possível salvar as notas.'),
        ),
        backgroundColor: ok ? const Color(0xFF047857) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = controller.selectedCourse.gradeLocked;
    final isHomologada = controller.isPautaHomologada(controller.selectedCourse.id);
    final pendingCount = controller.pendingGradeChangesCount;
    final hasError = controller.remoteError != null && controller.remoteError!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLocked)
          _StatusBanner(
            icon: Icons.lock_rounded,
            backgroundColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
            textColor: const Color(0xFF991B1B),
            message:
                'Pauta bloqueada pela Trava Regimental ou fechamento oficial (somente leitura).',
          )
        else if (isHomologada && pendingCount == 0)
          _StatusBanner(
            icon: Icons.info_outline_rounded,
            backgroundColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
            textColor: const Color(0xFF166534),
            message:
                'Pauta homologada ativa. Digite diretamente nas células (Tab / Enter para avançar) e salve em lote quando concluir.',
          ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StatusBanner(
              icon: Icons.error_outline_rounded,
              backgroundColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
              textColor: const Color(0xFFB91C1C),
              message: controller.remoteError!,
            ),
          ),
        if (pendingCount > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pendingCount discente(s) com notas alteradas • Médias recalculadas em tempo real',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: controller.isSavingGrades
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              controller.discardPendingGradeChanges();
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: const Text('Descartar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.isSavingGrades
                          ? null
                          : () => _handleSavePending(context),
                      icon: controller.isSavingGrades
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 16),
                      label: Text(
                        controller.isSavingGrades
                            ? 'Salvando...'
                            : 'Salvar Notas ($pendingCount)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: constraints.maxWidth < 1120 ? 1120 : constraints.maxWidth,
              child: FocusTraversalGroup(
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
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
                              width: 78,
                              child: Center(
                                child: Text('ATIV. N1', style: _colHeaderStyle),
                              ),
                            ),
                            SizedBox(
                              width: 78,
                              child: Center(
                                child: Text('PROVA P1', style: _colHeaderStyle),
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Center(
                                child: Text('TOTAL N1', style: _colHeaderStyle),
                              ),
                            ),
                            SizedBox(
                              width: 78,
                              child: Center(
                                child: Text('PROJ. N2', style: _colHeaderStyle),
                              ),
                            ),
                            SizedBox(
                              width: 78,
                              child: Center(
                                child: Text('PROVA P2', style: _colHeaderStyle),
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Center(
                                child: Text('TOTAL N2', style: _colHeaderStyle),
                              ),
                            ),
                            SizedBox(
                              width: 84,
                              child: Center(
                                child: Text('MÉDIA FINAL', style: _colHeaderStyle),
                              ),
                            ),
                            SizedBox(
                              width: 76,
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
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: gradebook.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Color(0xFFF4F4F5)),
                        itemBuilder: (context, index) {
                          final student = gradebook[index];
                          return _buildStudentRow(context, student, enabled: !isLocked);
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF4F4F5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentRow(
    BuildContext context,
    StudentGrade student, {
    required bool enabled,
  }) {
    final rowDirty =
        controller.isGradeFieldDirty(student.studentId, 'assignments') ||
        controller.isGradeFieldDirty(student.studentId, 'p1') ||
        controller.isGradeFieldDirty(student.studentId, 'projects') ||
        controller.isGradeFieldDirty(student.studentId, 'p2');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: rowDirty ? const Color(0xFFF8FAFF) : Colors.white,
      child: Row(
        children: [
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
          Expanded(
            flex: 3,
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
          SizedBox(
            width: 78,
            child: Center(
              child: _GradeInputCell(
                key: ValueKey('grade-${student.courseId}-${student.studentId}-assignments'),
                value: student.assignmentsScore,
                enabled: enabled,
                isDirty: controller.isGradeFieldDirty(student.studentId, 'assignments'),
                onChanged: (val) => controller.setDraftStudentGrade(
                  student.studentId,
                  assignments: val,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 78,
            child: Center(
              child: _GradeInputCell(
                key: ValueKey('grade-${student.courseId}-${student.studentId}-p1'),
                value: student.p1Score,
                enabled: enabled,
                isDirty: controller.isGradeFieldDirty(student.studentId, 'p1'),
                onChanged: (val) => controller.setDraftStudentGrade(
                  student.studentId,
                  p1: val,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 70,
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
          SizedBox(
            width: 78,
            child: Center(
              child: _GradeInputCell(
                key: ValueKey('grade-${student.courseId}-${student.studentId}-projects'),
                value: student.projectsScore,
                enabled: enabled,
                isDirty: controller.isGradeFieldDirty(student.studentId, 'projects'),
                onChanged: (val) => controller.setDraftStudentGrade(
                  student.studentId,
                  projects: val,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 78,
            child: Center(
              child: _GradeInputCell(
                key: ValueKey('grade-${student.courseId}-${student.studentId}-p2'),
                value: student.p2Score,
                enabled: enabled,
                isDirty: controller.isGradeFieldDirty(student.studentId, 'p2'),
                onChanged: (val) => controller.setDraftStudentGrade(
                  student.studentId,
                  p2: val,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 70,
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
          SizedBox(
            width: 84,
            child: Center(
              child: Text(
                student.status == AcademicStatus.semNotas
                    ? '—'
                    : _formatNumber(student.finalAverage),
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: _getAverageColor(student),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 76,
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
          SizedBox(
            width: 120,
            child: Center(
              child: AcademicStatusBadge(academicStatus: student.status),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              tooltip: 'Editar notas de ${student.studentName}',
              visualDensity: VisualDensity.compact,
              onPressed: !enabled
                  ? null
                  : () => DocenteGradeEditorDialog.show(
                        context,
                        controller: controller,
                        grade: student,
                      ),
              icon: const Icon(
                Icons.tune_rounded,
                size: 16,
                color: Color(0xFF71717A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1).replaceAll('.', ',');
  }

  Color _getAverageColor(StudentGrade student) {
    if (student.status == AcademicStatus.semNotas) {
      return const Color(0xFF71717A);
    }
    if (student.attendanceRate < student.thresholds.minimumAttendance) {
      return const Color(0xFFD97706);
    }
    if (student.finalAverage >= student.thresholds.minimumGrade) {
      return const Color(0xFF16A34A);
    }
    if (student.finalAverage >= student.thresholds.specialExamGrade) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFFDC2626);
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String message;

  const _StatusBanner({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: jakarta(size: 12, weight: FontWeight.w500, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeInputCell extends StatefulWidget {
  final double value;
  final bool enabled;
  final bool isDirty;
  final ValueChanged<double> onChanged;

  const _GradeInputCell({
    super.key,
    required this.value,
    required this.enabled,
    required this.isDirty,
    required this.onChanged,
  });

  @override
  State<_GradeInputCell> createState() => _GradeInputCellState();
}

class _GradeInputCellState extends State<_GradeInputCell> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: DocenteGradebookTable._formatNumber(widget.value),
    );
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _GradeInputCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      final formatted = DocenteGradebookTable._formatNumber(widget.value);
      if (_textController.text != formatted) {
        _textController.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textController.text.length,
      );
    } else {
      _commitCurrentValue();
    }
  }

  double? _parseText(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || !parsed.isFinite) return null;
    return double.parse(parsed.clamp(0.0, 10.0).toStringAsFixed(1));
  }

  void _commitCurrentValue() {
    final parsed = _parseText(_textController.text);
    final committed = parsed ?? widget.value;
    final formatted = DocenteGradebookTable._formatNumber(committed);
    if (_textController.text != formatted) {
      _textController.text = formatted;
    }
    if (committed != widget.value) {
      widget.onChanged(committed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 34,
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.next,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          LengthLimitingTextInputFormatter(4),
        ],
        style: jakarta(
          size: 12.5,
          weight: FontWeight.w600,
          color: widget.isDirty
              ? const Color(0xFF1D4ED8)
              : const Color(0xFF18181B),
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: !widget.enabled
              ? const Color(0xFFF4F4F5)
              : widget.isDirty
                  ? const Color(0xFFEFF6FF)
                  : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: widget.isDirty
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFD4D4D8),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: widget.isDirty
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFD4D4D8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Color(0xFF1E3A8A),
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
          ),
        ),
        onChanged: (raw) {
          final parsed = _parseText(raw);
          if (parsed != null && parsed != widget.value) {
            widget.onChanged(parsed);
          }
        },
        onSubmitted: (_) {
          _commitCurrentValue();
          FocusScope.of(context).nextFocus();
        },
      ),
    );
  }
}
