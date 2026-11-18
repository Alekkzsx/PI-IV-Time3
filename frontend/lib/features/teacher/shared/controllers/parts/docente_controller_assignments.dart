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
    DateTime? dueDate,
    String? dueHour,
    required String dueDateFormatted,
    required String modality,
    required bool allowLateWithPenalty,
    String? moduleTag,
    String? activityType,
    String? allowedFormats,
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
          if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
          if (dueHour != null && dueHour.trim().isNotEmpty)
            'dueHour': dueHour.trim(),
          'dueDateFormatted': dueDateFormatted,
          'modality': modality,
          'allowLateWithPenalty': allowLateWithPenalty,
          if (moduleTag != null && moduleTag.trim().isNotEmpty)
            'moduleTag': moduleTag.trim(),
          if (activityType != null && activityType.trim().isNotEmpty)
            'activityType': activityType.trim(),
          if (allowedFormats != null && allowedFormats.trim().isNotEmpty)
            'allowedFormats': allowedFormats.trim(),
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

  Future<bool> deleteAssignment(String assignmentId) async {
    final target = _assignments.where((a) => a.id == assignmentId).firstOrNull;
    if (target == null ||
        !_canManageCourse(target.courseId, 'manage_assignments')) {
      return false;
    }
    try {
      await _remote.deleteAssignment(assignmentId);
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível remover a atividade.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> evaluateRubric({
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
      return false;
    }

    final assignment = _assignments[asgIndex];
    final submission = assignment.submissions
        .where((item) => item.id == submissionId)
        .firstOrNull;
    if (!calculatedGrade.isFinite ||
        calculatedGrade < 0 ||
        calculatedGrade > 10 ||
        submission == null) {
      return false;
    }
    final normalizedGrade = double.parse(calculatedGrade.toStringAsFixed(1));
    final trimmedFeedback = feedback.trim();
    remoteError = null;
    try {
      final result = await _remote.evaluateSubmission(
        assignmentId: assignmentId,
        studentId: submission.studentId,
        calculatedGrade: normalizedGrade,
        feedback: trimmedFeedback,
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

      final updatedSubmissions = assignment.submissions.map((item) {
        if (item.id != submissionId && item.studentId != submission.studentId) {
          return item;
        }
        return item.copyWith(
          grade: normalizedGrade,
          status: SubmissionStatus.corrigido,
          teacherFeedback: trimmedFeedback,
          rubricEvaluations: List<RubricCriterion>.from(evaluatedCriteria),
        );
      }).toList();
      final updatedAssignments = List<AssignmentItem>.from(_assignments);
      updatedAssignments[asgIndex] = assignment.copyWith(
        submissions: updatedSubmissions,
      );
      _assignments = updatedAssignments;

      final consolidated = (result['consolidatedStageGrade'] as num?)?.toDouble();
      if (consolidated != null) {
        final isN2 = assignment.stage.toUpperCase() == 'N2';
        _gradebook = _gradebook.map((gradeItem) {
          if (gradeItem.courseId != assignment.courseId ||
              gradeItem.studentId != submission.studentId) {
            return gradeItem;
          }
          return gradeItem.copyWith(
            assignmentsScore: isN2 ? gradeItem.assignmentsScore : consolidated,
            projectsScore: isN2 ? consolidated : gradeItem.projectsScore,
            hasGrades: true,
          );
        }).toList();
      }
      _lastSyncedAt = DateTime.now();
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      remoteError = 'Não foi possível avaliar a entrega.';
      notifyListeners();
      return false;
    }
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

  Future<bool> replyDoubtById({
    required String assignmentId,
    required String doubtId,
    required String reply,
  }) async {
    final assignment = _assignments
        .where((item) => item.id == assignmentId)
        .firstOrNull;
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission('manage_assignments') ||
        assignment == null ||
        !_courses.any((course) => course.id == assignment.courseId) ||
        reply.trim().isEmpty) {
      return false;
    }
    try {
      await _remote.replyDoubt(
        assignmentId: assignmentId,
        doubtId: doubtId,
        reply: reply.trim(),
      );
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível responder à dúvida.';
    }
    notifyListeners();
    return false;
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
        .where(
          (item) =>
              (item['ra'] ?? item['studentRa'])?.toString() == studentRa,
        )
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

  Future<bool> salvarFeedbackIndividual({
    required String assignmentId,
    required String studentRa,
    required double nota,
    required String feedback,
    String? teacherReply,
  }) async {
    final asgIndex = _assignments.indexWhere((a) => a.id == assignmentId);
    if (!_hasActiveTeacherAccess ||
        !AppUserSession.instance.hasPermission('manage_assignments') ||
        asgIndex == -1 ||
        !_courses.any(
          (course) => course.id == _assignments[asgIndex].courseId,
        ) ||
        !nota.isFinite ||
        nota < 0 ||
        nota > 10) {
      return false;
    }
    final assignment = _assignments[asgIndex];
    final submission = assignment.submissions
        .where((item) => item.ra == studentRa)
        .firstOrNull;
    if (submission == null) return false;
    final ok = await evaluateRubric(
      assignmentId: assignmentId,
      submissionId: submission.id,
      calculatedGrade: nota,
      feedback: feedback.trim(),
      evaluatedCriteria: submission.rubricEvaluations,
    );
    if (ok && teacherReply != null && teacherReply.trim().isNotEmpty) {
      unawaited(enviarRespostaDuvida(assignmentId, studentRa, teacherReply));
    }
    return ok;
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
