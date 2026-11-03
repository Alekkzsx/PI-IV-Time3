// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:pi_iv_time3/features/admin/shared/data/admin_academic_data_source.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

class FakeAdminAcademicDataSource implements AdminAcademicDataSource {
  const FakeAdminAcademicDataSource();

  static final List<AdminClassModel> _classes = List.of(AdminMockData.classes);

  @override
  Future<List<AdminCourseModel>> getCourses() async =>
      List.of(AdminMockData.courses);

  @override
  Future<void> createCourse(AdminCourseModel course) async {
    AdminMockData.courses.add(course);
  }

  @override
  Future<List<AdminClassModel>> getClasses() async => List.of(_classes);

  @override
  Future<void> createClass({
    required String code,
    required String courseCode,
    required String semester,
    required String shift,
    required String location,
    required int maxCapacity,
    String? professorIdentity,
  }) async {
    final course = AdminMockData.courses.firstWhere(
      (item) => item.code == courseCode,
    );
    _classes.add(
      AdminClassModel(
        code: code,
        subjectName: course.name,
        courseName: course.name,
        semester: semester,
        shift: shift,
        location: location,
        enrolled: 0,
        maxCapacity: maxCapacity,
        professor: professorIdentity ?? 'Não atribuído',
        formulaRegime: 'Autonomia Docente',
      ),
    );
  }

  @override
  Future<void> assignTeacherToClass({
    required String classCode,
    required String professorIdentity,
  }) async {
    final classModel = _classes.firstWhere((item) => item.code == classCode);
    classModel.professor = professorIdentity;
  }

  @override
  Future<void> createEnrollment({
    required String classCode,
    required String studentIdentity,
  }) async {}

  @override
  Future<void> createClassSession({
    required String classCode,
    required String title,
    required DateTime startsAt,
  }) async {}
}
