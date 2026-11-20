// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Implementação formal de IDocenteRepository

import '../../../../core/network/auth_profile_remote_data_source.dart';
import '../domain/models/academic_event.dart';
import '../domain/models/academic_notice.dart';
import '../domain/models/assignment_model.dart';
import '../domain/models/attendance_record.dart';
import '../domain/models/docente_course.dart';
import '../domain/models/docente_profile.dart';
import '../domain/models/grade_record.dart';
import '../domain/repositories/docente_repository.dart';
import 'teacher_remote_data_source.dart';

class DocenteRepositoryImpl implements IDocenteRepository {
  final TeacherRemoteDataSource _remote;
  final AuthProfileRemoteDataSource _profileRemote;

  DocenteRepositoryImpl({
    TeacherRemoteDataSource? remoteDataSource,
    AuthProfileRemoteDataSource? profileRemoteDataSource,
  })  : _remote = remoteDataSource ?? TeacherRemoteDataSource(),
        _profileRemote =
            profileRemoteDataSource ?? AuthProfileRemoteDataSource();

  @override
  Future<TeacherDashboardSnapshot> getBootstrap() => _remote.getBootstrap();

  @override
  Future<List<DocenteCourse>> getCourses() async {
    final bootstrap = await _remote.getBootstrap();
    return bootstrap.courses;
  }

  @override
  Future<DocenteProfile> getProfile() async {
    final bootstrap = await _remote.getBootstrap();
    return bootstrap.profile;
  }

  @override
  Future<List<AcademicNotice>> getNotices() async {
    final bootstrap = await _remote.getBootstrap();
    return bootstrap.notices;
  }

  @override
  Future<List<AcademicEvent>> getEvents() async {
    final bootstrap = await _remote.getBootstrap();
    return bootstrap.events;
  }

  @override
  Future<List<AssignmentItem>> getAssignments() async {
    final bootstrap = await _remote.getBootstrap();
    return bootstrap.assignments;
  }

  @override
  Future<List<StudentGrade>> getGrades(String courseId) async {
    final bootstrap = await _remote.getBootstrap();
    return bootstrap.grades
        .where((grade) => grade.courseId == courseId)
        .toList();
  }

  @override
  Future<ClassSession> getCurrentSession() async {
    final bootstrap = await _remote.getBootstrap();
    return bootstrap.sessions.isNotEmpty
        ? bootstrap.sessions.first
        : ClassSession.empty;
  }

  @override
  Future<Map<String, dynamic>> createOrSelectSession({
    required String classCode,
    required DateTime date,
    int hours = 2,
  }) =>
      _remote.createOrSelectSession(
        classCode: classCode,
        date: date,
        hours: hours,
      );

  @override
  Future<void> updateSessionAttendance({
    required String sessionId,
    required String contentProgram,
    required String methodology,
    required String location,
    required bool isHomologated,
    required List<Map<String, Object?>> attendanceList,
  }) =>
      _remote.updateSessionAttendance(
        sessionId: sessionId,
        contentProgram: contentProgram,
        methodology: methodology,
        location: location,
        isHomologated: isHomologated,
        attendanceList: attendanceList,
      );

  @override
  Future<void> advanceSyllabus(String classCode, String unitId) =>
      _remote.advanceSyllabus(classCode, unitId);

  @override
  Future<Map<String, dynamic>> publishMaterial({
    required String classCode,
    required String title,
    required String fileName,
    required String mimeType,
    required String size,
    required String contentBase64,
    String? unitAssociated,
  }) =>
      _remote.publishMaterial(
        classCode: classCode,
        title: title,
        fileName: fileName,
        mimeType: mimeType,
        size: size,
        contentBase64: contentBase64,
        unitAssociated: unitAssociated,
      );

  @override
  Future<Map<String, dynamic>> createAssignment({
    required String classCode,
    required Map<String, Object?> assignment,
  }) =>
      _remote.createAssignment(
        classCode: classCode,
        assignment: assignment,
      );

  @override
  Future<Map<String, dynamic>> evaluateSubmission({
    required String assignmentId,
    required String studentId,
    required double calculatedGrade,
    required String feedback,
    required List<Map<String, Object?>> evaluatedCriteria,
  }) =>
      _remote.evaluateSubmission(
        assignmentId: assignmentId,
        studentId: studentId,
        calculatedGrade: calculatedGrade,
        feedback: feedback,
        evaluatedCriteria: evaluatedCriteria,
      );

  @override
  Future<Map<String, dynamic>> replyDoubt({
    required String assignmentId,
    required String doubtId,
    required String reply,
  }) =>
      _remote.replyDoubt(
        assignmentId: assignmentId,
        doubtId: doubtId,
        reply: reply,
      );

  @override
  Future<Map<String, dynamic>> updateGrade({
    required String classCode,
    required String studentId,
    double? assignmentsScore,
    double? p1Score,
    double? projectsScore,
    double? p2Score,
  }) =>
      _remote.updateGrade(
        classCode: classCode,
        studentId: studentId,
        assignmentsScore: assignmentsScore,
        p1Score: p1Score,
        projectsScore: projectsScore,
        p2Score: p2Score,
      );

  @override
  Future<Map<String, dynamic>> updateGradesBatch({
    required String classCode,
    required List<Map<String, Object?>> grades,
  }) =>
      _remote.updateGradesBatch(classCode: classCode, grades: grades);

  @override
  Future<Map<String, dynamic>> homologate(String classCode) =>
      _remote.homologate(classCode);

  @override
  Future<Map<String, dynamic>> rectify({
    required String classCode,
    required String studentId,
    required String stage,
    required double newScore,
    required String justification,
  }) =>
      _remote.rectify(
        classCode: classCode,
        studentId: studentId,
        stage: stage,
        newScore: newScore,
        justification: justification,
      );

  @override
  Future<Map<String, dynamic>> createForumTopic({
    required String classCode,
    required String title,
    required String body,
    String? category,
  }) =>
      _remote.createForumTopic(
        classCode: classCode,
        title: title,
        body: body,
        category: category,
      );

  @override
  Future<Map<String, dynamic>> replyForumTopic({
    required String classCode,
    required String topicId,
    required String body,
  }) =>
      _remote.replyForumTopic(
        classCode: classCode,
        topicId: topicId,
        body: body,
      );

  @override
  Future<List<Map<String, dynamic>>> saveSquads({
    required String classCode,
    required List<Map<String, Object?>> squads,
  }) =>
      _remote.saveSquads(
        classCode: classCode,
        squads: squads,
      );

  @override
  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String date,
    required String time,
    required String type,
    required String location,
  }) =>
      _remote.createEvent(
        title: title,
        date: date,
        time: time,
        type: type,
        location: location,
      );

  @override
  Future<Map<String, dynamic>> publishNotice({
    required String targetCourse,
    required String targetAudience,
    required String classification,
    required String title,
    required String message,
  }) =>
      _remote.publishNotice(
        targetCourse: targetCourse,
        targetAudience: targetAudience,
        classification: classification,
        title: title,
        message: message,
      );

  @override
  Future<Map<String, dynamic>> downloadSubmission(String id) =>
      _remote.downloadSubmission(id);

  @override
  Future<Map<String, dynamic>> noticeReads(String id) =>
      _remote.noticeReads(id);

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) =>
      _profileRemote.updateProfile(body);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _profileRemote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  @override
  Future<List<String>> backupCodes() => _profileRemote.backupCodes();

  @override
  Future<List<Map<String, dynamic>>> sessions() => _profileRemote.sessions();

  @override
  Future<List<Map<String, dynamic>>> securityLogs() =>
      _profileRemote.securityLogs();

  @override
  Future<Map<String, dynamic>> lgpdExport() => _profileRemote.lgpdExport();

  @override
  Future<void> toggleTwoFactor({
    required String password,
    required bool enabled,
  }) =>
      _profileRemote.toggleTwoFactor(
        password: password,
        enabled: enabled,
      );

  @override
  Future<void> revokeSession(String sessionId) =>
      _profileRemote.revokeSession(sessionId);

  @override
  Future<void> logoutOthers() => _profileRemote.logoutOthers();
}
