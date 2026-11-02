import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'role_permission_policy.dart';

/// Minimal authenticated identity used by role-aware frontend navigation.
class AppUserSession extends ChangeNotifier {
  AppUserSession._();

  static final AppUserSession instance = AppUserSession._();

  String? _identity;
  String? _role;
  String? _accessToken;
  Timer? _expiryTimer;
  VoidCallback? onExpired;

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
    _expiryTimer?.cancel();
    if (accessToken != null && accessToken.split('.').length == 3) {
      try {
        final payload = jsonDecode(
          utf8.decode(
            base64Url.decode(base64Url.normalize(accessToken.split('.')[1])),
          ),
        );
        if (payload is Map && payload['exp'] is num) {
          final remaining = DateTime.fromMillisecondsSinceEpoch(
            (payload['exp'] as num).toInt() * 1000,
          ).difference(DateTime.now());
          _expiryTimer = Timer(
            remaining.isNegative ? Duration.zero : remaining,
            expire,
          );
        }
      } on FormatException {
        /* A API valida a assinatura e o formato do token. */
      }
    }
    notifyListeners();
  }

  void expire() {
    signOut();
    onExpired?.call();
  }

  Future<void> logout() async {
    final token = _accessToken;
    signOut();
    if (token == null) return;
    const baseUrl = String.fromEnvironment(
      'AUTH_API_BASE_URL',
      defaultValue: 'http://127.0.0.1:3001',
    );
    try {
      await http
          .post(
            Uri.parse('$baseUrl/api/auth/logout'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      /* O estado local já foi encerrado; o JWT também possui expiração. */
    }
  }

  void signOut() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _identity = null;
    _role = null;
    _accessToken = null;
    notifyListeners();
  }
}
