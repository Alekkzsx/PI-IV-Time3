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
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import '../../helpers/student_fixtures.dart';

class _ProtocolDataSource extends StudentRemoteDataSource {
  final List<Map<String, dynamic>> _protocols = [];

  @override
  Future<StudentDashboardSnapshot> getBootstrap() async =>
      StudentDashboardSnapshot.fromJson({
        'studentInfo': {
          'name': 'Test Student',
          'ra': StudentFixtures.studentRa,
        },
        'stats': {'activeDisciplines': 0},
        'protocols': _protocols,
      });

  @override
  Future<Map<String, dynamic>> submitProtocol({
    required String requestType,
    required String targetComponent,
    required String justification,
    String? attachmentName,
    String? attachmentBase64,
  }) async {
    final protocol = <String, dynamic>{
      'protocolCode': 'PROT-TEST-001',
      'submittedAt': '03/11/2026',
      'subjectType': requestType,
      'componentObject': targetComponent,
      'status': 'pending',
      'officialOpinion': 'Aguardando análise da Secretaria Acadêmica.',
      'justification': justification,
      'attachmentName': attachmentName,
    };
    _protocols.add(protocol);
    return protocol;
  }
}

class _MessagesDataSource extends StudentRemoteDataSource {
  @override
  Future<StudentDashboardSnapshot> getBootstrap() async =>
      StudentDashboardSnapshot.fromJson({
        'studentInfo': {
          'name': 'Test Student',
          'ra': StudentFixtures.studentRa,
        },
        'stats': {'activeDisciplines': 0},
        'messages': [
          {
            'id': 'msg-inst-1',
            'category': 'institutional',
            'sender': 'Secretaria',
            'title': 'Prazo de matrícula',
            'body': 'Confira o prazo de matrícula.',
          },
          {
            'id': 'msg-inst-2',
            'category': 'institutional',
            'sender': 'Coordenação',
            'title': 'Manutenção do portal',
            'body': 'O portal passará por manutenção.',
          },
          {
            'id': 'msg-disc-1',
            'category': 'discipline',
            'sender': 'Coordenação',
            'title': 'Entrega de projeto',
            'body': 'Confira as orientações da atividade.',
          },
          {
            'id': 'msg-disc-2',
            'category': 'discipline',
            'sender': 'Docente',
            'title': 'Material da aula',
            'body': 'O material está disponível.',
          },
          {
            'id': 'msg-disc-3',
            'category': 'discipline',
            'sender': 'Docente',
            'title': 'Revisão',
            'body': 'A revisão será na próxima aula.',
          },
        ],
      });
}

void main() {
  group('StudentMessagesController & StudentMessagesPage', () {
    late StudentMessagesController controller;
    late _MessagesDataSource remote;

    setUp(() async {
      AppUserSession.instance.signIn(
        identity: StudentFixtures.studentRa,
        profile: 'aluno',
        accessToken: 'test-student-token',
      );
      addTearDown(AppUserSession.instance.signOut);
      remote = _MessagesDataSource();
      controller = StudentMessagesController(
        remote: remote,
        portalController: StudentPortalController.withRemoteDataSource(remote),
      );
      addTearDown(controller.dispose);
      await controller.loadFromServer();
    });

    test('Filtra comunicados carregados do painel remoto', () {
      expect(controller.filteredMessages.length, 5);

      controller.setFilter(MessageFilter.institutional);
      expect(controller.filteredMessages.length, 2);

      controller.setFilter(MessageFilter.discipline);
      expect(controller.filteredMessages.length, 3);

      controller.setFilter(MessageFilter.all);
      controller.setSearchQuery('Coordenação');
      expect(controller.filteredMessages.length, 1);
      expect(controller.filteredMessages.first.title, 'Manutenção do portal');
    });

    testWidgets(
      'Renderiza Central de Mensagens & Comunicados e permite filtrar',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StudentMessagesPage(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Central de Mensagens & Comunicados'), findsOneWidget);
        expect(find.text('Prazo de matrícula'), findsOneWidget);

        // Filtra por Secretaria & Reitoria
        await tester.tap(find.byKey(const Key('filter_institutional')));
        await tester.pumpAndSettle();

        expect(find.text('Manutenção do portal'), findsOneWidget);
        expect(find.text('Entrega de projeto'), findsNothing);
      },
    );
  });

  group('StudentSecretariatController & StudentSecretariatPage', () {
    setUp(() {
      AppUserSession.instance.signIn(
        identity: StudentFixtures.studentRa,
        profile: 'aluno',
        accessToken: 'test-student-token',
      );
      addTearDown(AppUserSession.instance.signOut);
    });

    test('Adiciona novo protocolo de requerimento', () async {
      final remote = _ProtocolDataSource();
      final portalController = StudentPortalController.withRemoteDataSource(
        remote,
      );
      final controller = StudentSecretariatController(
        remoteDataSource: remote,
        portalController: portalController,
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
            ra: StudentFixtures.studentRa,
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
            home: Scaffold(
              body: StudentSecretariatPage(controller: controller),
            ),
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
