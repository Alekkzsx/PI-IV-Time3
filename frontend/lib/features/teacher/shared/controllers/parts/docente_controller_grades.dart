// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
// Mixin de domínio para Notas, Caderneta PPC, Chancela Digital e Retificação

part of '../docente_controller.dart';

mixin _DocenteGradesMixin on _DocenteControllerBase {
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
