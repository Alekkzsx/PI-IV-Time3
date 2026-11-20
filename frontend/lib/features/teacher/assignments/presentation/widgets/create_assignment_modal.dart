// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/rubric_model.dart';
import 'components/assignment_basic_info_form.dart';
import 'components/assignment_deadline_settings.dart';
import 'components/assignment_rubric_matrix_editor.dart';

/// Modal dialog para criação de nova atividade avaliativa institucional.
class CreateAssignmentModal extends StatefulWidget {
  final DocenteController controller;
  final String? initialCourseId;
  final bool lockCourse;

  const CreateAssignmentModal({
    super.key,
    required this.controller,
    this.initialCourseId,
    this.lockCourse = false,
  });

  @override
  State<CreateAssignmentModal> createState() => _CreateAssignmentModalState();
}

class _CreateAssignmentModalState extends State<CreateAssignmentModal> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCourseId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController(text: '3.0');
  String _selectedStage = 'N1';
  final _dueDateController = TextEditingController();
  DateTime? _selectedDueDate;
  String _selectedModality = 'Trabalho em Grupo (Até 4 integrantes)';
  bool _allowLate = true;

  final List<Map<String, TextEditingController>> _rubricControllers = [];

  @override
  void initState() {
    super.initState();
    _selectedCourseId =
        widget.initialCourseId ?? widget.controller.selectedCourseId;

    _addCriterionControllers(
      title: 'Conformidade Técnica e Modelagem',
      points: '5.0',
      description:
          'Aderência aos conceitos ministrados e notação padronizada UML 2.5.',
    );
    _addCriterionControllers(
      title: 'Clareza Metodológica e Rastreabilidade',
      points: '5.0',
      description:
          'Documentação clara com apresentação dos casos de teste e justificativas GRASP.',
    );
  }

  void _addCriterionControllers({
    String title = '',
    String points = '2.5',
    String description = '',
  }) {
    setState(() {
      _rubricControllers.add({
        'title': TextEditingController(text: title),
        'points': TextEditingController(text: points),
        'desc': TextEditingController(text: description),
      });
    });
  }

  void _removeCriterion(int index) {
    if (_rubricControllers.length <= 1) return;
    setState(() {
      final removed = _rubricControllers.removeAt(index);
      removed['title']?.dispose();
      removed['points']?.dispose();
      removed['desc']?.dispose();
    });
  }

  double get _totalRubricSum {
    double sum = 0.0;
    for (final c in _rubricControllers) {
      sum += double.tryParse(c['points']!.text.replaceAll(',', '.')) ?? 0.0;
    }
    return sum;
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDueDate == null
          ? const TimeOfDay(hour: 23, minute: 59)
          : TimeOfDay.fromDateTime(_selectedDueDate!),
    );
    if (selectedTime == null || !mounted) return;

    _selectedDueDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    _dueDateController.text =
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year} às '
        '${selectedTime.hour.toString().padLeft(2, '0')}:'
        '${selectedTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _dueDateController.dispose();
    for (final c in _rubricControllers) {
      c['title']?.dispose();
      c['points']?.dispose();
      c['desc']?.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    if (weight == null || !weight.isFinite || weight <= 0) {
      _showValidationError('Informe um peso válido maior que zero.');
      return;
    }

    for (final criterion in _rubricControllers) {
      final title = criterion['title']!.text.trim();
      final points = double.tryParse(
        criterion['points']!.text.trim().replaceAll(',', '.'),
      );
      if (title.isEmpty || points == null || !points.isFinite || points <= 0) {
        _showValidationError(
          'Preencha cada critério com um nome e uma pontuação válida.',
        );
        return;
      }
    }

    if (_totalRubricSum <= 0) {
      _showValidationError('A rubrica precisa ter pontuação maior que zero.');
      return;
    }

    final selectedCourse = widget.controller.courses.firstWhere(
      (c) => c.id == _selectedCourseId,
      orElse: () => widget.controller.courses.first,
    );

    final rubricCriteria = <RubricCriterion>[];
    for (int i = 0; i < _rubricControllers.length; i++) {
      final c = _rubricControllers[i];
      rubricCriteria.add(
        RubricCriterion(
          id: 'rc-custom-$i',
          title: c['title']!.text.trim(),
          maxPoints: double.parse(
            c['points']!.text.trim().replaceAll(',', '.'),
          ),
          description: c['desc']!.text.trim(),
        ),
      );
    }

    final dueDateObj = _selectedDueDate;
    final cleanDateStr = dueDateObj != null
        ? '${dueDateObj.day.toString().padLeft(2, '0')}/'
            '${dueDateObj.month.toString().padLeft(2, '0')}/'
            '${dueDateObj.year}'
        : _dueDateController.text.trim().split(' ').first;
    final dueHourStr = dueDateObj != null
        ? '${dueDateObj.hour.toString().padLeft(2, '0')}:'
            '${dueDateObj.minute.toString().padLeft(2, '0')}'
        : (_dueDateController.text.contains('às')
              ? _dueDateController.text.split('às').last.trim()
              : '23:59');

    final created = await widget.controller.createAssignment(
      courseId: selectedCourse.id,
      courseCode: selectedCourse.code,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      weight: weight,
      stage: _selectedStage,
      dueDate: dueDateObj,
      dueHour: dueHourStr,
      dueDateFormatted: cleanDateStr,
      modality: _selectedModality,
      allowLateWithPenalty: _allowLate,
      rubricCriteria: rubricCriteria,
    );
    if (!mounted) return;
    if (!created) {
      _showValidationError(
        'Não foi possível publicar a atividade para esta turma.',
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF334155),
        content: Text('Atividade publicada com sucesso.'),
      ),
    );
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 860),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cadastrar Nova Atividade Avaliativa',
                        style: jakarta(
                          size: 19,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF71717A),
                      ),
                      tooltip: 'Fechar',
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF4F4F5)),

              // Corpo Rolável do Formulário
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AssignmentBasicInfoForm(
                        courses: widget.controller.courses,
                        selectedCourseId: _selectedCourseId,
                        lockCourse: widget.lockCourse,
                        onCourseChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCourseId = val);
                          }
                        },
                        titleController: _titleController,
                        descriptionController: _descriptionController,
                        weightController: _weightController,
                        selectedStage: _selectedStage,
                        onStageChanged: (v) =>
                            setState(() => _selectedStage = v!),
                      ),
                      const SizedBox(height: 18),
                      AssignmentDeadlineSettings(
                        dueDateController: _dueDateController,
                        onPickDueDate: _pickDueDate,
                        selectedModality: _selectedModality,
                        onModalityChanged: (v) =>
                            setState(() => _selectedModality = v!),
                        allowLate: _allowLate,
                        onAllowLateChanged: (v) =>
                            setState(() => _allowLate = v),
                      ),
                      const SizedBox(height: 22),
                      AssignmentRubricMatrixEditor(
                        rubricControllers: _rubricControllers,
                        totalRubricSum: _totalRubricSum,
                        onAddCriterion: () => _addCriterionControllers(),
                        onRemoveCriterion: _removeCriterion,
                        onPointsChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF4F4F5)),

              // Ações do Rodapé
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFF94A3B8)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Text(
                        'Cancelar',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 13,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Publicar Atividade para a Turma',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
