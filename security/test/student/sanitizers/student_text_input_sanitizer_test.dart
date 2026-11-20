// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:agmrm_security/student/sanitizers/student_text_input_sanitizer.dart';

void main() {
  group('StudentTextInputSanitizer Tests', () {
    test('Higieniza comentários de entrega removendo tags HTML e caracteres de controle', () {
      final input = 'Prof, segue o trabalho.<script>alert("xss")</script> Obrigado!\x00';
      final sanitized = StudentTextInputSanitizer.sanitizeDeliveryComments(input);

      expect(sanitized, equals('Prof, segue o trabalho.alert("xss") Obrigado!'));
      expect(sanitized.contains('<script>'), isFalse);
      expect(sanitized.contains('\x00'), isFalse);
    });

    test('Limita o comprimento de comentários respeitando o teto de 1000 caracteres', () {
      final longText = 'A' * 1500;
      final sanitized = StudentTextInputSanitizer.sanitizeDeliveryComments(longText);

      expect(sanitized.length, equals(1000));
    });

    test('Sanitiza justificativa de secretaria neutralizando injeções HTML e limitando a 2000 chars', () {
      final input = 'Solicito dispensa médica. <b>Comprovante em anexo</b> <iframe src="evil.com"></iframe>';
      final sanitized = StudentTextInputSanitizer.sanitizeProtocolJustification(input);

      expect(sanitized, equals('Solicito dispensa médica. Comprovante em anexo'));
      expect(sanitized.contains('<iframe'), isFalse);
      expect(sanitized.contains('<b>'), isFalse);

      final hugeText = 'Justificativa ' * 300;
      final truncated = StudentTextInputSanitizer.sanitizeProtocolJustification(hugeText);
      expect(truncated.length, lessThanOrEqualTo(2000));
    });
  });
}
