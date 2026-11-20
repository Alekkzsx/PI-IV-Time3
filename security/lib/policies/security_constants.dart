// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Constantes de segurança invariantes, limites e configurações de timeout
/// para a Arquitetura Corporativa de Defesa em Profundidade do AGMRM.
abstract final class SecurityConstants {
  // Construtor privado para evitar instanciação
  SecurityConstants._();

  // ─── CONTROLES DE FORÇA BRUTA E BLOQUEIO (R2) ───

  /// Máximo de tentativas de login consecutivas com falha antes do bloqueio temporário.
  static const int maxFailedLoginAttempts = 5;

  /// Duração do bloqueio temporário de conta em segundos.
  static const int lockoutDurationSeconds = 30;

  /// Duração do bloqueio como um objeto Duration tipado.
  static const Duration lockoutDuration = Duration(seconds: lockoutDurationSeconds);

  // ─── CICLO DE VIDA DO TOKEN EFÊMERO DE RECUPERAÇÃO (R3) ───

  /// Tempo de vida (TTL) para tokens efêmeros de recuperação de senha em segundos (5 minutos).
  static const int recoveryTokenTtlSeconds = 300;

  /// Alias padrão de TTL do token.
  static const int defaultTokenTtlSeconds = recoveryTokenTtlSeconds;

  /// TTL do token de recuperação em minutos.
  static const int recoveryTokenTtlMinutes = 5;

  /// TTL do token efêmero como um objeto Duration tipado.
  static const Duration recoveryTokenTtl = Duration(seconds: recoveryTokenTtlSeconds);

  /// Máximo de tentativas inválidas de verificação de OTP antes da revogação da sessão do token.
  static const int maxVerificationAttempts = 3;

  /// Máximo de tentativas inválidas de verificação de OTP (alias para consistência entre especificações).
  static const int maxInvalidVerificationAttempts = 3;

  /// Alias de máximo de tentativas de verificação de OTP.
  static const int maxOtpVerificationAttempts = maxVerificationAttempts;

  /// Comprimento do código numérico de verificação OTP.
  static const int otpCodeLength = 6;

  // ─── LIMITES DE ENTROPIA DE SENHA (R3) ───

  /// Comprimento mínimo de senha exigido para aceitação.
  static const int minPasswordLength = 8;

  /// Comprimento máximo de senha para mitigar ataques de negação de serviço por hashing.
  static const int maxPasswordLength = 128;

  /// Pontuação mínima de entropia necessária para habilitar o envio de redefinição de senha (de 4).
  static const int minPasswordEntropyScore = 3;

  /// Pontuação mínima de entropia necessária (alias para consistência entre especificações).
  static const int minRequiredEntropyScore = 3;

  /// Pontuação máxima de entropia atingível.
  static const int maxPasswordEntropyScore = 4;

  /// Pontuação máxima de entropia possível (alias para consistência entre especificações).
  static const int maxEntropyScore = 4;

  // ─── SANITIZAÇÃO DE ENTRADA E LIMITES DE PAYLOAD (R2, R4) ───

  /// Comprimento mínimo para identidade acadêmica (RA / Matrícula / ADM).
  static const int minIdentityLength = 3;

  /// Comprimento máximo para identidade acadêmica (RA / Matrícula / ADM).
  static const int maxIdentityLength = 32;

  /// Alias de comprimento máximo de RA.
  static const int maxRaLength = maxIdentityLength;

  /// Comprimento máximo de e-mail em conformidade com a RFC (RFC 5321).
  static const int maxEmailLength = 254;

  /// Tamanho máximo do payload de requisição HTTP em bytes (limite de 64 KB).
  static const int maxRequestBodySizeBytes = 65536;

  /// Tamanho máximo do payload de requisição HTTP em kilobytes.
  static const int maxBodySizeKb = 64;

  /// Tamanho do bloco de buffer em bytes para leitores de corpo em streaming.
  static const int bufferChunkSizeBytes = 4096;

  // ─── MITIGAÇÃO DE ATAQUES DE TEMPORIZAÇÃO E NORMALIZAÇÃO DE LATÊNCIA (R2) ───

  /// Duração padronizada de atraso artificial para respostas de autenticação (milissegundos).
  static const int standardizedAuthLatencyMs = 1000;

  /// Alias da duração padronizada de atraso artificial (milissegundos).
  static const int standardAuthLatencyMs = 1000;

  /// Alias de latência padrão de autenticação (milissegundos).
  static const int defaultAuthLatencyMs = standardizedAuthLatencyMs;

  /// Atraso artificial padronizado como um Duration tipado.
  static const Duration standardizedAuthLatency = Duration(milliseconds: standardizedAuthLatencyMs);

  /// Alias de atraso artificial padronizado como um Duration tipado.
  static const Duration standardAuthLatency = Duration(milliseconds: standardAuthLatencyMs);

  /// Tolerância de jitter de temporização em milissegundos.
  static const int timingJitterToleranceMs = 50;

  /// Alias padrão de tolerância de jitter de autenticação.
  static const int defaultAuthJitterMs = timingJitterToleranceMs;

  /// Mínimo de iterações de trabalho fictício para simulação de tempo constante em identidades inexistentes.
  static const int minDummyWorkIterations = 10000;

  // ─── PADRÕES DE REDE, SERVIDOR E CACHE (R4) ───

  /// Porta padrão de vínculo (binding) do servidor HTTP.
  static const int defaultServerPort = 8080;

  /// Endereço de host padrão do servidor HTTP.
  static const String defaultServerHost = '0.0.0.0';

  /// Timeout padrão de leitura/ocioso HTTP em segundos.
  static const int defaultRequestTimeoutSeconds = 30;

  /// Idade máxima em cache de pre-flight CORS em segundos (24 horas).
  static const int corsMaxAgeSeconds = 86400;

  // ─── CABEÇALHOS DE SEGURANÇA DEFENSIVOS HTTP (R4) ───

  /// Nome do cabeçalho para prevenção de MIME sniffing.
  static const String headerXContentTypeOptions = 'X-Content-Type-Options';
  /// Valor do cabeçalho que impõe a proibição de MIME sniffing.
  static const String headerContentTypeOptions = 'nosniff';
  /// Valor do cabeçalho que impõe a proibição de MIME sniffing (alias).
  static const String headerValueNosniff = 'nosniff';

  /// Nome do cabeçalho para defesa contra clickjacking.
  static const String headerXFrameOptions = 'X-Frame-Options';
  /// Valor do cabeçalho que nega a exibição em iframes.
  static const String headerFrameOptions = 'DENY';
  /// Valor do cabeçalho que nega a exibição em iframes (alias).
  static const String headerValueDeny = 'DENY';

  /// Nome do cabeçalho para proteção contra XSS.
  static const String headerXssProtection = '1; mode=block';

  /// Valor do cabeçalho para HTTP Strict Transport Security.
  static const String headerHsts = 'max-age=31536000; includeSubDomains';

  /// Nome do cabeçalho para Content Security Policy.
  static const String headerContentSecurityPolicy = 'Content-Security-Policy';
  /// Política CSP restritiva padrão.
  static const String headerCsp =
      "default-src 'self'; script-src 'self'; object-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'self'; frame-ancestors 'none';";
  /// Variante sandbox da política CSP restritiva padrão.
  static const String headerValueCspDefault =
      "default-src 'none'; frame-ancestors 'none'; sandbox";

  /// Nome do cabeçalho para Cross-Origin Resource Sharing.
  static const String headerAccessControlAllowOrigin = 'Access-Control-Allow-Origin';
  /// Fallback padrão de origem CORS.
  static const String headerValueCorsWildcard = '*';

  /// Nome do cabeçalho para controle de cache HTTP.
  static const String headerCacheControl = 'Cache-Control';
  /// Valor de controle de cache que proíbe a persistência de respostas sensíveis.
  static const String headerValueNoStore = 'no-store, no-cache, must-revalidate, max-age=0';

  /// Nome do cabeçalho para controle de cache pragma HTTP 1.0.
  static const String headerPragma = 'no-cache';

  // ─── CONTROLES DE DISPONIBILIDADE DO SERVIDOR FAIL-CLOSED ───

  /// Intervalo entre verificações periódicas de saúde dos servidores (segundos).
  static const int serverHealthCheckIntervalSeconds = 5;

  /// Timeout máximo de cada probe /health antes de considerar o servidor offline (segundos).
  static const int serverHealthCheckTimeoutSeconds = 3;

  /// Número de falhas consecutivas necessárias para acionar o bloqueio imediato.
  static const int serverHealthMaxConsecutiveFailures = 1;

  /// Intervalo de heartbeat como Duration.
  static const Duration serverHealthCheckInterval =
      Duration(seconds: serverHealthCheckIntervalSeconds);

  /// Timeout de probe /health como Duration.
  static const Duration serverHealthCheckTimeout =
      Duration(seconds: serverHealthCheckTimeoutSeconds);
}
