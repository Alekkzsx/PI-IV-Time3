// Desenvolvido por Guilherme Henrique Moreira
import 'dart:convert';

import '../../../../core/network/authenticated_api_client.dart';
import '../models/admin_models.dart';

class AdminRemoteDataSource {
  final AuthenticatedApiClient api;
  final AuthenticatedApiClient authApi;
  AdminRemoteDataSource({
    AuthenticatedApiClient? api,
    AuthenticatedApiClient? authApi,
  }) : api = api ?? AuthenticatedApiClient.academic(),
       authApi = authApi ?? api ?? AuthenticatedApiClient.auth();

  Future<dynamic> request(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) {
    final cleanPath = path.split('?').first;
    final client = cleanPath == '/users' || cleanPath.startsWith('/users/')
        ? authApi
        : api;
    return client.request(method, '/api/admin$path', body: body);
  }

  Future<Map<String, dynamic>> dashboard() async =>
      await request('GET', '/dashboard') as Map<String, dynamic>;

  Future<Map<String, dynamic>> settings() async =>
      await request('GET', '/settings') as Map<String, dynamic>;

  Future<void> patchSettings(Map<String, Object?> fields) async {
    await request('PATCH', '/settings', fields);
  }

  Future<List<AdminCalendarMilestone>> calendar() async =>
      ((await request('GET', '/calendar')) as List)
          .whereType<Map>()
          .map(
            (item) => AdminCalendarMilestone.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

  Future<Map<String, dynamic>> createCalendarEvent(
    Map<String, Object?> values,
  ) async => Map<String, dynamic>.from(
    await request('POST', '/calendar', values) as Map,
  );

  Future<Map<String, dynamic>> updateCalendarEvent(
    String id,
    Map<String, Object?> values,
  ) async => Map<String, dynamic>.from(
    await request('PATCH', '/calendar/${Uri.encodeComponent(id)}', values)
        as Map,
  );

  Future<void> deleteCalendarEvent(String id) async {
    await request('DELETE', '/calendar/${Uri.encodeComponent(id)}');
  }

  Future<Map<String, dynamic>> createAnnouncement(
    Map<String, Object?> values,
  ) async => Map<String, dynamic>.from(
    await request('POST', '/announcements', values) as Map,
  );

  Future<Map<String, dynamic>> dossier(String id) async =>
      Map<String, dynamic>.from(
        await request('GET', '/users/${Uri.encodeComponent(id)}/dossier')
            as Map,
      );

  Future<List<Map<String, dynamic>>> userSessions(String id) async =>
      ((await request('GET', '/users/${Uri.encodeComponent(id)}/sessions'))
              as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, Object?> fields,
  ) async => Map<String, dynamic>.from(
    await request('PATCH', '/users/${Uri.encodeComponent(id)}', fields) as Map,
  );

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

  Future<List<AdminUserModel>> users() async {
    final rawList = await request('GET', '/users?limit=500');
    if (rawList is! List) {
      throw const ApiException('A API retornou uma resposta inválida.');
    }
    return rawList.whereType<Map>().map((raw) {
      final value = Map<String, dynamic>.from(raw);
      return AdminUserModel(
        id: _str(value['id'] ?? value['_id']),
        identity: _str(value['identity']),
        name: _str(value['displayName'] ?? value['name'], fallback: 'Usuário'),
        email: _str(value['email']),
        profile: _str(value['profile'], fallback: 'aluno'),
        departmentOrCourse: _str(
          value['departmentOrCourse'] ?? value['department'],
        ),
        status: value['active'] == true ? 'Ativo' : 'Suspenso',
        twoFactorRequired: value['twoFactorRequired'] == true,
        activeSessionsCount: _int(value['activeSessionsCount']),
        suspensionReason: _nullableStr(value['suspensionReason']),
        lastLogin:
            _nullableStr(value['lastLogin']) ?? 'Sem acesso registrado',
      );
    }).toList();
  }

  Future<List<AdminProtocolModel>> protocols() async {
    final rawList = await request('GET', '/protocols');
    if (rawList is! List) {
      throw const ApiException('A API retornou uma resposta inválida.');
    }
    return rawList.whereType<Map>().map((raw) {
      final value = Map<String, dynamic>.from(raw);
      return AdminProtocolModel(
        id: _str(value['id'] ?? value['_id']),
        code: _nullableStr(value['code']),
        studentName: _str(value['studentName'], fallback: 'Discente'),
        studentRa: _str(value['studentRa'] ?? value['studentIdentity']),
        requestType: _str(
          value['requestType'],
          fallback: 'Requerimento Acadêmico',
        ),
        date: _str(value['createdAt'] ?? value['date']),
        status: _str(value['status'], fallback: 'Aguardando Parecer'),
        attachmentName: _str(value['attachmentName']),
        justification: _str(value['justification']),
        targetComponent: _nullableStr(value['targetComponent']),
        decisionNote: _nullableStr(value['decisionNote']),
        signedBy: _nullableStr(value['signedBy'] ?? value['decidedBy']),
      );
    }).toList();
  }

  Future<List<AdminAuditLogModel>> auditLogs() async {
    final rawList = await request('GET', '/audit-logs?limit=500');
    if (rawList is! List) {
      throw const ApiException('A API retornou uma resposta inválida.');
    }
    return rawList.whereType<Map>().map((raw) {
      final value = Map<String, dynamic>.from(raw);
      Map<String, dynamic>? mapValue(Object? input) {
        if (input is Map) return Map<String, dynamic>.from(input);
        if (input is String) {
          try {
            final decoded = jsonDecode(input);
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
          } catch (_) {}
        }
        return null;
      }

      final action = _str(value['action'], fallback: 'evento');
      final target = _str(value['target'], fallback: '-');
      return AdminAuditLogModel(
        id: _str(value['id'] ?? value['_id']),
        timestamp: _str(value['createdAt'] ?? value['timestamp']),
        actor: _nullableStr(value['actorName']) ??
            _nullableStr(value['actorIdentity']) ??
            _nullableStr(value['actorId']) ??
            'Sistema',
        actorRole: _nullableStr(value['actorRole']),
        actionType: action,
        description: '$action · $target',
        ipAddress: _nullableStr(value['ipAddress']) ?? 'Não informado',
        severity: _nullableStr(value['severity']) ?? 'INFO',
        targetUserId: _nullableStr(value['target']),
        diffBefore: mapValue(value['diffBefore']),
        diffAfter: mapValue(value['diffAfter'] ?? value['details']),
      );
    }).toList();
  }

  Future<Map<String, dynamic>> downloadProtocol(String id) async =>
      Map<String, dynamic>.from(
        await api.request(
              'GET',
              '/api/files/protocols/${Uri.encodeComponent(id)}',
            )
            as Map,
      );
}
