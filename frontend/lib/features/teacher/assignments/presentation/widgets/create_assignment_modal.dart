// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/rubric_model.dart';

/// Modal dialog for creating a new assignment with an evaluation rubric matrix.
class CreateAssignmentModal extends StatefulWidget {
  final DocenteController controller;

  const CreateAssignmentModal({super.key, required this.controller});

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
    _selectedCourseId = widget.controller.selectedCourseId;

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

  void _handleSubmit() {
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
          maxPoints:
              double.parse(c['points']!.text.trim().replaceAll(',', '.')),
          description: c['desc']!.text.trim(),
        ),
      );
    }

    widget.controller.createAssignment(
      courseId: selectedCourse.id,
      courseCode: selectedCourse.code,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      weight: weight,
      stage: _selectedStage,
      dueDateFormatted: _dueDateController.text.trim(),
      modality: _selectedModality,
      allowLateWithPenalty: _allowLate,
      rubricCriteria: rubricCriteria,
    );

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF334155),
        content: Text(
          'Atividade criada nesta sessão. A publicação oficial depende da integração com o servidor.',
        ),
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

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: jakarta(
        size: 13,
        weight: FontWeight.w400,
        color: const Color(0xFFA1A1AA),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: jakarta(
          size: 12,
          weight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
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
              // Header
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

              // Form Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Selector
                      _buildFieldLabel('Componente Curricular / Turma'),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCourseId,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF71717A),
                        ),
                        decoration: _inputDecoration(),
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w500,
                          color: const Color(0xFF18181B),
                        ),
                        items: widget.controller.courses.map((course) {
                          return DropdownMenuItem(
                            value: course.id,
                            child: Text('${course.code} - ${course.title}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCourseId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 18),

                      // Title
                      _buildFieldLabel('Título da Atividade Avaliativa'),
                      TextFormField(
                        controller: _titleController,
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w500,
                          color: const Color(0xFF18181B),
                        ),
                        decoration: _inputDecoration(
                          hintText:
                              'Ex: Entrega: Diagrama de Classes e Sequência',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Informe o título'
                            : null,
                      ),
                      const SizedBox(height: 18),

                      // Description
                      _buildFieldLabel('Descrição e Enunciado Pedagógico'),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w400,
                          color: const Color(0xFF18181B),
                        ),
                        decoration: _inputDecoration(
                          hintText:
                              'Descreva os objetivos de aprendizagem, escopo técnico e instruções...',
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Weight, Stage and Due Date
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Peso da Nota (Pontos)'),
                                TextFormField(
                                  controller: _weightController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: jakarta(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF18181B),
                                  ),
                                  decoration: _inputDecoration(),
                                  validator: (value) {
                                    final weight = double.tryParse(
                                      (value ?? '').trim().replaceAll(',', '.'),
                                    );
                                    if (weight == null ||
                                        !weight.isFinite ||
                                        weight <= 0) {
                                      return 'Informe um peso maior que zero';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Etapa Avaliativa'),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedStage,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: Color(0xFF71717A),
                                  ),
                                  decoration: _inputDecoration(),
                                  style: jakarta(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF18181B),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'N1',
                                      child: Text('Nota 1 (N1)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'N2',
                                      child: Text('Nota 2 (N2)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'PI',
                                      child: Text('Projeto Integrador (PI)'),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedStage = v!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Due Date & Modality
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Prazo Limite'),
                                TextFormField(
                                  controller: _dueDateController,
                                  readOnly: true,
                                  onTap: _pickDueDate,
                                  validator: (_) => _selectedDueDate == null
                                      ? 'Selecione data e horário'
                                      : null,
                                  style: jakarta(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF18181B),
                                  ),
                                  decoration: _inputDecoration(
                                    hintText: 'Selecionar data e horário',
                                  ).copyWith(
                                    suffixIcon: const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Modalidade'),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedModality,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: Color(0xFF71717A),
                                  ),
                                  decoration: _inputDecoration(),
                                  style: jakarta(
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF18181B),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value:
                                          'Trabalho em Grupo (Até 4 integrantes)',
                                      child: Text('Trabalho em Grupo (Até 4)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Trabalho Individual',
                                      child: Text('Trabalho Individual'),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedModality = v!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Checkbox late submission
                      InkWell(
                        onTap: () => setState(() => _allowLate = !_allowLate),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _allowLate,
                                  onChanged: (v) =>
                                      setState(() => _allowLate = v ?? true),
                                  activeColor: const Color(0xFF3B82F6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Permitir submissão com penalidade após o prazo',
                                  style: jakarta(
                                    size: 12.5,
                                    weight: FontWeight.w400,
                                    color: const Color(0xFF3F3F46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Rubric Section Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF4F4F5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Matriz de Correção (Rubrica Avaliativa)',
                                  style: jakarta(
                                    size: 13.5,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFE4E4E7),
                                    ),
                                  ),
                                  child: Text(
                                    'Soma: ${_totalRubricSum.toStringAsFixed(1)} pts',
                                    style: jakarta(
                                      size: 11.5,
                                      weight: FontWeight.w600,
                                      color: const Color(0xFF3F3F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Critérios transparentes que o discente consulta antes e depois da entrega.',
                              style: jakarta(
                                size: 12,
                                weight: FontWeight.w400,
                                color: const Color(0xFF71717A),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Criteria Cards
                            ...List.generate(_rubricControllers.length, (idx) {
                              final c = _rubricControllers[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE4E4E7),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.015,
                                      ),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        // Nome do Critério (Underlined like image)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Nome do critério',
                                                style: jakarta(
                                                  size: 11,
                                                  weight: FontWeight.w400,
                                                  color: const Color(
                                                    0xFF71717A,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              TextField(
                                                controller: c['title'],
                                                style: jakarta(
                                                  size: 13,
                                                  weight: FontWeight.w400,
                                                  color: const Color(
                                                    0xFF18181B,
                                                  ),
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 4,
                                                          ),
                                                      border:
                                                          UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Color(
                                                                    0xFFCBD5E1,
                                                                  ),
                                                                ),
                                                          ),
                                                      enabledBorder:
                                                          UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Color(
                                                                    0xFFCBD5E1,
                                                                  ),
                                                                ),
                                                          ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Color(
                                                                    0xFF18181B,
                                                                  ),
                                                                  width: 1.5,
                                                                ),
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Pontos (Underlined like image)
                                        SizedBox(
                                          width: 90,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Pontos',
                                                style: jakarta(
                                                  size: 11,
                                                  weight: FontWeight.w400,
                                                  color: const Color(
                                                    0xFF71717A,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              TextField(
                                                controller: c['points'],
                                                keyboardType:
                                                    TextInputType.number,
                                                style: jakarta(
                                                  size: 13,
                                                  weight: FontWeight.w400,
                                                  color: const Color(
                                                    0xFF18181B,
                                                  ),
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                      ),
                                                  suffixText: 'pts',
                                                  suffixStyle: jakarta(
                                                    size: 12,
                                                    weight: FontWeight.w400,
                                                    color: const Color(
                                                      0xFF71717A,
                                                    ),
                                                  ),
                                                  border:
                                                      const UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: Color(
                                                            0xFFCBD5E1,
                                                          ),
                                                        ),
                                                      ),
                                                  enabledBorder:
                                                      const UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: Color(
                                                            0xFFCBD5E1,
                                                          ),
                                                        ),
                                                      ),
                                                  focusedBorder:
                                                      const UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: Color(
                                                            0xFF18181B,
                                                          ),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                ),
                                                onChanged: (_) =>
                                                    setState(() {}),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Delete Icon
                                        IconButton(
                                          onPressed: () =>
                                              _removeCriterion(idx),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                          ),
                                          color: const Color(0xFFDC2626),
                                          tooltip: 'Remover critério',
                                          splashRadius: 18,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Descrição do que é esperado
                                    Text(
                                      'Descrição do que é esperado para pontuação máxima',
                                      style: jakarta(
                                        size: 11,
                                        weight: FontWeight.w400,
                                        color: const Color(0xFF71717A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    TextField(
                                      controller: c['desc'],
                                      style: jakarta(
                                        size: 13,
                                        weight: FontWeight.w400,
                                        color: const Color(0xFF18181B),
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFF18181B),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 6),
                            // Botão Adicionar Critério Avaliativo
                            OutlinedButton.icon(
                              onPressed: () => _addCriterionControllers(),
                              icon: const Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: Color(0xFF3F3F46),
                              ),
                              label: Text(
                                'Adicionar Critério Avaliativo',
                                style: jakarta(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF3F3F46),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF3F3F46),
                                side: const BorderSide(
                                  color: Color(0xFFE4E4E7),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF4F4F5)),

              // Footer Actions
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
