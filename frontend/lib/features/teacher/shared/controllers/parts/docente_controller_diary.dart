// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
// Mixin de domínio para Sessões MEC, Presença, Diário e Chamada

part of '../docente_controller.dart';

mixin _DocenteDiaryMixin on _DocenteControllerBase {
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
      if (_courses.any((course) => course.id == courseId)) {
        _selectedCourseId = courseId;
      }
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
}
