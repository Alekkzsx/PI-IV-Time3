// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

/// Invariant security constants, thresholds, and timeout configurations
/// for the AGMRM Enterprise Defense-in-Depth Architecture.
abstract final class SecurityConstants {
  // Private constructor to prevent instantiation
  SecurityConstants._();

  // ─── BRUTE-FORCE & LOCKOUT CONTROLS (R2) ───

  /// Maximum consecutive failed login attempts before temporary lockout.
  static const int maxFailedLoginAttempts = 5;

  /// Duration of temporary account lockout in seconds.
  static const int lockoutDurationSeconds = 30;

  /// Lockout duration as a typed Duration object.
  static const Duration lockoutDuration = Duration(seconds: lockoutDurationSeconds);

  // ─── EPHEMERAL RECOVERY TOKEN LIFECYCLE (R3) ───

  /// Time-To-Live (TTL) for ephemeral password recovery tokens in seconds (5 minutes).
  static const int recoveryTokenTtlSeconds = 300;

  /// Default token TTL alias.
  static const int defaultTokenTtlSeconds = recoveryTokenTtlSeconds;

  /// Recovery token TTL in minutes.
  static const int recoveryTokenTtlMinutes = 5;

  /// Ephemeral token TTL as a typed Duration object.
  static const Duration recoveryTokenTtl = Duration(seconds: recoveryTokenTtlSeconds);

  /// Maximum invalid OTP verification attempts before token session revocation.
  static const int maxVerificationAttempts = 3;

  /// Maximum invalid OTP verification attempts (alias for consistency across specs).
  static const int maxInvalidVerificationAttempts = 3;

  /// Maximum OTP verification attempts alias.
  static const int maxOtpVerificationAttempts = maxVerificationAttempts;

  /// Length of the numeric OTP verification code.
  static const int otpCodeLength = 6;

  // ─── PASSWORD ENTROPY BOUNDS (R3) ───

  /// Minimum password length required for acceptance.
  static const int minPasswordLength = 8;

  /// Maximum password length to mitigate hashing Denial-of-Service attacks.
  static const int maxPasswordLength = 128;

  /// Minimum entropy score required to enable reset password submission (out of 4).
  static const int minPasswordEntropyScore = 3;

  /// Minimum entropy score required (alias for consistency across specs).
  static const int minRequiredEntropyScore = 3;

  /// Maximum achievable entropy score.
  static const int maxPasswordEntropyScore = 4;

  /// Maximum possible entropy score (alias for consistency across specs).
  static const int maxEntropyScore = 4;

  // ─── INPUT SANITIZATION & PAYLOAD BOUNDARIES (R2, R4) ───

  /// Minimum length for academic identity (RA / Matrícula / ADM).
  static const int minIdentityLength = 3;

  /// Maximum length for academic identity (RA / Matrícula / ADM).
  static const int maxIdentityLength = 32;

  /// RA maximum length alias.
  static const int maxRaLength = maxIdentityLength;

  /// Maximum RFC-compliant email length (RFC 5321).
  static const int maxEmailLength = 254;

  /// Maximum HTTP request payload size in bytes (64 KB ceiling).
  static const int maxRequestBodySizeBytes = 65536;

  /// Maximum HTTP request payload size in kilobytes.
  static const int maxBodySizeKb = 64;

  /// Buffer chunk size in bytes for streaming body readers.
  static const int bufferChunkSizeBytes = 4096;

  // ─── TIMING ATTACK MITIGATION & LATENCY NORMALIZATION (R2) ───

  /// Standardized artificial delay duration for authentication responses (milliseconds).
  static const int standardizedAuthLatencyMs = 1000;

  /// Standardized artificial delay duration alias (milliseconds).
  static const int standardAuthLatencyMs = 1000;

  /// Default auth latency alias (milliseconds).
  static const int defaultAuthLatencyMs = standardizedAuthLatencyMs;

  /// Standardized artificial delay as a typed Duration.
  static const Duration standardizedAuthLatency = Duration(milliseconds: standardizedAuthLatencyMs);

  /// Standardized artificial delay alias as a typed Duration.
  static const Duration standardAuthLatency = Duration(milliseconds: standardAuthLatencyMs);

  /// Timing jitter tolerance in milliseconds.
  static const int timingJitterToleranceMs = 50;

  /// Default auth jitter tolerance alias.
  static const int defaultAuthJitterMs = timingJitterToleranceMs;

  /// Minimum dummy work iterations for constant-time simulation on non-existent identities.
  static const int minDummyWorkIterations = 10000;

  // ─── NETWORK, SERVER & CACHE DEFAULTS (R4) ───

  /// Default HTTP server binding port.
  static const int defaultServerPort = 8080;

  /// Default HTTP server host address.
  static const String defaultServerHost = '0.0.0.0';

  /// Default HTTP read/idle timeout in seconds.
  static const int defaultRequestTimeoutSeconds = 30;

  /// CORS pre-flight cache max age in seconds (24 hours).
  static const int corsMaxAgeSeconds = 86400;

  // ─── HTTP DEFENSIVE SECURITY HEADERS (R4) ───

  /// Header name for MIME sniffing prevention.
  static const String headerXContentTypeOptions = 'X-Content-Type-Options';
  /// Header value enforcing MIME sniffing prohibition.
  static const String headerContentTypeOptions = 'nosniff';
  /// Header value enforcing MIME sniffing prohibition (alias).
  static const String headerValueNosniff = 'nosniff';

  /// Header name for clickjacking defense.
  static const String headerXFrameOptions = 'X-Frame-Options';
  /// Header value denying framing in iframes.
  static const String headerFrameOptions = 'DENY';
  /// Header value denying framing in iframes (alias).
  static const String headerValueDeny = 'DENY';

  /// Header name for XSS protection.
  static const String headerXssProtection = '1; mode=block';

  /// Header value for HTTP Strict Transport Security.
  static const String headerHsts = 'max-age=31536000; includeSubDomains';

  /// Header name for Content Security Policy.
  static const String headerContentSecurityPolicy = 'Content-Security-Policy';
  /// Standard restrictive CSP policy.
  static const String headerCsp =
      "default-src 'self'; script-src 'self'; object-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'self'; frame-ancestors 'none';";
  /// Standard restrictive CSP policy sandbox variant.
  static const String headerValueCspDefault =
      "default-src 'none'; frame-ancestors 'none'; sandbox";

  /// Header name for Cross-Origin Resource Sharing.
  static const String headerAccessControlAllowOrigin = 'Access-Control-Allow-Origin';
  /// Standard CORS origin fallback.
  static const String headerValueCorsWildcard = '*';

  /// Header name for HTTP cache control.
  static const String headerCacheControl = 'Cache-Control';
  /// Cache control value prohibiting persistence of sensitive responses.
  static const String headerValueNoStore = 'no-store, no-cache, must-revalidate, max-age=0';

  /// Header name for HTTP 1.0 pragma cache control.
  static const String headerPragma = 'no-cache';
}
