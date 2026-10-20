// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/student_view/student_messages/domain/entities/academic_message.dart';
import 'package:pi_iv_time3/features/student_view/student_messages/presentation/controllers/student_messages_controller.dart';
import 'package:pi_iv_time3/features/student_view/student_messages/presentation/pages/student_messages_page.dart';
import 'package:pi_iv_time3/features/student_view/student_secretariat/presentation/controllers/student_secretariat_controller.dart';
import 'package:pi_iv_time3/features/student_view/student_secretariat/presentation/pages/student_secretariat_page.dart';

void main() {
  group('StudentMessagesController & StudentMessagesPage', () {
    test('Filtra comunicados por categoria e busca por termo', () {
      final controller = StudentMessagesController();
      expect(controller.filteredMessages.length, 5);

      controller.setFilter(MessageFilter.institutional);
      expect(controller.filteredMessages.length, 2);

      controller.setFilter(MessageFilter.discipline);
      expect(controller.filteredMessages.length, 3);

      controller.setFilter(MessageFilter.all);
      controller.setSearchQuery('Carlos Eduardo');
      expect(controller.filteredMessages.length, 1);
      expect(
        controller.filteredMessages.first.title,
        contains('Diagrama UML'),
      );
    });

    testWidgets('Renderiza Central de Mensagens & Comunicados e permite filtrar',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentMessagesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Central de Mensagens & Comunicados'),
        findsOneWidget,
      );
      expect(
        find.text('Período Oficial de Validação de Atividades Complementares 2026/2'),
        findsOneWidget,
      );

      // Filtra por Secretaria & Reitoria
      await tester.tap(find.byKey(const Key('filter_institutional')));
      await tester.pumpAndSettle();

      expect(
        find.text('Manutenção Preventiva dos Ambientes Virtuais de Aprendizagem'),
        findsOneWidget,
      );
      expect(
        find.text('Feedback da Sprint 1 e Orientações para o Diagrama UML'),
        findsNothing,
      );
    });
  });

  group('StudentSecretariatController & StudentSecretariatPage', () {
    test('Adiciona novo protocolo de requerimento', () {
      final controller = StudentSecretariatController();
      expect(controller.protocols.length, 1);
      expect(controller.protocolCountLabel, '1 requerimento registrado');

      controller.addProtocolRequest(
        subjectType: 'Segunda Chamada de Prova',
        componentObject: 'Cálculo Numérico',
      );

      expect(controller.protocols.length, 2);
      expect(controller.protocolCountLabel, '2 requerimentos registrados');
      expect(controller.protocols.first.protocolCode, 'PROT-2026/8836');
    });

    testWidgets(
        'Renderiza Secretaria Virtual & Requerimentos, Prontuário e Tabela de Protocolos',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentSecretariatPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Secretaria Virtual & Requerimentos'),
        findsOneWidget,
      );
      expect(
        find.text('Prontuário Acadêmico Regular'),
        findsOneWidget,
      );
      expect(
        find.text('2024.1.00892'),
        findsOneWidget,
      );
      expect(
        find.text('PROT-2026/8835'),
        findsOneWidget,
      );

      // Abre modal de Parecer
      await tester.tap(find.byKey(const Key('view_opinion_PROT-2026/8835')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Parecer — PROT-2026/8835'),
        findsOneWidget,
      );
    });
  });
}
