import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'role_permission_policy.dart';
import 'session_storage.dart';

/// Sessão autenticada global do usuário conectada à API real e persistida no navegador/dispositivo.
class AppUserSession extends ChangeNotifier {
  AppUserSession._();

  static final AppUserSession instance = AppUserSession._();
  static const String _sessionKey = 'agmrm_session_v1';
  static const String _rememberedIdentityKey = 'agmrm_remembered_identity_v1';

  String? _userId;
  String? _identity;
  String? _role;
  String? _accessToken;
  String? _displayName;
  String? _socialName;
  String? _email;
  String? _phone;
  String? _departmentOrCourse;
  String? _campus;
  String? _semester;
  String? _shift;
  bool _twoFactorRequired = false;
  Map<String, dynamic> _preferences = const <String, dynamic>{};

  Timer? _expiryTimer;
  VoidCallback? onExpired;

  String? get userId => _userId;
  String? get identity => _identity;
  String? get role => _role;
  String? get accessToken => _accessToken;
  String? get displayName => _displayName;
  String? get socialName => _socialName;
  String? get email => _email;
  String? get phone => _phone;
  String? get departmentOrCourse => _departmentOrCourse;
  String? get campus => _campus;
  String? get semester => _semester;
  String? get shift => _shift;
  bool get twoFactorRequired => _twoFactorRequired;
  Map<String, dynamic> get preferences => _preferences;

  /// Nome efetivo exibido na interface (respeita nome social quando configurado).
  String get effectiveName {
    final social = _socialName?.trim();
    if (social != null && social.isNotEmpty) return social;
    final name = _displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return _identity ?? 'Usuário';
  }

  /// Iniciais do usuário para avatares da barra superior/lateral.
  String get initials {
    final parts = effectiveName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'US';
    if (parts.length == 1) {
      final w = parts.first.toUpperCase();
      return w.length >= 2 ? w.substring(0, 2) : w;
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool get isAuthenticated => _identity?.isNotEmpty == true && _role != null;
  bool get hasLiveToken => _accessToken != null && _accessToken!.isNotEmpty;

  bool hasRole(String role) => _role == role;

  bool hasPermission(String permission) =>
      RolePermissionPolicy.hasPermission(_role, permission);

  String? getRememberedIdentity() => SessionStorage.read(_rememberedIdentityKey);

  void setRememberedIdentity(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      SessionStorage.remove(_rememberedIdentityKey);
    } else {
      SessionStorage.write(_rememberedIdentityKey, trimmed);
    }
  }

  void signIn({
    required String identity,
    required String profile,
    String? accessToken,
    String? userId,
    String? displayName,
    String? socialName,
    String? email,
    String? phone,
    String? departmentOrCourse,
    String? campus,
    String? semester,
    String? shift,
    bool? twoFactorRequired,
    Map<String, dynamic>? preferences,
    bool persist = true,
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
    if (userId != null) _userId = userId;
    if (displayName != null) _displayName = displayName;
    if (socialName != null) _socialName = socialName;
    if (email != null) _email = email;
    if (phone != null) _phone = phone;
    if (departmentOrCourse != null) _departmentOrCourse = departmentOrCourse;
    if (campus != null) _campus = campus;
    if (semester != null) _semester = semester;
    if (shift != null) _shift = shift;
    if (twoFactorRequired != null) _twoFactorRequired = twoFactorRequired;
    if (preferences != null) {
      _preferences = Map<String, dynamic>.unmodifiable(preferences);
    }

    _expiryTimer?.cancel();
    if (accessToken != null && accessToken.split('.').length == 3) {
      try {
        final payload = jsonDecode(
          utf8.decode(
            base64Url.decode(base64Url.normalize(accessToken.split('.')[1])),
          ),
        );
        if (payload is Map) {
          if (_userId == null && payload['sub'] is String) {
            _userId = payload['sub'] as String;
          }
          if (payload['exp'] is num) {
            final remaining = DateTime.fromMillisecondsSinceEpoch(
              (payload['exp'] as num).toInt() * 1000,
            ).difference(DateTime.now());
            _expiryTimer = Timer(
              remaining.isNegative ? Duration.zero : remaining,
              expire,
            );
          }
        }
      } on FormatException {
        /* A API valida a assinatura e o formato do token. */
      }
    }

    if (persist && accessToken != null && accessToken.isNotEmpty) {
      _persistCurrentSession();
    }
    notifyListeners();
  }

  /// Atualiza metadados do perfil vindos de `GET /api/auth/me` ou `PATCH /api/auth/profile`.
  void applyProfileMap(Map<String, dynamic> data) {
    if (data['id'] != null) _userId = data['id'].toString();
    if (data['identity'] is String && (data['identity'] as String).isNotEmpty) {
      _identity = data['identity'] as String;
    }
    if (data['displayName'] is String) {
      _displayName = data['displayName'] as String;
    }
    if (data.containsKey('socialName')) {
      _socialName = data['socialName']?.toString();
    }
    if (data['email'] is String) _email = data['email'] as String;
    if (data.containsKey('phone')) _phone = data['phone']?.toString();
    if (data.containsKey('departmentOrCourse')) {
      _departmentOrCourse = data['departmentOrCourse']?.toString();
    } else if (data.containsKey('department')) {
      _departmentOrCourse = data['department']?.toString();
    }
    if (data.containsKey('campus')) _campus = data['campus']?.toString();
    if (data.containsKey('semester')) _semester = data['semester']?.toString();
    if (data.containsKey('shift')) _shift = data['shift']?.toString();
    if (data['twoFactorRequired'] is bool) {
      _twoFactorRequired = data['twoFactorRequired'] as bool;
    }
    if (data['preferences'] is Map) {
      _preferences = Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(data['preferences'] as Map),
      );
    }
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      _persistCurrentSession();
    }
    notifyListeners();
  }

  /// Restaura sessão salva no navegador/dispositivo caso o JWT ainda não tenha expirado.
  bool restoreFromStorage() {
    final raw = SessionStorage.read(_sessionKey);
    if (raw == null || raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      final token = decoded['accessToken']?.toString();
      final identity = decoded['identity']?.toString();
      final role = decoded['role']?.toString();
      if (token == null || token.isEmpty || identity == null || role == null) {
        return false;
      }
      if (_isJwtExpired(token)) {
        SessionStorage.remove(_sessionKey);
        return false;
      }
      signIn(
        identity: identity,
        profile: role,
        accessToken: token,
        userId: decoded['userId']?.toString(),
        displayName: decoded['displayName']?.toString(),
        socialName: decoded['socialName']?.toString(),
        email: decoded['email']?.toString(),
        phone: decoded['phone']?.toString(),
        departmentOrCourse: decoded['departmentOrCourse']?.toString(),
        campus: decoded['campus']?.toString(),
        semester: decoded['semester']?.toString(),
        shift: decoded['shift']?.toString(),
        twoFactorRequired: decoded['twoFactorRequired'] == true,
        preferences: decoded['preferences'] is Map
            ? Map<String, dynamic>.from(decoded['preferences'] as Map)
            : null,
        persist: false,
      );
      return true;
    } catch (_) {
      SessionStorage.remove(_sessionKey);
      return false;
    }
  }

  /// Sincroniza a sessão atual com `GET /api/auth/me`.
  Future<bool> refreshProfileFromServer({http.Client? client}) async {
    final token = _accessToken;
    if (token == null || token.isEmpty) return false;
    const baseUrl = String.fromEnvironment(
      'AUTH_API_BASE_URL',
      defaultValue: 'http://127.0.0.1:3001',
    );
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(
            Uri.parse('$baseUrl/api/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          applyProfileMap(decoded);
          return true;
        }
      } else if (response.statusCode == 401 && _accessToken == token) {
        expire();
      }
    } catch (_) {
      // Se offline momentaneamente, preserva dados locais até próxima chamada autenticada
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
    return false;
  }

  String get defaultHomeRoute {
    switch (_role) {
      case 'admin':
        return '/admin-shell';
      case 'docente':
        return '/docente/home';
      case 'aluno':
        return '/student/home';
      default:
        return '/';
    }
  }

  bool _isJwtExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is Map && payload['exp'] is num) {
        final exp = DateTime.fromMillisecondsSinceEpoch(
          (payload['exp'] as num).toInt() * 1000,
        );
        return exp.isBefore(DateTime.now());
      }
    } catch (_) {}
    return false;
  }

  void _persistCurrentSession() {
    SessionStorage.write(
      _sessionKey,
      jsonEncode({
        'userId': _userId,
        'identity': _identity,
        'role': _role,
        'accessToken': _accessToken,
        'displayName': _displayName,
        'socialName': _socialName,
        'email': _email,
        'phone': _phone,
        'departmentOrCourse': _departmentOrCourse,
        'campus': _campus,
        'semester': _semester,
        'shift': _shift,
        'twoFactorRequired': _twoFactorRequired,
        'preferences': _preferences,
      }),
    );
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
    _userId = null;
    _identity = null;
    _role = null;
    _accessToken = null;
    _displayName = null;
    _socialName = null;
    _email = null;
    _phone = null;
    _departmentOrCourse = null;
    _campus = null;
    _semester = null;
    _shift = null;
    _twoFactorRequired = false;
    _preferences = const <String, dynamic>{};
    SessionStorage.remove(_sessionKey);
    notifyListeners();
  }
}
