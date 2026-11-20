// Desenvolvido por Murillo Caravita - RA: 25014012

import '../../../../core/network/authenticated_api_client.dart';
import '../../../../core/network/resilient_http_client.dart';

import 'package:http/http.dart' as http;
import '../models/admin_models.dart';

abstract interface class AdminAcademicDataSource {
  Future<List<AdminCourseModel>> getCourses();
  Future<void> createCourse(AdminCourseModel course);
  Future<void> patchCourse(String code, Map<String, Object?> fields);
  Future<List<AdminClassModel>> getClasses();
  Future<List<AdminUserModel>> getTeachers();
  Future<List<AdminGradeAuditRow>> classGrades(String classCode);
  Future<List<AdminEnrolledStudent>> getEnrollments(String classCode);
  Future<void> updateEnrollment({
    required String classCode,
    required String enrollmentId,
    required Map<String, Object?> fields,
  });
  Future<void> createClass({
    required String code,
    required String courseCode,
    required String semester,
    required String shift,
    required String location,
    required int maxCapacity,
    String? professorIdentity,
    String? subjectName,
    String? schedule,
    int? totalHours,
  });
  Future<void> assignTeacherToClass({
    required String classCode,
    required String professorIdentity,
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
    : _client = client ?? createResilientHttpClient();

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
  Future<void> patchCourse(String code, Map<String, Object?> fields) async {
    await _request(
      'PATCH',
      '/api/admin/courses/${Uri.encodeComponent(code)}',
      body: fields,
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
  Future<List<AdminUserModel>> getTeachers() async {
    final response = await _request('GET', '/api/admin/teachers');
    if (response is! List) {
      throw const AdminAcademicApiException('Resposta inválida da API.');
    }
    return response.whereType<Map>().map((item) {
      final value = Map<String, dynamic>.from(item);
      return AdminUserModel(
        id: value['id']?.toString() ?? value['identity']?.toString() ?? '',
        identity: value['identity']?.toString() ?? '',
        name: value['name']?.toString() ?? '',
        email: value['email']?.toString() ?? '',
        profile: 'docente',
        departmentOrCourse: value['department']?.toString() ?? '',
        status: value['active'] == true ? 'Ativo' : 'Suspenso',
        twoFactorRequired: false,
        activeSessionsCount: 0,
      );
    }).toList();
  }

  @override
  Future<List<AdminGradeAuditRow>> classGrades(String classCode) async {
    final response = await _request(
      'GET',
      '/api/admin/classes/${Uri.encodeComponent(classCode)}/grades',
    );
    final dynamic rawGrades = response is Map ? response['grades'] : response;
    if (rawGrades is! List) {
      throw const AdminAcademicApiException('Resposta inválida da API.');
    }
    return rawGrades
        .whereType<Map>()
        .map(
          (item) =>
              AdminGradeAuditRow.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<List<AdminEnrolledStudent>> getEnrollments(String classCode) async {
    final response = await _request(
      'GET',
      '/api/admin/classes/${Uri.encodeComponent(classCode)}/enrollments',
    );
    if (response is! List) {
      throw const AdminAcademicApiException('Resposta inválida da API.');
    }
    return response
        .whereType<Map>()
        .map(
          (item) =>
              AdminEnrolledStudent.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<void> updateEnrollment({
    required String classCode,
    required String enrollmentId,
    required Map<String, Object?> fields,
  }) async {
    await _request(
      'PATCH',
      '/api/admin/classes/${Uri.encodeComponent(classCode)}/enrollments/${Uri.encodeComponent(enrollmentId)}',
      body: fields,
    );
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
    String? subjectName,
    String? schedule,
    int? totalHours,
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
        if (subjectName != null && subjectName.trim().isNotEmpty)
          'subjectName': subjectName.trim(),
        if (schedule != null && schedule.trim().isNotEmpty)
          'schedule': schedule.trim(),
        if (totalHours != null) 'totalHours': totalHours,
      },
    );
  }

  @override
  Future<void> assignTeacherToClass({
    required String classCode,
    required String professorIdentity,
  }) async {
    await _request(
      'PATCH',
      '/api/admin/classes/${Uri.encodeComponent(classCode)}/professor',
      body: {'professorIdentity': professorIdentity.trim()},
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

  String _str(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String? _nullableStr(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int _int(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  AdminCourseModel _courseFromJson(dynamic value) {
    if (value is! Map) {
      throw const AdminAcademicApiException(
        'Curso retornado pela API é inválido.',
      );
    }
    final map = Map<String, dynamic>.from(value);
    final components = map['components'];
    return AdminCourseModel(
      code: _str(map['code']),
      name: _str(map['name'], fallback: 'Curso'),
      matrix: _str(map['matrix']),
      workload: _str(map['workload'], fallback: '0h'),
      studentsCount: _int(map['studentsCount']),
      formula: _str(
        map['formula'],
        fallback: 'Média Ponderada (N1 40% / N2 60%)',
      ),
      department: _str(
        map['department'],
        fallback: 'Departamento de Computação e Sistemas',
      ),
      modality: _str(map['modality'], fallback: 'Graduação'),
      components: components is List
          ? components
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : const [],
    );
  }

  AdminClassModel _classFromJson(dynamic value) {
    if (value is! Map) {
      throw const AdminAcademicApiException(
        'Turma retornada pela API é inválida.',
      );
    }
    final map = Map<String, dynamic>.from(value);
    final formulaRegime = _nullableStr(map['formulaRegime']);
    final enrolledStudentsRaw = map['enrolledStudents'];
    final parsedEnrolledStudents = enrolledStudentsRaw is List
        ? enrolledStudentsRaw
              .whereType<Map>()
              .map(
                (item) => AdminEnrolledStudent.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : const <AdminEnrolledStudent>[];
    final subjectName = _nullableStr(map['subjectName']) ??
        _nullableStr(map['courseName']) ??
        _str(map['code']);
    final courseName = _nullableStr(map['courseName']) ??
        _nullableStr(map['subjectName']) ??
        'Curso Superior';
    return AdminClassModel(
      code: _str(map['code']),
      courseCode: _str(map['courseCode']),
      gradeLocked: map['gradeLocked'] == true,
      pautaHomologated: map['pautaHomologated'] == true,
      chancelaCode: _nullableStr(map['chancelaCode']),
      subjectName: subjectName,
      courseName: courseName,
      semester: _str(map['semester']),
      shift: _str(map['shift']),
      schedule: _str(map['schedule']),
      location: _str(map['location'], fallback: 'A definir'),
      enrolled: map['enrolled'] == null
          ? parsedEnrolledStudents.length
          : _int(map['enrolled']),
      maxCapacity: _int(map['maxCapacity'], fallback: 40),
      enrolledStudentRas:
          (map['enrolledStudentRas'] is List)
              ? (map['enrolledStudentRas'] as List)
                    .map((item) => item.toString())
                    .toList()
              : const [],
      enrolledStudents: parsedEnrolledStudents,
      professor:
          _nullableStr(map['professorName']) ??
          _nullableStr(map['professorIdentity']) ??
          'Não alocado',
      professorIdentity: _nullableStr(map['professorIdentity']),
      formulaRegime: formulaRegime == 'admin'
          ? 'Impor pelo Admin'
          : 'Autonomia Docente',
      evaluationFormula:
          _nullableStr(map['evaluationFormula']) ?? '(N1 × 0.4) + (N2 × 0.6)',
      isLive: map['isLive'] == true,
    );
  }
}

class AdminAcademicApiException implements Exception {
  final String message;

  const AdminAcademicApiException(this.message);

  @override
  String toString() => message;
}
