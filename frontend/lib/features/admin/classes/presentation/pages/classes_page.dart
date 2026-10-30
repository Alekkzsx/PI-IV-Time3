// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/widgets/class_alocar_docente_modal.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/widgets/class_list_table.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/widgets/class_regime_formula_modal.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_academic_data_source.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';
import 'supervision_cockpit_page.dart';

/// Tela de Gestão de Turmas, Ensalamento e Atribuição Docente na Visão do Administrador.
/// Refatorada com arquitetura limpa e subcomponentes desacoplados em `widgets/`.
class ClassesPage extends StatefulWidget {
  final AdminAcademicDataSource? dataSource;

  const ClassesPage({super.key, this.dataSource});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final AdminPortalController _controller = AdminPortalController.instance;
  late final AdminAcademicDataSource _dataSource =
      widget.dataSource ?? AdminAcademicRemoteDataSource();
  List<AdminCourseModel> _courses = [];
  List<AdminClassModel> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;
  AdminClassModel? _activeSupervisedClass;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
    _loadData();
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final courses = await _dataSource.getCourses();
      final classes = await _dataSource.getClasses();
      if (!mounted) return;
      _controller.classes = classes;
      setState(() {
        _courses = courses;
        _classes = classes;
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

  Future<void> _createClass() async {
    if (_courses.isEmpty) {
      _showMessage('Cadastre um curso antes de abrir uma turma.');
      return;
    }

    final code = TextEditingController();
    final semester = TextEditingController(text: '2026/2');
    final shift = TextEditingController(text: 'Noturno');
    final location = TextEditingController();
    final capacity = TextEditingController(text: '40');
    final professorIdentity = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedCourseCode = _courses.first.code;

    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Abrir turma'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCourseCode,
                      decoration: const InputDecoration(labelText: 'Curso'),
                      items: _courses
                          .map(
                            (course) => DropdownMenuItem(
                              value: course.code,
                              child: Text(course.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedCourseCode = value);
                        }
                      },
                    ),
                    _formField(code, 'Código da turma'),
                    _formField(semester, 'Período letivo'),
                    _formField(shift, 'Turno'),
                    _formField(location, 'Sala/local'),
                    _formField(
                      capacity,
                      'Número de vagas',
                      keyboardType: TextInputType.number,
                      validator: (value) => int.tryParse(value ?? '') == null
                          ? 'Informe um número de vagas válido.'
                          : null,
                    ),
                    _formField(
                      professorIdentity,
                      'Identidade do docente (opcional)',
                      required: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, {
                  'code': code.text.trim(),
                  'semester': semester.text.trim(),
                  'shift': shift.text.trim(),
                  'location': location.text.trim(),
                  'capacity': capacity.text.trim(),
                  'professorIdentity': professorIdentity.text.trim(),
                });
              },
              child: const Text('Salvar turma'),
            ),
          ],
        ),
      ),
    );

    code.dispose();
    semester.dispose();
    shift.dispose();
    location.dispose();
    capacity.dispose();
    professorIdentity.dispose();
    if (values == null) return;

    try {
      await _dataSource.createClass(
        code: values['code']!,
        courseCode: selectedCourseCode,
        semester: values['semester']!,
        shift: values['shift']!,
        location: values['location']!,
        maxCapacity: int.parse(values['capacity']!),
        professorIdentity: values['professorIdentity'],
      );
      await _loadData();
      _showMessage('Turma cadastrada.');
    } on AdminAcademicApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _manageClassRecords(AdminClassModel classModel) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(classModel.code),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Matricular aluno'),
              onTap: () {
                Navigator.pop(dialogContext);
                _enrollStudent(classModel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Agendar aula'),
              onTap: () {
                Navigator.pop(dialogContext);
                _scheduleClassSession(classModel);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _enrollStudent(AdminClassModel classModel) async {
    final identityController = TextEditingController();
    final identity = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Matricular aluno'),
        content: TextField(
          controller: identityController,
          decoration: const InputDecoration(labelText: 'Identidade do aluno'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, identityController.text.trim()),
            child: const Text('Matricular'),
          ),
        ],
      ),
    );
    identityController.dispose();
    if (identity == null || identity.isEmpty) return;

    try {
      await _dataSource.createEnrollment(
        classCode: classModel.code,
        studentIdentity: identity,
      );
      await _loadData();
      _showMessage('Matrícula registrada.');
    } on AdminAcademicApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _scheduleClassSession(AdminClassModel classModel) async {
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Agendar aula'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Título da aula'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, titleController.text.trim()),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    titleController.dispose();
    if (title == null || title.isEmpty || !mounted) return;

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    try {
      await _dataSource.createClassSession(
        classCode: classModel.code,
        title: title,
        startsAt: DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
      _showMessage('Aula agendada.');
    } on AdminAcademicApiException catch (error) {
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showRegimeFormulaModal(BuildContext context, AdminClassModel c) {
    ClassRegimeFormulaModal.show(
      context: context,
      classModel: c,
      onSaveRegime: (regime) => _controller.updateFormulaRegime(c.code, regime),
    );
  }

  void _showAlocarDocenteModal(BuildContext context, AdminClassModel c) {
    ClassAlocarDocenteModal.show(
      context: context,
      classModel: c,
      onConfirmAllocation: (prof) =>
          _controller.reallocateProfessor(c.code, prof),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeSupervisedClass != null) {
      return SupervisionCockpitPage(
        classModel: _activeSupervisedClass!,
        onBack: () => setState(() => _activeSupervisedClass = null),
      );
    }

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
                        else if (_classes.isEmpty)
                          _buildStatus('Nenhuma turma cadastrada.')
                        else
                          ClassListTable(
                            classes: _classes,
                            onSupervise: (c) =>
                                setState(() => _activeSupervisedClass = c),
                            onOpenRegime: (c) =>
                                _showRegimeFormulaModal(context, c),
                            onOpenAlocar: (c) =>
                                _showAlocarDocenteModal(context, c),
                            onManageRecords: _manageClassRecords,
                            canManageClasses: _controller.canPerform(
                              'manage_classes',
                            ),
                            canManageVideoCalls: _controller.canPerform(
                              'manage_video_calls',
                            ),
                          ),
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
          'Gestão de Turmas, Ensalamento & Atribuição Docente',
          style: jakarta(
            size: isDesktop ? 26 : 22,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Abertura de turmas no período letivo, alocação de salas/laboratórios e vinculação do professor regente.',
          style: jakarta(
            size: 14,
            weight: FontWeight.w400,
            color: const Color(0xFF737373),
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _isLoading || !_controller.canPerform('manage_classes')
                ? null
                : _createClass,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Abrir turma'),
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
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator:
            validator ??
            (value) => required && (value == null || value.trim().isEmpty)
                ? 'Preencha este campo.'
                : null,
      ),
    );
  }
}
