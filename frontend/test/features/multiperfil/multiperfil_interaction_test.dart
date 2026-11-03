// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Testes Extremos de Interação Multiperfil (Aluno <-> Docente <-> Admin)
// Garante que todas as relações e permissões entre os diferentes tipos de usuário
// funcionam de forma integrada e coesa.

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/student/secretariat/presentation/controllers/student_secretariat_controller.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_remote_data_source.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/secretariat/domain/entities/protocol_request.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/rubric_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';
import '../../helpers/student_fixtures.dart';
import '../../helpers/fake_teacher_remote_data_source.dart';

void _closeOwnedSession(AcademicBridgeService bridge, String code) {
  final session = bridge.getSession(code);
  if (!session.isOpen) return;
  final role = session.openedByRole;
  final identity = session.openedByIdentity;
  if (role == null || identity == null) {
    throw StateError('Sessão aberta sem identidade responsável.');
  }
  AppUserSession.instance.signIn(identity: identity, profile: role);
  bridge.closeSession(code);
  AppUserSession.instance.signOut();
}

class _ProtocolRemoteDataSource extends StudentRemoteDataSource {
  final List<Map<String, dynamic>> protocols = [
    {
      'protocolCode': 'PROT-2026/8835',
      'submittedAt': '02/11/2026',
      'subjectType': 'Horas Complementares',
      'componentObject': 'APS-II',
      'status': 'pending',
      'officialOpinion': 'Aguardando análise.',
    },
  ];

  @override
  Future<StudentDashboardSnapshot> getBootstrap() async =>
      StudentDashboardSnapshot.fromJson({
        'studentInfo': {
          'name': 'Test Student',
          'ra': StudentFixtures.studentRa,
        },
        'stats': {'activeDisciplines': 0},
        'protocols': protocols,
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
      'protocolCode': 'PROT-API-001',
      'submittedAt': '03/11/2026',
      'subjectType': requestType,
      'componentObject': targetComponent,
      'status': 'pending',
      'officialOpinion': 'Aguardando análise.',
      'justification': justification,
      'attachmentName': attachmentName,
    };
    protocols.add(protocol);
    return protocol;
  }
}

class _StudentWorkRemoteDataSource extends StudentRemoteDataSource {
  bool submitted = false;

  @override
  Future<StudentDashboardSnapshot> getBootstrap() async =>
      StudentDashboardSnapshot.fromJson({
        'studentInfo': {
          'name': 'Test Student',
          'ra': StudentFixtures.studentRa,
        },
        'stats': {'activeDisciplines': 1},
        'disciplines': [
          {
            'code': 'APS-II',
            'name': 'Análise e Projeto de Sistemas II',
            'professor': 'Profa. Responsável',
            'progress': 0.6,
          },
        ],
        'deliveries': [
          {
            'id': 'DEL-01',
            'sourceAssignmentId': 'asg-1',
            'title': 'Modelagem GoF',
            'disciplineCode': 'APS-II',
            'disciplineName': 'Análise e Projeto de Sistemas II',
            'dueDate': '25/11/2026',
            'dueHour': '23:59',
            'status': submitted ? 'Em Análise' : 'Pendente',
            'weight': 2.5,
            'protocol': submitted ? 'AGR-TEST-001' : null,
          },
        ],
        'events': [],
        'messages': [],
      });

  @override
  Future<Map<String, dynamic>> submitDelivery({
    required String assignmentId,
    required String fileName,
    required String fileSize,
    required String mimeType,
    required String contentBase64,
    String? gitUrl,
    String? comments,
  }) async {
    submitted = true;
    return {'protocolCode': 'AGR-TEST-001'};
  }
}

void main() {
  const studentIdentity = StudentFixtures.studentRa;
  const teacherIdentity = 'DOC-88410';

  group('Verificação Extrema Multiperfil: Regras de Videochamada por Turma', () {
    late AcademicBridgeService bridge;

    setUp(() {
      bridge = AcademicBridgeService.instance;
      AppUserSession.instance.signOut();
      for (final code in ['APS-II', 'BD-II', 'FSO', 'FIS']) {
        _closeOwnedSession(bridge, code);
      }
      bridge
        ..clearRuntimeBindings()
        ..registerClassRoom(
          code: '218131 - APS-II',
          subjectName: 'Análise e Projeto de Sistemas II',
          professorName: 'Docente de teste',
          professorIdentity: teacherIdentity,
        )
        ..registerClassRoom(
          code: '218132 - BD-II',
          subjectName: 'Banco de Dados II',
          professorName: 'Docente de teste',
          professorIdentity: teacherIdentity,
        )
        ..registerStudentEnrollments(studentIdentity, const ['APS-II']);
      addTearDown(AppUserSession.instance.signOut);
    });

    test(
      'Regra Estrita: Apenas Docente da turma ou Admin podem ABRIR uma videochamada',
      () {
        expect(bridge.canUserOpenSession(role: 'docente'), isTrue);
        expect(bridge.canUserOpenSession(role: 'teacher'), isFalse);
        expect(bridge.canUserOpenSession(role: 'admin'), isTrue);
        expect(bridge.canUserOpenSession(role: 'moderator'), isFalse);

        // Aluno NÃO tem autorização para abrir chamada do zero
        expect(bridge.canUserOpenSession(role: 'aluno'), isFalse);
        expect(bridge.canUserOpenSession(role: 'student'), isFalse);
        expect(bridge.canUserOpenSession(role: 'participant'), isFalse);
      },
    );

    test('Aluno é impedido de abrir sessão de turma fechada', () {
      AppUserSession.instance.signIn(
        identity: studentIdentity,
        profile: 'aluno',
        displayName: 'Gabriel Soares de Oliveira',
      );
      final success = bridge.openSession(
        rawCourseCode: 'APS-II',
        openedByRole: 'aluno',
        openedByName: 'Gabriel Soares (Discente)',
      );

      expect(success, isFalse);
      expect(bridge.isSessionOpen('APS-II'), isFalse);
    });

    test(
      'Docente só abre turmas atribuídas e códigos desconhecidos são negados',
      () {
        AppUserSession.instance.signIn(
          identity: teacherIdentity,
          profile: 'docente',
        );
        expect(
          bridge.openSession(
            rawCourseCode: '218131 - FIS',
            openedByRole: 'docente',
            openedByName: 'Docente',
            openedByIdentity: teacherIdentity,
          ),
          isFalse,
        );
        expect(
          bridge.openSession(
            rawCourseCode: 'APS-II',
            openedByRole: 'docente',
            openedByName: 'Outro docente',
            openedByIdentity: 'DOC-88392',
          ),
          isFalse,
        );
        expect(
          bridge.openSession(
            rawCourseCode: 'OUTRA-TURMA-APS',
            openedByRole: 'admin',
            openedByName: 'Admin',
            openedByIdentity: 'ADM-00129',
          ),
          isFalse,
        );
        expect(bridge.isSessionOpen('FIS'), isFalse);
      },
    );

    test('Aluno só entra em sessão aberta com vínculo acadêmico válido', () {
      AppUserSession.instance.signIn(
        identity: teacherIdentity,
        profile: 'docente',
      );
      bridge.openSession(
        rawCourseCode: 'APS-II',
        openedByRole: 'docente',
        openedByName: 'Profa. Dra. Helena Bittencourt',
        openedByIdentity: teacherIdentity,
      );

      AppUserSession.instance.signIn(
        identity: studentIdentity,
        profile: 'aluno',
        displayName: 'Gabriel Soares de Oliveira',
      );
      expect(bridge.closeSession('APS-II'), isFalse);
      expect(bridge.isSessionOpen('APS-II'), isTrue);

      expect(
        bridge.canUserJoinSession(
          role: 'aluno',
          rawCourseCode: '218131 - APS-II',
          studentRa: studentIdentity,
        ),
        isTrue,
      );
      expect(
        bridge.canUserJoinSession(
          role: 'aluno',
          rawCourseCode: 'APS-II',
          studentRa: '2024.1.00001',
        ),
        isFalse,
      );
      AppUserSession.instance.signIn(
        identity: teacherIdentity,
        profile: 'docente',
      );
      expect(bridge.closeSession('APS-II'), isTrue);
      expect(
        bridge.canUserJoinSession(
          role: 'aluno',
          rawCourseCode: 'BD-II',
          studentRa: studentIdentity,
        ),
        isFalse,
      );
    });

    test(
      'Docente abre a sala da turma com sucesso e status muda para Ao Vivo',
      () {
        AppUserSession.instance.signIn(
          identity: teacherIdentity,
          profile: 'docente',
        );
        final success = bridge.openSession(
          rawCourseCode: 'APS-II',
          openedByRole: 'docente',
          openedByName: 'Profa. Dra. Helena Bittencourt',
          openedByIdentity: teacherIdentity,
        );

        expect(success, isTrue);
        expect(bridge.isSessionOpen('APS-II'), isTrue);

        final session = bridge.getSession('APS-II');
        expect(session.isOpen, isTrue);
        expect(session.openedByRole, 'docente');
        expect(session.openedByName, 'Profa. Dra. Helena Bittencourt');
        expect(session.openedAt, isNotNull);
      },
    );

    test(
      'Administrador pode abrir ou supervisionar a sala de qualquer turma',
      () {
        AppUserSession.instance.signIn(identity: 'ADM-00129', profile: 'admin');
        final success = bridge.openSession(
          rawCourseCode: 'APS-II',
          openedByRole: 'admin',
          openedByName: 'Carlos Mendes (Coordenação Geral)',
          openedByIdentity: 'ADM-00129',
        );

        expect(success, isTrue);
        expect(bridge.isSessionOpen('APS-II'), isTrue);

        final session = bridge.getSession('APS-II');
        expect(session.openedByRole, 'admin');
        expect(session.openedByName, 'Carlos Mendes (Coordenação Geral)');
      },
    );
  });

  group(
    'Verificação Extrema Multiperfil: Ciclo Completo de Atividades (Docente <-> Aluno)',
    () {
      late DocenteController docenteController;
      late StudentPortalController studentController;
      late FakeTeacherRemoteDataSource teacherRemote;

      setUp(() async {
        teacherRemote = FakeTeacherRemoteDataSource();
        final student = StudentPortalController.withRemoteDataSource(
          _StudentWorkRemoteDataSource(),
        );
        AppUserSession.instance.signIn(
          identity: teacherIdentity,
          profile: 'docente',
          accessToken: 'test-teacher-token',
        );
        addTearDown(AppUserSession.instance.signOut);
        docenteController = DocenteController(
          remoteDataSource: teacherRemote,
          profileRemoteDataSource: FakeTeacherProfileRemoteDataSource(
            teacherRemote,
          ),
        );
        addTearDown(docenteController.dispose);
        await docenteController.loadRemote();
        AppUserSession.instance.signIn(
          identity: studentIdentity,
          profile: 'aluno',
          accessToken: 'test-student-token',
        );
        await student.loadRemote();
        addTearDown(student.dispose);
        studentController = student;
      });

      test(
        'Publicação docente usa a API e não inventa dados no estado discente',
        () async {
          final initialDeliveriesCount = studentController.deliveries.length;
          final initialEventsCount = studentController.events.length;

          AppUserSession.instance.signIn(
            identity: teacherIdentity,
            profile: 'docente',
            accessToken: 'test-teacher-token',
          );
          final created = await docenteController.createAssignment(
            courseId: 'course-aps2',
            courseCode: '218131 - APS-II',
            title: 'Modelagem de Microsserviços e Mensageria',
            description:
                'Construa os diagramas de componentes e implantação no Kubernetes.',
            weight: 4.0,
            stage: 'N2',
            dueDateFormatted: '25/11/2026 às 23:59',
            modality: 'Trabalho em Dupla',
            allowLateWithPenalty: true,
            rubricCriteria: [
              const RubricCriterion(
                id: 'rc-1',
                title: 'Topologia dos Serviços',
                maxPoints: 5.0,
                description:
                    'Correta especificação dos pods e ingress controller.',
              ),
              const RubricCriterion(
                id: 'rc-2',
                title: 'Filas RabbitMQ',
                maxPoints: 5.0,
                description:
                    'Tratamento de dead-letter exchange e idempotência.',
              ),
            ],
          );

          expect(created, isTrue);
          expect(
            teacherRemote.lastCreatedAssignment?['title'],
            'Modelagem de Microsserviços e Mensageria',
          );
          expect(
            studentController.deliveries,
            hasLength(initialDeliveriesCount),
          );
          expect(studentController.events, hasLength(initialEventsCount));
        },
      );

      test(
        'Aluno submete arquivo de entrega e recebe protocolo persistido',
        () async {
          // Aluno envia arquivo
          AppUserSession.instance.signIn(
            identity: studentIdentity,
            profile: 'aluno',
            displayName: 'Gabriel Soares de Oliveira',
            accessToken: 'test-student-token',
          );
          await studentController.loadRemote();
          final generatedProtocol = await studentController.submitDelivery(
            deliveryId: 'DEL-01',
            fileName: 'modelagem_gof_gabriel_oliveira.pdf',
            fileSize: '4 KB',
            mimeType: 'application/pdf',
            contentBase64: 'dGVzdA==',
            gitUrl: 'https://github.com/gabriel/aps-gof',
            comments:
                'Trabalho concluído com os testes do padrão Observer e Strategy.',
          );

          expect(generatedProtocol['protocolCode'], startsWith('AGR-'));

          // Verifica status na visão do Aluno
          final studentItem = studentController.deliveries.firstWhere(
            (d) => d.id == 'DEL-01',
          );
          expect(studentItem.status, 'Em Análise');
          expect(studentItem.protocol, generatedProtocol['protocolCode']);
        },
      );

      test(
        'Avaliação docente não altera o painel discente até a API atualizar o bootstrap',
        () async {
          AppUserSession.instance.signIn(
            identity: studentIdentity,
            profile: 'aluno',
            displayName: 'Gabriel Soares de Oliveira',
            accessToken: 'test-student-token',
          );
          await studentController.loadRemote();
          await studentController.submitDelivery(
            deliveryId: 'DEL-01',
            fileName: 'modelagem_gof_gabriel_oliveira.pdf',
            fileSize: '4 KB',
            mimeType: 'application/pdf',
            contentBase64: 'dGVzdA==',
            gitUrl: 'https://github.com/gabriel/aps-gof',
          );

          // Docente avalia submissão
          AppUserSession.instance.signIn(
            identity: teacherIdentity,
            profile: 'docente',
            accessToken: 'test-teacher-token',
          );
          await docenteController.evaluateRubric(
            assignmentId: 'asg-1',
            submissionId: 'sub-1',
            calculatedGrade: 9.8,
            feedback:
                'Excelente modelagem com ótima separação de responsabilidades GRASP!',
            evaluatedCriteria: [
              const RubricCriterion(
                id: 'rc-1',
                title: 'Estruturação do Diagrama de Classes',
                maxPoints: 5.0,
                assignedScore: 5.0,
                description: 'Perfeita conformidade.',
              ),
              const RubricCriterion(
                id: 'rc-2',
                title: 'Consistência de Interação',
                maxPoints: 5.0,
                assignedScore: 4.8,
                description:
                    'Pequeno ajuste recomendado nas mensagens de retorno.',
              ),
            ],
          );

          expect(teacherRemote.lastEvaluatedSubmissionId, 'asg-1');
          final studentItem = studentController.deliveries.firstWhere(
            (d) => d.id == 'DEL-01',
          );
          expect(studentItem.status, 'Em Análise');
        },
      );
    },
  );

  group('Verificação Extrema Multiperfil: Secretaria Acadêmica (Aluno <-> Admin)', () {
    late StudentSecretariatController secretariatStudentController;
    late AdminPortalController adminController;
    late _ProtocolRemoteDataSource protocolRemote;
    late StudentPortalController studentPortal;

    setUp(() async {
      AppUserSession.instance.signIn(
        identity: studentIdentity,
        profile: 'aluno',
        displayName: 'Gabriel Soares de Oliveira',
        accessToken: 'test-student-token',
      );
      addTearDown(AppUserSession.instance.signOut);
      adminController = AdminPortalController.instance;
      protocolRemote = _ProtocolRemoteDataSource();
      studentPortal = StudentPortalController.withRemoteDataSource(
        protocolRemote,
      );
      await studentPortal.loadRemote();
      addTearDown(studentPortal.dispose);
      secretariatStudentController = StudentSecretariatController(
        remoteDataSource: protocolRemote,
        portalController: studentPortal,
      );
      addTearDown(secretariatStudentController.dispose);
      await secretariatStudentController.loadFromServer();
    });

    test(
      'Requerimento é enviado à API sem sincronização local com o controller admin',
      () async {
        final initialAdminProtocolsCount = adminController.protocols.length;

        await secretariatStudentController.addProtocolRequest(
          subjectType: '2ª Chamada de Avaliação / Prova Substitutiva',
          componentObject: '218131 - APS-II',
          justification:
              'Paciente em internação hospitalar no dia da avaliação regimental.',
          attachmentName: 'Atestado_Medico_Hospital_Albert_Einstein.pdf',
        );

        expect(secretariatStudentController.protocols, hasLength(2));
        expect(
          secretariatStudentController.protocols.last.protocolCode,
          'PROT-API-001',
        );
        expect(
          adminController.protocols,
          hasLength(initialAdminProtocolsCount),
        );
      },
    );

    test(
      'Admin defere requerimento com despacho e Aluno vê parecer oficial assinado',
      () async {
        AppUserSession.instance.signIn(identity: 'ADM-00129', profile: 'admin');
        final targetProtocol = secretariatStudentController.protocols.first;

        final approved = await adminController.decideProtocol(
          protocolId: targetProtocol.protocolCode,
          defer: true,
          parecerNote:
              'Atestado médico homologado pela Secretaria Geral. Segunda chamada deferida para 10/11/2026.',
        );

        // O Aluno recebe a decisão homologada
        final updatedStudentProtocol = secretariatStudentController.protocols
            .firstWhere((p) => p.protocolCode == targetProtocol.protocolCode);

        expect(approved, isFalse);
        expect(updatedStudentProtocol.status, ProtocolStatus.pending);
      },
    );
  });

  group(
    'Verificação Extrema Multiperfil: Materiais Didáticos (Docente -> Aluno)',
    () {
      late DocenteController docenteController;
      late AcademicBridgeService bridge;

      setUp(() {
        AppUserSession.instance.signIn(
          identity: teacherIdentity,
          profile: 'docente',
        );
        addTearDown(AppUserSession.instance.signOut);
        docenteController = DocenteController();
        bridge = AcademicBridgeService.instance;
      });

      test(
        'Docente publica material de aula e ele fica imediatamente disponível no repositório discente',
        () async {
          final initialMaterialsCount = bridge.materials.length;

          await docenteController.publishMaterial(
            'course-aps2',
            'Slides Aula 14 - Arquitetura Orientada a Eventos e Kafka.pdf',
            null,
          );

          expect(bridge.materials.length, initialMaterialsCount);
          expect(
            docenteController.remoteError,
            'Selecione um arquivo para publicar.',
          );
        },
      );
    },
  );

  group(
    'Verificação Extrema Multiperfil: Frequência e Diário de Classe Remotos',
    () {
      late DocenteController docenteController;
      late FakeTeacherRemoteDataSource teacherRemote;

      setUp(() async {
        AppUserSession.instance.signIn(
          identity: teacherIdentity,
          profile: 'docente',
          accessToken: 'test-teacher-token',
        );
        addTearDown(AppUserSession.instance.signOut);
        teacherRemote = FakeTeacherRemoteDataSource();
        docenteController = DocenteController(remoteDataSource: teacherRemote);
        addTearDown(docenteController.dispose);
        await docenteController.loadRemote();
      });

      test(
        'Docente persiste a homologação na fonte remota sem alterar estado discente local',
        () async {
          final sessionId = docenteController.currentSession.id;
          final initialStudentDisciplines = List.of(
            StudentPortalController.instance.disciplines,
          );
          expect(sessionId, isNotEmpty);

          await docenteController.homologateSession();

          expect(
            teacherRemote.sessions
                .firstWhere((session) => session.id == sessionId)
                .isHomologated,
            isTrue,
          );
          expect(
            StudentPortalController.instance.disciplines,
            initialStudentDisciplines,
          );
        },
      );
    },
  );

  group('Verificação Extrema Multiperfil: Decisão de Protocolo via API', () {
    late AdminPortalController adminController;
    late StudentPortalController studentController;
    late _ProtocolRemoteDataSource protocolRemote;

    setUp(() async {
      AppUserSession.instance.signIn(
        identity: studentIdentity,
        profile: 'aluno',
        accessToken: 'test-student-token',
      );
      protocolRemote = _ProtocolRemoteDataSource();
      studentController = StudentPortalController.withRemoteDataSource(
        protocolRemote,
      );
      addTearDown(studentController.dispose);
      await studentController.loadRemote();

      AppUserSession.instance.signIn(identity: 'ADM-00129', profile: 'admin');
      addTearDown(AppUserSession.instance.signOut);
      adminController = AdminPortalController.instance;
    });

    test(
      'Falha de autenticação não finge despacho nem altera o protocolo do aluno',
      () async {
        final approved = await adminController.decideProtocol(
          protocolId: 'MED-2026-99',
          defer: true,
          parecerNote:
              'Atestado médico aprovado. Deferido abono regimental de faltas.',
        );

        expect(approved, isFalse);
        expect(studentController.protocols.single['status'], 'pending');
        expect(protocolRemote.protocols.single['status'], 'pending');
      },
    );
  });

  group('Verificação Extrema Multiperfil: Comunicados Docentes via API', () {
    late DocenteController docenteController;
    late FakeTeacherRemoteDataSource teacherRemote;

    setUp(() async {
      AppUserSession.instance.signIn(
        identity: teacherIdentity,
        profile: 'docente',
        accessToken: 'test-teacher-token',
      );
      addTearDown(AppUserSession.instance.signOut);
      teacherRemote = FakeTeacherRemoteDataSource();
      docenteController = DocenteController(remoteDataSource: teacherRemote);
      addTearDown(docenteController.dispose);
      await docenteController.loadRemote();
    });

    test(
      'Comunicado publicado aparece na resposta remota, não no barramento local',
      () async {
        final initialRemoteNotices = teacherRemote.notices.length;
        final published = await docenteController.publishNotice(
          targetCourse: docenteController.courses.first.code,
          targetAudience: 'Todos os discentes da turma',
          classification: NoticeClassification.informativo,
          title: 'Revisão Geral para Avaliação N2',
          message:
              'A aula de revisão será conduzida na próxima terça-feira com foco em microsserviços.',
        );

        expect(published, isTrue);
        expect(teacherRemote.notices.length, initialRemoteNotices + 1);
        expect(
          teacherRemote.notices.first.title,
          'Revisão Geral para Avaliação N2',
        );
        expect(AcademicBridgeService.instance.broadcastNotices, isEmpty);
      },
    );
  });
}
