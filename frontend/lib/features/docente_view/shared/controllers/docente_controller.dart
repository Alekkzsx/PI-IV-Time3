// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/foundation.dart';
import '../data/docente_mock_data.dart';
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
  DocenteNavTab _activeTab = DocenteNavTab.painel;
  bool _isSidebarCollapsed = false;

  List<DocenteCourse> _courses = [];
  String _selectedCourseId = 'course-aps2';

  ClassSession _currentSession = DocenteMockData.initialClassSession;
  List<ClassSession> _sessions = [];
  List<AssignmentItem> _assignments = [];
  String _selectedAssignmentId = 'asg-1';

  List<StudentGrade> _gradebook = [];
  List<AcademicEvent> _events = [];
  List<AcademicNotice> _notices = [];
  DocenteProfile _profile = DocenteMockData.initialProfile;

  String _settingsSubtab = 'perfil'; // 'perfil', 'seguranca', 'notificacoes', 'preferencias', 'privacidade'

  DocenteController() {
    _courses = List.from(DocenteMockData.initialCourses);
    _assignments = List.from(DocenteMockData.initialAssignments);
    _gradebook = List.from(DocenteMockData.initialGradebook);
    _events = List.from(DocenteMockData.initialEvents);
    _notices = List.from(DocenteMockData.initialNotices);
    _sessions = List.from(DocenteMockData.defaultSessions);
    _currentSession = _sessions.firstWhere(
      (s) => s.courseId == _selectedCourseId && s.sessionNumber == 27,
      orElse: () => _sessions.firstWhere(
        (s) => s.courseId == _selectedCourseId,
        orElse: () => DocenteMockData.initialClassSession,
      ),
    );
  }

  // --- Getters ---
  DocenteNavTab get activeTab => _activeTab;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  List<DocenteCourse> get courses => List.unmodifiable(_courses);
  String get selectedCourseId => _selectedCourseId;
  ClassSession get currentSession => _currentSession;
  List<ClassSession> get sessions => List.unmodifiable(_sessions);
  List<ClassSession> get sessionsForSelectedCourse =>
      _sessions.where((s) => s.courseId == _selectedCourseId).toList();
  List<AssignmentItem> get assignments => List.unmodifiable(_assignments);
  String get selectedAssignmentId => _selectedAssignmentId;
  List<StudentGrade> get gradebook => List.unmodifiable(_gradebook);
  List<AcademicEvent> get events => List.unmodifiable(_events);
  List<AcademicNotice> get notices => List.unmodifiable(_notices);
  DocenteProfile get profile => _profile;
  String get settingsSubtab => _settingsSubtab;

  DocenteCourse get selectedCourse =>
      _courses.firstWhere((c) => c.id == _selectedCourseId, orElse: () => _courses.first);

  AssignmentItem get selectedAssignment =>
      _assignments.firstWhere((a) => a.id == _selectedAssignmentId, orElse: () => _assignments.first);

  // --- Navigation Methods ---
  void navigateToTab(DocenteNavTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void toggleSidebarCollapse() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void selectCourse(String courseId) {
    _selectedCourseId = courseId;
    final courseSessions = _sessions.where((s) => s.courseId == courseId).toList();
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
  void advanceSyllabusClasses(String courseId, String unitId) {
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return;

    final course = _courses[courseIndex];
    final updatedUnits = course.syllabusUnits.map((u) {
      if (u.id == unitId) {
        final newClasses = u.completedClasses >= u.totalClasses
            ? (u.completedClasses - 2).clamp(0, u.totalClasses)
            : (u.completedClasses + 2).clamp(0, u.totalClasses);
        return u.copyWith(completedClasses: newClasses);
      }
      return u;
    }).toList();

    _courses[courseIndex] = course.copyWith(syllabusUnits: updatedUnits);
    notifyListeners();
  }

  void publishMaterial(String courseId, String title) {
    if (title.trim().isEmpty) return;
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return;

    final newMaterial = CourseMaterial(
      id: 'mat-${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      title: title.trim(),
      date: 'Hoje, 20/09/2026',
      size: '1.5 MB',
      type: 'PDF',
    );

    final updatedMaterials = [newMaterial, ..._courses[courseIndex].materials];
    _courses[courseIndex] = _courses[courseIndex].copyWith(materials: updatedMaterials);
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
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    const weekdays = [
      'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
      'Sexta-feira', 'Sábado', 'Domingo'
    ];
    final dayStr = date.day.toString().padLeft(2, '0');
    final monthStr = months[date.month - 1];
    final weekdayStr = weekdays[date.weekday - 1];
    return '$dayStr de $monthStr de ${date.year} ($weekdayStr)';
  }

  void selectSession(String sessionId) {
    final found = _sessions.firstWhere((s) => s.id == sessionId, orElse: () => _currentSession);
    _currentSession = found;
    notifyListeners();
  }

  void selectSessionByDate(DateTime pickedDate) {
    final existing = _sessions.firstWhere(
      (s) => s.courseId == _selectedCourseId &&
             s.sessionDate.year == pickedDate.year &&
             s.sessionDate.month == pickedDate.month &&
             s.sessionDate.day == pickedDate.day,
      orElse: () => _createSessionForDate(pickedDate),
    );
    _currentSession = existing;
    notifyListeners();
  }

  ClassSession _createSessionForDate(DateTime pickedDate) {
    final list = sessionsForSelectedCourse;
    final nextNumber = (list.map((s) => s.sessionNumber).fold<int>(0, (max, n) => n > max ? n : max)) + 1;
    final formatted = formatSessionDate(pickedDate);
    final newSession = ClassSession(
      id: 'sess-${pickedDate.millisecondsSinceEpoch}',
      courseId: _selectedCourseId,
      sessionNumber: nextNumber,
      hours: 2,
      date: pickedDate,
      dateFormatted: formatted,
      contentProgram: 'Planejamento de aula para ${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}',
      methodology: 'Aula expositiva dialogada e atividades práticas.',
      location: selectedCourse.room,
      isHomologated: false,
      attendanceList: _currentSession.attendanceList.map((st) => st.copyWith(status: AttendanceStatus.presente)).toList(),
    );
    _sessions.add(newSession);
    return newSession;
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

  void updateSessionContent(String content, String methodology, [String? location]) {
    _currentSession = _currentSession.copyWith(
      contentProgram: content,
      methodology: methodology,
      location: location ?? _currentSession.location,
    );
    _syncSessionInList();
    notifyListeners();
  }

  void markAllPresent() {
    for (final student in _currentSession.attendanceList) {
      if (student.status != AttendanceStatus.presente) {
        toggleAttendance(student.studentId, AttendanceStatus.presente);
      }
    }
  }

  void toggleAttendance(String studentId, AttendanceStatus newStatus) {
    final updatedAttendance = _currentSession.attendanceList.map((record) {
      if (record.studentId == studentId) {
        final wasAbsent = record.status == AttendanceStatus.ausente;
        final willBeAbsent = newStatus == AttendanceStatus.ausente;

        int delta = 0;
        if (!wasAbsent && willBeAbsent) delta = 1;
        if (wasAbsent && !willBeAbsent) delta = -1;

        final newAbsences = (record.accumulatedAbsences + delta).clamp(0, 40);
        const totalClassesHeld = 38;
        final newRate = double.parse(
          (((totalClassesHeld - newAbsences) / totalClassesHeld) * 100).toStringAsFixed(1),
        );

        AttendanceRiskLevel risk = AttendanceRiskLevel.regular;
        if (newRate < 75.0) {
          risk = AttendanceRiskLevel.critico;
        } else if (newRate < 80.0) {
          risk = AttendanceRiskLevel.atencao;
        }

        return record.copyWith(
          status: newStatus,
          accumulatedAbsences: newAbsences,
          attendanceRate: newRate,
          riskLevel: risk,
        );
      }
      return record;
    }).toList();

    _currentSession = _currentSession.copyWith(
      attendanceList: updatedAttendance,
      isHomologated: false,
    );
    _syncSessionInList();
    notifyListeners();
  }

  void homologateSession() {
    _currentSession = _currentSession.copyWith(isHomologated: true);
    _syncSessionInList();
    notifyListeners();
  }

  // --- Assignments & Rubric Methods ---
  void selectAssignment(String assignmentId) {
    _selectedAssignmentId = assignmentId;
    notifyListeners();
  }

  void createAssignment({
    required String courseId,
    required String courseCode,
    required String title,
    required double weight,
    required String stage,
    required String dueDateFormatted,
    required String modality,
    required bool allowLateWithPenalty,
    required List<RubricCriterion> rubricCriteria,
  }) {
    final newAssignment = AssignmentItem(
      id: 'asg-${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      courseCode: courseCode,
      title: title,
      weight: weight,
      stage: stage,
      dueDateFormatted: dueDateFormatted,
      isUrgent: false,
      modality: modality,
      allowLateWithPenalty: allowLateWithPenalty,
      rubricCriteria: rubricCriteria,
      submissions: _currentSession.attendanceList.map((st) {
        return StudentSubmission(
          id: 'sub-${st.studentId}',
          studentId: st.studentId,
          ra: st.ra,
          studentName: st.name,
          fileName: null,
          submittedAtFormatted: null,
          fileSize: null,
          grade: null,
          status: SubmissionStatus.naoEntregue,
          rubricEvaluations: rubricCriteria,
        );
      }).toList(),
    );

    _assignments = [newAssignment, ..._assignments];
    _selectedAssignmentId = newAssignment.id;
    notifyListeners();
  }

  void evaluateRubric({
    required String assignmentId,
    required String submissionId,
    required double calculatedGrade,
    required String feedback,
    required List<RubricCriterion> evaluatedCriteria,
  }) {
    final asgIndex = _assignments.indexWhere((a) => a.id == assignmentId);
    if (asgIndex == -1) return;

    final assignment = _assignments[asgIndex];
    final updatedSubmissions = assignment.submissions.map((sub) {
      if (sub.id == submissionId) {
        return sub.copyWith(
          grade: calculatedGrade,
          status: SubmissionStatus.corrigido,
          teacherFeedback: feedback,
          rubricEvaluations: evaluatedCriteria,
        );
      }
      return sub;
    }).toList();

    _assignments[asgIndex] = assignment.copyWith(submissions: updatedSubmissions);
    notifyListeners();
  }

  // --- Gradebook Methods ---
  void updateStudentGrade(
    String studentId, {
    double? assignments,
    double? p1,
    double? projects,
    double? p2,
  }) {
    _gradebook = _gradebook.map((grade) {
      if (grade.studentId == studentId) {
        return grade.copyWith(
          assignmentsScore: assignments ?? grade.assignmentsScore,
          p1Score: p1 ?? grade.p1Score,
          projectsScore: projects ?? grade.projectsScore,
          p2Score: p2 ?? grade.p2Score,
        );
      }
      return grade;
    }).toList();
    notifyListeners();
  }

  // --- Agenda & Events Methods ---
  void addEvent({
    required String title,
    required String date,
    required String time,
    required EventType type,
    required String location,
  }) {
    if (title.trim().isEmpty) return;
    final newEvent = AcademicEvent(
      id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      date: date,
      time: time,
      type: type,
      location: location.trim(),
      isSynced: true,
    );

    _events = [newEvent, ..._events];
    notifyListeners();
  }

  // --- Notices & Announcements Methods ---
  void publishNotice({
    required String targetCourse,
    required String targetAudience,
    required NoticeClassification classification,
    required String title,
    required String message,
  }) {
    if (title.trim().isEmpty || message.trim().isEmpty) return;
    final newNotice = AcademicNotice(
      id: 'not-${DateTime.now().millisecondsSinceEpoch}',
      author: 'Você (Profa. Helena Bittencourt)',
      targetCourse: targetCourse,
      targetAudience: targetAudience,
      classification: classification,
      publishedAt: 'Hoje, ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      title: title.trim(),
      message: message.trim(),
      readCount: 0,
      totalRecipients: selectedCourse.enrolledCount,
      isFromSecretaria: false,
    );

    _notices = [newNotice, ..._notices];
    notifyListeners();
  }

  // --- Settings & Profile Methods ---
  void updateProfile({
    String? socialName,
    String? personalEmail,
  }) {
    _profile = _profile.copyWith(
      socialName: socialName ?? _profile.socialName,
      personalEmail: personalEmail ?? _profile.personalEmail,
    );
    notifyListeners();
  }

  void toggleTwoFactor() {
    _profile = _profile.copyWith(twoFactorEnabled: !_profile.twoFactorEnabled);
    notifyListeners();
  }

  void disconnectSession(String sessionId) {
    final updatedSessions = _profile.activeSessions.where((s) => s.id != sessionId).toList();
    _profile = _profile.copyWith(activeSessions: updatedSessions);
    notifyListeners();
  }
}

