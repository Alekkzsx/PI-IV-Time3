// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
// Mixin de domínio para Perfil Docente, 2FA, Sessões Ativas e LGPD

part of '../docente_controller.dart';

mixin _DocenteSettingsMixin on _DocenteControllerBase {
  void setSettingsSubtab(String subtab) {
    _settingsSubtab = subtab;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? socialName,
    String? personalEmail,
  }) async {
    if (!_hasActiveTeacherAccess) return false;
    try {
      await _profileRemote.updateProfile({
        if (socialName != null) 'socialName': socialName.trim(),
        if (personalEmail != null) 'personalEmail': personalEmail.trim(),
      });
      await _profileRemote.me();
      await loadRemote(force: true);
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    } catch (_) {
      remoteError = 'Não foi possível atualizar o perfil.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _profileRemote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on ApiException catch (error) {
      remoteError = error.message;
    }
    notifyListeners();
    return false;
  }

  Future<List<String>> backupCodes() => _profileRemote.backupCodes();

  Future<List<Map<String, dynamic>>> securitySessions() =>
      _profileRemote.sessions();

  Future<List<Map<String, dynamic>>> securityLogs() =>
      _profileRemote.securityLogs();

  Future<Map<String, dynamic>> exportPersonalData() =>
      _profileRemote.lgpdExport();

  Future<void> toggleTwoFactor({required String password}) async {
    if (!_hasActiveTeacherAccess) return;
    try {
      await _profileRemote.toggleTwoFactor(
        password: password,
        enabled: !_profile.twoFactorEnabled,
      );
    } on ApiException catch (error) {
      remoteError = error.message;
    }
    notifyListeners();
  }

  Future<void> disconnectSession(String sessionId) async {
    if (!_hasActiveTeacherAccess) return;
    try {
      await _profileRemote.revokeSession(sessionId);
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    }
    notifyListeners();
  }

  /// Encerra todas as sessões, exceto a do dispositivo atualmente em uso.
  Future<void> disconnectOtherSessions() async {
    if (!_hasActiveTeacherAccess) return;
    try {
      await _profileRemote.logoutOthers();
      await loadRemote(force: true);
    } on ApiException catch (error) {
      remoteError = error.message;
    }
    notifyListeners();
  }
}
