// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import '../../domain/models/academic_event.dart';
import '../../domain/models/academic_notice.dart';
import '../../domain/models/assignment_model.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/docente_course.dart';
import '../../domain/models/docente_profile.dart';
import '../../domain/models/grade_record.dart';
import '../../domain/repositories/docente_repository.dart';
import '../docente_mock_data.dart';

/// Implementação padrão local em memória do repositório acadêmico do docente.
/// Permite simulação assíncrona desacoplada de rede enquanto o backend é desenvolvido.
class MockDocenteRepository implements IDocenteRepository {
  final List<DocenteCourse> _courses = List.from(DocenteMockData.initialCourses);
  DocenteProfile _profile = DocenteMockData.initialProfile;
  final List<AcademicNotice> _notices = List.from(DocenteMockData.initialNotices);
  final List<AcademicEvent> _events = List.from(DocenteMockData.initialEvents);
  final List<AssignmentItem> _assignments = List.from(DocenteMockData.initialAssignments);
  final List<StudentGrade> _gradebook = List.from(DocenteMockData.initialGradebook);
  final ClassSession _currentSession = DocenteMockData.initialClassSession;

  @override
  Future<List<DocenteCourse>> getCourses() async {
    return List.unmodifiable(_courses);
  }

  @override
  Future<DocenteProfile> getProfile() async {
    return _profile;
  }

  @override
  Future<List<AcademicNotice>> getNotices() async {
    return List.unmodifiable(_notices);
  }

  @override
  Future<List<AcademicEvent>> getEvents() async {
    return List.unmodifiable(_events);
  }

  @override
  Future<List<AssignmentItem>> getAssignments() async {
    return List.unmodifiable(_assignments);
  }

  @override
  Future<List<StudentGrade>> getGrades(String courseId) async {
    return List.unmodifiable(_gradebook);
  }

  @override
  Future<ClassSession> getCurrentSession() async {
    return _currentSession;
  }

  @override
  Future<void> updateProfile({String? socialName, String? personalEmail}) async {
    _profile = _profile.copyWith(
      socialName: socialName ?? _profile.socialName,
      personalEmail: personalEmail ?? _profile.personalEmail,
    );
  }

  @override
  Future<void> toggleTwoFactor() async {
    _profile = _profile.copyWith(twoFactorEnabled: !_profile.twoFactorEnabled);
  }

  @override
  Future<void> disconnectSession(String sessionId) async {
    final updated =
        _profile.activeSessions.where((s) => s.id != sessionId).toList();
    _profile = _profile.copyWith(activeSessions: updated);
  }

  @override
  Future<void> addNotice(AcademicNotice notice) async {
    _notices.insert(0, notice);
  }

  @override
  Future<void> addEvent(AcademicEvent event) async {
    _events.add(event);
  }
}
