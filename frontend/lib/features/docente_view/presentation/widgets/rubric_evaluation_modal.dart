// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import '../../core/docente_colors.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/rubric_model.dart';
import '../controllers/docente_controller.dart';

/// Modal dialog for grading an assignment submission against its predefined rubric criteria.
class RubricEvaluationModal extends StatefulWidget {
  /// Associated assignment.
  final AssignmentItem assignment;

  /// Submission being evaluated.
  final StudentSubmission submission;

  /// Reactive controller for state updates.
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
  late Map<String, double> _criterionScores;
  late TextEditingController _feedbackController;

  @override
  void initState() {
    super.initState();
    _criterionScores = {};
    for (final criterion in widget.assignment.rubricCriteria) {
      final existing = widget.submission.rubricEvaluations.firstWhere(
        (r) => r.id == criterion.id,
        orElse: () => criterion,
      );
      _criterionScores[criterion.id] = existing.assignedScore ?? (criterion.maxScore * 0.8);
    }
    _feedbackController = TextEditingController(
      text: widget.submission.teacherFeedback ??
          'Excelente aplicação dos princípios de arquitetura. O diagrama C4 está muito bem estruturado e a resiliência foi demonstrada de forma clara nos testes de carga.',
    );
  }

  @override
  void disposeWidget() {
    _feedbackController.dispose();
  }

  double get _totalScore {
    return _criterionScores.values.fold(0.0, (acc, val) => acc + val);
  }

  double get _maxPossibleScore {
    return widget.assignment.rubricCriteria.fold(0.0, (acc, c) => acc + c.maxScore);
  }

  void _saveEvaluation() {
    final updatedCriteria = widget.assignment.rubricCriteria.map((c) {
      return c.copyWith(assignedScore: _criterionScores[c.id] ?? 0.0);
    }).toList();

    widget.controller.evaluateRubric(
      assignmentId: widget.assignment.id,
      submissionId: widget.submission.id,
      calculatedGrade: double.parse(_totalScore.toStringAsFixed(1)),
      feedback: _feedbackController.text.trim(),
      evaluatedCriteria: updatedCriteria,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Avaliação de ${widget.submission.studentName} salva com sucesso! Nota: ${_totalScore.toStringAsFixed(1)}',
        ),
        backgroundColor: DocenteColors.emerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStudentFileInfo(),
                    const SizedBox(height: 20),
                    _buildRubricMatrixSection(),
                    const SizedBox(height: 24),
                    _buildTeacherFeedbackSection(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
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
              color: DocenteColors.emerald.withOpacity(0.1),
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
                const Text(
                  'Avaliação por Rubrica Pedagógica',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DocenteColors.charcoal,
                  ),
                ),
                Text(
                  '${widget.assignment.title} • ${widget.submission.studentName} (RA: ${widget.submission.ra})',
                  style: const TextStyle(
                    fontSize: 13,
                    color: DocenteColors.slate,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: DocenteColors.slate),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildStudentFileInfo() {
    final fileName = widget.submission.fileName ?? 'relatorio_arquitetura_lucas_silva.pdf';
    final fileSize = widget.submission.fileSize ?? '2.4 MB';
    final submittedAt = widget.submission.submittedAtFormatted ?? '20/09/2026 às 14:32';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DocenteColors.offWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DocenteColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DocenteColors.border),
            ),
            child: const Icon(Icons.picture_as_pdf, color: DocenteColors.crimson, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DocenteColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Entregue em: $submittedAt • Tamanho: $fileSize',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DocenteColors.slate,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Download do arquivo "$fileName" iniciado.'),
                  backgroundColor: DocenteColors.charcoal,
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Baixar Entrega'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DocenteColors.charcoal,
              side: const BorderSide(color: DocenteColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRubricMatrixSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                color: DocenteColors.emerald.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Nota Total: ${_totalScore.toStringAsFixed(1)} / ${_maxPossibleScore.toStringAsFixed(1)}',
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
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DocenteColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DocenteColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            criterion.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: DocenteColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            criterion.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: DocenteColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DocenteColors.offWhite,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: DocenteColors.border),
                      ),
                      child: Text(
                        '${currentScore.toStringAsFixed(1)} / ${criterion.maxScore.toStringAsFixed(1)} pts',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: DocenteColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: DocenteColors.emerald,
                    inactiveTrackColor: DocenteColors.border,
                    thumbColor: DocenteColors.emerald,
                    overlayColor: DocenteColors.emerald.withOpacity(0.12),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: currentScore.clamp(0.0, criterion.maxScore),
                    min: 0.0,
                    max: criterion.maxScore,
                    divisions: (criterion.maxScore * 10).round(),
                    onChanged: (val) {
                      setState(() {
                        _criterionScores[criterion.id] = double.parse(val.toStringAsFixed(1));
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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
            hintText: 'Escreva orientações detalhadas de melhoria para o estudante...',
            hintStyle: const TextStyle(color: DocenteColors.muted, fontSize: 13),
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
              borderSide: const BorderSide(color: DocenteColors.emerald, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: DocenteColors.charcoal,
              side: const BorderSide(color: DocenteColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _saveEvaluation,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text(
              'Salvar Avaliação & Publicar Nota',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DocenteColors.emerald,
              foregroundColor: DocenteColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
