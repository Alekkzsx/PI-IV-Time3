import 'package:flutter/foundation.dart';
import 'role_permission_policy.dart';

/// Minimal authenticated identity used by role-aware frontend navigation.
class AppUserSession extends ChangeNotifier {
  AppUserSession._();

  static final AppUserSession instance = AppUserSession._();

  String? _identity;
  String? _role;
  String? _accessToken;

  String? get identity => _identity;
  String? get role => _role;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _identity?.isNotEmpty == true && _role != null;

  bool hasRole(String role) => _role == role;

  bool hasPermission(String permission) =>
      RolePermissionPolicy.hasPermission(_role, permission);

  void signIn({
    required String identity,
    required String profile,
    String? accessToken,
  }) {
    final normalizedIdentity = identity.trim();
    if (normalizedIdentity.isEmpty) {
      throw ArgumentError.value(identity, 'identity', 'Identidade inválida.');
    }
    final normalizedProfile = profile.trim().toLowerCase();
    if (!const {'aluno', 'docente', 'admin'}.contains(normalizedProfile)) {
      throw ArgumentError.value(profile, 'profile', 'Perfil inválido.');
    }

    _identity = normalizedIdentity;
    _role = normalizedProfile;
    _accessToken = accessToken;
    notifyListeners();
  }

  void signOut() {
    _identity = null;
    _role = null;
    _accessToken = null;
    notifyListeners();
  }
}
