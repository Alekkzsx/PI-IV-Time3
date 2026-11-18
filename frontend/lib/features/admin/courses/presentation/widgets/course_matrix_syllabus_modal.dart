// Desenvolvido por Guilherme Henrique Moreira

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_academic_data_source.dart';
import 'package:pi_iv_time3/features/admin/shared/models/admin_models.dart';

/// Modal de Matriz Curricular & Ementário de um Curso
class CourseMatrixSyllabusModal extends StatefulWidget {
  final AdminCourseModel course;
  final VoidCallback? onUpdated;
  final AdminAcademicDataSource? dataSource;

  const CourseMatrixSyllabusModal({
    super.key,
    required this.course,
    this.onUpdated,
    this.dataSource,
  });

  static Future<void> show(
    BuildContext context,
    AdminCourseModel course, {
    VoidCallback? onUpdated,
    AdminAcademicDataSource? dataSource,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => CourseMatrixSyllabusModal(
        course: course,
        onUpdated: onUpdated,
        dataSource: dataSource,
      ),
    );
  }

  @override
  State<CourseMatrixSyllabusModal> createState() =>
      _CourseMatrixSyllabusModalState();
}

class _CourseMatrixSyllabusModalState extends State<CourseMatrixSyllabusModal> {
  bool _saving = false;
  late List<Map<String, dynamic>> _components;

  @override
  void initState() {
    super.initState();
    _components = widget.course.components
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _componentPeriod(Map<String, dynamic> c) {
    final sem = c['semestre'] ?? c['semester'];
    if (sem == null) return '-';
    if (sem is num) return '${sem.toInt()}º Sem.';
    final text = sem.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  String _componentName(Map<String, dynamic> c) {
    final name = (c['disciplina'] ?? c['name'])?.toString().trim() ?? '';
    final code = c['code']?.toString().trim() ?? '';
    if (name.isEmpty) {
      return code.isEmpty ? 'Componente Curricular' : code;
    }
    if (code.isEmpty || name.contains(code)) return name;
    return '$code · $name';
  }

  String _componentWorkload(Map<String, dynamic> c) {
    final carga = c['carga']?.toString().trim();
    if (carga != null && carga.isNotEmpty) return carga;
    final hours = c['workloadHours'];
    if (hours is num) return '${hours.toInt()}h';
    final hoursText = hours?.toString().trim();
    if (hoursText != null && hoursText.isNotEmpty) return '${hoursText}h';
    return '-';
  }

  String _componentProfessor(Map<String, dynamic> c) {
    final doc = (c['docente'] ?? c['professor'] ?? c['professorName'])
        ?.toString()
        .trim();
    return (doc == null || doc.isEmpty) ? 'A definir / Colegiado' : doc;
  }

  Future<void> _editComponents() async {
    final controller = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(_components),
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar componentes curriculares'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            maxLines: 16,
            decoration: const InputDecoration(
              hintText: '[{"semestre":"1º","disciplina":"...","carga":"...","docente":"..."}]',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List || decoded.any((item) => item is! Map)) {
        throw const FormatException('Informe uma lista JSON de componentes.');
      }
      final updatedComponents = decoded
          .map((item) => Map<String, Object?>.from(item as Map))
          .toList();
      setState(() => _saving = true);
      final ds = widget.dataSource ?? AdminAcademicRemoteDataSource();
      await ds.patchCourse(widget.course.code, {
        'components': updatedComponents,
      });
      if (mounted) {
        setState(() {
          _components = decoded
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
        widget.onUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matriz curricular atualizada.')),
        );
      }
    } on AdminAcademicApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MATRIZ CURRICULAR & COMPONENTES',
                          style: jakarta(
                            size: 11,
                            weight: FontWeight.w700,
                            color: const Color(0xFF737373),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.course.name,
                          style: jakarta(
                            size: 20,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.course.matrix} • Carga Horária Total: ${widget.course.workload}',
                          style: jakarta(
                            size: 13,
                            color: const Color(0xFF737373),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Color(0xFF737373),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Componentes Curriculares em Oferta no Período Letivo Vigente:',
                style: jakarta(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(3.0),
                    2: FlexColumnWidth(1.0),
                    3: FlexColumnWidth(2.5),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                      children: [
                        _buildTh('PERÍODO'),
                        _buildTh('COMPONENTE CURRICULAR'),
                        _buildTh('CARGA'),
                        _buildTh('DOCENTE HOMOLOGADO'),
                      ],
                    ),
                    ..._components.map((c) {
                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _componentPeriod(c),
                              style: jakarta(
                                size: 12.5,
                                color: const Color(0xFF737373),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _componentName(c),
                              style: jakarta(
                                size: 13,
                                weight: FontWeight.w600,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _componentWorkload(c),
                              style: jakarta(
                                size: 12.5,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _componentProfessor(c),
                              style: jakarta(
                                size: 12.5,
                                color: const Color(0xFF525252),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _editComponents,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar matriz'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF18181B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Fechar',
                        style: jakarta(
                          size: 13,
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

  Widget _buildTh(String label) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        label,
        style: jakarta(
          size: 11,
          weight: FontWeight.w700,
          color: const Color(0xFF737373),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
