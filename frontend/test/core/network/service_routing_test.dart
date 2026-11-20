// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pi_iv_time3/core/network/auth_profile_remote_data_source.dart';
import 'package:pi_iv_time3/core/network/authenticated_api_client.dart';
import 'package:pi_iv_time3/core/network/resilient_http_client_io.dart';
import 'package:pi_iv_time3/core/network/service_endpoints.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_remote_data_source.dart';
import 'package:pi_iv_time3/features/admin/users/data/admin_user_remote_data_source.dart';
import 'package:pi_iv_time3/features/video_call/data/datasources/video_call_room_remote_data_source.dart';

void main() {
  group('Fronteira de roteamento entre Java (:8080) e API Acadêmica (:3001)', () {
    setUp(() {
      AppUserSession.instance.signIn(
        identity: 'admin.demo',
        profile: 'admin',
        accessToken: 'jwt-token-teste',
      );
    });

    tearDown(() {
      AppUserSession.instance.signOut();
    });

    test('AuthenticatedApiClient direciona factories auth (:8080) e academic (:3001)', () async {
      final visitedUris = <Uri>[];
      final mockClient = MockClient((request) async {
        visitedUris.add(request.url);
        return http.Response(jsonEncode({'ok': true}), 200);
      });

      await AuthenticatedApiClient.auth(client: mockClient).getMap('/api/auth/me');
      await AuthenticatedApiClient.academic(client: mockClient).getMap('/api/student/bootstrap');
      await AuthenticatedApiClient(client: mockClient).getMap('/api/teacher/bootstrap');

      expect(visitedUris[0].toString(), 'http://127.0.0.1:8080/api/auth/me');
      expect(visitedUris[1].toString(), 'http://127.0.0.1:3001/api/student/bootstrap');
      expect(visitedUris[2].toString(), 'http://127.0.0.1:3001/api/teacher/bootstrap');
    });

    test('AuthProfileRemoteDataSource e VideoCallRoomRemoteDataSource usam Java (:8080)', () async {
      final visitedUris = <Uri>[];
      final mockClient = MockClient((request) async {
        visitedUris.add(request.url);
        if (request.url.path == '/api/video-call/rooms') {
          return http.Response(jsonEncode({'rooms': []}), 200);
        }
        if (request.url.path == '/api/auth/sessions') {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response(jsonEncode({'identity': 'admin.demo'}), 200);
      });

      final profileDs = AuthProfileRemoteDataSource(
        api: AuthenticatedApiClient.auth(client: mockClient),
      );
      await profileDs.me();
      await profileDs.sessions();

      final videoDs = VideoCallRoomRemoteDataSource(client: mockClient);
      await videoDs.listRooms();

      expect(visitedUris[0].toString(), 'http://127.0.0.1:8080/api/auth/me');
      expect(visitedUris[1].toString(), 'http://127.0.0.1:8080/api/auth/sessions');
      expect(visitedUris[2].toString(), 'http://127.0.0.1:8080/api/video-call/rooms');
    });

    test('AdminRemoteDataSource e AdminUserRemoteDataSource dividem usuários (:8080) e núcleo acadêmico (:3001)', () async {
      final visited = <String>[];
      final mockClient = MockClient((request) async {
        visited.add('${request.method} ${request.url}');
        if (request.url.path == '/api/admin/users' || request.url.path == '/api/admin/teachers' && request.method == 'GET') {
          return http.Response(jsonEncode([]), 200);
        }
        if (request.url.path == '/api/admin/teachers' && request.method == 'POST') {
          return http.Response(jsonEncode({'identity': 'prof.novo'}), 201);
        }
        return http.Response(jsonEncode({'ok': true}), 200);
      });

      final adminRemote = AdminRemoteDataSource(
        api: AuthenticatedApiClient.academic(client: mockClient),
        authApi: AuthenticatedApiClient.auth(client: mockClient),
      );
      await adminRemote.users();
      await adminRemote.dossier('u-123');
      await adminRemote.dashboard();
      await adminRemote.settings();

      final teacherDs = AdminUserRemoteDataSource(client: mockClient);
      await teacherDs.createTeacher(
        name: 'Profa. Nova',
        email: 'nova@agmrm.edu.br',
        department: 'ES',
      );
      await teacherDs.getTeachers();

      expect(visited[0], 'GET http://127.0.0.1:8080/api/admin/users?limit=500');
      expect(visited[1], 'GET http://127.0.0.1:8080/api/admin/users/u-123/dossier');
      expect(visited[2], 'GET http://127.0.0.1:3001/api/admin/dashboard');
      expect(visited[3], 'GET http://127.0.0.1:3001/api/admin/settings');
      expect(visited[4], 'POST http://127.0.0.1:8080/api/admin/teachers');
      expect(visited[5], 'GET http://127.0.0.1:3001/api/admin/teachers');
    });

    test('ServiceEndpoints e proxy bypass funcionam em localhost, LAN e redes corporativas', () {
      expect(
        ServiceEndpoints.resolveDefaultHttpUrl(
          port: 8080,
          currentPageUri: Uri.parse('http://localhost:54321/#/'),
        ),
        'http://localhost:8080',
      );
      expect(
        ServiceEndpoints.resolveDefaultHttpUrl(
          port: 3001,
          currentPageUri: Uri.parse('http://192.168.10.25:5000/'),
        ),
        'http://192.168.10.25:3001',
      );
      expect(
        ServiceEndpoints.resolveDefaultWsUrl(
          port: 8080,
          currentPageUri: Uri.parse('https://ava.universidade.edu/'),
        ),
        'wss://ava.universidade.edu:8080',
      );
      expect(
        ServiceEndpoints.resolveDefaultHttpUrl(
          port: 8080,
          currentPageUri: Uri.parse('file:///home/user/app/'),
        ),
        'http://127.0.0.1:8080',
      );

      expect(isLoopbackOrPrivateHost('127.0.0.1'), isTrue);
      expect(isLoopbackOrPrivateHost('localhost'), isTrue);
      expect(isLoopbackOrPrivateHost('::1'), isTrue);
      expect(isLoopbackOrPrivateHost('192.168.0.10'), isTrue);
      expect(isLoopbackOrPrivateHost('10.20.30.40'), isTrue);
      expect(isLoopbackOrPrivateHost('172.16.0.1'), isTrue);
      expect(isLoopbackOrPrivateHost('cloud.mongodb.com'), isFalse);
      expect(isLoopbackOrPrivateHost('8.8.8.8'), isFalse);
    });
  });
}
