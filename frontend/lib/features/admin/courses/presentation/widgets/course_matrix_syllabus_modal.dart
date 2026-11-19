// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_academic_data_source.dart';
import 'package:pi_iv_time3/features/admin/shared/models/admin_models.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';

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
    final updatedComponents = await AcademicModalDialog.show<
        List<Map<String, Object?>>>(
      context: context,
      builder: (dialogCtx) =>
          _StructuredComponentsEditorDialog(initialComponents: _components),
    );
    if (updatedComponents == null) return;
    try {
      setState(() => _saving = true);
      final ds = widget.dataSource ?? AdminAcademicRemoteDataSource();
      await ds.patchCourse(widget.course.code, {
        'components': updatedComponents,
      });
      if (mounted) {
        setState(() {
          _components = updatedComponents
              .map((item) => Map<String, dynamic>.from(item))
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

class _StructuredComponentsEditorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> initialComponents;

  const _StructuredComponentsEditorDialog({required this.initialComponents});

  @override
  State<_StructuredComponentsEditorDialog> createState() =>
      _StructuredComponentsEditorDialogState();
}

class _StructuredComponentsEditorDialogState
    extends State<_StructuredComponentsEditorDialog> {
  late final List<Map<String, TextEditingController>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialComponents.map((c) => _makeRow(c)).toList();
    if (_rows.isEmpty) {
      _rows.add(_makeRow({}));
    }
  }

  Map<String, TextEditingController> _makeRow(Map<String, dynamic> c) {
    final semRaw = (c['semestre'] ?? c['semester'] ?? '1º').toString();
    final nameRaw = (c['disciplina'] ?? c['name'] ?? '').toString();
    final codeRaw = (c['code'] ?? '').toString();
    final cargaRaw = (c['carga'] ??
            (c['workloadHours'] != null ? '${c['workloadHours']}h' : '80h'))
        .toString();
    final docRaw =
        (c['docente'] ?? c['professor'] ?? c['professorName'] ?? '').toString();
    return {
      'semestre': TextEditingController(text: semRaw),
      'code': TextEditingController(text: codeRaw),
      'disciplina': TextEditingController(text: nameRaw),
      'carga': TextEditingController(text: cargaRaw),
      'docente': TextEditingController(text: docRaw),
    };
  }

  @override
  void dispose() {
    for (final row in _rows) {
      for (final ctrl in row.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_makeRow({'semestre': '${_rows.length + 1}º', 'carga': '80h'}));
    });
  }

  void _removeRow(int index) {
    final removed = _rows.removeAt(index);
    for (final ctrl in removed.values) {
      ctrl.dispose();
    }
    setState(() {});
  }

  void _save() {
    final output = _rows
        .where((r) => r['disciplina']!.text.trim().isNotEmpty)
        .map(
          (r) => <String, Object?>{
            'semestre': r['semestre']!.text.trim(),
            if (r['code']!.text.trim().isNotEmpty) 'code': r['code']!.text.trim(),
            'disciplina': r['disciplina']!.text.trim(),
            'carga': r['carga']!.text.trim(),
            'docente': r['docente']!.text.trim(),
          },
        )
        .toList();
    Navigator.of(context).pop(output);
  }

  @override
  Widget build(BuildContext context) {
    return AcademicModalDialog(
      title: 'Editar Componentes Curriculares',
      subtitle: 'Adicione, edite ou remova disciplinas da matriz curricular sem JSON manual.',
      icon: Icons.edit_note_rounded,
      maxWidth: 740,
      cancelLabel: 'Cancelar',
      confirmLabel: 'Salvar Matriz',
      onConfirm: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < _rows.length; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: InstColors.stone,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: InstColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 82,
                        child: TextField(
                          controller: _rows[i]['semestre'],
                          decoration: InstText.inputDecoration(
                            labelText: 'Período',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _rows[i]['code'],
                          decoration: InstText.inputDecoration(
                            labelText: 'Código',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _rows[i]['disciplina'],
                          decoration: InstText.inputDecoration(
                            labelText: 'Nome da Disciplina',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 82,
                        child: TextField(
                          controller: _rows[i]['carga'],
                          decoration: InstText.inputDecoration(
                            labelText: 'Carga',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remover componente',
                        onPressed: () => _removeRow(i),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: InstColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rows[i]['docente'],
                    decoration: InstText.inputDecoration(
                      labelText: 'Docente Homologado / Colegiado',
                    ),
                  ),
                ],
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar componente'),
            ),
          ),
        ],
      ),
    );
  }
}
