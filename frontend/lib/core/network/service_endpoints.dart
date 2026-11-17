/// Resolvedor centralizado das URLs dos serviços HTTP/WebSocket do ecossistema AGMRM.
///
/// Respeita `--dart-define` quando explícito e, na execução Web (`http`/`https`),
/// reutiliza automaticamente o mesmo host da página (`localhost`, `127.0.0.1`,
/// `[::1]` ou IP da LAN) para evitar falsas falhas cross-origin e permitir acesso
/// em redes corporativas/universitárias.
class ServiceEndpoints {
  const ServiceEndpoints._();

  static const String _configuredAuthBaseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
  );
  static const String _configuredAcademicBaseUrl = String.fromEnvironment(
    'ACADEMIC_API_BASE_URL',
  );
  static const String _legacyApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _configuredJavaServerBaseUrl = String.fromEnvironment(
    'JAVA_SERVER_BASE_URL',
  );
  static const String _configuredVideoCallWsBaseUrl = String.fromEnvironment(
    'VIDEO_CALL_WS_BASE_URL',
  );

  static String get authBaseUrl => _configuredAuthBaseUrl.isNotEmpty
      ? _stripTrailingSlash(_configuredAuthBaseUrl)
      : resolveDefaultHttpUrl(port: 8080);

  static String get academicBaseUrl {
    if (_configuredAcademicBaseUrl.isNotEmpty) {
      return _stripTrailingSlash(_configuredAcademicBaseUrl);
    }
    if (_legacyApiBaseUrl.isNotEmpty) {
      return _stripTrailingSlash(_legacyApiBaseUrl);
    }
    return resolveDefaultHttpUrl(port: 3001);
  }

  static String get javaServerBaseUrl =>
      _configuredJavaServerBaseUrl.isNotEmpty
      ? _stripTrailingSlash(_configuredJavaServerBaseUrl)
      : authBaseUrl;

  static String get videoCallWsBaseUrl =>
      _configuredVideoCallWsBaseUrl.isNotEmpty
      ? _stripTrailingSlash(_configuredVideoCallWsBaseUrl)
      : resolveDefaultWsUrl(port: 8080);

  static String resolveDefaultHttpUrl({
    required int port,
    Uri? currentPageUri,
  }) {
    final page = currentPageUri ?? Uri.base;
    if ((page.scheme == 'http' || page.scheme == 'https') &&
        page.host.isNotEmpty) {
      return '${page.scheme}://${_formatHost(page.host)}:$port';
    }
    return 'http://127.0.0.1:$port';
  }

  static String resolveDefaultWsUrl({
    required int port,
    Uri? currentPageUri,
  }) {
    final page = currentPageUri ?? Uri.base;
    if ((page.scheme == 'http' || page.scheme == 'https') &&
        page.host.isNotEmpty) {
      final wsScheme = page.scheme == 'https' ? 'wss' : 'ws';
      return '$wsScheme://${_formatHost(page.host)}:$port';
    }
    return 'ws://127.0.0.1:$port';
  }

  static Uri resolveVideoCallWebSocketUri({
    required String roomCode,
    String? ticket,
    String? baseUrlOverride,
  }) {
    final baseUri = Uri.parse(baseUrlOverride ?? videoCallWsBaseUrl);
    final scheme = baseUri.scheme == 'https' || baseUri.scheme == 'wss'
        ? 'wss'
        : 'ws';
    return baseUri
        .replace(scheme: scheme)
        .resolve('/ws/video-call/${Uri.encodeComponent(roomCode)}')
        .replace(queryParameters: ticket == null ? null : {'ticket': ticket});
  }

  static String _formatHost(String host) {
    final clean = host.trim();
    if (clean.contains(':') && !clean.startsWith('[')) {
      return '[$clean]';
    }
    return clean;
  }

  static String _stripTrailingSlash(String url) {
    var result = url.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
