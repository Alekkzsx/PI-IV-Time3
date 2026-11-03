import 'authenticated_api_client.dart';
import '../state/app_user_session.dart';

class AuthProfileRemoteDataSource {
  final AuthenticatedApiClient _api;

  AuthProfileRemoteDataSource({AuthenticatedApiClient? api})
    : _api = api ?? AuthenticatedApiClient();

  Future<Map<String, dynamic>> me() async {
    final profile = await _api.getMap('/api/auth/me');
    AppUserSession.instance.applyProfileMap(profile);
    return profile;
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, Object?> fields,
  ) async {
    final profile = await _api.patchMap('/api/auth/profile', fields);
    AppUserSession.instance.applyProfileMap(profile);
    return profile;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.request(
      'POST',
      '/api/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    AppUserSession.instance.signOut();
  }

  Future<void> toggleTwoFactor({
    required String password,
    required bool enabled,
  }) async {
    await _api.request(
      'POST',
      '/api/auth/two-factor',
      body: {'password': password, 'enabled': enabled},
    );
    AppUserSession.instance.signOut();
  }

  Future<List<String>> backupCodes() async {
    final response = await _api.postMap('/api/auth/backup-codes');
    final codes = response['codes'];
    if (codes is! List || codes.any((code) => code is! String)) {
      throw const ApiException('A API retornou códigos de backup inválidos.');
    }
    return codes.cast<String>();
  }

  Future<List<Map<String, dynamic>>> sessions() =>
      _api.getList('/api/auth/sessions');

  Future<void> revokeSession(String sessionId) =>
      _api.delete('/api/auth/sessions/${Uri.encodeComponent(sessionId)}');

  Future<void> logoutOthers() async {
    await _api.request('POST', '/api/auth/logout-others');
  }

  Future<List<Map<String, dynamic>>> securityLogs() =>
      _api.getList('/api/auth/security-logs');

  Future<Map<String, dynamic>> lgpdExport() =>
      _api.getMap('/api/auth/lgpd-export');
}
