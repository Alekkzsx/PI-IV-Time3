// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:pi_iv_time3/features/admin/shared/data/admin_academic_data_source.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

class FakeAdminAcademicDataSource implements AdminAcademicDataSource {
  const FakeAdminAcademicDataSource();

  @override
  Future<List<AdminCourseModel>> getCourses() async =>
      List.of(AdminMockData.courses);

  @override
  Future<void> createCourse(AdminCourseModel course) async {
    AdminMockData.courses.add(course);
  }

  @override
  Future<List<AdminClassModel>> getClasses() async =>
      List.of(AdminMockData.classes);

  @override
  Future<void> createClass({
    required String code,
    required String courseCode,
    required String semester,
    required String shift,
    required String location,
    required int maxCapacity,
    String? professorIdentity,
  }) async {}

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
