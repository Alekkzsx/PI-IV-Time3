// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:async';
import 'package:agmrm_security/security.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../state/app_user_session.dart';
import 'resilient_http_client.dart';
import 'service_endpoints.dart';

/// Estado global de conectividade da política Fail-Closed.
enum ServerConnectionState { idle, checking, online, offline }

/// Retrato imutável da saúde simultânea do Servidor Java (:8080)
/// e do Backend Acadêmico (:3001).
class ServerHealthSnapshot {
  final ServerConnectionState state;
  final bool authServerOnline;
  final bool academicServerOnline;
  final bool isRechecking;
  final DateTime? lastCheckedAt;
  final String? failureReason;

  const ServerHealthSnapshot({
    required this.state,
    required this.authServerOnline,
    required this.academicServerOnline,
    this.isRechecking = false,
    this.lastCheckedAt,
    this.failureReason,
  });

  const ServerHealthSnapshot.idle()
    : state = ServerConnectionState.idle,
      authServerOnline = false,
      academicServerOnline = false,
      isRechecking = false,
      lastCheckedAt = null,
      failureReason = null;

  bool get isBlocking =>
      state == ServerConnectionState.offline ||
      state == ServerConnectionState.checking;

  ServerHealthSnapshot copyWith({
    ServerConnectionState? state,
    bool? authServerOnline,
    bool? academicServerOnline,
    bool? isRechecking,
    DateTime? lastCheckedAt,
    String? failureReason,
    bool clearFailureReason = false,
  }) {
    return ServerHealthSnapshot(
      state: state ?? this.state,
      authServerOnline: authServerOnline ?? this.authServerOnline,
      academicServerOnline: academicServerOnline ?? this.academicServerOnline,
      isRechecking: isRechecking ?? this.isRechecking,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      failureReason: clearFailureReason
          ? null
          : (failureReason ?? this.failureReason),
    );
  }
}

/// Monitor contínuo Fail-Closed que fiscaliza simultaneamente o Servidor Java (:8080)
/// e o Backend Acadêmico (:3001).
///
/// Se qualquer um dos dois serviços ficar indisponível — esteja o usuário logado
/// ou ainda na tela de login — o estado muda imediatamente para
/// [ServerConnectionState.offline] para bloquear o aplicativo por completo.
class ServerHealthMonitor extends ChangeNotifier {
  static final ServerHealthMonitor instance = ServerHealthMonitor._(
    active: false,
  );

  final http.Client Function()? _clientFactory;
  final String? _authBaseUrlOverride;
  final String? _academicBaseUrlOverride;
  final Future<void> Function()? _onReconnected;
  final Duration _probeTimeout;

  ServerHealthSnapshot _snapshot = const ServerHealthSnapshot.idle();
  Timer? _heartbeatTimer;
  Future<bool>? _inflightCheck;
  int _consecutiveFailures = 0;
  bool _active;
  bool _revalidatingSession = false;

  ServerHealthMonitor._({
    required bool active,
    http.Client Function()? clientFactory,
    String? authBaseUrl,
    String? academicBaseUrl,
    Future<void> Function()? onReconnected,
    Duration? probeTimeout,
  }) : _active = active,
       _clientFactory = clientFactory,
       _authBaseUrlOverride = authBaseUrl,
       _academicBaseUrlOverride = academicBaseUrl,
       _onReconnected = onReconnected,
       _probeTimeout = probeTimeout ?? SecurityConstants.serverHealthCheckTimeout;

  /// Construtor para instâncias isoladas em testes automatizados.
  factory ServerHealthMonitor({
    http.Client Function()? clientFactory,
    String? authBaseUrl,
    String? academicBaseUrl,
    Future<void> Function()? onReconnected,
    Duration? probeTimeout,
    bool active = true,
  }) {
    return ServerHealthMonitor._(
      active: active,
      clientFactory: clientFactory,
      authBaseUrl: authBaseUrl,
      academicBaseUrl: academicBaseUrl,
      onReconnected: onReconnected,
      probeTimeout: probeTimeout,
    );
  }

  ServerHealthSnapshot get snapshot => _snapshot;
  bool get isActive => _active;
  int get consecutiveFailures => _consecutiveFailures;

  String get _authBaseUrl =>
      _authBaseUrlOverride ?? ServiceEndpoints.authBaseUrl;

  String get _academicBaseUrl =>
      _academicBaseUrlOverride ?? ServiceEndpoints.academicBaseUrl;

  /// Ativa o monitor, agenda o heartbeat periódico e dispara a primeira checagem.
  void start({Duration? interval}) {
    _active = true;
    if (_snapshot.state == ServerConnectionState.idle) {
      _snapshot = const ServerHealthSnapshot(
        state: ServerConnectionState.checking,
        authServerOnline: false,
        academicServerOnline: false,
        isRechecking: true,
      );
      notifyListeners();
    }
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      interval ?? SecurityConstants.serverHealthCheckInterval,
      (_) => unawaited(checkNow()),
    );
    unawaited(checkNow());
  }

  /// Interrompe o heartbeat periódico sem apagar o último retrato obtido.
  void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _active = false;
  }

  /// Restaura completamente o estado interno (uso exclusivo em testes).
  @visibleForTesting
  void resetForTesting() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _inflightCheck = null;
    _consecutiveFailures = 0;
    _active = false;
    _revalidatingSession = false;
    _snapshot = const ServerHealthSnapshot.idle();
    notifyListeners();
  }

  /// Executa verificação paralela de `GET /health` nos dois serviços obrigatórios.
  ///
  /// Retorna `true` somente quando **ambos** responderem HTTP `200`.
  Future<bool> checkNow() {
    final existing = _inflightCheck;
    if (existing != null) return existing;

    final future = _performHealthCheck();
    _inflightCheck = future;
    future.whenComplete(() {
      if (identical(_inflightCheck, future)) {
        _inflightCheck = null;
      }
    });
    return future;
  }

  /// Bloqueia imediatamente a interface quando qualquer cliente HTTP detectar
  /// erro de transporte (`ClientException`, `TimeoutException`) ou `503`
  /// indicando queda do Servidor Java (:8080) ou do Backend Acadêmico (:3001).
  void reportTransportFailure({
    required bool isAuthServer,
    String? detail,
    bool verifyImmediately = true,
  }) {
    if (!_active) return;

    _consecutiveFailures++;
    final authOnline = isAuthServer ? false : _snapshot.authServerOnline;
    final academicOnline = isAuthServer
        ? _snapshot.academicServerOnline
        : false;

    final reason = buildFailureReason(
      authServerOnline: authOnline,
      academicServerOnline: academicOnline,
    );

    _snapshot = ServerHealthSnapshot(
      state: ServerConnectionState.offline,
      authServerOnline: authOnline,
      academicServerOnline: academicOnline,
      isRechecking: verifyImmediately && !_revalidatingSession,
      lastCheckedAt: DateTime.now(),
      failureReason: reason,
    );
    notifyListeners();

    if (verifyImmediately && !_revalidatingSession && _inflightCheck == null) {
      unawaited(checkNow());
    }
  }

  Future<bool> _performHealthCheck() async {
    final previousState = _snapshot.state;
    if (previousState == ServerConnectionState.idle) {
      _snapshot = const ServerHealthSnapshot(
        state: ServerConnectionState.checking,
        authServerOnline: false,
        academicServerOnline: false,
        isRechecking: true,
      );
      notifyListeners();
    } else if (!_snapshot.isRechecking) {
      _snapshot = _snapshot.copyWith(isRechecking: true);
      notifyListeners();
    }

    final results = await Future.wait<bool>([
      _probeHealthEndpoint(_authBaseUrl),
      _probeHealthEndpoint(_academicBaseUrl),
    ]);

    final authOk = results[0];
    final academicOk = results[1];
    final bothOnline = authOk && academicOk;
    final checkedAt = DateTime.now();

    if (bothOnline) {
      _consecutiveFailures = 0;
      _snapshot = ServerHealthSnapshot(
        state: ServerConnectionState.online,
        authServerOnline: true,
        academicServerOnline: true,
        isRechecking: false,
        lastCheckedAt: checkedAt,
        failureReason: null,
      );
      notifyListeners();

      if (previousState == ServerConnectionState.offline) {
        unawaited(_revalidateSessionAfterRecovery());
      }
      return true;
    }

    _consecutiveFailures++;
    final shouldBlock =
        _consecutiveFailures >=
        SecurityConstants.serverHealthMaxConsecutiveFailures;

    _snapshot = ServerHealthSnapshot(
      state: shouldBlock
          ? ServerConnectionState.offline
          : _snapshot.state,
      authServerOnline: authOk,
      academicServerOnline: academicOk,
      isRechecking: false,
      lastCheckedAt: checkedAt,
      failureReason: buildFailureReason(
        authServerOnline: authOk,
        academicServerOnline: academicOk,
      ),
    );
    notifyListeners();
    return false;
  }

  Future<bool> _probeHealthEndpoint(String baseUrl) async {
    final client = _clientFactory?.call() ?? createResilientHttpClient();
    try {
      final response = await client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(_probeTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<void> _revalidateSessionAfterRecovery() async {
    if (_revalidatingSession) return;
    _revalidatingSession = true;
    try {
      if (_onReconnected != null) {
        await _onReconnected();
      } else if (AppUserSession.instance.isAuthenticated) {
        await AppUserSession.instance.verifySessionWithServer();
      }
    } finally {
      _revalidatingSession = false;
    }
  }

  /// Mensagem clara e específica indicando exatamente qual serviço está fora do ar.
  static String buildFailureReason({
    required bool authServerOnline,
    required bool academicServerOnline,
  }) {
    if (!authServerOnline && !academicServerOnline) {
      return 'O Servidor Java (porta 8080) e o Backend Acadêmico (porta 3001) estão desligados ou fora do ar.';
    }
    if (!authServerOnline) {
      return 'O Servidor Java (porta 8080) está desligado ou fora do ar.';
    }
    if (!academicServerOnline) {
      return 'O Backend Acadêmico (porta 3001) está desligado ou fora do ar.';
    }
    return 'Todos os serviços estão operando normalmente.';
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
