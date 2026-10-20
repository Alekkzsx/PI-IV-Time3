// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/docente_view/domain/models/academic_event.dart';
import 'package:pi_iv_time3/features/docente_view/domain/models/academic_notice.dart';
import 'package:pi_iv_time3/features/docente_view/domain/models/attendance_record.dart';
import 'package:pi_iv_time3/features/docente_view/presentation/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/presentation/pages/docente_course_hub_page.dart';
import 'package:pi_iv_time3/features/docente_view/presentation/pages/docente_shell_page.dart';

void main() {
  group('DocenteController Unit Tests', () {
    late DocenteController controller;

    setUp(() {
      controller = DocenteController();
    });

    test('Initial state contains expected courses, assignments and students', () {
      expect(controller.courses.length, equals(3));
      expect(controller.assignments.length, equals(2));
      expect(controller.currentSession.attendanceList.length, equals(8));
      expect(controller.gradebook.length, equals(8));
      expect(controller.events.length, equals(6));
      expect(controller.notices.length, equals(2));
      expect(controller.profile.twoFactorEnabled, isTrue);
    });

    test('PPC Grade calculations follow institutional formula accurately', () {
      final grade = controller.gradebook.first;
      // Formula:
      // N1 = (assignments * 0.4) + (p1 * 0.6)
      // N2 = (projects * 0.4) + (p2 * 0.6)
      // MS = (N1 * 0.4) + (N2 * 0.6)
      final expectedN1 = double.parse(((grade.assignmentsScore * 0.4) + (grade.p1Score * 0.6)).toStringAsFixed(1));
      final expectedN2 = double.parse(((grade.projectsScore * 0.4) + (grade.p2Score * 0.6)).toStringAsFixed(1));
      final expectedMS = double.parse(((expectedN1 * 0.4) + (expectedN2 * 0.6)).toStringAsFixed(1));

      expect(grade.n1Score, closeTo(expectedN1, 0.05));
      expect(grade.n2Score, closeTo(expectedN2, 0.05));
      expect(grade.finalAverage, closeTo(expectedMS, 0.05));
    });

    test('Attendance toggling recalculates absences, rate and risk levels', () {
      final studentId = controller.currentSession.attendanceList.first.studentId;
      final initialAbsences = controller.currentSession.attendanceList.first.accumulatedAbsences;

      controller.toggleAttendance(studentId, AttendanceStatus.ausente);

      final updatedStudent = controller.currentSession.attendanceList.firstWhere((s) => s.studentId == studentId);
      expect(updatedStudent.status, equals(AttendanceStatus.ausente));
      expect(updatedStudent.accumulatedAbsences, equals(initialAbsences + 1));
      expect(controller.currentSession.isHomologated, isFalse);

      controller.homologateSession();
      expect(controller.currentSession.isHomologated, isTrue);
    });

    test('Publishing a new notice updates the notices list with recipient calculation', () {
      final initialCount = controller.notices.length;
      controller.publishNotice(
        targetCourse: 'CC-401',
        targetAudience: 'Todos os Alunos',
        classification: NoticeClassification.urgencia,
        title: 'Plantão Extraordinário',
        message: 'Plantão hoje às 18:00 para alinhamento.',
      );

      expect(controller.notices.length, equals(initialCount + 1));
      expect(controller.notices.first.title, equals('Plantão Extraordinário'));
      expect(controller.notices.first.classification, equals(NoticeClassification.urgencia));
      expect(controller.notices.first.sciencePercentage, equals(0.0));
    });

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
      final sessionToDisconnect = controller.profile.activeSessions.firstWhere((s) => !s.isCurrent);
      controller.disconnectSession(sessionToDisconnect.id);
      expect(controller.profile.activeSessions.length, equals(initialSessions - 1));
    });

    test('Advancing syllabus classes increments progress correctly', () {
      final course = controller.courses.first;
      final unit = course.syllabusUnits.first;
      final initialCompleted = unit.completedClasses;

      controller.advanceSyllabusClasses(course.id, unit.id);
      final updatedCourse = controller.courses.firstWhere((c) => c.id == course.id);
      final updatedUnit = updatedCourse.syllabusUnits.firstWhere((u) => u.id == unit.id);

      expect(updatedUnit.completedClasses, isNot(equals(initialCompleted)));
    });

    test('Publishing course material adds it to course repository', () {
      final course = controller.courses.first;
      final initialCount = course.materials.length;

      controller.publishMaterial(course.id, 'Novo Guia de Arquitetura.pdf');
      final updatedCourse = controller.courses.firstWhere((c) => c.id == course.id);

      expect(updatedCourse.materials.length, equals(initialCount + 1));
      expect(updatedCourse.materials.first.title, equals('Novo Guia de Arquitetura.pdf'));
    });
  });

  group('Docente Shell & Widgets Rendering Tests', () {
    testWidgets('Renders DocenteShellPage with sidebar, header, and dashboard tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DocenteShellPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Professor Helena profile header
      expect(find.text('Profa. Helena Bittencourt'), findsWidgets);
      expect(find.text('Departamento de Computação • 2026/2'), findsWidgets);

      // Verify Dashboard KPI cards
      expect(find.text('Alunos Ativos'), findsOneWidget);
      expect(find.text('Média Semestral Geral'), findsOneWidget);
      expect(find.text('Frequência Média'), findsOneWidget);
      expect(find.text('Pendências no Diário'), findsOneWidget);

      // Verify Today Class card
      expect(find.text('Aula do Dia — Hoje'), findsOneWidget);
      expect(find.text('Iniciar Transmissão'), findsOneWidget);
    });

    testWidgets('Renders DocenteCourseHubPage and displays top navigation and metrics', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = DocenteController();
      final course = controller.courses.first;

      await tester.pumpWidget(
        MaterialApp(
          home: DocenteCourseHubPage(
            course: course,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Voltar para Minhas Turmas'), findsOneWidget);
      expect(find.text(course.name), findsOneWidget);
      expect(find.text('Iniciar Transmissão ao Vivo'), findsOneWidget);
      expect(find.text('Visão Geral & Cockpit'), findsOneWidget);
      expect(find.text('Diário de Classe & Frequência'), findsOneWidget);
      expect(find.text('Livro de Notas & Gradebook'), findsOneWidget);
    });
  });
}
