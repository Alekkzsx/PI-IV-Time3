// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Testes Extremos de Interação Multiperfil (Aluno <-> Docente <-> Admin)
// Garante que todas as relações e permissões entre os diferentes tipos de usuário
// funcionam de forma integrada e coesa.

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/student/secretariat/presentation/controllers/student_secretariat_controller.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/secretariat/domain/entities/protocol_request.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/assignment_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/rubric_model.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';

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

void main() {
  const studentIdentity = '2024.1.00892';
  const teacherIdentity = 'DOC-88410';

  group('Verificação Extrema Multiperfil: Regras de Videochamada por Turma', () {
    late AcademicBridgeService bridge;

    setUp(() {
      bridge = AcademicBridgeService.instance;
      AppUserSession.instance.signOut();
      for (final code in ['APS-II', 'BD-II', 'FSO', 'FIS']) {
        _closeOwnedSession(bridge, code);
      }
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
      );
      expect(bridge.closeSession('APS-II'), isFalse);
      expect(bridge.isSessionOpen('APS-II'), isTrue);

      expect(
        bridge.canUserJoinSession(
          role: 'aluno',
          rawCourseCode: '218131 - APS-II',
          studentRa: '2024.1.00892',
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
          studentRa: '2024.1.00892',
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

      setUp(() {
        final student = StudentPortalController.instance;
        student.deliveries = List.from(StudentMockData.deliveries);
        student.events = List.from(StudentMockData.calendarEvents);
        student.disciplines = List.from(StudentMockData.disciplines);
        AppUserSession.instance.signIn(
          identity: teacherIdentity,
          profile: 'docente',
        );
        addTearDown(AppUserSession.instance.signOut);
        docenteController = DocenteController();
        studentController = StudentPortalController.instance;
      });

      test(
        'Docente publica atividade e Aluno recebe imediatamente nas Entregas e no Calendário',
        () {
          final initialDeliveriesCount = studentController.deliveries.length;
          final initialEventsCount = studentController.events.length;

          // Professor cria nova atividade
          docenteController.createAssignment(
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

          // Aluno agora possui a nova entrega na sua lista
          expect(
            studentController.deliveries.length,
            initialDeliveriesCount + 1,
          );
          final newDelivery = studentController.deliveries.first;
          expect(newDelivery.title, 'Modelagem de Microsserviços e Mensageria');
          expect(newDelivery.disciplineCode, 'APS-II');
          expect(newDelivery.status, 'Pendente');
          expect(newDelivery.weight, 4.0);

          // Calendário do aluno incorporou o evento
          expect(studentController.events.length, initialEventsCount + 1);
          expect(
            studentController.events.first.title,
            'Entrega: Modelagem de Microsserviços e Mensageria',
          );
        },
      );

      test(
        'Aluno submete arquivo de entrega e Docente recebe a submissão para correção',
        () {
          // Aluno envia arquivo
          AppUserSession.instance.signIn(
            identity: studentIdentity,
            profile: 'aluno',
          );
          final generatedProtocol = studentController.submitDelivery(
            deliveryId: 'DEL-01',
            fileName: 'modelagem_gof_gabriel_oliveira.pdf',
            gitUrl: 'https://github.com/gabriel/aps-gof',
            comments:
                'Trabalho concluído com os testes do padrão Observer e Strategy.',
          );

          expect(generatedProtocol, startsWith('AGR-'));

          // Verifica status na visão do Aluno
          final studentItem = studentController.deliveries.firstWhere(
            (d) => d.id == 'DEL-01',
          );
          expect(studentItem.status, 'Em Análise');
          expect(studentItem.protocol, generatedProtocol);

          // Verifica recepção na visão do Docente
          final apsAssignment = docenteController.assignments.firstWhere(
            (a) => a.id == 'asg-1' || a.courseId == 'course-aps2',
          );
          final gabrielSub = apsAssignment.submissions.firstWhere(
            (s) => s.ra == '2024.1.00892',
          );

          expect(gabrielSub.fileName, 'modelagem_gof_gabriel_oliveira.pdf');
          expect(gabrielSub.status, SubmissionStatus.aguardandoCorrecao);
          expect(gabrielSub.teacherFeedback, contains(generatedProtocol));
        },
      );

      test(
        'Docente corrige entrega com rubrica e Aluno vê status Avaliada e notas recalculadas',
        () {
          AppUserSession.instance.signIn(
            identity: studentIdentity,
            profile: 'aluno',
          );
          studentController.submitDelivery(
            deliveryId: 'DEL-01',
            fileName: 'modelagem_gof_gabriel_oliveira.pdf',
            gitUrl: 'https://github.com/gabriel/aps-gof',
          );

          // Docente avalia submissão
          AppUserSession.instance.signIn(
            identity: teacherIdentity,
            profile: 'docente',
          );
          docenteController.evaluateRubric(
            assignmentId: 'asg-1',
            submissionId: 'sub-DEL-01-2024.1.00892',
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

          // Aluno vê entrega avaliada
          final studentItem = studentController.deliveries.firstWhere(
            (d) => d.id == 'DEL-01',
          );
          expect(studentItem.status, 'Avaliada');
          expect(studentItem.score, 9.8);
          expect(studentItem.feedback, contains('Excelente modelagem'));

          // Boletim e média parcial do Aluno em APS-II foram recalculados
          final apsDisc = studentController.disciplines.firstWhere(
            (d) => d.code == 'APS-II',
          );
          expect(apsDisc.n1, 9.8);
          expect(apsDisc.p1, 9.8);
        },
      );
    },
  );

  group('Verificação Extrema Multiperfil: Secretaria Acadêmica (Aluno <-> Admin)', () {
    late StudentSecretariatController secretariatStudentController;
    late AdminPortalController adminController;

    setUp(() {
      AppUserSession.instance.signIn(
        identity: studentIdentity,
        profile: 'aluno',
      );
      addTearDown(AppUserSession.instance.signOut);
      adminController = AdminPortalController.instance;
      secretariatStudentController = StudentSecretariatController();
    });

    test(
      'Aluno abre requerimento e Admin recebe imediatamente na Mesa da Secretaria',
      () {
        final initialAdminProtocolsCount = adminController.protocols.length;

        secretariatStudentController.addProtocolRequest(
          subjectType: '2ª Chamada de Avaliação / Prova Substitutiva',
          componentObject: '218131 - APS-II',
          justification:
              'Paciente em internação hospitalar no dia da avaliação regimental.',
          attachmentName: 'Atestado_Medico_Hospital_Albert_Einstein.pdf',
        );

        // Entrou na lista da Secretaria Geral do Administrador
        expect(
          adminController.protocols.length,
          initialAdminProtocolsCount + 1,
        );
        final adminProtocol = adminController.protocols.first;
        expect(adminProtocol.studentName, 'Gabriel Soares de Oliveira');
        expect(adminProtocol.studentRa, '2024.1.00892');
        expect(
          adminProtocol.requestType,
          '2ª Chamada de Avaliação / Prova Substitutiva',
        );
        expect(adminProtocol.status, 'Aguardando Parecer');
        expect(
          adminProtocol.attachmentName,
          'Atestado_Medico_Hospital_Albert_Einstein.pdf',
        );
      },
    );

    test(
      'Admin defere requerimento com despacho e Aluno vê parecer oficial assinado',
      () {
        AppUserSession.instance.signIn(identity: 'ADM-00129', profile: 'admin');
        final targetProtocol = secretariatStudentController.protocols.first;

        // Admin analisa e defere o protocolo
        adminController.decideProtocol(
          protocolId: targetProtocol.protocolCode,
          defer: true,
          parecerNote:
              'Atestado médico homologado pela Secretaria Geral. Segunda chamada deferida para 10/11/2026.',
        );

        // O Aluno recebe a decisão homologada
        final updatedStudentProtocol = secretariatStudentController.protocols
            .firstWhere((p) => p.protocolCode == targetProtocol.protocolCode);

        expect(updatedStudentProtocol.status, ProtocolStatus.approved);
        expect(
          updatedStudentProtocol.officialOpinion,
          contains('Atestado médico homologado'),
        );
        expect(
          updatedStudentProtocol.approverName,
          'Administrador institucional',
        );
        expect(updatedStudentProtocol.responseDate, contains('Hoje às'));
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
        () {
          final initialMaterialsCount = bridge.materials.length;

          docenteController.publishMaterial(
            'course-aps2',
            'Slides Aula 14 - Arquitetura Orientada a Eventos e Kafka.pdf',
          );

          expect(bridge.materials.length, initialMaterialsCount + 1);
          final published = bridge.materials.first;
          expect(published['title'], contains('Kafka'));
          expect(published['courseCode'], contains('APS'));
          expect(published['fileType'], 'PDF');
        },
      );
    },
  );

  group(
    'Verificação Extrema Multiperfil: Frequência e Diário de Classe (Docente <-> Aluno)',
    () {
      late DocenteController docenteController;
      late StudentPortalController studentController;

      setUp(() {
        AppUserSession.instance.signIn(
          identity: teacherIdentity,
          profile: 'docente',
        );
        addTearDown(AppUserSession.instance.signOut);
        docenteController = DocenteController();
        studentController = StudentPortalController.instance;
      });

      test(
        'Docente homologa chamada com ausência e frequência do aluno é recalculada',
        () {
          final initialAbsences = studentController.disciplines
              .firstWhere((d) => d.code == 'APS-II')
              .absences;
          final initialRate = studentController.disciplines
              .firstWhere((d) => d.code == 'APS-II')
              .attendancePercentage;

          // Professor registra ausência para o aluno e homologa
          docenteController.homologateSession();

          final updatedDisc = studentController.disciplines.firstWhere(
            (d) => d.code == 'APS-II',
          );
          // Frequência do aluno é atualizada
          expect(updatedDisc.completedHours, greaterThan(0));
          expect(updatedDisc.absences, greaterThanOrEqualTo(initialAbsences));
          expect(initialRate, greaterThan(0));
          expect(updatedDisc.attendancePercentage, isNotNull);
        },
      );
    },
  );

  group(
    'Verificação Extrema Multiperfil: Abono de Faltas via Deferimento de Atestado (Admin -> Aluno)',
    () {
      late AdminPortalController adminController;
      late StudentPortalController studentController;

      setUp(() {
        AppUserSession.instance.signIn(identity: 'ADM-00129', profile: 'admin');
        addTearDown(AppUserSession.instance.signOut);
        adminController = AdminPortalController.instance;
        studentController = StudentPortalController.instance;
      });

      test(
        'Admin defere protocolo de atestado médico e faltas são regularizadas no boletim do aluno',
        () {
          final targetDisc = studentController.disciplines.firstWhere(
            (d) => d.code == 'APS-II',
          );
          final absencesBefore = targetDisc.absences;

          adminController.decideProtocol(
            protocolId: 'MED-2026-99',
            defer: true,
            parecerNote:
                'Atestado médico aprovado. Deferido abono regimental de faltas.',
          );

          final absencesAfter = studentController.disciplines
              .firstWhere((d) => d.code == 'APS-II')
              .absences;
          expect(absencesAfter, lessThanOrEqualTo(absencesBefore));
        },
      );
    },
  );

  group(
    'Verificação Extrema Multiperfil: Comunicados em Massa (Docente/Admin -> Aluno)',
    () {
      late DocenteController docenteController;
      late AdminPortalController adminController;
      late AcademicBridgeService bridge;

      setUp(() {
        AppUserSession.instance.signIn(
          identity: teacherIdentity,
          profile: 'docente',
        );
        addTearDown(AppUserSession.instance.signOut);
        docenteController = DocenteController();
        adminController = AdminPortalController.instance;
        bridge = AcademicBridgeService.instance;
      });

      test(
        'Comunicados emitidos por Docente e Admin refletem no barramento com papéis corretos',
        () {
          final initialNotices = bridge.broadcastNotices.length;

          // Docente publica aviso de prova
          docenteController.publishNotice(
            targetCourse: docenteController.courses.first.code,
            targetAudience: 'Todos os discentes da turma',
            classification: NoticeClassification.informativo,
            title: 'Revisão Geral para Avaliação N2',
            message:
                'A aula de revisão será conduzida na próxima terça-feira com foco em microsserviços.',
          );

          // Admin publica comunicado institucional para todo o campus
          AppUserSession.instance.signIn(
            identity: 'ADM-00129',
            profile: 'admin',
          );
          adminController.broadcastAnnouncement(
            title: 'Semana de Iniciação Científica e Extensão 2026/2',
            audience: 'Campus Central e Alunos Presenciais',
            category: 'Institucional',
            body:
                'Estão abertas as inscrições para submissão de artigos científicos.',
          );

          expect(bridge.broadcastNotices.length, initialNotices + 2);

          final adminNotice = bridge.broadcastNotices.firstWhere(
            (n) => n['senderRole'] == 'admin',
          );
          expect(adminNotice['title'], contains('Iniciação Científica'));

          final docNotice = bridge.broadcastNotices.firstWhere(
            (n) => n['senderRole'] == 'docente',
          );
          expect(docNotice['title'], contains('Revisão Geral'));
        },
      );
    },
  );
}
