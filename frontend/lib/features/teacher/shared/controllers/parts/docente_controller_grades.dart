// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
// Mixin de domínio para Notas, Caderneta PPC, Chancela Digital e Retificação

part of '../docente_controller.dart';

mixin _DocenteGradesMixin on _DocenteControllerBase {
  String _gradeDraftKey(String courseId, String studentId) =>
      '$courseId::$studentId';

  double? _normalizeGrade(double? value) {
    if (value == null || !value.isFinite) return null;
    return double.parse(value.clamp(0.0, 10.0).toStringAsFixed(1));
  }

  int get pendingGradeChangesCount {
    final prefix = '$_selectedCourseId::';
    return _pendingGradeDrafts.keys.where((k) => k.startsWith(prefix)).length;
  }

  bool get hasPendingGradeChanges => pendingGradeChangesCount > 0;

  bool isGradeFieldDirty(String studentId, String field) {
    final draft = _pendingGradeDrafts[_gradeDraftKey(_selectedCourseId, studentId)];
    if (draft == null) return false;
    final persisted = _gradebook.firstWhere(
      (g) => g.courseId == _selectedCourseId && g.studentId == studentId,
      orElse: () => draft,
    );
    return switch (field) {
      'assignments' => draft.assignmentsScore != persisted.assignmentsScore,
      'p1' => draft.p1Score != persisted.p1Score,
      'projects' => draft.projectsScore != persisted.projectsScore,
      'p2' => draft.p2Score != persisted.p2Score,
      _ => false,
    };
  }

  void setDraftStudentGrade(
    String studentId, {
    double? assignments,
    double? p1,
    double? projects,
    double? p2,
  }) {
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission('edit_grades') ||
        selectedCourse.gradeLocked) {
      return;
    }
    final persisted = _gradebook
        .where((g) => g.courseId == _selectedCourseId && g.studentId == studentId)
        .firstOrNull;
    if (persisted == null) return;

    final key = _gradeDraftKey(_selectedCourseId, studentId);
    final current = _pendingGradeDrafts[key] ?? persisted;
    final nextAssignments = _normalizeGrade(assignments) ?? current.assignmentsScore;
    final nextP1 = _normalizeGrade(p1) ?? current.p1Score;
    final nextProjects = _normalizeGrade(projects) ?? current.projectsScore;
    final nextP2 = _normalizeGrade(p2) ?? current.p2Score;

    final matchesPersisted =
        nextAssignments == persisted.assignmentsScore &&
        nextP1 == persisted.p1Score &&
        nextProjects == persisted.projectsScore &&
        nextP2 == persisted.p2Score;

    if (matchesPersisted) {
      _pendingGradeDrafts.remove(key);
    } else {
      _pendingGradeDrafts[key] = current.copyWith(
        assignmentsScore: nextAssignments,
        p1Score: nextP1,
        projectsScore: nextProjects,
        p2Score: nextP2,
        hasGrades: true,
      );
    }
    remoteError = null;
    notifyListeners();
  }

  void discardPendingGradeChanges() {
    final prefix = '$_selectedCourseId::';
    _pendingGradeDrafts.removeWhere((k, _) => k.startsWith(prefix));
    remoteError = null;
    notifyListeners();
  }

  Future<bool> savePendingGradeChanges() async {
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission('edit_grades') ||
        isSavingGrades) {
      return false;
    }
    final prefix = '$_selectedCourseId::';
    final entries = _pendingGradeDrafts.entries
        .where((e) => e.key.startsWith(prefix))
        .toList();
    if (entries.isEmpty) return true;

    final batchPayload = <Map<String, Object?>>[];
    for (final entry in entries) {
      final draft = entry.value;
      final persisted = _gradebook
          .where((g) => g.courseId == _selectedCourseId && g.studentId == draft.studentId)
          .firstOrNull;
      if (persisted == null) continue;
      final item = <String, Object?>{'studentId': draft.studentId};
      if (draft.assignmentsScore != persisted.assignmentsScore) {
        item['assignmentsScore'] = draft.assignmentsScore;
      }
      if (draft.p1Score != persisted.p1Score) {
        item['p1Score'] = draft.p1Score;
      }
      if (draft.projectsScore != persisted.projectsScore) {
        item['projectsScore'] = draft.projectsScore;
      }
      if (draft.p2Score != persisted.p2Score) {
        item['p2Score'] = draft.p2Score;
      }
      if (item.length > 1) batchPayload.add(item);
    }
    if (batchPayload.isEmpty) {
      discardPendingGradeChanges();
      return true;
    }

    isSavingGrades = true;
    remoteError = null;
    notifyListeners();
    try {
      await _remote.updateGradesBatch(
        classCode: selectedCourse.code,
        grades: batchPayload,
      );
      _gradebook = _gradebook.map((item) {
        if (item.courseId != _selectedCourseId) return item;
        return _pendingGradeDrafts[_gradeDraftKey(_selectedCourseId, item.studentId)] ??
            item;
      }).toList();
      _pendingGradeDrafts.removeWhere((k, _) => k.startsWith(prefix));
      _lastSyncedAt = DateTime.now();
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
      return false;
    } catch (_) {
      remoteError = 'Não foi possível salvar as notas em lote.';
      return false;
    } finally {
      isSavingGrades = false;
      notifyListeners();
    }
  }

  Future<bool> updateStudentGrade(
    String studentId, {
    double? assignments,
    double? p1,
    double? projects,
    double? p2,
  }) async {
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission('edit_grades') ||
        !gradebook.any((grade) => grade.studentId == studentId)) {
      return false;
    }

    final normalizedAssignments = _normalizeGrade(assignments);
    final normalizedP1 = _normalizeGrade(p1);
    final normalizedProjects = _normalizeGrade(projects);
    final normalizedP2 = _normalizeGrade(p2);
    remoteError = null;
    try {
      await _remote.updateGrade(
        classCode: selectedCourse.code,
        studentId: studentId,
        assignmentsScore: normalizedAssignments,
        p1Score: normalizedP1,
        projectsScore: normalizedProjects,
        p2Score: normalizedP2,
      );
      _gradebook = _gradebook.map((item) {
        if (item.courseId != _selectedCourseId || item.studentId != studentId) {
          return item;
        }
        return item.copyWith(
          assignmentsScore: normalizedAssignments ?? item.assignmentsScore,
          p1Score: normalizedP1 ?? item.p1Score,
          projectsScore: normalizedProjects ?? item.projectsScore,
          p2Score: normalizedP2 ?? item.p2Score,
          hasGrades: true,
        );
      }).toList();
      _pendingGradeDrafts.remove(_gradeDraftKey(_selectedCourseId, studentId));
      _lastSyncedAt = DateTime.now();
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      remoteError = 'Não foi possível salvar a nota.';
      notifyListeners();
      return false;
    }
  }

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
}
