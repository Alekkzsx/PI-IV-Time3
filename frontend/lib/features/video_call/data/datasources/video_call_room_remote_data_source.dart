import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pi_iv_time3/core/state/app_user_session.dart';

class VideoCallRoomRemoteDataSource {
  static const String _baseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3001',
  );

  final http.Client _client;

  VideoCallRoomRemoteDataSource({http.Client? client})
    : _client = client ?? http.Client();

  Future<VideoCallRoomAccess> enterRoom(String roomCode) async {
    final response = await _request('/api/video-call/rooms/enter', {
      'roomCode': roomCode,
    });
    if (response is! Map<String, dynamic> ||
        response['opened'] is! bool ||
        response['webSocketTicket'] is! String ||
        (response['webSocketTicket'] as String).isEmpty) {
      throw const VideoCallRoomApiException(
        'Resposta inválida da API de videochamada.',
      );
    }
    return VideoCallRoomAccess(
      opened: response['opened'] as bool,
      webSocketTicket: response['webSocketTicket'] as String,
    );
  }

  Future<void> closeRoom(String roomCode) async {
    await _request('/api/video-call/rooms/close', {'roomCode': roomCode});
  }

  Future<dynamic> _request(String path, Map<String, Object?> body) async {
    final token = AppUserSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const VideoCallRoomApiException(
        'Entre na sua conta para acessar a videochamada.',
      );
    }

    late final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
    } on http.ClientException {
      throw const VideoCallRoomApiException(
        'Não foi possível conectar ao serviço de videochamada.',
      );
    } on TimeoutException {
      throw const VideoCallRoomApiException(
        'O serviço de videochamada demorou para responder.',
      );
    }

    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw const VideoCallRoomApiException('Resposta inválida da API.');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          decoded is Map<String, dynamic> && decoded['message'] is String
          ? decoded['message'] as String
          : 'A API não conseguiu acessar a sala.';
      throw VideoCallRoomApiException(message);
    }
    return decoded;
  }
}

class VideoCallRoomAccess {
  final bool opened;
  final String webSocketTicket;

  const VideoCallRoomAccess({
    required this.opened,
    required this.webSocketTicket,
  });
}

class VideoCallRoomApiException implements Exception {
  final String message;

  const VideoCallRoomApiException(this.message);

  @override
  String toString() => message;
}
