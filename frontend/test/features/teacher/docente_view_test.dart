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

void main() {
  group('DocenteController Unit Tests', () {
    late DocenteController controller;

    setUp(() {
      AppUserSession.instance.signIn(identity: 'DOC-88410', profile: 'docente');
      addTearDown(AppUserSession.instance.signOut);
      controller = DocenteController();
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

    test('Student cannot mutate the teacher diary or create an assignment', () {
      AppUserSession.instance.signIn(
        identity: '2024.1.00892',
        profile: 'aluno',
      );
      final attendanceBefore = controller.currentSession.attendanceList;
      final assignmentCountBefore = controller.assignments.length;

      controller.markAllPresent();
      final created = controller.createAssignment(
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
    });

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
      // Formula:
      // N1 = (assignments * 0.4) + (p1 * 0.6)
      // N2 = (projects * 0.4) + (p2 * 0.6)
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

    test('Attendance toggling recalculates absences, rate and risk levels', () {
      final studentId =
          controller.currentSession.attendanceList.first.studentId;
      final initialAbsences =
          controller.currentSession.attendanceList.first.accumulatedAbsences;

      controller.toggleAttendance(studentId, AttendanceStatus.ausente);

      final updatedStudent = controller.currentSession.attendanceList
          .firstWhere((s) => s.studentId == studentId);
      expect(updatedStudent.status, equals(AttendanceStatus.ausente));
      expect(updatedStudent.accumulatedAbsences, equals(initialAbsences + 1));
      expect(controller.currentSession.isHomologated, isFalse);

      controller.homologateSession();
      expect(controller.currentSession.isHomologated, isTrue);
    });

    test(
      'Publishing a new notice updates the notices list with recipient calculation',
      () {
        final initialCount = controller.notices.length;
        controller.publishNotice(
          targetCourse: controller.courses.first.code,
          targetAudience: 'Todos os Alunos',
          classification: NoticeClassification.urgencia,
          title: 'Plantão Extraordinário',
          message: 'Plantão hoje às 18:00 para alinhamento.',
        );

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

    test('Adding an academic event adds it to the agenda', () {
      final initialEventsCount = controller.events.length;
      controller.addEvent(
        title: 'Reunião do NDE',
        date: '28/09/2026',
        time: '14:00 - 16:00',
        type: EventType.reuniao,
        location: 'Sala dos Professores',
      );

      expect(controller.events.length, equals(initialEventsCount + 1));
      expect(controller.events.first.title, equals('Reunião do NDE'));
    });

    test('Two-factor authentication toggle modifies profile state', () {
      expect(controller.profile.twoFactorEnabled, isTrue);
      controller.toggleTwoFactor();
      expect(controller.profile.twoFactorEnabled, isFalse);
      controller.toggleTwoFactor();
      expect(controller.profile.twoFactorEnabled, isTrue);
    });

    test('Disconnecting an active session removes it from the list', () {
      final initialSessions = controller.profile.activeSessions.length;
      final sessionToDisconnect = controller.profile.activeSessions.firstWhere(
        (s) => !s.isCurrent,
      );
      controller.disconnectSession(sessionToDisconnect.id);
      expect(
        controller.profile.activeSessions.length,
        equals(initialSessions - 1),
      );
    });

    test('Advancing syllabus classes increments progress correctly', () {
      final course = controller.courses.first;
      final unit = course.syllabusUnits.first;
      final initialCompleted = unit.completedClasses;

      controller.advanceSyllabusClasses(course.id, unit.id);
      final updatedCourse = controller.courses.firstWhere(
        (c) => c.id == course.id,
      );
      final updatedUnit = updatedCourse.syllabusUnits.firstWhere(
        (u) => u.id == unit.id,
      );

      expect(updatedUnit.completedClasses, isNot(equals(initialCompleted)));
    });

    test('Publishing course material adds it to course repository', () {
      final course = controller.courses.first;
      final initialCount = course.materials.length;

      controller.publishMaterial(course.id, 'Novo Guia de Arquitetura.pdf');
      final updatedCourse = controller.courses.firstWhere(
        (c) => c.id == course.id,
      );

      expect(updatedCourse.materials.length, equals(initialCount + 1));
      expect(
        updatedCourse.materials.first.title,
        equals('Novo Guia de Arquitetura.pdf'),
      );
      final now = DateTime.now();
      expect(
        updatedCourse.materials.first.date,
        'Hoje, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      );
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
      () {
        controller.selectCourse('course-fso');
        final existingSession = controller.currentSession;

        controller.selectSessionByDate(DateTime(2026, 9, 25, 15));

        expect(controller.currentSession.courseId, equals('course-fso'));
        expect(controller.currentSession.sessionNumber, equals(11));
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
        expect(controller.currentSession.sessionNumber, equals(12));
      },
    );

    test('Diary date selection rejects dates outside the course schedule', () {
      final initialSession = controller.currentSession;
      final initialCount = controller.sessions.length;

      controller.selectSessionByDate(DateTime(2026, 10, 1)); // Thursday

      expect(controller.currentSession.id, equals(initialSession.id));
      expect(controller.sessions.length, equals(initialCount));
    });

    test('Notice recipient totals follow the chosen course', () {
      final targetCourse = controller.courses.firstWhere(
        (course) => course.id == 'course-bd2',
      );
      controller.publishNotice(
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

    test('Disconnecting other sessions preserves the current session only', () {
      controller.disconnectOtherSessions();

      expect(controller.profile.activeSessions, hasLength(1));
      expect(controller.profile.activeSessions.single.isCurrent, isTrue);
    });
  });

  group('Docente Shell & Widgets Rendering Tests', () {
    setUp(() {
      AppUserSession.instance.signIn(identity: 'DOC-88410', profile: 'docente');
      addTearDown(AppUserSession.instance.signOut);
    });

    testWidgets(
      'Submission row actions wrap inside the action column without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        AppUserSession.instance.signIn(
          identity: 'DOC-88410',
          profile: 'docente',
        );
        addTearDown(AppUserSession.instance.signOut);

        final controller = DocenteController();
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
        AppUserSession.instance.signIn(
          identity: 'DOC-88410',
          profile: 'docente',
        );
        addTearDown(AppUserSession.instance.signOut);

        final controller = DocenteController();
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

        await tester.pumpWidget(const MaterialApp(home: DocenteShellPage()));
        await tester.pumpAndSettle();

        // Verify Professor Helena profile header
        expect(find.text('Bem-vinda, Helena.'), findsOneWidget);
        expect(find.text('Departamento de Computação'), findsOneWidget);

        // Verify Dashboard KPI cards
        expect(find.text('TURMAS ATIVAS'), findsOneWidget);
        expect(find.text('ENTREGAS DO MÊS'), findsOneWidget);
        expect(find.text('CARGA HORÁRIA TOTAL'), findsOneWidget);
        expect(find.text('FREQUÊNCIA MÉDIA'), findsOneWidget);

        // Verify Today Class card
        expect(find.text('Aula do Dia'), findsOneWidget);
        expect(find.text('Iniciar Transmissão'), findsOneWidget);

        // Verify DocenteFooter is present
        expect(find.byType(DocenteFooter), findsOneWidget);
        expect(find.text('© 2026 AGMRM'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders DocenteCourseHubPage and displays top navigation and metrics',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = DocenteController();
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
        expect(find.text('MÉDIA GERAL DA TURMA'), findsOneWidget);

        // Verify DocenteFooter is rendered
        expect(find.byType(DocenteFooter), findsOneWidget);
        expect(find.text('© 2026 AGMRM'), findsOneWidget);

        // Switch to Equipes de Projeto (tab index 7) to verify footer layout in short content
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

        final controller = DocenteController();

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

        // Tap Marcar Todos como Presentes
        await tester.tap(find.text('Marcar Todos como Presentes'));
        await tester.pumpAndSettle();

        expect(find.text('Presentes: 8'), findsOneWidget);
        expect(find.text('Faltas: 0'), findsOneWidget);
        expect(find.text('Justificadas: 0'), findsOneWidget);

        // Tap Salvar e Homologar Aula
        await tester.ensureVisible(find.text('Salvar e Homologar Aula'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar e Homologar Aula'));
        await tester.pumpAndSettle();

        expect(controller.currentSession.isHomologated, isTrue);
        expect(find.text('Homologado no Sistema'), findsOneWidget);

        // Scroll back up and navigate to previous session via chevron left
        await tester.ensureVisible(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        expect(find.text('AULA Nº 26 • CARGA: 2H/AULA'), findsOneWidget);
        expect(
          find.text('28 de Setembro de 2026 (Segunda-feira)'),
          findsOneWidget,
        );

        // Open ClassSessionPickerModal via Trocar Aula
        await tester.tap(find.text('Trocar Aula'));
        await tester.pumpAndSettle();

        expect(
          find.text('Grade de Aulas e Chamadas do Semestre'),
          findsOneWidget,
        );
        expect(find.text('Abrir Calendário Interativo'), findsOneWidget);

        // Tap on Aula 25 inside modal to select it
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

        final controller = DocenteController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DocenteSettingsTab(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        // Default subtab is Perfil Docente
        expect(find.text('Configurações da Conta Docente'), findsOneWidget);
        expect(find.text('Perfil Docente'), findsWidgets);
        expect(find.text('Identidade Visual & Foto'), findsOneWidget);

        // Switch to Notificações
        await tester.tap(find.text('Notificações Institucionais'));
        await tester.pumpAndSettle();

        expect(find.text('Canais de Comunicação'), findsOneWidget);
        expect(
          find.text('Comunicados Institucionais & Rematrícula'),
          findsOneWidget,
        );
        expect(find.text('Salvar Preferências de Notificação'), findsOneWidget);

        // Switch to Preferências do Sistema
        await tester.tap(find.text('Preferências do Sistema'));
        await tester.pumpAndSettle();

        expect(find.text('Aparência & Tema'), findsOneWidget);
        expect(find.text('Acessibilidade & Leitura'), findsOneWidget);
        expect(
          find.text('Preferências do Calendário Acadêmico'),
          findsOneWidget,
        );
        expect(find.text('Salvar Preferências do Sistema'), findsOneWidget);

        // Switch to Privacidade & LGPD
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

        // Security controls use the controller action to keep only this session.
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
  });
}
