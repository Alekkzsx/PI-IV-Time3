// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Contrato oficial da camada de domínio do módulo Docente

import '../models/academic_event.dart';
import '../models/academic_notice.dart';
import '../models/assignment_model.dart';
import '../models/attendance_record.dart';
import '../models/docente_course.dart';
import '../models/docente_profile.dart';
import '../models/grade_record.dart';
import '../../data/teacher_remote_data_source.dart';

abstract class IDocenteRepository {
  Future<TeacherDashboardSnapshot> getBootstrap();
  Future<List<DocenteCourse>> getCourses();
  Future<DocenteProfile> getProfile();
  Future<List<AcademicNotice>> getNotices();
  Future<List<AcademicEvent>> getEvents();
  Future<List<AssignmentItem>> getAssignments();
  Future<List<StudentGrade>> getGrades(String courseId);
  Future<ClassSession> getCurrentSession();

  Future<Map<String, dynamic>> createOrSelectSession({
    required String classCode,
    required DateTime date,
    int hours,
  });

  Future<void> updateSessionAttendance({
    required String sessionId,
    required String contentProgram,
    required String methodology,
    required String location,
    required bool isHomologated,
    required List<Map<String, Object?>> attendanceList,
  });

  Future<void> advanceSyllabus(String classCode, String unitId);

  Future<Map<String, dynamic>> publishMaterial({
    required String classCode,
    required String title,
    required String fileName,
    required String mimeType,
    required String size,
    required String contentBase64,
    String? unitAssociated,
  });

  Future<Map<String, dynamic>> createAssignment({
    required String classCode,
    required Map<String, Object?> assignment,
  });

  Future<Map<String, dynamic>> evaluateSubmission({
    required String assignmentId,
    required String studentId,
    required double calculatedGrade,
    required String feedback,
    required List<Map<String, Object?>> evaluatedCriteria,
  });

  Future<Map<String, dynamic>> replyDoubt({
    required String assignmentId,
    required String doubtId,
    required String reply,
  });

  Future<Map<String, dynamic>> updateGrade({
    required String classCode,
    required String studentId,
    double? assignmentsScore,
    double? p1Score,
    double? projectsScore,
    double? p2Score,
  });

  Future<Map<String, dynamic>> updateGradesBatch({
    required String classCode,
    required List<Map<String, Object?>> grades,
  });

  Future<Map<String, dynamic>> homologate(String classCode);

  Future<Map<String, dynamic>> rectify({
    required String classCode,
    required String studentId,
    required String stage,
    required double newScore,
    required String justification,
  });

  Future<Map<String, dynamic>> createForumTopic({
    required String classCode,
    required String title,
    required String body,
    String? category,
  });

  Future<Map<String, dynamic>> replyForumTopic({
    required String classCode,
    required String topicId,
    required String body,
  });

  Future<List<Map<String, dynamic>>> saveSquads({
    required String classCode,
    required List<Map<String, Object?>> squads,
  });

  Future<Map<String, dynamic>> createEvent({
    required String title,
    required String date,
    required String time,
    required String type,
    required String location,
  });

  Future<Map<String, dynamic>> publishNotice({
    required String targetCourse,
    required String targetAudience,
    required String classification,
    required String title,
    required String message,
  });

  Future<Map<String, dynamic>> downloadSubmission(String id);
  Future<Map<String, dynamic>> noticeReads(String id);

  // Perfil e Segurança
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<List<String>> backupCodes();
  Future<List<Map<String, dynamic>>> sessions();
  Future<List<Map<String, dynamic>>> securityLogs();
  Future<Map<String, dynamic>> lgpdExport();
  Future<void> toggleTwoFactor({
    required String password,
    required bool enabled,
  });
  Future<void> revokeSession(String sessionId);
  Future<void> logoutOthers();
}
