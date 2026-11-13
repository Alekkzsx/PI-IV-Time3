// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
// Modularizado e particionado com Domain Mixins

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import '../../../../core/network/auth_profile_remote_data_source.dart';
import '../../../../core/utils/platform_file_helper.dart';
import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/state/app_user_session.dart';
import '../../../../core/state/academic_bridge_service.dart';
import '../data/teacher_remote_data_source.dart';
import '../data/docente_repository_impl.dart';
import '../domain/models/academic_event.dart';
import '../domain/models/academic_notice.dart';
import '../domain/models/assignment_model.dart';
import '../domain/models/attendance_record.dart';
import '../domain/models/docente_course.dart';
import '../domain/models/docente_profile.dart';
import '../domain/models/grade_record.dart';
import '../domain/models/rubric_model.dart';
import '../domain/models/teacher_dashboard_overview.dart';
import '../domain/models/teacher_protocol.dart';
import '../domain/repositories/docente_repository.dart';

part 'parts/docente_controller_courses.dart';
part 'parts/docente_controller_diary.dart';
part 'parts/docente_controller_assignments.dart';
part 'parts/docente_controller_grades.dart';
part 'parts/docente_controller_agenda_notices.dart';
part 'parts/docente_controller_settings.dart';

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

/// Classe base abstrata que gerencia o estado reativo compartilhado e o ciclo de vida
/// remoto do Portal Docente.
abstract class _DocenteControllerBase extends ChangeNotifier {
  final TeacherRemoteDataSource _remote;
  final AuthProfileRemoteDataSource _profileRemote;
  final IDocenteRepository _repository;

  bool isLoadingRemote = false;
  String? remoteError;

  DocenteNavTab _activeTab = DocenteNavTab.painel;
  bool _isSidebarCollapsed = false;

  List<DocenteCourse> _courses = [];
  String _selectedCourseId = '';

  ClassSession _currentSession = ClassSession.empty;
  List<ClassSession> _sessions = [];
  List<AssignmentItem> _assignments = [];
  String _selectedAssignmentId = '';

  List<StudentGrade> _gradebook = [];
  List<AcademicEvent> _events = [];
  List<AcademicNotice> _notices = [];
  List<TeacherProtocol> _protocols = [];
  DocenteProfile _profile = DocenteProfile.empty;
  TeacherDashboardOverview _dashboard = TeacherDashboardOverview.empty;
  String _ownerIdentity = '';

  String _settingsSubtab = 'perfil';

  final Map<String, bool> _pautaHomologada = {};
  final Map<String, String> _pautaChancelaCodes = {};
  final List<Map<String, dynamic>> _retificacaoRequests = [];
  final Map<String, List<Map<String, dynamic>>> _forumTopicsByCourse = {};

  _DocenteControllerBase({
    TeacherRemoteDataSource? remoteDataSource,
    AuthProfileRemoteDataSource? profileRemoteDataSource,
    IDocenteRepository? repository,
  })  : _remote = remoteDataSource ?? TeacherRemoteDataSource(),
        _profileRemote =
            profileRemoteDataSource ?? AuthProfileRemoteDataSource(),
        _repository = repository ??
            DocenteRepositoryImpl(
              remoteDataSource: remoteDataSource,
              profileRemoteDataSource: profileRemoteDataSource,
            );

  static const ClassSession _emptySession = ClassSession.empty;
  static const DocenteProfile _emptyProfile = DocenteProfile.empty;
  static const DocenteCourse _emptyCourse = DocenteCourse.empty;
  static const AssignmentItem _emptyAssignment = AssignmentItem.empty;

  // Getters Públicos Reativos
  IDocenteRepository get repository => _repository;
  DocenteNavTab get activeTab => _activeTab;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  List<DocenteCourse> get courses => List.unmodifiable(_courses);
  String get selectedCourseId => _selectedCourseId;
  ClassSession get currentSession => _currentSession;
  List<ClassSession> get sessions => List.unmodifiable(_sessions);
  List<AssignmentItem> get assignments => List.unmodifiable(_assignments);
  String get selectedAssignmentId => _selectedAssignmentId;
  List<AcademicEvent> get events => List.unmodifiable(_events);
  List<AcademicNotice> get notices => List.unmodifiable(_notices);
  List<TeacherProtocol> get protocols => List.unmodifiable(_protocols);
  DocenteProfile get profile => _profile;
  TeacherDashboardOverview get dashboard => _dashboard;
  String get settingsSubtab => _settingsSubtab;

  DocenteCourse get selectedCourse => _courses.firstWhere(
        (course) => course.id == _selectedCourseId,
        orElse: () => _emptyCourse,
      );

  AssignmentItem get selectedAssignment => _assignments.firstWhere(
        (assignment) => assignment.id == _selectedAssignmentId,
        orElse: () => _emptyAssignment,
      );

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

  List<StudentGrade> get gradebook => List.unmodifiable(
        _gradebook.where((g) => g.courseId == _selectedCourseId).toList(),
      );

  bool isPautaHomologada(String courseId) =>
      _pautaHomologada[courseId] ?? false;

  String? getChancelaCode(String courseId) => _pautaChancelaCodes[courseId];

  List<Map<String, dynamic>> get retificacaoRequests =>
      List.unmodifiable(_retificacaoRequests);

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

  // Ciclo de Vida e Bootstrap
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
      _dashboard = snapshot.dashboard;
      _courses = snapshot.courses;
      _selectedCourseId = _courses.isEmpty ? '' : _courses.first.id;
      _sessions = snapshot.sessions;
      _assignments = snapshot.assignments;
      _gradebook = snapshot.grades;
      _events = snapshot.events;
      _notices = snapshot.notices;
      _protocols = snapshot.protocols;
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
      _selectedAssignmentId =
          _assignments.isEmpty ? '' : _assignments.first.id;
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
    _protocols = [];
    _profile = _emptyProfile;
    _dashboard = TeacherDashboardOverview.empty;
    _currentSession = _emptySession;
    _selectedCourseId = '';
    _selectedAssignmentId = '';
    _pautaHomologada.clear();
    _pautaChancelaCodes.clear();
    _forumTopicsByCourse.clear();
  }

  Future<bool> decideProtocol({
    required String protocolId,
    required TeacherProtocolStatus decision,
    String? officialResponse,
  }) async {
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty || !_hasActiveTeacherAccess) {
      return false;
    }
    try {
      await _remote.decideProtocol(
        protocolId: protocolId,
        status: decision.name,
        officialResponse: officialResponse,
      );
      await loadRemote(force: true);
      return true;
    } catch (_) {
      return false;
    }
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
}

/// Reactive controller managing all frontend state for the Docente Portal.
class DocenteController extends _DocenteControllerBase
    with
        _DocenteCoursesMixin,
        _DocenteDiaryMixin,
        _DocenteAssignmentsMixin,
        _DocenteGradesMixin,
        _DocenteAgendaNoticesMixin,
        _DocenteSettingsMixin {
  DocenteController({
    super.remoteDataSource,
    super.profileRemoteDataSource,
    super.repository,
  });
}
