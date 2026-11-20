// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:agmrm_security/student/policies/student_security_limits.dart';
import 'package:agmrm_security/student/policies/student_security_policy.dart';

void main() {
  group('StudentSecurityPolicy & Limits Tests', () {
    test('Limites regimentais de arquivos estão dentro das normas (7 MB)', () {
      expect(StudentSecurityLimits.maxDeliveryFileBytes, equals(7 * 1024 * 1024));
      expect(StudentSecurityLimits.maxProtocolAttachmentBytes, equals(7 * 1024 * 1024));
      expect(StudentSecurityLimits.maxFileNameLength, equals(120));
    });

    test('Limites de caracteres previnem buffer overflow e DoS textual', () {
      expect(StudentSecurityLimits.minJustificationLength, equals(5));
      expect(StudentSecurityLimits.maxJustificationLength, equals(2000));
      expect(StudentSecurityLimits.maxDeliveryCommentsLength, equals(1000));
      expect(StudentSecurityLimits.maxForumTitleLength, equals(120));
      expect(StudentSecurityLimits.maxForumBodyLength, equals(4000));
      expect(StudentSecurityLimits.maxPersonalNotesLength, equals(30000));
    });

    test('Parâmetros de janela deslizante e cotas de rate limiting', () {
      expect(StudentSecurityLimits.slidingWindowDuration.inSeconds, equals(60));
      expect(StudentSecurityLimits.maxDeliverySubmissionsPerWindow, equals(3));
      expect(StudentSecurityLimits.maxProtocolSubmissionsPerWindow, equals(2));
      expect(StudentSecurityLimits.maxEnrollmentDeclarationsPerWindow, equals(2));
      expect(StudentSecurityLimits.maxForumTopicsPerWindow, equals(3));
    });

    test('Whitelist de extensões de entrega contém formatos acadêmicos essenciais', () {
      expect(StudentSecurityPolicy.allowedDeliveryExtensions.contains('pdf'), isTrue);
      expect(StudentSecurityPolicy.allowedDeliveryExtensions.contains('zip'), isTrue);
      expect(StudentSecurityPolicy.allowedDeliveryExtensions.contains('docx'), isTrue);
      expect(StudentSecurityPolicy.allowedDeliveryExtensions.contains('dart'), isTrue);
      expect(StudentSecurityPolicy.allowedDeliveryExtensions.contains('py'), isTrue);
    });

    test('Whitelist de protocolos de secretaria é restrita a PDF e imagens rasterizadas', () {
      expect(StudentSecurityPolicy.allowedProtocolExtensions, equals({'pdf', 'png', 'jpg', 'jpeg'}));
      expect(StudentSecurityPolicy.allowedProtocolExtensions.contains('svg'), isFalse);
      expect(StudentSecurityPolicy.allowedProtocolExtensions.contains('exe'), isFalse);
    });

    test('Blacklist de extensões perigosas bloqueia executáveis, scripts e vetores XSS', () {
      for (final ext in ['exe', 'bat', 'cmd', 'sh', 'php', 'svg', 'xhtml', 'jar', 'apk']) {
        expect(StudentSecurityPolicy.blockedDangerousExtensions.contains(ext), isTrue,
            reason: 'Extensão $ext deve ser sumariamente bloqueada');
      }
    });

    test('Whitelist de hosts Git homologados protege contra domínios arbitrários', () {
      expect(StudentSecurityPolicy.trustedGitHosts.contains('github.com'), isTrue);
      expect(StudentSecurityPolicy.trustedGitHosts.contains('gitlab.com'), isTrue);
      expect(StudentSecurityPolicy.trustedGitHosts.contains('gitlab.puc-campinas.edu.br'), isTrue);
    });
  });
}
