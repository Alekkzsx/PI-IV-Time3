// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
// Mixin de domínio para Atividades, Rubricas, Entregas e Dúvidas

part of '../docente_controller.dart';

mixin _DocenteAssignmentsMixin on _DocenteControllerBase {
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
    final doubt = assignment.doubts
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
}
