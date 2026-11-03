// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import '../../../../core/network/auth_profile_remote_data_source.dart';
import '../../../../core/utils/platform_file_helper.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/state/app_user_session.dart';
import '../../../../core/state/academic_bridge_service.dart';
import '../data/teacher_remote_data_source.dart';
import '../domain/models/academic_event.dart';
import '../domain/models/academic_notice.dart';
import '../domain/models/assignment_model.dart';
import '../domain/models/attendance_record.dart';
import '../domain/models/docente_course.dart';
import '../domain/models/docente_profile.dart';
import '../domain/models/grade_record.dart';
import '../domain/models/rubric_model.dart';

/// Available tabs in the Docente Portal sidebar navigation.
enum DocenteNavTab {
  painel,
  turmas,
  diario,
  atividades,
  notas,
  agenda,
  comunicados,
  configuracoes,
}

/// Reactive controller managing all frontend state for the Docente Portal.
class DocenteController extends ChangeNotifier {
  final TeacherRemoteDataSource _remote;
  final AuthProfileRemoteDataSource _profileRemote;
  bool isLoadingRemote = false;
  String? remoteError;

  DocenteNavTab _activeTab = DocenteNavTab.painel;
  bool _isSidebarCollapsed = false;

  List<DocenteCourse> _courses = [];
  String _selectedCourseId = '';

  ClassSession _currentSession = _emptySession;
  List<ClassSession> _sessions = [];
  List<AssignmentItem> _assignments = [];
  String _selectedAssignmentId = '';

  List<StudentGrade> _gradebook = [];
  List<AcademicEvent> _events = [];
  List<AcademicNotice> _notices = [];
  DocenteProfile _profile = _emptyProfile;
  String _ownerIdentity = '';

  String _settingsSubtab =
      'perfil'; // 'perfil', 'seguranca', 'notificacoes', 'preferencias', 'privacidade'

  // Homologação de Pauta & Chancela Digital do Docente Titular
  final Map<String, bool> _pautaHomologada = {};
  final Map<String, String> _pautaChancelaCodes = {};

  final List<Map<String, dynamic>> _retificacaoRequests = [];
  final Map<String, List<Map<String, dynamic>>> _forumTopicsByCourse = {};

  DocenteController({
    TeacherRemoteDataSource? remoteDataSource,
    AuthProfileRemoteDataSource? profileRemoteDataSource,
  }) : _remote = remoteDataSource ?? TeacherRemoteDataSource(),
       _profileRemote =
           profileRemoteDataSource ?? AuthProfileRemoteDataSource() {
    _ownerIdentity = '';
  }

  Future<void> loadRemote({bool force = false}) async {
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      remoteError = 'Entre novamente para carregar suas turmas.';
      _clearRemoteState();
      notifyListeners();
      return;
    }
    if (isLoadingRemote) return;

    isLoadingRemote = true;
    remoteError = null;
    _clearRemoteState();
    notifyListeners();
    try {
      final snapshot = await _remote.getBootstrap();
      if (AppUserSession.instance.accessToken != token) return;
      _ownerIdentity = snapshot.profile.registrationId;
      _profile = snapshot.profile;
      _courses = snapshot.courses;
      _selectedCourseId = _courses.isEmpty ? '' : _courses.first.id;
      _sessions = snapshot.sessions;
      _assignments = snapshot.assignments;
      _gradebook = snapshot.grades;
      _events = snapshot.events;
      _notices = snapshot.notices;
      _currentSession = _sessions.isEmpty
          ? _emptySession
          : _sessions.firstWhere(
              (session) => session.courseId == _selectedCourseId,
              orElse: () => _sessions.first,
            );
      _pautaHomologada
        ..clear()
        ..addEntries(
          _courses.map(
            (course) => MapEntry(course.id, course.pautaHomologated),
          ),
        );
      _pautaChancelaCodes
        ..clear()
        ..addEntries(
          _courses
              .where((course) => course.chancelaCode != null)
              .map((course) => MapEntry(course.id, course.chancelaCode!)),
        );
      _selectedAssignmentId = _assignments.isEmpty ? '' : _assignments.first.id;
      _forumTopicsByCourse
        ..clear()
        ..addEntries(
          _courses.map((course) => MapEntry(course.code, course.forumTopics)),
        );
      AcademicBridgeService.instance.registerTeacherCourses(
        _ownerIdentity,
        _courses.map((course) => course.code),
        teacherEmail: _profile.academicEmail,
      );
      for (final course in _courses) {
        AcademicBridgeService.instance.registerClassRoom(
          code: course.code,
          subjectName: course.title,
          professorName: _profile.fullName,
          professorIdentity: _ownerIdentity,
        );
      }
    } on ApiException catch (error) {
      if (AppUserSession.instance.accessToken == token) {
        remoteError = error.message;
      }
    } catch (_) {
      if (AppUserSession.instance.accessToken == token) {
        remoteError = 'Não foi possível carregar os dados docentes.';
      }
    } finally {
      isLoadingRemote = false;
      notifyListeners();
    }
  }

  void _clearRemoteState() {
    _courses = [];
    _sessions = [];
    _assignments = [];
    _gradebook = [];
    _events = [];
    _notices = [];
    _profile = _emptyProfile;
    _currentSession = _emptySession;
    _selectedCourseId = '';
    _selectedAssignmentId = '';
    _pautaHomologada.clear();
    _pautaChancelaCodes.clear();
    _forumTopicsByCourse.clear();
  }

  Future<void> _persistCurrentSession() async {
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty || _currentSession.id.isEmpty) {
      remoteError = 'Entre novamente para salvar o diário.';
      notifyListeners();
      return;
    }
    final courseId = _selectedCourseId;
    final sessionId = _currentSession.id;
    try {
      await _remote.updateSessionAttendance(
        sessionId: sessionId,
        contentProgram: _currentSession.contentProgram,
        methodology: _currentSession.methodology,
        location: _currentSession.location,
        isHomologated: _currentSession.isHomologated,
        attendanceList: _currentSession.attendanceList
            .map(
              (student) => <String, Object?>{
                'studentId': student.studentId,
                'ra': student.ra,
                'name': student.name,
                'status': student.status.name,
              },
            )
            .toList(),
      );
      await _reloadSessionContext(courseId, sessionId);
    } on ApiException catch (error) {
      remoteError = error.message;
      notifyListeners();
    } catch (_) {
      remoteError = 'Não foi possível salvar o diário.';
      notifyListeners();
    }
  }

  Future<void> _reloadSessionContext(String courseId, String sessionId) async {
    await loadRemote(force: true);
    if (_courses.any((course) => course.id == courseId)) {
      _selectedCourseId = courseId;
    }
    _currentSession = _sessions.firstWhere(
      (session) => session.id == sessionId,
      orElse: () =>
          _sessions
              .where((session) => session.courseId == courseId)
              .firstOrNull ??
          _emptySession,
    );
    notifyListeners();
  }

  static const ClassSession _emptySession = ClassSession(
    id: '',
    courseId: '',
    sessionNumber: 0,
    hours: 0,
    dateFormatted: '',
    contentProgram: '',
    methodology: '',
    isHomologated: false,
    attendanceList: [],
  );

  static const DocenteProfile _emptyProfile = DocenteProfile(
    fullName: '',
    socialName: '',
    registrationId: '',
    department: '',
    semester: '',
    campus: '',
    status: '',
    academicEmail: '',
    personalEmail: '',
    twoFactorEnabled: false,
    activeSessions: [],
    loginAudits: [],
  );

  bool get _hasActiveTeacherAccess {
    final session = AppUserSession.instance;
    return _ownerIdentity.isNotEmpty &&
        session.hasRole('docente') &&
        session.identity == _ownerIdentity;
  }

  bool _canManageCourse(String courseId, String permission) =>
      _hasActiveTeacherAccess &&
      AppUserSession.instance.hasPermission(permission) &&
      _courses.any((course) => course.id == courseId);

  static const DocenteCourse _emptyCourse = DocenteCourse(
    id: '',
    teacherIdentity: '',
    code: '',
    title: '',
    term: '',
    shift: '',
    room: '',
    schedule: '',
    enrolledCount: 0,
    completedHours: 0,
    totalHours: 0,
    syllabusUnits: [],
    materials: [],
  );

  static const AssignmentItem _emptyAssignment = AssignmentItem(
    id: '',
    courseId: '',
    courseCode: '',
    title: '',
    weight: 0,
    stage: '',
    dueDateFormatted: '',
    isUrgent: false,
    modality: '',
    allowLateWithPenalty: false,
    rubricCriteria: [],
    submissions: [],
  );

  // --- Getters ---
  DocenteNavTab get activeTab => _activeTab;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  List<DocenteCourse> get courses => List.unmodifiable(_courses);
  String get selectedCourseId => _selectedCourseId;
  ClassSession get currentSession => _currentSession;
  List<ClassSession> get sessions => List.unmodifiable(_sessions);
  List<ClassSession> get sessionsForSelectedCourse =>
      (_sessions.where((s) => s.courseId == _selectedCourseId).toList()
        ..sort((a, b) {
          final dateOrder = a.sessionDate.compareTo(b.sessionDate);
          return dateOrder != 0
              ? dateOrder
              : a.sessionNumber.compareTo(b.sessionNumber);
        }));
  List<AttendanceStudent> get studentsForSelectedCourse {
    final studentsByRa = <String, AttendanceStudent>{};
    for (final session in sessionsForSelectedCourse) {
      for (final student in session.attendanceList) {
        studentsByRa.putIfAbsent(student.ra, () => student);
      }
    }
    return studentsByRa.values.toList()
      ..sort((first, second) => first.name.compareTo(second.name));
  }

  List<AssignmentItem> get assignments => List.unmodifiable(_assignments);
  String get selectedAssignmentId => _selectedAssignmentId;
  List<StudentGrade> get gradebook => List.unmodifiable(
    _gradebook.where((grade) => grade.courseId == _selectedCourseId),
  );
  List<AcademicEvent> get events => List.unmodifiable(_events);
  List<AcademicNotice> get notices => List.unmodifiable(_notices);
  DocenteProfile get profile => _profile;
  String get settingsSubtab => _settingsSubtab;

  DocenteCourse get selectedCourse => _courses.firstWhere(
    (c) => c.id == _selectedCourseId,
    orElse: () => _emptyCourse,
  );

  AssignmentItem get selectedAssignment => _assignments.firstWhere(
    (a) => a.id == _selectedAssignmentId,
    orElse: () => _emptyAssignment,
  );

  bool isPautaHomologada(String courseId) =>
      _pautaHomologada[courseId] ?? false;
  String? getChancelaCode(String courseId) => _pautaChancelaCodes[courseId];
  List<Map<String, dynamic>> get retificacaoRequests =>
      List.unmodifiable(_retificacaoRequests);

  // --- Navigation Methods ---
  void navigateToTab(DocenteNavTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void toggleSidebarCollapse() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void selectCourse(String courseId) {
    if (!_courses.any((course) => course.id == courseId)) return;
    _selectedCourseId = courseId;
    final courseSessions = _sessions
        .where((s) => s.courseId == courseId)
        .toList();
    if (courseSessions.isNotEmpty) {
      _currentSession = courseSessions.firstWhere(
        (s) => s.sessionNumber == 27,
        orElse: () => courseSessions.first,
      );
    }
    notifyListeners();
  }

  void setSettingsSubtab(String subtab) {
    _settingsSubtab = subtab;
    notifyListeners();
  }

  // --- Course & Syllabus Methods ---
  Future<void> advanceSyllabusClasses(String courseId, String unitId) async {
    if (!_canManageCourse(courseId, 'manage_course_content')) return;
    try {
      await _remote.advanceSyllabus(selectedCourse.code, unitId);
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível avançar o plano de ensino.';
    }
    notifyListeners();
  }

  Future<void> publishMaterial(
    String courseId,
    String title,
    PickedPlatformFile? file,
  ) async {
    if (!_canManageCourse(courseId, 'manage_materials') ||
        title.trim().isEmpty ||
        file == null ||
        file.sizeBytes > 25 * 1024 * 1024) {
      if (file == null) remoteError = 'Selecione um arquivo para publicar.';
      if (file != null && file.sizeBytes > 25 * 1024 * 1024) {
        remoteError = 'O arquivo deve ter no máximo 25 MB.';
      }
      notifyListeners();
      return;
    }
    try {
      await _remote.publishMaterial(
        classCode: selectedCourse.code,
        title: title.trim(),
        fileName: file.name,
        mimeType: file.mimeType,
        size: file.sizeLabel,
        contentBase64: file.base64Content,
      );
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível publicar o material.';
    }
    notifyListeners();
  }

  // --- Attendance & Diary Methods ---
  void _syncSessionInList() {
    final idx = _sessions.indexWhere((s) => s.id == _currentSession.id);
    if (idx != -1) {
      _sessions[idx] = _currentSession;
    }
  }

  String formatSessionDate(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    const weekdays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    final dayStr = date.day.toString().padLeft(2, '0');
    final monthStr = months[date.month - 1];
    final weekdayStr = weekdays[date.weekday - 1];
    return '$dayStr de $monthStr de ${date.year} ($weekdayStr)';
  }

  void selectSession(String sessionId) {
    final found = _sessions
        .where((s) => s.id == sessionId && s.courseId == _selectedCourseId)
        .firstOrNull;
    if (found == null || found.id == _currentSession.id) return;
    _currentSession = found;
    notifyListeners();
  }

  Future<void> selectSessionByDate(DateTime pickedDate) async {
    if (!selectedCourse.classWeekdays.contains(pickedDate.weekday)) return;

    final normalizedDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
    );
    final existing = _sessions
        .where(
          (s) =>
              s.courseId == _selectedCourseId &&
              s.sessionDate.year == normalizedDate.year &&
              s.sessionDate.month == normalizedDate.month &&
              s.sessionDate.day == normalizedDate.day,
        )
        .firstOrNull;
    if (existing != null) {
      if (existing.id == _currentSession.id) return;
      _currentSession = existing;
      notifyListeners();
      return;
    }

    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      remoteError = 'Entre novamente para agendar uma aula.';
      notifyListeners();
      return;
    }
    final courseId = _selectedCourseId;
    final classCode = selectedCourse.code;
    try {
      await _remote.createOrSelectSession(
        classCode: classCode,
        date: normalizedDate,
      );
      await loadRemote(force: true);
      if (_courses.any((course) => course.id == courseId))
        _selectedCourseId = courseId;
      _currentSession = _sessions.firstWhere(
        (session) =>
            session.courseId == courseId &&
            session.sessionDate.year == normalizedDate.year &&
            session.sessionDate.month == normalizedDate.month &&
            session.sessionDate.day == normalizedDate.day,
        orElse: () => _currentSession,
      );
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível agendar a aula.';
    }
    notifyListeners();
  }

  bool get canGoToPreviousSession {
    final list = sessionsForSelectedCourse;
    final index = list.indexWhere((s) => s.id == _currentSession.id);
    return index > 0;
  }

  bool get canGoToNextSession {
    final list = sessionsForSelectedCourse;
    final index = list.indexWhere((s) => s.id == _currentSession.id);
    return index != -1 && index < list.length - 1;
  }

  void goToPreviousSession() {
    final list = sessionsForSelectedCourse;
    final index = list.indexWhere((s) => s.id == _currentSession.id);
    if (index > 0) {
      _currentSession = list[index - 1];
      notifyListeners();
    }
  }

  void goToNextSession() {
    final list = sessionsForSelectedCourse;
    final index = list.indexWhere((s) => s.id == _currentSession.id);
    if (index != -1 && index < list.length - 1) {
      _currentSession = list[index + 1];
      notifyListeners();
    }
  }

  Future<void> updateSessionContent(
    String content,
    String methodology, [
    String? location,
  ]) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_attendance') ||
        _currentSession.courseId != _selectedCourseId) {
      return;
    }
    final normalizedContent = content.trim();
    final normalizedMethodology = methodology.trim();
    final normalizedLocation = location?.trim();
    if (normalizedContent.isEmpty || normalizedMethodology.isEmpty) return;
    _currentSession = _currentSession.copyWith(
      contentProgram: normalizedContent,
      methodology: normalizedMethodology,
      location: normalizedLocation?.isEmpty == false
          ? normalizedLocation
          : _currentSession.location,
      // Any edit after approval requires a new homologation.
      isHomologated: false,
    );
    _syncSessionInList();
    notifyListeners();
    await _persistCurrentSession();
  }

  Future<void> markAllPresent() async {
    if (!_canManageCourse(_selectedCourseId, 'manage_attendance') ||
        _currentSession.courseId != _selectedCourseId) {
      return;
    }
    if (_currentSession.attendanceList.every(
      (student) => student.status == AttendanceStatus.presente,
    )) {
      return;
    }
    final updatedAttendance = _currentSession.attendanceList
        .map(
          (student) =>
              _attendanceWithStatus(student, AttendanceStatus.presente),
        )
        .toList();
    _currentSession = _currentSession.copyWith(
      attendanceList: updatedAttendance,
      isHomologated: false,
    );
    _syncSessionInList();
    notifyListeners();
    await _persistCurrentSession();
  }

  AttendanceStudent _attendanceWithStatus(
    AttendanceStudent record,
    AttendanceStatus newStatus,
  ) {
    return record.copyWith(status: newStatus);
  }

  Future<void> toggleAttendance(
    String studentId,
    AttendanceStatus newStatus,
  ) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_attendance') ||
        _currentSession.courseId != _selectedCourseId ||
        !_currentSession.attendanceList.any(
          (record) => record.studentId == studentId,
        )) {
      return;
    }
    final updatedAttendance = _currentSession.attendanceList.map((record) {
      if (record.studentId == studentId) {
        return _attendanceWithStatus(record, newStatus);
      }
      return record;
    }).toList();

    _currentSession = _currentSession.copyWith(
      attendanceList: updatedAttendance,
      isHomologated: false,
    );
    _syncSessionInList();
    notifyListeners();
    await _persistCurrentSession();
  }

  Future<void> homologateSession() async {
    if (!_canManageCourse(_selectedCourseId, 'manage_attendance') ||
        _currentSession.courseId != _selectedCourseId) {
      return;
    }
    _currentSession = _currentSession.copyWith(isHomologated: true);
    _syncSessionInList();

    notifyListeners();
    await _persistCurrentSession();
  }

  // --- Assignments & Rubric Methods ---
  void selectAssignment(String assignmentId) {
    if (!_assignments.any((assignment) => assignment.id == assignmentId) ||
        _selectedAssignmentId == assignmentId) {
      return;
    }
    _selectedAssignmentId = assignmentId;
    notifyListeners();
  }

  Future<bool> createAssignment({
    required String courseId,
    required String courseCode,
    required String title,
    String description = '',
    required double weight,
    required String stage,
    required String dueDateFormatted,
    required String modality,
    required bool allowLateWithPenalty,
    required List<RubricCriterion> rubricCriteria,
  }) async {
    if (!_canManageCourse(courseId, 'manage_assignments') ||
        !_courses.any(
          (course) =>
              course.id == courseId &&
              AcademicBridgeService.instance.courseCodesMatch(
                course.code,
                courseCode,
              ),
        ) ||
        title.trim().isEmpty ||
        dueDateFormatted.trim().isEmpty ||
        !weight.isFinite ||
        weight <= 0 ||
        rubricCriteria.isEmpty) {
      return false;
    }
    try {
      await _remote.createAssignment(
        classCode: courseCode,
        assignment: {
          'title': title.trim(),
          'description': description.trim(),
          'weight': weight,
          'stage': stage,
          'dueDateFormatted': dueDateFormatted,
          'modality': modality,
          'allowLateWithPenalty': allowLateWithPenalty,
          'rubricCriteria': rubricCriteria
              .map(
                (criterion) => {
                  'id': criterion.id,
                  'title': criterion.title,
                  'maxPoints': criterion.maxPoints,
                  'description': criterion.description,
                },
              )
              .toList(),
        },
      );
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível criar a atividade.';
    }
    notifyListeners();
    return false;
  }

  Future<void> evaluateRubric({
    required String assignmentId,
    required String submissionId,
    required double calculatedGrade,
    required String feedback,
    required List<RubricCriterion> evaluatedCriteria,
  }) async {
    final asgIndex = _assignments.indexWhere((a) => a.id == assignmentId);
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission('manage_assignments') ||
        asgIndex == -1 ||
        !_courses.any(
          (course) => course.id == _assignments[asgIndex].courseId,
        )) {
      return;
    }

    final assignment = _assignments[asgIndex];
    if (!calculatedGrade.isFinite ||
        calculatedGrade < 0 ||
        calculatedGrade > 10 ||
        !assignment.submissions.any(
          (submission) =>
              submission.id == submissionId &&
              submission.status == SubmissionStatus.aguardandoCorrecao,
        )) {
      return;
    }
    final submission = assignment.submissions.firstWhere(
      (item) => item.id == submissionId,
    );
    try {
      await _remote.evaluateSubmission(
        assignmentId: assignmentId,
        studentId: submission.studentId,
        calculatedGrade: calculatedGrade,
        feedback: feedback.trim(),
        evaluatedCriteria: evaluatedCriteria
            .map(
              (criterion) => <String, Object?>{
                'id': criterion.id,
                'title': criterion.title,
                'maxPoints': criterion.maxPoints,
                'assignedScore': criterion.assignedScore ?? 0,
                'description': criterion.description,
              },
            )
            .toList(),
      );
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível avaliar a entrega.';
    }
    notifyListeners();
  }

  // --- Gradebook Methods ---
  Future<void> updateStudentGrade(
    String studentId, {
    double? assignments,
    double? p1,
    double? projects,
    double? p2,
  }) async {
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission('edit_grades') ||
        !gradebook.any((grade) => grade.studentId == studentId)) {
      return;
    }

    double? normalize(double? value) {
      if (value == null || !value.isFinite) return null;
      return value.clamp(0.0, 10.0).toDouble();
    }

    final normalizedAssignments = normalize(assignments);
    final normalizedP1 = normalize(p1);
    final normalizedProjects = normalize(projects);
    final normalizedP2 = normalize(p2);
    try {
      await _remote.updateGrade(
        classCode: selectedCourse.code,
        studentId: studentId,
        assignmentsScore: normalizedAssignments,
        p1Score: normalizedP1,
        projectsScore: normalizedProjects,
        p2Score: normalizedP2,
      );
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível salvar a nota.';
    }
    notifyListeners();
  }

  // --- Métodos de Homologação, Chancela Digital & Retificação com Coordenação ---

  Future<void> homologarPautaComChancela(String courseId) async {
    if (!_canManageCourse(courseId, 'edit_grades') ||
        !_courses.any((course) => course.id == courseId)) {
      return;
    }
    final course = _courses.firstWhere((c) => c.id == courseId);
    try {
      final result = await _remote.homologate(course.code);
      if (result['pautaHomologated'] == true) {
        _pautaHomologada[courseId] = true;
      }
      if (result['chancelaCode'] is String) {
        _pautaChancelaCodes[courseId] = result['chancelaCode'] as String;
      }
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível homologar a pauta.';
    }
    notifyListeners();
  }

  Future<void> solicitarRetificacaoNota({
    required String courseId,
    required String studentRa,
    required String studentName,
    required String avaliacao,
    required double notaAnterior,
    required double novaNota,
    required String justificativa,
  }) async {
    final course = _courses.where((item) => item.id == courseId).firstOrNull;
    final isEnrolledStudent = _sessions
        .where((session) => session.courseId == courseId)
        .expand((session) => session.attendanceList)
        .any((student) => student.ra == studentRa);
    if (!_canManageCourse(courseId, 'edit_grades') ||
        course == null ||
        courseId != _selectedCourseId ||
        !isEnrolledStudent ||
        !notaAnterior.isFinite ||
        !novaNota.isFinite ||
        novaNota < 0 ||
        novaNota > 10 ||
        justificativa.trim().isEmpty) {
      return;
    }
    final student = _sessions
        .where((session) => session.courseId == courseId)
        .expand((session) => session.attendanceList)
        .firstWhere((record) => record.ra == studentRa);
    try {
      final result = await _remote.rectify(
        classCode: course.code,
        studentId: student.studentId,
        stage: avaliacao,
        newScore: novaNota,
        justification: justificativa.trim(),
      );
      _retificacaoRequests.insert(0, result);
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível solicitar a retificação.';
    }
    notifyListeners();
  }

  // --- Métodos de Feedback Individual & Canal de Dúvidas de Atividades ---

  List<Map<String, String>> getDoubtThread(
    String assignmentId,
    String studentRa,
  ) {
    final assignment = _assignments
        .where((item) => item.id == assignmentId)
        .firstOrNull;
    if (assignment == null) return const [];
    final doubt = assignment.doubts
        .where((item) => item['ra']?.toString() == studentRa)
        .firstOrNull;
    if (doubt == null) return const [];
    final replies = doubt['replies'];
    return [
      {
        'sender': doubt['studentName']?.toString() ?? studentRa,
        'role': 'student',
        'time': doubt['createdAt']?.toString() ?? '',
        'text':
            doubt['question']?.toString() ?? doubt['body']?.toString() ?? '',
      },
      if (replies is List)
        ...replies.whereType<Map>().map(
          (reply) => {
            'sender': reply['senderName']?.toString() ?? 'Docente',
            'role': 'teacher',
            'time': reply['createdAt']?.toString() ?? '',
            'text': reply['body']?.toString() ?? '',
          },
        ),
    ];
  }

  Future<void> enviarRespostaDuvida(
    String assignmentId,
    String studentRa,
    String reply,
  ) async {
    final assignment = _assignments
        .where((item) => item.id == assignmentId)
        .firstOrNull;
    final isEnrolledStudent =
        assignment != null &&
        _sessions
            .where((session) => session.courseId == assignment.courseId)
            .expand((session) => session.attendanceList)
            .any((student) => student.ra == studentRa);
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission('manage_assignments') ||
        assignment == null ||
        !_courses.any((course) => course.id == assignment.courseId) ||
        !isEnrolledStudent ||
        reply.trim().isEmpty) {
      return;
    }
    final doubt = assignment!.doubts
        .where((item) => item['ra']?.toString() == studentRa)
        .firstOrNull;
    if (doubt == null || doubt['id'] == null) {
      remoteError = 'A dúvida não está mais disponível.';
      notifyListeners();
      return;
    }
    try {
      await _remote.replyDoubt(
        assignmentId: assignmentId,
        doubtId: doubt['id'].toString(),
        reply: reply.trim(),
      );
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível responder à dúvida.';
    }
    notifyListeners();
  }

  void salvarFeedbackIndividual({
    required String assignmentId,
    required String studentRa,
    required double nota,
    required String feedback,
    String? teacherReply,
  }) {
    final asgIndex = _assignments.indexWhere((a) => a.id == assignmentId);
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission('manage_assignments') ||
        asgIndex == -1 ||
        !_courses.any(
          (course) => course.id == _assignments[asgIndex].courseId,
        ) ||
        !nota.isFinite ||
        nota < 0 ||
        nota > 10 ||
        !_assignments[asgIndex].submissions.any(
          (submission) =>
              submission.ra == studentRa &&
              submission.status == SubmissionStatus.aguardandoCorrecao,
        )) {
      return;
    }
    final assignment = _assignments[asgIndex];
    final submission = assignment.submissions
        .where((item) => item.ra == studentRa)
        .firstOrNull;
    if (submission == null) return;
    unawaited(
      evaluateRubric(
        assignmentId: assignmentId,
        submissionId: submission.id,
        calculatedGrade: nota,
        feedback: feedback.trim(),
        evaluatedCriteria: submission.rubricEvaluations,
      ),
    );
    if (teacherReply != null && teacherReply.trim().isNotEmpty) {
      unawaited(enviarRespostaDuvida(assignmentId, studentRa, teacherReply));
    }
  }

  void notificarAlunoInfrequencia(String studentId, String studentName) {
    if (!_canManageCourse(_selectedCourseId, 'publish_course_announcements')) {
      return;
    }
    publishNotice(
      targetCourse: selectedCourse.title,
      targetAudience: 'Discente: $studentName ($studentId)',
      classification: NoticeClassification.urgencia,
      title: 'Alerta Preventivo de Infrequência - Assiduidade Regimental',
      message:
          'Prezado(a) $studentName, identificamos que seu percentual de frequência na disciplina ${selectedCourse.title} atingiu o limite crítico regimental. Por gentileza, procure a docente durante o plantão de dúvidas ou regularize eventuais faltas com atestados perante a Secretaria Geral.',
    );
  }

  // --- Agenda & Events Methods ---
  Future<void> addEvent({
    required String title,
    required String date,
    required String time,
    required EventType type,
    required String location,
  }) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_course_calendar') ||
        title.trim().isEmpty) {
      return;
    }
    try {
      await _remote.createEvent(
        title: title.trim(),
        date: date,
        time: time,
        type: type.name,
        location: location.trim(),
      );
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível salvar o evento.';
    }
    notifyListeners();
  }

  // --- Notices & Announcements Methods ---
  Future<bool> publishNotice({
    required String targetCourse,
    required String targetAudience,
    required NoticeClassification classification,
    required String title,
    required String message,
  }) async {
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission(
          'publish_course_announcements',
        ) ||
        title.trim().isEmpty ||
        message.trim().isEmpty) {
      return false;
    }
    final normalizedTargetCourse = targetCourse.trim().toLowerCase();
    final recipientCourse = _courses.where((course) {
      return course.id.toLowerCase() == normalizedTargetCourse ||
          course.code.toLowerCase() == normalizedTargetCourse ||
          course.title.toLowerCase() == normalizedTargetCourse;
    }).firstOrNull;
    if (recipientCourse == null ||
        !_courses.any((course) => course.id == recipientCourse.id)) {
      return false;
    }
    try {
      await _remote.publishNotice(
        targetCourse: recipientCourse.code,
        targetAudience: targetAudience.trim(),
        classification: classification.name,
        title: title.trim(),
        message: message.trim(),
      );
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      remoteError = 'Não foi possível publicar o comunicado.';
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  List<Map<String, dynamic>> get currentForumTopics =>
      List.unmodifiable(selectedCourse.forumTopics);

  Future<bool> createForumTopic({
    required String title,
    required String body,
    String? category,
  }) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_course_content') ||
        title.trim().isEmpty ||
        body.trim().isEmpty) {
      return false;
    }
    try {
      await _remote.createForumTopic(
        classCode: selectedCourse.code,
        title: title.trim(),
        body: body.trim(),
        category: category,
      );
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível criar o tópico.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> replyForumTopic({
    required String topicId,
    required String body,
  }) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_course_content') ||
        body.trim().isEmpty) {
      return false;
    }
    try {
      await _remote.replyForumTopic(
        classCode: selectedCourse.code,
        topicId: topicId,
        body: body.trim(),
      );
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível responder no fórum.';
    }
    notifyListeners();
    return false;
  }

  Future<void> saveSquads(List<Map<String, Object?>> squads) async {
    if (!_canManageCourse(_selectedCourseId, 'manage_course_content')) return;
    try {
      await _remote.saveSquads(classCode: selectedCourse.code, squads: squads);
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível salvar as equipes.';
    }
    notifyListeners();
  }

  Future<String?> downloadSubmission(StudentSubmission submission) async {
    try {
      final file = await _remote.downloadSubmission(submission.id);
      final encoded = file['contentBase64'];
      if (encoded is! String || encoded.isEmpty) {
        throw const ApiException('A API não retornou o arquivo da entrega.');
      }
      final bytes = base64Decode(encoded);
      final saved = await PlatformFileHelper.saveOrDownloadFile(
        fileName:
            file['fileName']?.toString() ??
            submission.fileName ??
            'entrega-${submission.id}.bin',
        bytes: bytes,
        mimeType: file['mimeType']?.toString() ?? 'application/octet-stream',
      );
      if (saved == null) {
        throw const ApiException('Não foi possível salvar o arquivo.');
      }
      return saved;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível baixar a submissão.';
    }
    notifyListeners();
    return null;
  }

  Future<Map<String, dynamic>?> getNoticeReads(String id) async {
    try {
      return await _remote.noticeReads(id);
    } on ApiException catch (error) {
      remoteError = error.message;
    }
    notifyListeners();
    return null;
  }

  // --- Settings & Profile Methods ---
  Future<bool> updateProfile({
    String? socialName,
    String? personalEmail,
  }) async {
    if (!_hasActiveTeacherAccess) return false;
    try {
      await _profileRemote.updateProfile({
        if (socialName != null) 'socialName': socialName.trim(),
        if (personalEmail != null) 'personalEmail': personalEmail.trim(),
      });
      await _profileRemote.me();
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível atualizar o perfil.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _profileRemote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    }
    notifyListeners();
    return false;
  }

  Future<List<String>> backupCodes() => _profileRemote.backupCodes();

  Future<List<Map<String, dynamic>>> securitySessions() =>
      _profileRemote.sessions();

  Future<List<Map<String, dynamic>>> securityLogs() =>
      _profileRemote.securityLogs();

  Future<Map<String, dynamic>> exportPersonalData() =>
      _profileRemote.lgpdExport();

  Future<void> toggleTwoFactor({required String password}) async {
    if (!_hasActiveTeacherAccess) return;
    try {
      await _profileRemote.toggleTwoFactor(
        password: password,
        enabled: !_profile.twoFactorEnabled,
      );
    } on ApiException catch (error) {
      remoteError = error.message;
    }
    notifyListeners();
  }

  Future<void> disconnectSession(String sessionId) async {
    if (!_hasActiveTeacherAccess) return;
    try {
      await _profileRemote.revokeSession(sessionId);
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    }
    notifyListeners();
  }

  /// Ends all sessions except the device currently in use.
  Future<void> disconnectOtherSessions() async {
    if (!_hasActiveTeacherAccess) return;
    try {
      await _profileRemote.logoutOthers();
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    }
    notifyListeners();
  }
}
