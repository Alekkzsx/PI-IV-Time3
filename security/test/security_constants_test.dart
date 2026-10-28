// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:agmrm_security/security.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityConstants - Validação das Invariantes Institucionais (M1)', () {
    test('Limites de Força Bruta e Lockout (R2)', () {
      expect(SecurityConstants.maxFailedLoginAttempts, equals(5));
      expect(SecurityConstants.lockoutDurationSeconds, equals(30));
      expect(SecurityConstants.lockoutDuration, equals(const Duration(seconds: 30)));
    });

    test('Ciclo de Vida do Token Efêmero (R3)', () {
      expect(SecurityConstants.recoveryTokenTtlSeconds, equals(300));
      expect(SecurityConstants.recoveryTokenTtlMinutes, equals(5));
      expect(SecurityConstants.recoveryTokenTtl, equals(const Duration(seconds: 300)));
      expect(SecurityConstants.maxVerificationAttempts, equals(3));
      expect(SecurityConstants.maxInvalidVerificationAttempts, equals(3));
      expect(SecurityConstants.otpCodeLength, equals(6));
    });

    test('Limites de Entropia e Comprimento de Senha (R3)', () {
      expect(SecurityConstants.minPasswordLength, equals(8));
      expect(SecurityConstants.maxPasswordLength, equals(128));
      expect(SecurityConstants.minPasswordEntropyScore, equals(3));
      expect(SecurityConstants.minRequiredEntropyScore, equals(3));
      expect(SecurityConstants.maxPasswordEntropyScore, equals(4));
      expect(SecurityConstants.maxEntropyScore, equals(4));
    });

    test('Limites de Sanitização e Payload Ceiling (R2, R4)', () {
      expect(SecurityConstants.minIdentityLength, equals(3));
      expect(SecurityConstants.maxIdentityLength, equals(32));
      expect(SecurityConstants.maxEmailLength, equals(254));
      expect(SecurityConstants.maxRequestBodySizeBytes, equals(65536));
      expect(SecurityConstants.maxBodySizeKb, equals(64));
      expect(SecurityConstants.bufferChunkSizeBytes, equals(4096));
    });

    test('Mitigação de Ataques de Temporização (R2)', () {
      expect(SecurityConstants.standardizedAuthLatencyMs, equals(1000));
      expect(SecurityConstants.standardAuthLatencyMs, equals(1000));
      expect(SecurityConstants.standardizedAuthLatency, equals(const Duration(milliseconds: 1000)));
      expect(SecurityConstants.standardAuthLatency, equals(const Duration(milliseconds: 1000)));
      expect(SecurityConstants.timingJitterToleranceMs, equals(50));
      expect(SecurityConstants.minDummyWorkIterations, equals(10000));
    });

    test('Parâmetros de Rede e Servidor Padrão (R4)', () {
      expect(SecurityConstants.defaultServerPort, equals(8080));
      expect(SecurityConstants.defaultServerHost, equals('0.0.0.0'));
      expect(SecurityConstants.defaultRequestTimeoutSeconds, equals(30));
      expect(SecurityConstants.corsMaxAgeSeconds, equals(86400));
    });

    test('Constantes de Headers HTTP Defensivos (R4)', () {
      expect(SecurityConstants.headerXContentTypeOptions, equals('X-Content-Type-Options'));
      expect(SecurityConstants.headerContentTypeOptions, equals('nosniff'));
      expect(SecurityConstants.headerValueNosniff, equals('nosniff'));
      expect(SecurityConstants.headerXFrameOptions, equals('X-Frame-Options'));
      expect(SecurityConstants.headerFrameOptions, equals('DENY'));
      expect(SecurityConstants.headerValueDeny, equals('DENY'));
      expect(SecurityConstants.headerXssProtection, equals('1; mode=block'));
      expect(SecurityConstants.headerHsts, contains('max-age=31536000'));
      expect(SecurityConstants.headerContentSecurityPolicy, equals('Content-Security-Policy'));
      expect(SecurityConstants.headerCsp, contains("default-src 'self'"));
      expect(SecurityConstants.headerValueCspDefault, contains("default-src 'none'"));
      expect(SecurityConstants.headerAccessControlAllowOrigin, equals('Access-Control-Allow-Origin'));
      expect(SecurityConstants.headerValueCorsWildcard, equals('*'));
      expect(SecurityConstants.headerCacheControl, equals('Cache-Control'));
      expect(SecurityConstants.headerValueNoStore, contains('no-store'));
      expect(SecurityConstants.headerPragma, equals('no-cache'));
    });
  });
}
