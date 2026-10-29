// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';

/// Modal de Avaliação, Feedback Individualizado e Canal Contextual de Dúvidas da Atividade.
class DocenteAssignmentFeedbackDialog extends StatefulWidget {
  final AssignmentItem assignment;
  final StudentSubmission submission;
  final DocenteController controller;

  const DocenteAssignmentFeedbackDialog({
    super.key,
    required this.assignment,
    required this.submission,
    required this.controller,
  });

  static Future<void> show({
    required BuildContext context,
    required AssignmentItem assignment,
    required StudentSubmission submission,
    required DocenteController controller,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DocenteAssignmentFeedbackDialog(
        assignment: assignment,
        submission: submission,
        controller: controller,
      ),
    );
  }

  @override
  State<DocenteAssignmentFeedbackDialog> createState() =>
      _DocenteAssignmentFeedbackDialogState();
}

class _DocenteAssignmentFeedbackDialogState
    extends State<DocenteAssignmentFeedbackDialog> {
  late final TextEditingController _gradeController;
  late final TextEditingController _feedbackController;
  final TextEditingController _replyController = TextEditingController();

  int _activeTab = 0; // 0: Parecer & Nota, 1: Canal de Dúvidas

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(
      text: widget.submission.grade != null
          ? widget.submission.grade!.toStringAsFixed(1)
          : '9.0',
    );
    _feedbackController = TextEditingController(
      text:
          widget.submission.teacherFeedback ??
          'Excelente estruturação no diagrama de sequência. Atenção apenas na representação do retorno síncrono do gateway de faturamento para evitar inconsistências no modelo de domínio.',
    );
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doubtThread = widget.controller.getDoubtThread(
      widget.assignment.id,
      widget.submission.ra,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 680,
        height: 600,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    widget.submission.studentName.isNotEmpty
                        ? widget.submission.studentName[0]
                        : 'A',
                    style: jakarta(
                      size: 16,
                      weight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.submission.studentName,
                            style: jakarta(
                              size: 17,
                              weight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              'RA: ${widget.submission.ra}',
                              style: jakarta(
                                size: 11,
                                weight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Atividade: ${widget.assignment.title} • ${widget.submission.fileName ?? "Arquivo submetido"}',
                        style: jakarta(
                          size: 12.5,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Switcher
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  _buildTabButton(
                    index: 0,
                    title: 'Avaliação & Parecer Pedagógico',
                    icon: Icons.rate_review_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildTabButton(
                    index: 1,
                    title: 'Canal de Dúvidas (${doubtThread.length})',
                    icon: Icons.question_answer_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: _activeTab == 0
                  ? _buildEvaluationTab()
                  : _buildDoubtsTab(doubtThread),
            ),

            // Bottom Actions
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'A devolutiva será visualizada imediatamente no portal do aluno.',
                      style: jakarta(size: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final grade =
                        double.tryParse(
                          _gradeController.text.replaceAll(',', '.'),
                        ) ??
                        0.0;
                    widget.controller.salvarFeedbackIndividual(
                      assignmentId: widget.assignment.id,
                      studentRa: widget.submission.ra,
                      nota: grade,
                      feedback: _feedbackController.text,
                      teacherReply: _replyController.text.isNotEmpty
                          ? _replyController.text
                          : null,
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Feedback e nota de ${widget.submission.studentName} salvos com sucesso.',
                          style: jakarta(size: 13, color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF047857),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    'Salvar & Enviar Feedback',
                    style: jakarta(size: 13, weight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: jakarta(
                size: 12.5,
                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nota da Atividade',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _gradeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: jakarta(
                        size: 16,
                        weight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        suffixText: '/ ${widget.assignment.weight}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E4E7),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E4E7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rubrica Aplicada',
                        style: jakarta(
                          size: 11,
                          weight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.assignment.rubricCriteria.length} critérios regimentais vinculados • Peso N1 (${widget.assignment.weight} pontos)',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Parecer Pedagógico Individual (Devolutiva com orientações de melhoria)',
            style: jakarta(
              size: 12.5,
              weight: FontWeight.w600,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _feedbackController,
            maxLines: 7,
            style: jakarta(
              size: 13,
              color: const Color(0xFF18181B),
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'Escreva orientações detalhadas sobre o trabalho entregue pelo estudante...',
              hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubtsTab(List<Map<String, String>> doubtThread) {
    return Column(
      children: [
        Expanded(
          child: doubtThread.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 36,
                        color: Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Nenhuma dúvida aberta por este discente nesta atividade.',
                        style: jakarta(
                          size: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: doubtThread.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final msg = doubtThread[i];
                    final isTeacher =
                        msg['sender']!.contains('Docente') ||
                        msg['sender']!.contains('Helena');

                    return Align(
                      alignment: isTeacher
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTeacher
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTeacher
                                ? const Color(0xFFBFDBFE)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  msg['sender']!,
                                  style: jakarta(
                                    size: 11.5,
                                    weight: FontWeight.w700,
                                    color: isTeacher
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  msg['time']!,
                                  style: jakarta(
                                    size: 10.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['text']!,
                              style: jakarta(
                                size: 12.5,
                                color: const Color(0xFF1E293B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                style: jakarta(size: 12.5, color: const Color(0xFF18181B)),
                decoration: InputDecoration(
                  hintText:
                      'Escreva uma resposta direta ao discente sobre esta tarefa...',
                  hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_replyController.text.trim().isNotEmpty) {
                  widget.controller.enviarRespostaDuvida(
                    widget.assignment.id,
                    widget.submission.ra,
                    _replyController.text,
                  );
                  _replyController.clear();
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(Icons.send_rounded, size: 16),
            ),
          ],
        ),
      ],
    );
  }
}
