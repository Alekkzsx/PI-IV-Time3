// Desenvolvido por Murillo Caravita - RA: 25014012

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pi_iv_time3/core/state/app_user_session.dart';
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
  static const String _baseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3001',
  );
  static const Duration _timeout = Duration(seconds: 8);

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
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const AdminAcademicApiException(
        'Entre como administrador para continuar.',
      );
    }

    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = method == 'GET'
          ? await _client.get(uri, headers: headers).timeout(_timeout)
          : await _client
                .post(uri, headers: headers, body: jsonEncode(body))
                .timeout(_timeout);
      dynamic decoded;
      if (response.body.isNotEmpty) {
        try {
          decoded = jsonDecode(response.body);
        } on FormatException {
          throw const AdminAcademicApiException('Resposta inválida da API.');
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message =
            decoded is Map<String, dynamic> && decoded['message'] is String
            ? decoded['message'] as String
            : 'A API não conseguiu concluir a operação.';
        throw AdminAcademicApiException(message);
      }
      return decoded;
    } on http.ClientException {
      throw const AdminAcademicApiException('Não foi possível conectar à API.');
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
