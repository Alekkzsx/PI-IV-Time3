// Desenvolvido por Guilherme Henrique Moreira
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../state/app_user_session.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final String? code;
  const ApiException(this.message, {this.status, this.code});
  @override
  String toString() => message;
}

class AuthenticatedApiClient {
  static const baseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3001',
  );
  final http.Client _client;
  AuthenticatedApiClient({http.Client? client})
    : _client = client ?? http.Client();

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException('Entre novamente para continuar.');
    }
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);
    try {
      final response = await http.Response.fromStream(
        await _client.send(request),
      ).timeout(const Duration(seconds: 20));
      dynamic data;
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } on FormatException {
          throw const ApiException('A API retornou uma resposta inválida.');
        }
      }
      if (response.statusCode == 401 &&
          AppUserSession.instance.accessToken == token &&
          !(data is Map && data['code'] == 'invalid_password')) {
        AppUserSession.instance.expire();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          data is Map && data['message'] is String
              ? data['message'] as String
              : 'Não foi possível concluir a operação.',
          status: response.statusCode,
          code: data is Map && data['code'] is String
              ? data['code'] as String
              : null,
        );
      }
      return data;
    } on TimeoutException {
      throw const ApiException(
        'A API demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException('Não foi possível conectar à API.');
    }
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final res = await request('GET', path);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getList(String path) async {
    final res = await request('GET', path);
    if (res is List) {
      return res
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> postMap(
    String path, [
    Map<String, Object?>? body,
  ]) async {
    final res = await request('POST', path, body: body);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> patchMap(
    String path,
    Map<String, Object?> body,
  ) async {
    final res = await request('PATCH', path, body: body);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> putMap(
    String path,
    Map<String, Object?> body,
  ) async {
    final res = await request('PUT', path, body: body);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{};
  }

  Future<void> delete(String path) async {
    await request('DELETE', path);
  }
}

/// Cliente HTTP dedicado ao servidor nativo Java (`server/` na porta 8080)
/// para cálculo regimental de notas, frequência de telemetria e estado de salas.
class JavaServerApiClient {
  static const baseUrl = String.fromEnvironment(
    'JAVA_SERVER_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
  final http.Client _client;
  JavaServerApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>?> getJson(String path) async {
    try {
      final token = AppUserSession.instance.accessToken;
      final response = await _client
          .get(
            Uri.parse('$baseUrl$path'),
            headers: {
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    try {
      final token = AppUserSession.instance.accessToken;
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }
}
