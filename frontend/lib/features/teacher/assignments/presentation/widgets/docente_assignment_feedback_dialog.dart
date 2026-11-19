// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'components/doubt_reply_input_box.dart';
import 'components/doubt_thread_message_bubble.dart';
import 'components/feedback_grading_section.dart';

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
          : '',
    );
    _feedbackController = TextEditingController(
      text: widget.submission.teacherFeedback ?? '',
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: Padding(
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
                    ? FeedbackGradingSection(
                        gradeController: _gradeController,
                        feedbackController: _feedbackController,
                        assignment: widget.assignment,
                      )
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
                        style: jakarta(
                          size: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final grade =
                          double.tryParse(
                            _gradeController.text.replaceAll(',', '.'),
                          ) ??
                          0.0;
                      final ok = await widget.controller.salvarFeedbackIndividual(
                        assignmentId: widget.assignment.id,
                        studentRa: widget.submission.ra,
                        nota: grade.clamp(0.0, 10.0),
                        feedback: _feedbackController.text,
                        teacherReply: _replyController.text.isNotEmpty
                            ? _replyController.text
                            : null,
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pop();
                      }
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Feedback e nota de ${widget.submission.studentName} salvos com sucesso.'
                                : (widget.controller.remoteError ?? 'Não foi possível salvar a avaliação.'),
                            style: jakarta(size: 13, color: Colors.white),
                          ),
                          backgroundColor: ok ? const Color(0xFF047857) : const Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      'Salvar & Enviar Feedback',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
                    return DoubtThreadMessageBubble(message: msg);
                  },
                ),
        ),
        const SizedBox(height: 10),
        DoubtReplyInputBox(
          controller: _replyController,
          onSend: () {
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
        ),
      ],
    );
  }
}
