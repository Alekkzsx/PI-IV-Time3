import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../../core/network/authenticated_api_client.dart';

class VideoCallRoomRemoteDataSource {
  final AuthenticatedApiClient _api;

  VideoCallRoomRemoteDataSource({http.Client? client})
    : _api = AuthenticatedApiClient(client: client);

  Future<List<VideoCallRoomSummary>> listRooms() async => (await _api.getList(
    '/api/video-call/rooms',
  )).map(VideoCallRoomSummary.fromJson).toList();

  Future<VideoCallRoomAccess> enterRoom(String roomCode) async {
    final response = await _request('/api/video-call/rooms/enter', {
      'roomCode': roomCode,
    });
    if (response is! Map ||
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

  Future<void> recordAttendance({
    required String roomCode,
    required String event,
    int? connectedSeconds,
  }) async {
    await _request('/api/video-call/rooms/attendance', {
      'roomCode': roomCode,
      'event': event,
      if (connectedSeconds != null) 'connectedSeconds': connectedSeconds,
    });
  }

  Future<dynamic> _request(String path, Map<String, Object?> body) async {
    try {
      return await _api.request('POST', path, body: body);
    } on ApiException catch (error) {
      throw VideoCallRoomApiException(error.message);
    } on TimeoutException {
      throw const VideoCallRoomApiException(
        'O serviço de videochamada demorou para responder.',
      );
    }
  }
}

class VideoCallRoomSummary {
  final String roomCode;
  final String classCode;
  final String title;
  final String courseName;
  final String semester;
  final String shift;
  final String location;
  final String? professorName;
  final bool isOpen;

  const VideoCallRoomSummary({
    required this.roomCode,
    required this.classCode,
    required this.title,
    this.courseName = '',
    this.semester = '',
    this.shift = '',
    this.location = '',
    this.professorName,
    required this.isOpen,
  });

  factory VideoCallRoomSummary.fromJson(Map<String, dynamic> json) =>
      VideoCallRoomSummary(
        roomCode: json['roomCode']?.toString() ?? '',
        classCode: json['classCode']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        courseName: json['courseName']?.toString() ?? '',
        semester: json['semester']?.toString() ?? '',
        shift: json['shift']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        professorName: json['professorName']?.toString(),
        isOpen: json['isOpen'] == true,
      );
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
