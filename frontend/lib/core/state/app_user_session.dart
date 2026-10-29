import 'package:flutter/foundation.dart';

/// Minimal authenticated identity used by role-aware frontend navigation.
class AppUserSession extends ChangeNotifier {
  AppUserSession._();

  static final AppUserSession instance = AppUserSession._();

  String? _identity;
  String? _role;

  String? get identity => _identity;
  String? get role => _role;
  bool get isAuthenticated => _identity?.isNotEmpty == true && _role != null;

  bool hasRole(String role) => _role == role;

  void signIn({required String identity, required String profile}) {
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
    notifyListeners();
  }

  void signOut() {
    _identity = null;
    _role = null;
    notifyListeners();
  }
}
