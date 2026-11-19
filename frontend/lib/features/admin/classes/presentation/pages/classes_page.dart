// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/widgets/class_alocar_docente_modal.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/widgets/class_list_table.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/widgets/class_regime_formula_modal.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shared/models/admin_models.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_academic_data_source.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/widgets/admin_footer.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';
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
  List<AdminUserModel> _teachers = [];
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
      final values = await Future.wait<dynamic>([
        _dataSource.getCourses(),
        _dataSource.getClasses(),
        _dataSource.getTeachers(),
      ]);
      final courses = values[0] as List<AdminCourseModel>;
      final classes = values[1] as List<AdminClassModel>;
      final teachers = values[2] as List<AdminUserModel>;
      if (!mounted) return;
      _controller.classes = classes;
      setState(() {
        _courses = courses;
        _classes = classes;
        _teachers = teachers;
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

    final draft = await AcademicModalDialog.show<_ClassDraft>(
      context: context,
      builder: (_) => _CreateClassDialog(
        courses: _courses,
        teachers: _teachers,
      ),
    );
    if (draft == null) return;

    try {
      await _dataSource.createClass(
        code: draft.code,
        courseCode: draft.courseCode,
        subjectName: draft.subjectName,
        semester: draft.semester,
        shift: draft.shift,
        schedule: draft.schedule,
        location: draft.location,
        totalHours: draft.totalHours,
        maxCapacity: draft.maxCapacity,
        professorIdentity: draft.professorIdentity,
      );
      await _loadData();
      _showMessage('Turma cadastrada.');
    } on AdminAcademicApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _manageClassRecords(AdminClassModel classModel) async {
    await AcademicModalDialog.show<void>(
      context: context,
      builder: (dialogContext) => AcademicModalDialog(
        title: 'Registros da Turma ${classModel.code}',
        subtitle: classModel.subjectName,
        icon: Icons.event_note_outlined,
        cancelLabel: 'Fechar',
        confirmLabel: 'Concluir',
        onConfirm: () => Navigator.pop(dialogContext),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.pop(dialogContext);
                _enrollStudent(classModel);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: InstColors.stone,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: InstColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 19,
                      color: InstColors.ink,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Matricular aluno',
                        style: jakarta(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: InstColors.ink,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: InstColors.muted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.pop(dialogContext);
                _scheduleClassSession(classModel);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: InstColors.stone,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: InstColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      size: 19,
                      color: InstColors.ink,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Agendar aula',
                        style: jakarta(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: InstColors.ink,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: InstColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enrollStudent(AdminClassModel classModel) async {
    final identity = await _showTextPrompt(
      title: 'Matricular aluno',
      label: 'Identidade do aluno',
      action: 'Matricular',
    );
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

  Future<String?> _showTextPrompt({
    required String title,
    required String label,
    required String action,
  }) => AcademicModalDialog.show<String>(
    context: context,
    builder: (_) =>
        _TextPromptDialog(title: title, label: label, action: action),
  );

  Future<void> _scheduleClassSession(AdminClassModel classModel) async {
    final title = await _showTextPrompt(
      title: 'Agendar aula',
      label: 'Título da aula',
      action: 'Continuar',
    );
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
      onSaveRegime: (regime) async {
        final ok = await _controller.persistClass(c.code, {
          'formulaRegime': regime == 'Impor pelo Admin'
              ? 'admin'
              : 'autonomia_docente',
        });
        _showMessage(
          ok
              ? 'Regime atualizado.'
              : _controller.remoteError ?? 'Não foi possível atualizar.',
        );
        if (ok) await _loadData();
      },
    );
  }

  void _showAlocarDocenteModal(BuildContext context, AdminClassModel c) {
    ClassAlocarDocenteModal.show(
      context: context,
      classModel: c,
      teachers: _teachers,
      onConfirmAllocation: (prof) async {
        final ok = await _controller.persistClass(c.code, {
          'professorIdentity': prof,
        });
        _showMessage(
          ok
              ? 'Docente atribuído.'
              : _controller.remoteError ?? 'Não foi possível atribuir.',
        );
        if (ok) await _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeSupervisedClass != null) {
      final liveClass = _classes
          .where((item) => item.code == _activeSupervisedClass!.code)
          .firstOrNull;
      final portalClass = _controller.classes
          .where((item) => item.code == _activeSupervisedClass!.code)
          .firstOrNull;
      return SupervisionCockpitPage(
        classModel: portalClass ?? liveClass ?? _activeSupervisedClass!,
        onBack: () {
          setState(() => _activeSupervisedClass = null);
          _loadData();
        },
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
    final openBtn = ElevatedButton.icon(
      onPressed: _isLoading || !_controller.canPerform('manage_classes')
          ? null
          : _createClass,
      icon: const Icon(Icons.add, size: 17, color: Colors.white),
      label: Text(
        'Abrir turma',
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
      ],
    );

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titleColumn),
          const SizedBox(width: 24),
          openBtn,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titleColumn, const SizedBox(height: 16), openBtn],
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
}

class _ClassDraft {
  final String code;
  final String courseCode;
  final String subjectName;
  final String semester;
  final String shift;
  final String schedule;
  final String location;
  final int totalHours;
  final int maxCapacity;
  final String? professorIdentity;

  const _ClassDraft({
    required this.code,
    required this.courseCode,
    required this.subjectName,
    required this.semester,
    required this.shift,
    required this.schedule,
    required this.location,
    required this.totalHours,
    required this.maxCapacity,
    required this.professorIdentity,
  });
}

class _CreateClassDialog extends StatefulWidget {
  final List<AdminCourseModel> courses;
  final List<AdminUserModel> teachers;

  const _CreateClassDialog({required this.courses, required this.teachers});

  @override
  State<_CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<_CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _subjectName = TextEditingController();
  final _semester = TextEditingController(text: '2026/2');
  final _shift = TextEditingController(text: 'Noturno');
  final _schedule = TextEditingController(
    text: 'Segundas e Quartas, 19:00 - 20:40',
  );
  final _location = TextEditingController();
  final _totalHours = TextEditingController(text: '80');
  final _capacity = TextEditingController(text: '40');
  late String _selectedCourseCode = widget.courses.first.code;
  String? _selectedProfessorIdentity;

  @override
  void dispose() {
    _code.dispose();
    _subjectName.dispose();
    _semester.dispose();
    _shift.dispose();
    _schedule.dispose();
    _location.dispose();
    _totalHours.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AcademicModalDialog(
    title: 'Abrir Nova Turma',
    subtitle:
        'Associe o componente curricular, horários, sala e professor titular.',
    icon: Icons.class_outlined,
    cancelLabel: 'Cancelar',
    confirmLabel: 'Salvar turma',
    onConfirm: () {
      if (!_formKey.currentState!.validate()) return;
      Navigator.pop(
        context,
        _ClassDraft(
          code: _code.text.trim(),
          courseCode: _selectedCourseCode,
          subjectName: _subjectName.text.trim(),
          semester: _semester.text.trim(),
          shift: _shift.text.trim(),
          schedule: _schedule.text.trim(),
          location: _location.text.trim(),
          totalHours: int.parse(_totalHours.text.trim()),
          maxCapacity: int.parse(_capacity.text.trim()),
          professorIdentity: _selectedProfessorIdentity,
        ),
      );
    },
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedCourseCode,
            decoration: InstText.inputDecoration(labelText: 'Curso'),
            items: widget.courses
                .map(
                  (course) => DropdownMenuItem(
                    value: course.code,
                    child: Text(
                      course.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCourseCode = value);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(_code, 'Código da turma (ex: IHC-305)')),
              const SizedBox(width: 12),
              Expanded(child: _field(_semester, 'Período letivo')),
            ],
          ),
          _field(_subjectName, 'Nome da disciplina'),
          Row(
            children: [
              Expanded(child: _field(_shift, 'Turno')),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _totalHours,
                  'Carga horária (h)',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 10 || parsed > 400) {
                      return 'Informe entre 10 e 400.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _capacity,
                  'Vagas',
                  keyboardType: TextInputType.number,
                  validator: (value) => int.tryParse(value ?? '') == null
                      ? 'Informe um número válido.'
                      : null,
                ),
              ),
            ],
          ),
          _field(_location, 'Sala / Laboratório'),
          _field(_schedule, 'Dias e horário', required: false),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _selectedProfessorIdentity,
            decoration: InstText.inputDecoration(
              labelText: 'Docente titular (opcional)',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Alocar posteriormente'),
              ),
              ...widget.teachers.map(
                (t) => DropdownMenuItem<String?>(
                  value: t.identity,
                  child: Text(
                    '${t.name} (${t.identity})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (val) => setState(() => _selectedProfessorIdentity = val),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: jakarta(size: 13.5, color: InstColors.ink),
      decoration: InstText.inputDecoration(labelText: label),
      validator:
          validator ??
          (value) => required && (value == null || value.trim().isEmpty)
              ? 'Preencha este campo.'
              : null,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  final String title;
  final String label;
  final String action;

  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.action,
  });

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AcademicModalDialog(
    title: widget.title,
    icon: Icons.edit_outlined,
    cancelLabel: 'Cancelar',
    confirmLabel: widget.action,
    onConfirm: () => Navigator.pop(context, _controller.text.trim()),
    child: TextField(
      controller: _controller,
      decoration: InstText.inputDecoration(labelText: widget.label),
    ),
  );
}
