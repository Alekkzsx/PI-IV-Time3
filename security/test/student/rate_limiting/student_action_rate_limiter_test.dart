// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:agmrm_security/student/rate_limiting/student_action_type.dart';
import 'package:agmrm_security/student/rate_limiting/student_action_rate_limiter.dart';

void main() {
  group('StudentActionRateLimiter Tests', () {
    late StudentActionRateLimiter limiter;

    setUp(() {
      limiter = StudentActionRateLimiter.instance;
      limiter.resetAll();
    });

    test('Permite até 3 entregas de atividade consecutivas na mesma janela', () {
      final now = DateTime(2026, 11, 7, 10, 0, 0);

      expect(limiter.canExecute(StudentActionType.submitDelivery, now: now), isTrue);
      expect(limiter.recordAction(StudentActionType.submitDelivery, now: now), isTrue);

      expect(limiter.recordAction(StudentActionType.submitDelivery, now: now.add(const Duration(seconds: 5))), isTrue);
      expect(limiter.recordAction(StudentActionType.submitDelivery, now: now.add(const Duration(seconds: 10))), isTrue);

      // 4ª tentativa dentro da janela de 60s deve ser bloqueada
      expect(limiter.canExecute(StudentActionType.submitDelivery, now: now.add(const Duration(seconds: 15))), isFalse);
      expect(limiter.recordAction(StudentActionType.submitDelivery, now: now.add(const Duration(seconds: 15))), isFalse);
    });

    test('Calcula cooldown restante com exatidão após atingir o limite', () {
      final now = DateTime(2026, 11, 7, 10, 0, 0);

      // Protocolo permite max 2 por janela
      limiter.recordAction(StudentActionType.issueProtocol, now: now);
      limiter.recordAction(StudentActionType.issueProtocol, now: now.add(const Duration(seconds: 10)));

      // No segundo 20, faltam 40s para expirar a primeira ação do segundo 0
      final cooldown = limiter.getRemainingCooldownSeconds(
        StudentActionType.issueProtocol,
        now: now.add(const Duration(seconds: 20)),
      );
      expect(cooldown, equals(40));
    });

    test('Libera novo slot automaticamente após expiração da janela de 60 segundos', () {
      final now = DateTime(2026, 11, 7, 10, 0, 0);

      limiter.recordAction(StudentActionType.createForumTopic, now: now);
      limiter.recordAction(StudentActionType.createForumTopic, now: now.add(const Duration(seconds: 1)));
      limiter.recordAction(StudentActionType.createForumTopic, now: now.add(const Duration(seconds: 2)));

      // Bloqueado aos 30s
      expect(limiter.canExecute(StudentActionType.createForumTopic, now: now.add(const Duration(seconds: 30))), isFalse);

      // Liberado aos 61s (a 1ª ação do segundo 0 expirou)
      final afterWindow = now.add(const Duration(seconds: 61));
      expect(limiter.canExecute(StudentActionType.createForumTopic, now: afterWindow), isTrue);
      expect(limiter.recordAction(StudentActionType.createForumTopic, now: afterWindow), isTrue);
    });

    test('Isolamento entre tipos de ação (esgotar entregas não afeta emissão de protocolos)', () {
      final now = DateTime(2026, 11, 7, 10, 0, 0);

      // Esgota entregas
      limiter.recordAction(StudentActionType.submitDelivery, now: now);
      limiter.recordAction(StudentActionType.submitDelivery, now: now);
      limiter.recordAction(StudentActionType.submitDelivery, now: now);
      expect(limiter.canExecute(StudentActionType.submitDelivery, now: now), isFalse);

      // Protocolos continuam liberados
      expect(limiter.canExecute(StudentActionType.issueProtocol, now: now), isTrue);
    });
  });
}
