// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../models/academic_event.dart';
import '../models/academic_notice.dart';
import '../models/assignment_model.dart';
import '../models/attendance_record.dart';
import '../models/docente_course.dart';
import '../models/docente_profile.dart';
import '../models/grade_record.dart';

/// Contrato abstrato do repositório acadêmico do corpo docente.
/// Prepara o ecossistema frontend para receber a injeção do cliente HTTP/REST do backend.
abstract class IDocenteRepository {
  Future<List<DocenteCourse>> getCourses();
  Future<DocenteProfile> getProfile();
  Future<List<AcademicNotice>> getNotices();
  Future<List<AcademicEvent>> getEvents();
  Future<List<AssignmentItem>> getAssignments();
  Future<List<StudentGrade>> getGrades(String courseId);
  Future<ClassSession> getCurrentSession();
  Future<void> updateProfile({String? socialName, String? personalEmail});
  Future<void> toggleTwoFactor();
  Future<void> disconnectSession(String sessionId);
  Future<void> addNotice(AcademicNotice notice);
  Future<void> addEvent(AcademicEvent event);
}

