// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/rubric_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';
import 'components/rubric_criterion_tile.dart';
import 'components/rubric_score_summary_card.dart';

/// Modal dialog institucional para avaliação por rubrica pedagógica ou nota direta.
class RubricEvaluationModal extends StatefulWidget {
  final AssignmentItem assignment;
  final StudentSubmission submission;
  final DocenteController controller;

  const RubricEvaluationModal({
    super.key,
    required this.assignment,
    required this.submission,
    required this.controller,
  });

  @override
  State<RubricEvaluationModal> createState() => _RubricEvaluationModalState();
}

class _RubricEvaluationModalState extends State<RubricEvaluationModal> {
  late StudentSubmission _currentSubmission;
  late Map<String, double> _criterionScores;
  late double _directGrade;
  late TextEditingController _directGradeController;
  late FocusNode _directGradeFocus;
  late TextEditingController _feedbackController;
  bool _isSaving = false;
  String? _statusMessage;
  bool _statusIsError = false;

  bool get _hasRubricCriteria => widget.assignment.rubricCriteria.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
    _directGradeController = TextEditingController();
    _directGradeFocus = FocusNode()..addListener(_handleDirectFocusChange);
    _loadSubmission(widget.submission);
  }

  @override
  void dispose() {
    _directGradeFocus
      ..removeListener(_handleDirectFocusChange)
      ..dispose();
    _directGradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _handleDirectFocusChange() {
    if (_directGradeFocus.hasFocus) {
      _directGradeController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _directGradeController.text.length,
      );
    } else {
      final parsed = double.tryParse(
        _directGradeController.text.trim().replaceAll(',', '.'),
      );
      final committed = parsed != null && parsed.isFinite
          ? double.parse(parsed.clamp(0.0, 10.0).toStringAsFixed(1))
          : _directGrade;
      setState(() {
        _directGrade = committed;
        _directGradeController.text = _formatScore(committed);
      });
    }
  }

  static String _formatScore(double val) =>
      val.toStringAsFixed(1).replaceAll('.', ',');

  void _loadSubmission(StudentSubmission submission) {
    _currentSubmission = submission;
    _criterionScores = {};
    final hasSavedGrade =
        submission.status == SubmissionStatus.corrigido ||
        submission.grade != null;

    if (_hasRubricCriteria) {
      for (final criterion in widget.assignment.rubricCriteria) {
        final existing = submission.rubricEvaluations.firstWhere(
          (r) => r.id == criterion.id,
          orElse: () => criterion,
        );
        _criterionScores[criterion.id] = hasSavedGrade
            ? (existing.assignedScore ??
                  (submission.grade == null
                      ? 0.0
                      : criterion.maxScore * submission.grade! / 10))
            : 0.0;
      }
      _directGrade = submission.grade ?? 0.0;
    } else {
      _directGrade = hasSavedGrade
          ? (submission.grade ?? 0.0).clamp(0.0, 10.0).toDouble()
          : 0.0;
      _directGradeController.text = _formatScore(_directGrade);
    }

    _feedbackController.text = submission.teacherFeedback ?? '';
  }

  List<StudentSubmission> get _submissionQueue {
    final liveAssignment = widget.controller.assignments
        .where((a) => a.id == widget.assignment.id)
        .firstOrNull;
    return liveAssignment?.submissions ?? widget.assignment.submissions;
  }

  StudentSubmission? _findNextSubmission() {
    final queue = _submissionQueue;
    if (queue.length <= 1) return null;
    final currentIdx = queue.indexWhere(
      (s) => s.id == _currentSubmission.id || s.studentId == _currentSubmission.studentId,
    );
    if (currentIdx == -1) return null;

    for (var offset = 1; offset < queue.length; offset++) {
      final candidate = queue[(currentIdx + offset) % queue.length];
      if (candidate.status == SubmissionStatus.aguardandoCorrecao) {
        return candidate;
      }
    }
    return queue[(currentIdx + 1) % queue.length];
  }

  double get _totalScore {
    if (!_hasRubricCriteria) return _directGrade;
    return _criterionScores.values.fold(0.0, (acc, val) => acc + val);
  }

  double get _maxPossibleScore {
    if (!_hasRubricCriteria) return 10.0;
    return widget.assignment.rubricCriteria.fold(
      0.0,
      (acc, c) => acc + c.maxScore,
    );
  }

  Future<void> _saveEvaluation({bool advanceToNext = false}) async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();

    final calculatedGrade = _hasRubricCriteria
        ? (_maxPossibleScore > 0 ? (_totalScore / _maxPossibleScore) * 10.0 : 0.0)
        : _directGrade;
    final roundedGrade = double.parse(
      calculatedGrade.clamp(0.0, 10.0).toStringAsFixed(1),
    );
    final updatedCriteria = _hasRubricCriteria
        ? widget.assignment.rubricCriteria.map((c) {
            return c.copyWith(assignedScore: _criterionScores[c.id] ?? 0.0);
          }).toList()
        : const <RubricCriterion>[];

    setState(() {
      _isSaving = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    final evaluatedName = _currentSubmission.studentName;
    final ok = await widget.controller.evaluateRubric(
      assignmentId: widget.assignment.id,
      submissionId: _currentSubmission.id,
      calculatedGrade: roundedGrade,
      feedback: _feedbackController.text.trim(),
      evaluatedCriteria: updatedCriteria,
    );

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _isSaving = false;
        _statusIsError = true;
        _statusMessage =
            widget.controller.remoteError ?? 'Não foi possível salvar a correção.';
      });
      return;
    }

    if (advanceToNext) {
      final next = _findNextSubmission();
      if (next != null && next.studentId != _currentSubmission.studentId) {
        setState(() {
          _isSaving = false;
          _loadSubmission(next);
          _statusIsError = false;
          _statusMessage =
              'Salvo: $evaluatedName (${roundedGrade.toStringAsFixed(1)}/10). Próximo aluno carregado.';
        });
        return;
      }
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Avaliação de $evaluatedName salva! Nota: ${roundedGrade.toStringAsFixed(1)} / 10',
        ),
        backgroundColor: DocenteColors.emerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextStudent = _findNextSubmission();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 820,
        constraints: const BoxConstraints(maxHeight: 780),
        decoration: BoxDecoration(
          color: DocenteColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DocenteColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                color: _statusIsError
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFECFDF5),
                child: Row(
                  children: [
                    Icon(
                      _statusIsError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 16,
                      color: _statusIsError
                          ? const Color(0xFFDC2626)
                          : DocenteColors.emerald,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _statusIsError
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RubricScoreSummaryCard(submission: _currentSubmission),
                    const SizedBox(height: 20),
                    _hasRubricCriteria
                        ? _buildRubricMatrixSection()
                        : _buildDirectGradeSection(),
                    const SizedBox(height: 24),
                    _buildTeacherFeedbackSection(),
                  ],
                ),
              ),
            ),
            _buildFooter(nextStudent),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DocenteColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DocenteColors.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: DocenteColors.emerald,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasRubricCriteria
                      ? 'Avaliação por Rubrica Pedagógica'
                      : 'Avaliação & Lançamento de Nota',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DocenteColors.charcoal,
                  ),
                ),
                Text(
                  '${widget.assignment.title} • ${_currentSubmission.studentName} (RA: ${_currentSubmission.ra})',
                  style: const TextStyle(
                    fontSize: 13,
                    color: DocenteColors.slate,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: DocenteColors.slate),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildRubricMatrixSection() {
    final normalizedPreview = _maxPossibleScore > 0
        ? ((_totalScore / _maxPossibleScore) * 10.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text(
              'Matriz de Critérios & Pontuação',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DocenteColors.charcoal,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DocenteColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Nota Total: ${_totalScore.toStringAsFixed(1)} / ${_maxPossibleScore.toStringAsFixed(1)} (Nota: ${normalizedPreview.toStringAsFixed(1)}/10)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DocenteColors.emerald,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.assignment.rubricCriteria.map((criterion) {
          final currentScore = _criterionScores[criterion.id] ?? 0.0;
          return RubricCriterionTile(
            key: ValueKey('rubric-${_currentSubmission.studentId}-${criterion.id}'),
            criterion: criterion,
            currentScore: currentScore,
            onScoreChanged: (val) {
              setState(() {
                _criterionScores[criterion.id] = double.parse(
                  val.toStringAsFixed(1),
                );
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildDirectGradeSection() {
    const quickScores = [0.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DocenteColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atribuição Direta de Nota (0,0 a 10,0)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DocenteColors.charcoal,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Esta atividade não possui critérios divididos na rubrica. Digite a nota diretamente ou utilize os atalhos abaixo.',
                      style: TextStyle(
                        fontSize: 12,
                        color: DocenteColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: DocenteColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Nota Final: ${_directGrade.toStringAsFixed(1)} / 10.0',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DocenteColors.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _directGradeController,
                  focusNode: _directGradeFocus,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DocenteColors.charcoal,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nota',
                    suffixText: '/ 10',
                    filled: true,
                    fillColor: DocenteColors.offWhite,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: DocenteColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: DocenteColors.emerald, width: 1.5),
                    ),
                  ),
                  onChanged: (raw) {
                    final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
                    if (parsed != null && parsed.isFinite) {
                      setState(() {
                        _directGrade = double.parse(
                          parsed.clamp(0.0, 10.0).toStringAsFixed(1),
                        );
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: DocenteColors.emerald,
                    inactiveTrackColor: DocenteColors.border,
                    thumbColor: DocenteColors.emerald,
                    overlayColor: DocenteColors.emerald.withValues(alpha: 0.12),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _directGrade.clamp(0.0, 10.0),
                    min: 0.0,
                    max: 10.0,
                    divisions: 100,
                    onChanged: (val) {
                      final rounded = double.parse(val.toStringAsFixed(1));
                      setState(() {
                        _directGrade = rounded;
                        _directGradeController.text = _formatScore(rounded);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickScores.map((score) {
              final selected = (_directGrade - score).abs() < 0.05;
              return ChoiceChip(
                label: Text(
                  score.toInt().toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : DocenteColors.charcoal,
                  ),
                ),
                selected: selected,
                selectedColor: DocenteColors.emerald,
                backgroundColor: DocenteColors.offWhite,
                onSelected: (_) {
                  setState(() {
                    _directGrade = score;
                    _directGradeController.text = _formatScore(score);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parecer Pedagógico & Feedback para o Aluno',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DocenteColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _feedbackController,
          maxLines: 4,
          style: const TextStyle(fontSize: 13, color: DocenteColors.charcoal),
          decoration: InputDecoration(
            hintText:
                'Escreva orientações detalhadas de melhoria para o estudante...',
            hintStyle: const TextStyle(
              color: DocenteColors.muted,
              fontSize: 13,
            ),
            fillColor: DocenteColors.offWhite,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DocenteColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DocenteColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: DocenteColors.emerald,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(StudentSubmission? nextStudent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: DocenteColors.offWhite,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(top: BorderSide(color: DocenteColors.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: DocenteColors.charcoal,
              side: const BorderSide(color: DocenteColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancelar'),
          ),
          if (nextStudent != null &&
              nextStudent.studentId != _currentSubmission.studentId)
            OutlinedButton.icon(
              onPressed:
                  _isSaving ? null : () => _saveEvaluation(advanceToNext: true),
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: Text(
                'Salvar & Próximo (${nextStudent.studentName.split(' ').first})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DocenteColors.emerald,
                side: const BorderSide(color: DocenteColors.emerald),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _saveEvaluation(),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: Text(
              _isSaving ? 'Salvando...' : 'Salvar Correção',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DocenteColors.emerald,
              foregroundColor: DocenteColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
