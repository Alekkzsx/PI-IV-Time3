// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/courses/presentation/widgets/course_card_item.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/models/admin_models.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_academic_data_source.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';

/// Tela de Cursos & Matrizes Curriculares (PPC) da Visão do Administrador.
/// Exibe a estrutura pedagógica institucional, carga horária regimental,
/// critérios de aprovação e o modal de detalhamento do ementário por período.
class CoursesPage extends StatefulWidget {
  final AdminAcademicDataSource? dataSource;

  const CoursesPage({super.key, this.dataSource});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  late final AdminAcademicDataSource _dataSource =
      widget.dataSource ?? AdminAcademicRemoteDataSource();
  List<AdminCourseModel> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final courses = await _dataSource.getCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } on AdminAcademicApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _createCourse() async {
    final course = await AcademicModalDialog.show<AdminCourseModel>(
      context: context,
      builder: (context) => const _CourseFormDialog(),
    );
    if (course == null) return;

    try {
      await _dataSource.createCourse(course);
      await _loadCourses();
      if (widget.dataSource == null) {
        AdminPortalController.instance.loadRemote();
      }
    } on AdminAcademicApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _editCourse(AdminCourseModel current) async {
    final updated = await AcademicModalDialog.show<AdminCourseModel>(
      context: context,
      builder: (context) => _CourseFormDialog(initialCourse: current),
    );
    if (updated == null) return;

    try {
      await _dataSource.patchCourse(current.code, {
        'name': updated.name,
        'matrix': updated.matrix,
        'workload': updated.workload,
        'department': updated.department,
        'modality': updated.modality,
        'formula': updated.formula,
      });
      await _loadCourses();
      if (widget.dataSource == null) {
        AdminPortalController.instance.loadRemote();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curso atualizado com sucesso.')),
      );
    } on AdminAcademicApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : 20.0,
                      vertical: 36.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDesktop),
                        const SizedBox(height: 28),

                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_errorMessage != null)
                          _buildStatus(_errorMessage!, retry: true)
                        else if (_courses.isEmpty)
                          _buildStatus('Nenhum curso cadastrado.')
                        else ...[
                          if (isDesktop && _courses.length >= 2) ...[
                            for (var i = 0; i < _courses.length; i += 2) ...[
                              if (i > 0) const SizedBox(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: CourseCardItem(
                                      course: _courses[i],
                                      onUpdated: _loadCourses,
                                      onEdit: () => _editCourse(_courses[i]),
                                      dataSource: _dataSource,
                                    ),
                                  ),
                                  if (i + 1 < _courses.length) ...[
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: CourseCardItem(
                                        course: _courses[i + 1],
                                        onUpdated: _loadCourses,
                                        onEdit: () =>
                                            _editCourse(_courses[i + 1]),
                                        dataSource: _dataSource,
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(width: 24),
                                    const Expanded(child: SizedBox.shrink()),
                                  ],
                                ],
                              ),
                            ],
                          ] else ...[
                            for (int i = 0; i < _courses.length; i++) ...[
                              if (i > 0) const SizedBox(height: 20),
                              CourseCardItem(
                                course: _courses[i],
                                onUpdated: _loadCourses,
                                onEdit: () => _editCourse(_courses[i]),
                                dataSource: _dataSource,
                              ),
                            ],
                          ],
                        ],
                      ],
                    ),
                  ),
                  const AdminFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    final createBtn = ElevatedButton.icon(
      onPressed: _isLoading ? null : _createCourse,
      icon: const Icon(Icons.add, size: 17, color: Colors.white),
      label: Text(
        'Novo curso',
        style: jakarta(size: 13.5, weight: FontWeight.w600, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: InstColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cursos & Matrizes Curriculares (PPC)',
          style: jakarta(
            size: isDesktop ? 28 : 24,
            weight: FontWeight.w700,
            color: const Color(0xFF000000),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Estrutura pedagógica institucional, carga horária regimental e parametrização das fórmulas de avaliação.',
          style: jakarta(
            size: 14.5,
            weight: FontWeight.w400,
            color: const Color(0xFF737373),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titleColumn),
          const SizedBox(width: 24),
          createBtn,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titleColumn, const SizedBox(height: 16), createBtn],
    );
  }

  Widget _buildStatus(String message, {bool retry = false}) {
    return Center(
      child: Column(
        children: [
          Text(message),
          if (retry) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadCourses,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CourseFormDialog extends StatefulWidget {
  final AdminCourseModel? initialCourse;

  const _CourseFormDialog({this.initialCourse});

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _matrix;
  late final TextEditingController _workload;
  late final TextEditingController _department;
  late String _modality;
  late String _formula;

  static const _modalities = ['Graduação', 'Tecnólogo', 'Pós-Graduação', 'Presencial'];
  static const _formulas = [
    '(N1 × 0.4) + (N2 × 0.6)',
    '(N1 + N2) / 2',
    'Média aritmética de instrumentos contínuos',
  ];

  bool get _isEditing => widget.initialCourse != null;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCourse;
    _code = TextEditingController(text: c?.code ?? '');
    _name = TextEditingController(text: c?.name ?? '');
    _matrix = TextEditingController(text: c?.matrix ?? '');
    _workload = TextEditingController(text: c?.workload ?? '');
    _department = TextEditingController(text: c?.department ?? '');
    _modality = _modalities.contains(c?.modality) ? c!.modality : 'Graduação';
    final initFormula = c?.formula ?? '';
    _formula = _formulas.contains(initFormula)
        ? initFormula
        : '(N1 × 0.4) + (N2 × 0.6)';
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _matrix.dispose();
    _workload.dispose();
    _department.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AcademicModalDialog(
      title: _isEditing ? 'Editar Curso & PPC' : 'Cadastrar Curso',
      subtitle:
          'Configure os dados regimentais, modalidade e fórmula avaliativa padrão do curso.',
      icon: Icons.school_outlined,
      cancelLabel: 'Cancelar',
      confirmLabel: _isEditing ? 'Salvar alterações' : 'Salvar curso',
      onConfirm: () {
        if (!_formKey.currentState!.validate()) return;
        Navigator.pop(
          context,
          AdminCourseModel(
            code: _code.text.trim(),
            name: _name.text.trim(),
            matrix: _matrix.text.trim(),
            workload: _workload.text.trim(),
            studentsCount: widget.initialCourse?.studentsCount ?? 0,
            formula: _formula,
            department: _department.text.trim(),
            modality: _modality,
            components: widget.initialCourse?.components ?? const [],
          ),
        );
      },
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _field(_code, 'Código do curso', readOnly: _isEditing),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: _modality,
                      decoration: InstText.inputDecoration(
                        labelText: 'Modalidade',
                      ),
                      items: _modalities
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _modality = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
            _field(_name, 'Nome do curso'),
            Row(
              children: [
                Expanded(child: _field(_matrix, 'Matriz curricular')),
                const SizedBox(width: 12),
                Expanded(child: _field(_workload, 'Carga horária (ex: 3.200h)')),
              ],
            ),
            _field(_department, 'Departamento / Unidade'),
            DropdownButtonFormField<String>(
              initialValue: _formula,
              decoration: InstText.inputDecoration(
                labelText: 'Fórmula de avaliação padrão',
              ),
              items: _formulas
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _formula = v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: jakarta(
          size: 13.5,
          color: readOnly ? InstColors.muted : InstColors.ink,
        ),
        decoration: InstText.inputDecoration(labelText: label),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Preencha este campo.'
            : null,
      ),
    );
  }
}
