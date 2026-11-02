// Desenvolvido por Guilherme Henrique Moreira
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../state/app_user_session.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, {this.status});
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
      ).timeout(const Duration(seconds: 15));
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
}
