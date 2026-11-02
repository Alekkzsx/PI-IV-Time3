import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

class AdminUserRemoteDataSource {
  static const String _baseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3001',
  );

  final http.Client _client;

  AdminUserRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  Future<List<AdminUserModel>> getTeachers() async {
    final response = await _getTeachers();
    if (response is! List) {
      throw const AdminUserApiException('Resposta inválida da API.');
    }

    return response.map((value) {
      if (value is! Map<String, dynamic> ||
          value['identity'] is! String ||
          value['name'] is! String ||
          value['email'] is! String ||
          value['department'] is! String ||
          value['active'] is! bool) {
        throw const AdminUserApiException(
          'A API retornou um cadastro de docente inválido.',
        );
      }
      return AdminUserModel(
        id: value['identity'] as String,
        name: value['name'] as String,
        email: value['email'] as String,
        profile: 'docente',
        departmentOrCourse: value['department'] as String,
        status: value['active'] == true ? 'Ativo' : 'Suspenso',
        twoFactorRequired: false,
        activeSessionsCount: 0,
      );
    }).toList();
  }

  Future<String> createTeacher({
    required String name,
    required String email,
    required String department,
  }) async {
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const AdminUserApiException(
        'Entre como administrador para cadastrar um docente.',
      );
    }

    final uri = Uri.parse('$_baseUrl/api/admin/teachers');
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'department': department,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } on http.ClientException {
      throw const AdminUserApiException('Não foi possível conectar à API.');
    } on TimeoutException {
      throw const AdminUserApiException('A API demorou para responder.');
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const AdminUserApiException('Resposta inválida da API.');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded is Map<String, dynamic> && decoded['message'] is String
          ? decoded['message'] as String
          : 'A API não conseguiu cadastrar o docente.';
      throw AdminUserApiException(message);
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['identity'] is! String ||
        (decoded['identity'] as String).isEmpty) {
      throw const AdminUserApiException(
        'A API retornou uma identidade inválida para o docente.',
      );
    }
    return decoded['identity'] as String;
  }

  Future<dynamic> _getTeachers() async {
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const AdminUserApiException(
        'Entre como administrador para consultar os docentes.',
      );
    }

    late final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse('$_baseUrl/api/admin/teachers'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
    } on http.ClientException {
      throw const AdminUserApiException('Não foi possível conectar à API.');
    } on TimeoutException {
      throw const AdminUserApiException('A API demorou para responder.');
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const AdminUserApiException('Resposta inválida da API.');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded is Map<String, dynamic> && decoded['message'] is String
          ? decoded['message'] as String
          : 'A API não conseguiu consultar os docentes.';
      throw AdminUserApiException(message);
    }
    return decoded;
  }
}

class AdminUserApiException implements Exception {
  final String message;

  const AdminUserApiException(this.message);

  @override
  String toString() => message;
}
