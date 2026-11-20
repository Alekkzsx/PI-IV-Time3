// Desenvolvido por Guilherme Henrique Moreira
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../state/app_user_session.dart';
import 'resilient_http_client.dart';
import 'server_health_monitor.dart';
import 'service_endpoints.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final String? code;
  const ApiException(this.message, {this.status, this.code});
  @override
  String toString() => message;
}

class AuthenticatedApiClient {
  static String get authBaseUrl => ServiceEndpoints.authBaseUrl;

  static String get academicBaseUrl => ServiceEndpoints.academicBaseUrl;

  static String get baseUrl => academicBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  AuthenticatedApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? createResilientHttpClient(),
      _baseUrl = baseUrl ?? academicBaseUrl;

  factory AuthenticatedApiClient.auth({http.Client? client}) =>
      AuthenticatedApiClient(client: client, baseUrl: authBaseUrl);

  factory AuthenticatedApiClient.academic({http.Client? client}) =>
      AuthenticatedApiClient(client: client, baseUrl: academicBaseUrl);

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException('Entre novamente para continuar.');
    }
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);
    final isAuthTarget = _baseUrl == authBaseUrl;
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
      if (response.statusCode == 503 && data is Map) {
        final code = data['code']?.toString();
        if (code == 'identity_service_unavailable') {
          ServerHealthMonitor.instance.reportTransportFailure(
            isAuthServer: true,
            detail: data['message']?.toString(),
          );
        } else if (code == 'academic_service_unavailable') {
          ServerHealthMonitor.instance.reportTransportFailure(
            isAuthServer: false,
            detail: data['message']?.toString(),
          );
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final remoteMessage = data is Map
            ? (data['message'] is String
                  ? data['message'] as String
                  : (data['erro'] is String ? data['erro'] as String : null))
            : null;
        throw ApiException(
          remoteMessage ?? 'Não foi possível concluir a operação.',
          status: response.statusCode,
          code: data is Map && data['code'] is String
              ? data['code'] as String
              : null,
        );
      }
      return data;
    } on TimeoutException {
      ServerHealthMonitor.instance.reportTransportFailure(
        isAuthServer: isAuthTarget,
      );
      throw const ApiException(
        'A API demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      ServerHealthMonitor.instance.reportTransportFailure(
        isAuthServer: isAuthTarget,
      );
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
  static String get baseUrl => ServiceEndpoints.javaServerBaseUrl;
  final http.Client _client;
  JavaServerApiClient({http.Client? client})
    : _client = client ?? createResilientHttpClient();

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
      if (response.statusCode == 503) {
        _reportJavaServiceUnavailable(response.body);
        return null;
      }
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } on TimeoutException {
      ServerHealthMonitor.instance.reportTransportFailure(isAuthServer: true);
    } on http.ClientException {
      ServerHealthMonitor.instance.reportTransportFailure(isAuthServer: true);
    } on FormatException {
      return null;
    }
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
      if (response.statusCode == 503) {
        _reportJavaServiceUnavailable(response.body);
        return null;
      }
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } on TimeoutException {
      ServerHealthMonitor.instance.reportTransportFailure(isAuthServer: true);
    } on http.ClientException {
      ServerHealthMonitor.instance.reportTransportFailure(isAuthServer: true);
    } on FormatException {
      return null;
    }
    return null;
  }

  void _reportJavaServiceUnavailable(String body) {
    var isAuthServer = true;
    String? detail;
    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          if (decoded['code'] == 'academic_service_unavailable') {
            isAuthServer = false;
          }
          if (decoded['message'] is String) {
            detail = decoded['message'] as String;
          }
        }
      } on FormatException {
        // Segue bloqueio padrão indicando indisponibilidade do Servidor Java.
      }
    }
    ServerHealthMonitor.instance.reportTransportFailure(
      isAuthServer: isAuthServer,
      detail: detail,
    );
  }
}
