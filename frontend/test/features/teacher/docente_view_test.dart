// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/teacher/courses/presentation/pages/docente_course_hub_page.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/pages/docente_assignments_tab.dart';
import 'package:pi_iv_time3/features/teacher/assignments/presentation/widgets/docente_submissions_table.dart';
import 'package:pi_iv_time3/features/teacher/diary/presentation/pages/docente_diary_tab.dart';
import 'package:pi_iv_time3/features/teacher/grades/presentation/pages/docente_grades_tab.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_event.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/attendance_record.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/rubric_model.dart';
import 'package:pi_iv_time3/features/teacher/settings/presentation/pages/docente_settings_tab.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/pages/docente_shell_page.dart';
import 'package:pi_iv_time3/features/teacher/shell/presentation/widgets/docente_footer.dart';
import '../../helpers/fake_teacher_remote_data_source.dart';

Future<DocenteController> _createLoadedTeacherController() async {
  final remote = FakeTeacherRemoteDataSource();
  final controller = DocenteController(
    remoteDataSource: remote,
    profileRemoteDataSource: FakeTeacherProfileRemoteDataSource(remote),
  );
  await controller.loadRemote();
  return controller;
}

void main() {
  group('DocenteController Unit Tests', () {
    late DocenteController controller;
    late FakeTeacherRemoteDataSource remote;

    setUp(() async {
      AppUserSession.instance.signIn(
        identity: 'DOC-88410',
        profile: 'docente',
        accessToken: 'test-teacher-token',
      );
      addTearDown(AppUserSession.instance.signOut);
      remote = FakeTeacherRemoteDataSource();
      controller = DocenteController(
        remoteDataSource: remote,
        profileRemoteDataSource: FakeTeacherProfileRemoteDataSource(remote),
      );
      addTearDown(controller.dispose);
      await controller.loadRemote();
    });

    test(
      'Initial state contains expected courses, assignments and students',
      () {
        expect(controller.courses.length, equals(3));
        expect(controller.assignments.length, equals(2));
        expect(controller.currentSession.attendanceList.length, equals(8));
        expect(controller.gradebook.length, equals(8));
        expect(controller.events.length, equals(6));
        expect(controller.notices.length, equals(5));
        expect(controller.profile.twoFactorEnabled, isTrue);
      },
    );

    test('Course records are scoped to the signed-in teacher', () {
      AppUserSession.instance.signIn(identity: 'DOC-88392', profile: 'docente');
      addTearDown(AppUserSession.instance.signOut);
      final otherTeacherController = DocenteController();
      addTearDown(otherTeacherController.dispose);

      expect(otherTeacherController.courses, isEmpty);
      expect(otherTeacherController.assignments, isEmpty);
      expect(otherTeacherController.studentsForSelectedCourse, isEmpty);
    });

    test(
      'Student cannot mutate the teacher diary or create an assignment',
      () async {
        AppUserSession.instance.signIn(
          identity: '2024.1.00892',
          profile: 'aluno',
        );
        final attendanceBefore = controller.currentSession.attendanceList;
        final assignmentCountBefore = controller.assignments.length;

        await controller.markAllPresent();
        final created = await controller.createAssignment(
          courseId: controller.courses.first.id,
          courseCode: controller.courses.first.code,
          title: 'Atividade indevida',
          weight: 1,
          stage: 'N1',
          dueDateFormatted: '30/11/2026 às 23:59',
          modality: 'Individual',
          allowLateWithPenalty: false,
          rubricCriteria: const [
            RubricCriterion(
              id: 'rubric',
              title: 'Critério',
              maxPoints: 10,
              description: 'Critério de teste.',
            ),
          ],
        );

        expect(created, isFalse);
        expect(controller.assignments.length, assignmentCountBefore);
        expect(controller.currentSession.attendanceList, attendanceBefore);
      },
    );

    test('Gradebook only returns records for the selected course', () {
      final apsStudent = controller.gradebook.first;
      controller.selectCourse('course-bd2');

      expect(controller.gradebook, isEmpty);
      controller.updateStudentGrade(apsStudent.studentId, p1: 1.0);

      controller.selectCourse('course-aps2');
      expect(controller.gradebook.first.p1Score, apsStudent.p1Score);
    });

    test('Each assignment includes every student in its course roster', () {
      for (final assignment in controller.assignments) {
        final roster = controller.sessions
            .where((session) => session.courseId == assignment.courseId)
            .expand((session) => session.attendanceList)
            .map((student) => student.studentId)
            .toSet();
        expect(assignment.submissions, hasLength(roster.length));
        expect(
          assignment.submissions
              .map((submission) => submission.studentId)
              .toSet(),
          hasLength(assignment.submissions.length),
        );
      }
    });

    test('PPC Grade calculations follow institutional formula accurately', () {
      final grade = controller.gradebook.first;
      // Fórmula:
      // N1 = (atividades * 0.4) + (p1 * 0.6)
      // N2 = (projetos * 0.4) + (p2 * 0.6)
      // MS = (N1 * 0.4) + (N2 * 0.6)
      final expectedN1 = double.parse(
        ((grade.assignmentsScore * 0.4) + (grade.p1Score * 0.6))
            .toStringAsFixed(1),
      );
      final expectedN2 = double.parse(
        ((grade.projectsScore * 0.4) + (grade.p2Score * 0.6)).toStringAsFixed(
          1,
        ),
      );
      final expectedMS = double.parse(
        ((expectedN1 * 0.4) + (expectedN2 * 0.6)).toStringAsFixed(1),
      );

      expect(grade.n1Score, closeTo(expectedN1, 0.05));
      expect(grade.n2Score, closeTo(expectedN2, 0.05));
      expect(grade.finalAverage, closeTo(expectedMS, 0.05));
    });

    test(
      'Attendance changes persist before the session is homologated',
      () async {
        final studentId =
            controller.currentSession.attendanceList.first.studentId;

        await controller.toggleAttendance(studentId, AttendanceStatus.ausente);

        final updatedStudent = controller.currentSession.attendanceList
            .firstWhere((s) => s.studentId == studentId);
        expect(updatedStudent.status, equals(AttendanceStatus.ausente));
        expect(controller.currentSession.isHomologated, isFalse);

        await controller.homologateSession();
        expect(controller.currentSession.isHomologated, isTrue);
      },
    );

    test(
      'Publishing a new notice updates the notices list with recipient calculation',
      () async {
        final initialCount = controller.notices.length;
        final published = await controller.publishNotice(
          targetCourse: controller.courses.first.code,
          targetAudience: 'Todos os Alunos',
          classification: NoticeClassification.urgencia,
          title: 'Plantão Extraordinário',
          message: 'Plantão hoje às 18:00 para alinhamento.',
        );

        expect(published, isTrue);
        expect(controller.notices.length, equals(initialCount + 1));
        expect(
          controller.notices.first.title,
          equals('Plantão Extraordinário'),
        );
        expect(
          controller.notices.first.classification,
          equals(NoticeClassification.urgencia),
        );
        expect(controller.notices.first.sciencePercentage, equals(0.0));
      },
    );

    test('Adding an academic event adds it to the agenda', () async {
      final initialEventsCount = controller.events.length;
      await controller.addEvent(
        title: 'Reunião do NDE',
        date: '28/09/2026',
        time: '14:00 - 16:00',
        type: EventType.reuniao,
        location: 'Sala dos Professores',
      );

      expect(controller.events.length, equals(initialEventsCount + 1));
      expect(controller.events.first.title, equals('Reunião do NDE'));
    });

    test('Two-factor state changes only after backend confirmation', () async {
      final initialState = controller.profile.twoFactorEnabled;
      await controller.toggleTwoFactor(password: 'test-password');
      expect(controller.profile.twoFactorEnabled, initialState);
    });

    test('Disconnecting an active session removes it from the list', () async {
      final initialSessions = controller.profile.activeSessions.length;
      final sessionToDisconnect = controller.profile.activeSessions.firstWhere(
        (s) => !s.isCurrent,
      );
      await controller.disconnectSession(sessionToDisconnect.id);
      expect(
        controller.profile.activeSessions.length,
        equals(initialSessions - 1),
      );
    });

    test('Advancing syllabus classes increments progress correctly', () async {
      final course = controller.courses.first;
      final unit = course.syllabusUnits[1];
      final initialCompleted = unit.completedClasses;

      await controller.advanceSyllabusClasses(course.id, unit.id);
      final updatedCourse = controller.courses.firstWhere(
        (c) => c.id == course.id,
      );
      final updatedUnit = updatedCourse.syllabusUnits.firstWhere(
        (u) => u.id == unit.id,
      );

      expect(updatedUnit.completedClasses, isNot(equals(initialCompleted)));
    });

    test('Publishing course material requires a selected file', () async {
      final course = controller.courses.first;
      final initialCount = course.materials.length;

      await controller.publishMaterial(
        course.id,
        'Novo Guia de Arquitetura.pdf',
        null,
      );
      final updatedCourse = controller.courses.firstWhere(
        (c) => c.id == course.id,
      );

      expect(updatedCourse.materials.length, initialCount);
      expect(controller.remoteError, 'Selecione um arquivo para publicar.');
    });

    test(
      'Course classWeekdays and classDaysLabel correctly map timetable days',
      () {
        final apsCourse = controller.courses.firstWhere(
          (c) => c.id == 'course-aps2',
        );
        expect(
          apsCourse.classWeekdays,
          containsAll([DateTime.monday, DateTime.wednesday]),
        );
        expect(apsCourse.classWeekdays.contains(DateTime.tuesday), isFalse);
        expect(apsCourse.classWeekdays.contains(DateTime.sunday), isFalse);
        expect(apsCourse.classDaysLabel, equals('Segundas e Quartas'));

        final bdCourse = controller.courses.firstWhere(
          (c) => c.id == 'course-bd2',
        );
        expect(
          bdCourse.classWeekdays,
          containsAll([DateTime.tuesday, DateTime.thursday]),
        );
        expect(bdCourse.classDaysLabel, equals('Terças e Quintas'));
      },
    );

    test('Navigating between class sessions respects course sessions list', () {
      controller.selectSession('sess-27');
      expect(controller.currentSession.sessionNumber, equals(27));
      expect(controller.canGoToPreviousSession, isTrue);

      controller.goToPreviousSession();
      expect(controller.currentSession.sessionNumber, equals(26));
      expect(
        controller.currentSession.dateFormatted,
        contains('28 de Setembro de 2026 (Segunda-feira)'),
      );

      controller.goToPreviousSession();
      expect(controller.currentSession.sessionNumber, equals(25));
      expect(controller.canGoToPreviousSession, isFalse);

      controller.goToNextSession();
      expect(controller.currentSession.sessionNumber, equals(26));
    });

    test('Selecting a session cannot cross the selected course', () {
      controller.selectCourse('course-bd2');
      final selectedSession = controller.currentSession;
      expect(selectedSession.courseId, equals('course-bd2'));

      controller.selectSession('sess-27');

      expect(controller.currentSession.id, equals(selectedSession.id));
      expect(controller.currentSession.courseId, equals('course-bd2'));
    });

    test(
      'New diary sessions use course roster and chronological navigation',
      () async {
        controller.selectCourse('course-fso');
        final existingSession = controller.currentSession;

        await controller.selectSessionByDate(DateTime(2026, 9, 25, 15));

        expect(controller.currentSession.courseId, equals('course-fso'));
        expect(
          controller.currentSession.sessionDate,
          equals(DateTime(2026, 9, 25)),
        );
        expect(
          controller.currentSession.attendanceList
              .map((student) => student.studentId)
              .toList(),
          equals(
            existingSession.attendanceList
                .map((student) => student.studentId)
                .toList(),
          ),
        );
        expect(controller.canGoToNextSession, isTrue);

        controller.goToNextSession();
        expect(controller.currentSession.id, equals(existingSession.id));
        expect(
          controller.currentSession.sessionNumber,
          equals(existingSession.sessionNumber),
        );
      },
    );

    test('Diary date selection rejects dates outside the course schedule', () {
      final initialSession = controller.currentSession;
      final initialCount = controller.sessions.length;

      controller.selectSessionByDate(DateTime(2026, 10, 1)); // Quinta-feira

      expect(controller.currentSession.id, equals(initialSession.id));
      expect(controller.sessions.length, equals(initialCount));
    });

    test('Notice recipient totals follow the chosen course', () async {
      final targetCourse = controller.courses.firstWhere(
        (course) => course.id == 'course-bd2',
      );
      await controller.publishNotice(
        targetCourse: targetCourse.code,
        targetAudience: 'Todos os Alunos Matriculados',
        classification: NoticeClassification.informativo,
        title: 'Aviso para Banco de Dados',
        message: 'Comunicado da turma selecionada.',
      );

      expect(
        controller.notices.first.totalRecipients,
        targetCourse.enrolledCount,
      );
    });

    test(
      'Disconnecting other sessions preserves the current session only',
      () async {
        await controller.disconnectOtherSessions();

        expect(controller.profile.activeSessions, hasLength(1));
        expect(controller.profile.activeSessions.single.isCurrent, isTrue);
      },
    );
  });

  group('Docente Shell & Widgets Rendering Tests', () {
    setUp(() {
      AppUserSession.instance.signIn(
        identity: 'DOC-88410',
        profile: 'docente',
        accessToken: 'test-teacher-token',
      );
      addTearDown(AppUserSession.instance.signOut);
    });

    testWidgets(
      'Submission row actions wrap inside the action column without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = await _createLoadedTeacherController();
        addTearDown(controller.dispose);
        final assignment = controller.assignments.first;
        final course = controller.courses.firstWhere(
          (course) => course.id == assignment.courseId,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 1100,
                  child: DocenteSubmissionsTable(
                    assignment: assignment,
                    selectedCourse: course,
                    controller: controller,
                    onOpenRubric: (_, _) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Feedback'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Grades and assignments tabs remain usable without horizontal layout overflows on mobile',
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = await _createLoadedTeacherController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DocenteGradesTab(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Homologar com Chancela Digital'), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsWidgets);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DocenteAssignmentsTab(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Cadastrar Nova Atividade'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders DocenteShellPage with sidebar, header, and dashboard tabs',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = await _createLoadedTeacherController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(home: DocenteShellPage(controller: controller)),
        );
        await tester.pumpAndSettle();

        // Verifica se o cabeçalho e a barra lateral renderizam Painel Geral
        expect(find.text('Painel Geral'), findsWidgets);

        // Verifica o cabeçalho principal e os cartões de KPI da visão geral do painel do backend
        expect(find.text('Bem-vinda, Helena.'), findsOneWidget);
        expect(find.text('Departamento de Computação'), findsOneWidget);
        expect(find.text('Docência 2026/2'), findsOneWidget);
        expect(find.text('TURMAS ATIVAS'), findsOneWidget);
        expect(find.text('ENTREGAS DO MÊS'), findsOneWidget);
        expect(find.text('CARGA HORÁRIA TOTAL'), findsOneWidget);
        expect(find.text('FREQUÊNCIA MÉDIA'), findsOneWidget);

        // Verifica Aula do Dia e Atendimento Docente
        expect(find.text('Aula do Dia'), findsOneWidget);
        expect(find.text('Atendimento Docente'), findsOneWidget);

        // Verifica os cartões de disciplinas do painel correspondentes à interface de referência
        expect(find.text('Análise e Projeto de Sistemas II'), findsWidgets);
        expect(find.text('Sala de Aula AVA'), findsWidgets);
        expect(find.text('Progresso do Plano'), findsWidgets);
        expect(find.text('Autoria & Edição habilitadas'), findsWidgets);

        // Verifica a seção de Requerimentos Acadêmicos
        expect(find.text('Requerimentos Acadêmicos das Turmas'), findsOneWidget);
        expect(find.text('Camila Duarte Fagundes'), findsOneWidget);
        expect(find.text('Rodrigo Antunes Nogueira'), findsOneWidget);
        expect(find.text('PROT - 2026/0541'), findsOneWidget);
        expect(find.text('PROT - 2026/0650'), findsOneWidget);

        // Verifica os cartões da coluna direita (prévia de avaliações e prévia de avisos)
        expect(find.text('Prazos e Entregas'), findsOneWidget);
        expect(find.text('Mensagens e Avisos'), findsOneWidget);
        expect(find.text('Ver todos'), findsOneWidget);

        // Verifica se DocenteFooter está presente
        expect(find.byType(DocenteFooter), findsOneWidget);
        expect(find.text('© 2026 AGMRM'), findsOneWidget);

        // Navega para a aba Turmas e verifica a visualização de Disciplinas em 3 colunas
        await tester.tap(find.byKey(const Key('docente_sidebar_item_turmas')));
        await tester.pumpAndSettle();

        expect(find.text('Disciplinas'), findsOneWidget);
        expect(
          find.text('Minhas Turmas e Componentes Curriculares'),
          findsOneWidget,
        );
        expect(find.text('Análise e Projeto de Sistemas II'), findsOneWidget);
        expect(find.text('Estudos de Banco de Dados II'), findsOneWidget);
        expect(
          find.text('Fundamentos de Sistemas Operacionais'),
          findsOneWidget,
        );
        expect(find.text('Lab Informática 04 - Bloco C'), findsOneWidget);
        expect(find.text('Lab Banco de Dados 02 - Bloco B'), findsOneWidget);
        expect(find.text('Anfiteatro 101 - Bloco Central'), findsOneWidget);
        expect(find.text('34 discentes matriculados'), findsOneWidget);
        expect(find.text('31 discentes matriculados'), findsOneWidget);
        expect(find.text('36 discentes matriculados'), findsOneWidget);
        expect(find.text('68%'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('55%'), findsOneWidget);
        expect(
          find.text('Acessar Sala de Aula Virtual (AVA)'),
          findsNWidgets(3),
        );
        expect(find.text('Plano de Ensino & Materiais'), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Renders DocenteCourseHubPage and displays top navigation and metrics',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = await _createLoadedTeacherController();
        addTearDown(controller.dispose);
        final course = controller.courses.first;

        await tester.pumpWidget(
          MaterialApp(
            home: DocenteCourseHubPage(course: course, controller: controller),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Minhas Turmas'), findsOneWidget);
        expect(find.text('Livro de Notas (Gradebook)'), findsOneWidget);
        expect(find.text('Diário de Presença'), findsOneWidget);
        expect(find.text('Módulos & Conteúdos'), findsOneWidget);
        expect(find.text('Tarefas & Submissões'), findsOneWidget);
        expect(find.text('Fórum da Turma'), findsOneWidget);
        expect(find.text('Alunos Matriculados'), findsOneWidget);
        expect(find.text('Plano de Ensino'), findsOneWidget);
        expect(find.text('Equipes de Projeto'), findsOneWidget);
        expect(find.text('Média geral'), findsOneWidget);

        // Verifica se DocenteFooter é renderizado
        expect(find.byType(DocenteFooter), findsOneWidget);
        expect(find.text('© 2026 AGMRM'), findsOneWidget);

        // Alterna para Equipes de Projeto (índice de aba 7) para verificar o layout do rodapé em conteúdo curto
        await tester.tap(find.text('Equipes de Projeto'));
        await tester.pumpAndSettle();

        expect(
          find.text('Equipes de Projeto & Squads Integradores'),
          findsOneWidget,
        );
        expect(find.byType(DocenteFooter), findsOneWidget);
      },
    );

    testWidgets(
      'DocenteFooter renders institutional copyright and triggers snackbars on help/privacy',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: DocenteFooter())),
        );
        await tester.pumpAndSettle();

        expect(find.text('© 2026 AGMRM'), findsOneWidget);
        expect(
          find.text(
            'Portal AVA AGMRM • Ambiente Virtual de Aprendizagem Universitário',
          ),
          findsOneWidget,
        );
        expect(find.text('Ajuda'), findsOneWidget);
        expect(find.text('Privacidade'), findsOneWidget);

        await tester.tap(find.text('Ajuda'));
        await tester.pump();
        expect(
          find.text('Central de Ajuda ao Docente: suporte@agmrm.edu.br'),
          findsOneWidget,
        );

        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Privacidade'));
        await tester.pump();
        expect(
          find.text(
            'Termos de Privacidade e Proteção de Dados (LGPD) • AGMRM 2026',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders DocenteDiaryTab with MEC session card, attendance table, badges, mark all, and footer',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = await _createLoadedTeacherController();
        addTearDown(controller.dispose);
        controller.selectSession('sess-27');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DocenteDiaryTab(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Diário de Classe Eletrônico & Registro de Chamada'),
          findsOneWidget,
        );
        expect(find.text('AULA Nº 27 • CARGA: 2H/AULA'), findsOneWidget);
        expect(
          find.text('30 de Setembro de 2026 (Quarta-feira)'),
          findsOneWidget,
        );
        expect(find.text('Aguardando Homologação'), findsOneWidget);
        expect(find.text('Total: 8'), findsOneWidget);
        expect(find.text('Presentes: 5'), findsOneWidget);
        expect(find.text('Faltas: 2'), findsOneWidget);
        expect(find.text('Justificadas: 1'), findsOneWidget);
        expect(find.text('DISCENTE CONECTADO'), findsOneWidget);
        expect(find.text('Marcar Todos como Presentes'), findsOneWidget);
        expect(find.byType(DocenteFooter), findsOneWidget);

        // Toca em Marcar Todos como Presentes
        await tester.tap(find.text('Marcar Todos como Presentes'));
        await tester.pumpAndSettle();

        expect(find.text('Presentes: 8'), findsOneWidget);
        expect(find.text('Faltas: 0'), findsOneWidget);
        expect(find.text('Justificadas: 0'), findsOneWidget);

        // Toca em Salvar e Homologar Aula
        await tester.ensureVisible(find.text('Salvar e Homologar Aula'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar e Homologar Aula'));
        await tester.pumpAndSettle();

        expect(controller.currentSession.isHomologated, isTrue);
        expect(find.text('Homologado no Sistema'), findsOneWidget);

        // Rola de volta para cima e navega para a aula anterior pela seta à esquerda
        await tester.ensureVisible(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        expect(find.text('AULA Nº 26 • CARGA: 2H/AULA'), findsOneWidget);
        expect(
          find.text('28 de Setembro de 2026 (Segunda-feira)'),
          findsOneWidget,
        );

        // Abre o ClassSessionPickerModal por meio de Trocar Aula
        await tester.tap(find.text('Trocar Aula'));
        await tester.pumpAndSettle();

        expect(
          find.text('Grade de Aulas e Chamadas do Semestre'),
          findsOneWidget,
        );
        expect(find.text('Abrir Calendário Interativo'), findsOneWidget);

        // Toca na Aula 25 dentro do modal para selecioná-la
        await tester.tap(find.text('23 de Setembro de 2026 (Quarta-feira)'));
        await tester.pumpAndSettle();

        expect(find.text('AULA Nº 25 • CARGA: 2H/AULA'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders DocenteSettingsTab and navigates between subtabs seamlessly',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final controller = await _createLoadedTeacherController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DocenteSettingsTab(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        // A subaba padrão é Perfil Docente
        expect(find.text('Configurações da Conta Docente'), findsOneWidget);
        expect(find.text('Perfil Docente'), findsWidgets);
        expect(find.text('Identidade Visual & Foto'), findsOneWidget);

        // Alterna para Notificações
        await tester.tap(find.text('Notificações Institucionais'));
        await tester.pumpAndSettle();

        expect(find.text('Canais de Comunicação'), findsOneWidget);
        expect(
          find.text('Comunicados Institucionais & Rematrícula'),
          findsOneWidget,
        );
        expect(find.text('Salvar Preferências de Notificação'), findsOneWidget);

        // Alterna para Preferências do Sistema
        await tester.tap(find.text('Preferências do Sistema'));
        await tester.pumpAndSettle();

        expect(find.text('Aparência & Tema'), findsOneWidget);
        expect(find.text('Acessibilidade & Leitura'), findsOneWidget);
        expect(
          find.text('Preferências do Calendário Acadêmico'),
          findsOneWidget,
        );
        expect(find.text('Salvar Preferências do Sistema'), findsOneWidget);

        // Alterna para Privacidade & LGPD
        await tester.tap(find.text('Privacidade & LGPD'));
        await tester.pumpAndSettle();

        expect(
          find.text('Visibilidade de Perfil & Dados entre Colegas'),
          findsOneWidget,
        );
        expect(
          find.text('Privacidade & Direitos do Titular (LGPD)'),
          findsOneWidget,
        );
        expect(find.text('Salvar Preferências de Privacidade'), findsOneWidget);
        expect(find.text('Arquivo JSON'), findsOneWidget);
        expect(find.text('Relatório (.txt)'), findsOneWidget);

        // Os controles de segurança usam a ação do controlador para manter apenas esta sessão.
        await tester.tap(find.text('Segurança & Acessos'));
        await tester.pumpAndSettle();
        final sessionsBefore = controller.profile.activeSessions.length;
        expect(sessionsBefore, greaterThan(1));
        await tester.ensureVisible(find.text('Encerrar Outras Sessões'));
        await tester.tap(find.text('Encerrar Outras Sessões'));
        await tester.pumpAndSettle();
        expect(controller.profile.activeSessions, hasLength(1));
        expect(controller.profile.activeSessions.single.isCurrent, isTrue);
      },
    );

    testWidgets('Settings profile fits mobile widths without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = DocenteController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DocenteSettingsTab(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Identidade Visual & Foto'), findsOneWidget);
    });

    testWidgets(
      'Sidebar edge-to-edge hit test, toggle collapse and drawer auto-close',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = await _createLoadedTeacherController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(home: DocenteShellPage(controller: controller)),
        );
        await tester.pumpAndSettle();

        // 1. Teste de toque de ponta a ponta na linha: toca com deslocamento horizontal fora do centro
        final turmasTile = find.byKey(const Key('docente_sidebar_item_turmas'));
        expect(turmasTile, findsOneWidget);
        await tester.tapAt(tester.getCenter(turmasTile) + const Offset(-60, 0));
        await tester.pumpAndSettle();
        expect(controller.activeTab, DocenteNavTab.turmas);
        expect(find.text('Disciplinas'), findsOneWidget);

        // 2. O botão flutuante de recolher/expandir funciona perfeitamente sem ser bloqueado
        final toggleBtn = find.byKey(const Key('sidebar_toggle_collapse_btn'));
        expect(toggleBtn, findsOneWidget);
        await tester.tap(toggleBtn);
        await tester.pumpAndSettle();
        expect(controller.isSidebarCollapsed, isTrue);

        // Toca novamente para expandir
        await tester.tap(toggleBtn);
        await tester.pumpAndSettle();
        expect(controller.isSidebarCollapsed, isFalse);

        // 3. Viewport estreita: a gaveta abre e fecha automaticamente ao selecionar um item
        tester.view.physicalSize = const Size(900, 900);
        await tester.pumpAndSettle();

        final openDrawerBtn = find.byTooltip('Abrir Menu');
        expect(openDrawerBtn, findsOneWidget);
        await tester.tap(openDrawerBtn);
        await tester.pumpAndSettle();

        // Verifica se a gaveta abriu com os itens da barra lateral e se o toque fecha a gaveta
        final configTile = find.byKey(
          const Key('docente_sidebar_item_configuracoes'),
        );
        expect(configTile, findsOneWidget);
        await tester.tap(configTile);
        await tester.pumpAndSettle();

        // A gaveta deve estar fechada e activeTab alternada para configuracoes
        expect(controller.activeTab, DocenteNavTab.configuracoes);
        expect(find.text('Configurações da Conta Docente'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'DocenteCourseHubPage AVA flows: EM CURSO badge, assignments, forum reply, syllabus edit, squads create, and mobile layout',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        AppUserSession.instance.signIn(
          identity: 'DOC-88410',
          profile: 'docente',
          accessToken: 'test-teacher-token',
        );
        addTearDown(AppUserSession.instance.signOut);

        final remote = FakeTeacherRemoteDataSource();
        remote.grades[0] = remote.grades[0].copyWith(
          hasGrades: false,
          assignmentsScore: 0,
          p1Score: 0,
          projectsScore: 0,
          p2Score: 0,
        );
        final controller = DocenteController(
          remoteDataSource: remote,
          profileRemoteDataSource: FakeTeacherProfileRemoteDataSource(remote),
        );
        addTearDown(controller.dispose);
        await controller.loadRemote();

        final course = controller.courses.first;
        await tester.pumpWidget(
          MaterialApp(
            home: DocenteCourseHubPage(course: course, controller: controller),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Livro de Notas exibe "EM CURSO" para aluno sem notas lancadas
        await tester.tap(find.text('Livro de Notas (Gradebook)'));
        await tester.pumpAndSettle();
        expect(find.text('EM CURSO'), findsAtLeastNWidgets(1));

        // 2. Tarefas & Submissoes lista atividades da turma e abre modal de criacao
        await tester.tap(find.text('Tarefas & Submissões'));
        await tester.pumpAndSettle();
        expect(
          find.text(controller.assignmentsForSelectedCourse.first.title),
          findsAtLeastNWidgets(1),
        );
        await tester.tap(find.text('Nova Atividade').first);
        await tester.pumpAndSettle();
        expect(find.text('Cadastrar Nova Atividade Avaliativa'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        // 3. Forum da Turma cria topico e responde no thread
        await tester.tap(find.text('Fórum da Turma'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Novo Tópico'));
        await tester.pumpAndSettle();
        final forumDialogFields = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(
          forumDialogFields.at(0),
          'Dúvida sobre Adapter',
        );
        await tester.enterText(
          forumDialogFields.at(1),
          'Como isolar a interface legada?',
        );
        await tester.tap(find.text('Publicar Tópico'));
        await tester.pumpAndSettle();
        expect(find.text('Dúvida sobre Adapter'), findsOneWidget);

        await tester.tap(find.text('Participar').first);
        await tester.pumpAndSettle();
        final replyDialogField = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(
          replyDialogField.last,
          'Use uma camada adaptadora dedicada.',
        );
        await tester.tap(find.text('Publicar Resposta'));
        await tester.pumpAndSettle();
        expect(find.text('1 resposta'), findsAtLeastNWidgets(1));
        expect(
          (controller.courses.first.forumTopics.first['replies'] as List)
              .length,
          1,
        );

        // 4. Plano de Ensino edita e persiste alteracoes
        await tester.tap(find.text('Plano de Ensino'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Editar Plano'));
        await tester.pumpAndSettle();
        final syllabusDialogFields = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(
          syllabusDialogFields.first,
          'Ementa atualizada via widget test.',
        );
        await tester.tap(find.text('Salvar Plano de Ensino'));
        await tester.pumpAndSettle();
        expect(find.text('Ementa atualizada via widget test.'), findsOneWidget);

        // 5. Equipes de Projeto cria squad com projectTitle valido
        await tester.tap(find.text('Equipes de Projeto'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nova Equipe'));
        await tester.pumpAndSettle();
        final squadDialogFields = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(squadDialogFields.at(0), 'Squad Alpha');
        await tester.enterText(
          squadDialogFields.at(1),
          'Portal Integrado Teste',
        );
        await tester.tap(find.text('Salvar Equipe'));
        await tester.pumpAndSettle();
        expect(find.text('SQUAD ALPHA'), findsOneWidget);
        expect(find.text('Portal Integrado Teste'), findsOneWidget);

        // 6. Viewport movel (compact tab bar) sem overflow
        tester.view.physicalSize = const Size(430, 900);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
