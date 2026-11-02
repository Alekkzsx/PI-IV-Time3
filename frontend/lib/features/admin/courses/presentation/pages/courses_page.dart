// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/courses/presentation/widgets/course_card_item.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_academic_data_source.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';

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
    final course = await showDialog<AdminCourseModel>(
      context: context,
      builder: (context) => const _CreateCourseDialog(),
    );
    if (course == null) return;

    try {
      await _dataSource.createCourse(course);
      await _loadCourses();
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
                                    child: CourseCardItem(course: _courses[i]),
                                  ),
                                  if (i + 1 < _courses.length) ...[
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: CourseCardItem(
                                        course: _courses[i + 1],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ] else ...[
                            for (int i = 0; i < _courses.length; i++) ...[
                              if (i > 0) const SizedBox(height: 20),
                              CourseCardItem(course: _courses[i]),
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
    return Column(
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
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _createCourse,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Novo curso'),
          ),
        ),
      ],
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

class _CreateCourseDialog extends StatefulWidget {
  const _CreateCourseDialog();

  @override
  State<_CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<_CreateCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _matrix = TextEditingController();
  final _workload = TextEditingController();
  final _department = TextEditingController();

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
    return AlertDialog(
      title: const Text('Cadastrar curso'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_code, 'Código do curso'),
                _field(_name, 'Nome do curso'),
                _field(_matrix, 'Matriz curricular'),
                _field(_workload, 'Carga horária'),
                _field(_department, 'Departamento'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              AdminCourseModel(
                code: _code.text.trim(),
                name: _name.text.trim(),
                matrix: _matrix.text.trim(),
                workload: _workload.text.trim(),
                studentsCount: 0,
                formula: 'Média ponderada',
                department: _department.text.trim(),
                modality: 'Graduação',
                components: const [],
              ),
            );
          },
          child: const Text('Salvar curso'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Preencha este campo.'
            : null,
      ),
    );
  }
}
