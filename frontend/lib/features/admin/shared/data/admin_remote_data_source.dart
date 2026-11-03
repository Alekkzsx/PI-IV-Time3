// Desenvolvido por Guilherme Henrique Moreira
import '../../../../core/network/authenticated_api_client.dart';
import '../models/admin_models.dart';

class AdminRemoteDataSource {
  final AuthenticatedApiClient api;
  AdminRemoteDataSource({AuthenticatedApiClient? api})
    : api = api ?? AuthenticatedApiClient();
  Future<dynamic> request(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) => api.request(method, '/api/admin$path', body: body);

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

  Future<List<AdminUserModel>> users() async {
    final values = await request('GET', '/users?limit=500') as List;
    return values.map((raw) {
      final value = raw as Map<String, dynamic>;
      return AdminUserModel(
        id: value['id'] as String,
        identity: value['identity'] as String,
        name: value['displayName'] as String,
        email: value['email'] as String,
        profile: value['profile'] as String,
        departmentOrCourse: value['departmentOrCourse'] as String? ?? '',
        status: value['active'] == true ? 'Ativo' : 'Suspenso',
        twoFactorRequired: value['twoFactorRequired'] == true,
        activeSessionsCount: value['activeSessionsCount'] as int? ?? 0,
        suspensionReason: value['suspensionReason'] as String?,
        lastLogin: value['lastLogin'] as String? ?? 'Sem acesso registrado',
      );
    }).toList();
  }

  Future<List<AdminProtocolModel>> protocols() async =>
      (await request('GET', '/protocols') as List).map((raw) {
        final value = raw as Map<String, dynamic>;
        return AdminProtocolModel(
          id: value['id'] as String,
          studentName: value['studentName'] as String,
          studentRa: value['studentRa'] as String,
          requestType: value['requestType'] as String,
          date: value['createdAt'] as String,
          status: value['status'] as String,
          attachmentName: value['attachmentName'] as String? ?? '',
          justification: value['justification'] as String,
          targetComponent: value['targetComponent'] as String?,
          decisionNote: value['decisionNote'] as String?,
          signedBy: value['decidedBy'] as String?,
        );
      }).toList();
  Future<List<AdminAuditLogModel>> auditLogs() async =>
      (await request('GET', '/audit-logs?limit=500') as List).map((raw) {
        final value = raw as Map<String, dynamic>;
        return AdminAuditLogModel(
          id: value['id'] as String,
          timestamp: value['createdAt'] as String,
          actor: value['actorId'] as String,
          actorRole: 'admin',
          actionType: value['action'] as String,
          description: '${value['action']} · ${value['target']}',
          ipAddress: 'Não registrado',
          severity: 'INFO',
          targetUserId: value['target'] as String,
          diffAfter: value['details'] is Map
              ? Map<String, dynamic>.from(value['details'] as Map)
              : null,
        );
      }).toList();
}
