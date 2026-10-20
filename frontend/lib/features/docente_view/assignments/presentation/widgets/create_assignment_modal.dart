// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/rubric_model.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Modal dialog for creating a new assignment with an evaluation rubric matrix.
class CreateAssignmentModal extends StatefulWidget {
  final DocenteController controller;

  const CreateAssignmentModal({
    super.key,
    required this.controller,
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
  final _dueDateController = TextEditingController(text: 'Hoje, 20/09/2026 às 23:59');
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
      description: 'Aderência aos conceitos ministrados e notação padronizada UML 2.5.',
    );
    _addCriterionControllers(
      title: 'Clareza Metodológica e Rastreabilidade',
      points: '5.0',
      description: 'Documentação clara com apresentação dos casos de teste e justificativas GRASP.',
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
      sum += double.tryParse(c['points']!.text) ?? 0.0;
    }
    return sum;
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
          maxPoints: double.tryParse(c['points']!.text) ?? 2.5,
          description: c['desc']!.text.trim(),
        ),
      );
    }

    widget.controller.createAssignment(
      courseId: selectedCourse.id,
      courseCode: selectedCourse.code,
      title: _titleController.text.trim(),
      weight: double.tryParse(_weightController.text) ?? 3.0,
      stage: _selectedStage,
      dueDateFormatted: _dueDateController.text.trim(),
      modality: _selectedModality,
      allowLateWithPenalty: _allowLate,
      rubricCriteria: rubricCriteria,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DocenteColors.success,
        content: Text('Atividade avaliativa e rubrica publicadas com sucesso!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: DocenteColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 860),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cadastrar Nova Atividade Avaliativa',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: DocenteColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: DocenteColors.border),

              // Form Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Selector
                      const Text(
                        'Componente Curricular / Turma',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedCourseId,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: widget.controller.courses.map((course) {
                          return DropdownMenuItem(
                            value: course.id,
                            child: Text('${course.code} - ${course.title}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCourseId = val);
                        },
                      ),
                      const SizedBox(height: 18),

                      // Title
                      const Text(
                        'Título da Atividade Avaliativa',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Entrega: Diagrama de Classes e Sequência',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Informe o título' : null,
                      ),
                      const SizedBox(height: 18),

                      // Description
                      const Text(
                        'Descrição e Enunciado Pedagógico',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Descreva os objetivos de aprendizagem, escopo técnico e instruções...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Weight, Stage and Due Date
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Peso da Nota (Pontos)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Etapa Avaliativa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedStage,
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                  items: const [
                                    DropdownMenuItem(value: 'N1', child: Text('Nota 1 (N1)')),
                                    DropdownMenuItem(value: 'N2', child: Text('Nota 2 (N2)')),
                                    DropdownMenuItem(value: 'PI', child: Text('Projeto Integrador (PI)')),
                                  ],
                                  onChanged: (v) => setState(() => _selectedStage = v!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Due Date & Modality
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Prazo Limite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _dueDateController,
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Modalidade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedModality,
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                  items: const [
                                    DropdownMenuItem(value: 'Trabalho Individual', child: Text('Trabalho Individual')),
                                    DropdownMenuItem(value: 'Trabalho em Grupo (Até 4 integrantes)', child: Text('Trabalho em Grupo (Até 4)')),
                                  ],
                                  onChanged: (v) => setState(() => _selectedModality = v!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _allowLate,
                        onChanged: (v) => setState(() => _allowLate = v ?? true),
                        title: const Text('Permitir submissão com penalidade após o prazo'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 24),

                      // Rubric Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: DocenteColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DocenteColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Matriz de Correção (Rubrica Avaliativa)',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: DocenteColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: DocenteColors.border),
                                  ),
                                  child: Text(
                                    'Soma: ${_totalRubricSum.toStringAsFixed(1)} pts',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Critérios transparentes que o discente consulta antes e depois da entrega.',
                              style: TextStyle(fontSize: 12, color: DocenteColors.textSecondary),
                            ),
                            const SizedBox(height: 16),

                            // Criteria builder list
                            ...List.generate(_rubricControllers.length, (idx) {
                              final c = _rubricControllers[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: DocenteColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: DocenteColors.border),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: c['title'],
                                            decoration: const InputDecoration(
                                              labelText: 'Nome do critério',
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 90,
                                          child: TextField(
                                            controller: c['points'],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Pontos',
                                              suffixText: 'pts',
                                              isDense: true,
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _removeCriterion(idx),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                          color: DocenteColors.danger,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: c['desc'],
                                      decoration: const InputDecoration(
                                        labelText: 'Descrição do que é esperado para pontuação máxima',
                                        isDense: true,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            OutlinedButton.icon(
                              onPressed: () => _addCriterionControllers(),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Adicionar Critério Avaliativo'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: DocenteColors.borderDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DocenteColors.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      ),
                      child: const Text('Publicar Atividade para a Turma'),
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

