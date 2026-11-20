// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import '../../../../shared/domain/models/docente_course.dart';

/// Formulário molecular com dados básicos da atividade avaliativa (turma, título, peso, etapa).
class AssignmentBasicInfoForm extends StatelessWidget {
  final List<DocenteCourse> courses;
  final String selectedCourseId;
  final bool lockCourse;
  final ValueChanged<String?> onCourseChanged;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController weightController;
  final String selectedStage;
  final ValueChanged<String?> onStageChanged;

  const AssignmentBasicInfoForm({
    super.key,
    required this.courses,
    required this.selectedCourseId,
    this.lockCourse = false,
    required this.onCourseChanged,
    required this.titleController,
    required this.descriptionController,
    required this.weightController,
    required this.selectedStage,
    required this.onStageChanged,
  });

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Selector
        _buildFieldLabel('Componente Curricular / Turma'),
        DropdownButtonFormField<String>(
          initialValue: selectedCourseId,
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
          items: courses.map((course) {
            return DropdownMenuItem(
              value: course.id,
              child: Text('${course.code} - ${course.title}'),
            );
          }).toList(),
          onChanged: lockCourse ? null : onCourseChanged,
        ),
        const SizedBox(height: 18),

        // Title
        _buildFieldLabel('Título da Atividade Avaliativa'),
        TextFormField(
          controller: titleController,
          style: jakarta(
            size: 13,
            weight: FontWeight.w500,
            color: const Color(0xFF18181B),
          ),
          decoration: _inputDecoration(
            hintText: 'Ex: Entrega: Diagrama de Classes e Sequência',
          ),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Informe o título'
              : null,
        ),
        const SizedBox(height: 18),

        // Description
        _buildFieldLabel('Descrição e Enunciado Pedagógico'),
        TextFormField(
          controller: descriptionController,
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

        // Weight & Stage
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Peso da Nota (Pontos)'),
                  TextFormField(
                    controller: weightController,
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
                      if (weight == null || !weight.isFinite || weight <= 0) {
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
                    initialValue: selectedStage,
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
                    onChanged: onStageChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
