// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/network/authenticated_api_client.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/student/messages/domain/entities/academic_message.dart';
import 'package:pi_iv_time3/features/student/messages/presentation/controllers/student_messages_controller.dart';
import 'package:pi_iv_time3/features/student/messages/presentation/pages/student_messages_page.dart';
import 'package:pi_iv_time3/features/student/secretariat/presentation/controllers/student_secretariat_controller.dart';
import 'package:pi_iv_time3/features/student/secretariat/presentation/pages/student_secretariat_page.dart';
import 'package:pi_iv_time3/features/student/secretariat/domain/entities/academic_record_summary.dart';
import 'package:pi_iv_time3/features/student/secretariat/domain/entities/protocol_request.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_remote_data_source.dart';

class _ProtocolDataSource extends StudentRemoteDataSource {
  @override
  Future<Map<String, dynamic>> submitProtocol({
    required String requestType,
    required String targetComponent,
    required String justification,
    String? attachmentName,
    String? attachmentBase64,
  }) async => {
    'protocolCode': 'PROT-TEST-001',
    'submittedAt': '03/11/2026',
    'subjectType': requestType,
    'componentObject': targetComponent,
    'status': 'pending',
    'officialOpinion': 'Aguardando análise da Secretaria Acadêmica.',
    'justification': justification,
    'attachmentName': attachmentName,
  };
}

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
      expect(controller.filteredMessages.first.title, contains('Diagrama UML'));
    });

    testWidgets(
      'Renderiza Central de Mensagens & Comunicados e permite filtrar',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: StudentMessagesPage())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Central de Mensagens & Comunicados'), findsOneWidget);
        expect(
          find.text(
            'Período Oficial de Validação de Atividades Complementares 2026/2',
          ),
          findsOneWidget,
        );

        // Filtra por Secretaria & Reitoria
        await tester.tap(find.byKey(const Key('filter_institutional')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Manutenção Preventiva dos Ambientes Virtuais de Aprendizagem',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Feedback da Sprint 1 e Orientações para o Diagrama UML'),
          findsNothing,
        );
      },
    );
  });

  group('StudentSecretariatController & StudentSecretariatPage', () {
    setUp(() {
      AppUserSession.instance.signIn(
        identity: '2024.1.00892',
        profile: 'aluno',
      );
      addTearDown(AppUserSession.instance.signOut);
    });

    test('Adiciona novo protocolo de requerimento', () async {
      final controller = StudentSecretariatController(
        remoteDataSource: _ProtocolDataSource(),
      );
      expect(controller.protocols, isEmpty);

      await controller.addProtocolRequest(
        subjectType: 'Segunda Chamada de Prova',
        componentObject: 'Cálculo Numérico',
        justification: 'Solicito segunda chamada conforme comprovante anexado.',
      );

      expect(controller.protocols, hasLength(1));
      expect(controller.protocolCountLabel, '1 requerimento registrado');
      expect(controller.protocols.first.protocolCode, 'PROT-TEST-001');
    });

    test('Perfil docente não pode criar protocolo de aluno', () async {
      final controller = StudentSecretariatController();
      AppUserSession.instance.signIn(identity: 'DOC-88410', profile: 'docente');

      await expectLater(
        controller.addProtocolRequest(
          subjectType: 'Segunda Chamada de Prova',
          componentObject: 'Cálculo Numérico',
          justification: 'Solicito segunda chamada.',
        ),
        throwsA(isA<ApiException>()),
      );

      expect(controller.protocols, isEmpty);
    });

    testWidgets(
      'Renderiza Secretaria Virtual & Requerimentos, Prontuário e Tabela de Protocolos',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final controller = StudentSecretariatController(
          recordSummary: const AcademicRecordSummary(
            ra: '2024.1.00892',
            course: 'Engenharia de Software',
            academicIndex: '8.8',
            completedWorkload: '40h / 80h',
            activeEnrollmentBadge: 'MATRÍCULA ATIVA',
          ),
          initialProtocols: const [
            ProtocolRequest(
              protocolCode: 'PROT-TEST-001',
              submittedAt: '03/11/2026',
              subjectType: 'Horas Complementares',
              componentObject: 'Curso extracurricular',
              status: ProtocolStatus.pending,
              officialOpinion: 'Aguardando análise.',
              justification: 'Protocolo de teste.',
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StudentSecretariatPage(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Secretaria Virtual & Requerimentos'), findsOneWidget);
        expect(find.text('Prontuário Acadêmico Regular'), findsOneWidget);
        expect(find.text('2024.1.00892'), findsOneWidget);
        expect(find.text('PROT-TEST-001'), findsOneWidget);

        // Abre modal de Parecer
        await tester.tap(find.byKey(const Key('view_opinion_PROT-TEST-001')));
        await tester.pumpAndSettle();

        expect(find.text('Parecer Formal:'), findsOneWidget);
      },
    );
  });
}
