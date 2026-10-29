// Desenvolvido por Marcelo Zarpelon - RA: 25015323 e Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/auth_remote_datasource.dart';

/// Datasource HTTP para o serviço de autenticação TypeScript.
///
/// A URL pode ser substituída em builds com
/// `--dart-define=AUTH_API_BASE_URL=https://...`.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  static const String _baseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3001',
  );
  static const Duration _requestTimeout = Duration(seconds: 8);

  final http.Client _client;

  AuthRemoteDataSourceImpl({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<String> authenticateUser({
    required String identity,
    required String password,
    required String profile,
  }) async {
    final response = await _post('/api/auth/login', {
      'identity': identity,
      'password': password,
      'profile': profile,
    });
    final payload = _decodeResponse(response);
    final accessToken = payload['accessToken'];

    if (accessToken is! String || accessToken.isEmpty) {
      throw const AuthApiException(
        'Resposta inválida do serviço de autenticação.',
      );
    }

    return accessToken;
  }

  @override
  Future<void> sendPasswordResetInstructions({required String identity}) async {
    final response = await _post('/api/auth/send-recovery-otp', {
      'identity': identity,
    });
    _decodeResponse(response);
  }

  @override
  Future<String> verifyPasswordRecoveryCodeRemote({
    required String identity,
    required String code,
  }) async {
    final response = await _post('/api/auth/verify-recovery-otp', {
      'identity': identity,
      'code': code,
    });
    final payload = _decodeResponse(response);
    final resetToken = payload['resetToken'];

    if (payload['valid'] != true ||
        resetToken is! String ||
        resetToken.isEmpty) {
      throw const AuthApiException(
        'O serviço não retornou uma autorização válida para redefinir a senha.',
      );
    }

    return resetToken;
  }

  @override
  Future<bool> verifyOtpTokenRemote({
    required String identity,
    required String code,
  }) async {
    throw const AuthApiException(
      'A validação de código para segundo fator ainda não está disponível.',
    );
  }

  @override
  Future<void> updatePasswordRemote({
    required String identity,
    required String newPassword,
    required String resetToken,
  }) async {
    if (resetToken.isEmpty) {
      throw const AuthApiException(
        'A sessão de recuperação expirou. Solicite um novo código.',
      );
    }

    final response = await _post('/api/auth/reset-password', {
      'identity': identity,
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
    _ensureSuccessful(response);
  }

  @override
  Future<bool> checkTwoFactorStatusRemote({
    required String identity,
    required String profile,
  }) async {
    // O serviço atual não habilita 2FA; o login principal continua validado pela API.
    return false;
  }

  Future<http.Response> _post(String path, Map<String, Object?> body) async {
    final uri = Uri.parse('$_baseUrl$path');

    try {
      return await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } on http.ClientException {
      throw const AuthApiException(
        'Não foi possível conectar ao serviço de autenticação.',
      );
    } on FormatException {
      throw const AuthApiException(
        'A URL do serviço de autenticação está inválida.',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    _ensureSuccessful(response);

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      throw const AuthApiException(
        'Resposta inválida do serviço de autenticação.',
      );
    }

    throw const AuthApiException(
      'Resposta inválida do serviço de autenticação.',
    );
  }

  void _ensureSuccessful(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    var message = 'O serviço de autenticação não concluiu a solicitação.';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } on FormatException {
      // O erro de status continua sendo explícito mesmo se o corpo não for JSON.
    }

    throw AuthApiException(message, statusCode: response.statusCode);
  }
}

/// Erro de transporte apresentado pelas telas de autenticação.
class AuthApiException implements Exception {
  final String message;
  final int? statusCode;

  const AuthApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
