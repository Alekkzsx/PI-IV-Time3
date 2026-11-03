// Desenvolvido por Murillo Caravita - RA: 25014012

import '../../../../core/network/authenticated_api_client.dart';

import 'package:http/http.dart' as http;
import 'admin_mock_data.dart';

abstract interface class AdminAcademicDataSource {
  Future<List<AdminCourseModel>> getCourses();
  Future<void> createCourse(AdminCourseModel course);
  Future<List<AdminClassModel>> getClasses();
  Future<void> createClass({
    required String code,
    required String courseCode,
    required String semester,
    required String shift,
    required String location,
    required int maxCapacity,
    String? professorIdentity,
  });
  Future<void> createEnrollment({
    required String classCode,
    required String studentIdentity,
  });
  Future<void> createClassSession({
    required String classCode,
    required String title,
    required DateTime startsAt,
  });
}

class AdminAcademicRemoteDataSource implements AdminAcademicDataSource {
  final http.Client _client;

  AdminAcademicRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<List<AdminCourseModel>> getCourses() async {
    final response = await _request('GET', '/api/admin/courses');
    if (response is! List) {
      throw const AdminAcademicApiException('Resposta inválida da API.');
    }
    return response.map(_courseFromJson).toList();
  }

  @override
  Future<void> createCourse(AdminCourseModel course) async {
    await _request(
      'POST',
      '/api/admin/courses',
      body: {
        'code': course.code,
        'name': course.name,
        'matrix': course.matrix,
        'workload': course.workload,
        'formula': course.formula,
        'department': course.department,
        'modality': course.modality,
        'components': course.components,
      },
    );
  }

  @override
  Future<List<AdminClassModel>> getClasses() async {
    final response = await _request('GET', '/api/admin/classes');
    if (response is! List) {
      throw const AdminAcademicApiException('Resposta inválida da API.');
    }
    return response.map(_classFromJson).toList();
  }

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
    await _request(
      'POST',
      '/api/admin/classes',
      body: {
        'code': code,
        'courseCode': courseCode,
        'semester': semester,
        'shift': shift,
        'location': location,
        'maxCapacity': maxCapacity,
        if (professorIdentity != null && professorIdentity.trim().isNotEmpty)
          'professorIdentity': professorIdentity.trim(),
      },
    );
  }

  @override
  Future<void> createEnrollment({
    required String classCode,
    required String studentIdentity,
  }) async {
    await _request(
      'POST',
      '/api/admin/classes/${Uri.encodeComponent(classCode)}/enrollments',
      body: {'studentIdentity': studentIdentity},
    );
  }

  @override
  Future<void> createClassSession({
    required String classCode,
    required String title,
    required DateTime startsAt,
  }) async {
    await _request(
      'POST',
      '/api/admin/classes/${Uri.encodeComponent(classCode)}/sessions',
      body: {'title': title, 'startsAt': startsAt.toUtc().toIso8601String()},
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    try {
      return await AuthenticatedApiClient(
        client: _client,
      ).request(method, path, body: body);
    } on ApiException catch (error) {
      throw AdminAcademicApiException(error.message);
    }
  }

  AdminCourseModel _courseFromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const AdminAcademicApiException(
        'Curso retornado pela API é inválido.',
      );
    }
    final components = value['components'];
    return AdminCourseModel(
      code: value['code'] as String,
      name: value['name'] as String,
      matrix: value['matrix'] as String,
      workload: value['workload'] as String,
      studentsCount: value['studentsCount'] as int? ?? 0,
      formula: value['formula'] as String,
      department: value['department'] as String,
      modality: value['modality'] as String,
      components: components is List
          ? components
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : const [],
    );
  }

  AdminClassModel _classFromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const AdminAcademicApiException(
        'Turma retornada pela API é inválida.',
      );
    }
    final formulaRegime = value['formulaRegime'] as String?;
    return AdminClassModel(
      code: value['code'] as String,
      gradeLocked: value['gradeLocked'] == true,
      subjectName: value['courseName'] as String,
      courseName: value['courseName'] as String,
      semester: value['semester'] as String,
      shift: value['shift'] as String,
      location: value['location'] as String,
      enrolled: value['enrolled'] as int? ?? 0,
      maxCapacity: value['maxCapacity'] as int,
      professor: value['professorIdentity'] as String? ?? 'Não atribuído',
      formulaRegime: formulaRegime == 'admin'
          ? 'Impor pelo Admin'
          : 'Autonomia Docente',
    );
  }
}

class AdminAcademicApiException implements Exception {
  final String message;

  const AdminAcademicApiException(this.message);

  @override
  String toString() => message;
}
