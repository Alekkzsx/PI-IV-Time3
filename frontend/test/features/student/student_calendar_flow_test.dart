// Desenvolvido por Rafael Henrique Inácio - RA: 25009719
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/student/calendar/presentation/pages/student_calendar_page.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';

void main() {
  late StudentPortalController controller;

  setUp(() {
    controller = StudentPortalController.instance;
    controller.activeEventTypes
      ..clear()
      ..addAll({'Entrega', 'Aula', 'Fórum', 'Avaliação'});
    controller.activeDisciplineFilters
      ..clear()
      ..addAll({'APS-II', 'BD-II', 'FIS', 'FSO'});
    controller.setCalendarViewMode('Mês');
    controller.setCalendarFocusedDate(DateTime(2026, 10, 20));
  });

  testWidgets('navega meses e retorna para hoje', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(body: StudentCalendarPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OUTUBRO 2026'), findsWidgets);
    await tester.tap(find.byKey(const Key('calendar_previous')));
    await tester.pumpAndSettle();
    expect(find.text('SETEMBRO 2026'), findsWidgets);

    await tester.tap(find.byKey(const Key('calendar_next')));
    await tester.pumpAndSettle();
    expect(find.text('OUTUBRO 2026'), findsWidgets);

    await tester.tap(find.byKey(const Key('calendar_today')));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(controller.calendarFocusedDate.year, now.year);
    expect(controller.calendarFocusedDate.month, now.month);
    expect(controller.calendarFocusedDate.day, now.day);
  });

  testWidgets('agenda filtra compromissos pela data selecionada', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(body: StudentCalendarPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar_period_hoje')));
    await tester.pumpAndSettle();

    expect(find.text('Aula Síncrona: Padrões de Projeto GoF'), findsOneWidget);
    expect(find.text('Entrega: Padrões Adapter e Facade'), findsOneWidget);
    expect(
      find.text('Avaliação Parcial N1: Álgebra Relacional e SQL'),
      findsNothing,
    );
    await tester.tap(find.text('Detalhes').first);
    await tester.pumpAndSettle();
    expect(find.text('Local: Sala Virtual AVA / Lab 04'), findsOneWidget);
  });

  testWidgets('filtros do calendário controlam os eventos exibidos', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(body: StudentCalendarPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar_filter_APS-II')));
    await tester.pumpAndSettle();

    expect(
      controller.visibleCalendarEvents.any(
        (event) => event.discipline == 'APS-II',
      ),
      isFalse,
    );
    expect(
      controller.visibleCalendarEvents.any(
        (event) => event.discipline == 'BD-II',
      ),
      isTrue,
    );
  });

  testWidgets('valida data real e registra evento no calendário selecionado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(body: StudentCalendarPage()),
      ),
    );
    await tester.pumpAndSettle();
    final initialCount = controller.events.length;
    await tester.tap(find.byTooltip('Novo Evento'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Evento de teste');
    await tester.enterText(find.byType(TextField).at(1), '31/02/2026');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Informe um título e uma data válida (dd/mm/aaaa).'),
      findsOneWidget,
    );
    expect(controller.events.length, initialCount);

    await tester.enterText(find.byType(TextField).at(1), '29/02/2028');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    final event = controller.events.firstWhere(
      (item) => item.title == 'Evento de teste',
    );
    expect(event.date, '2028-02-29');
    expect(event.discipline, 'APS-II');
    expect(controller.events.length, initialCount + 1);
  });

  testWidgets('rejeita horário inválido em tarefa pessoal', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(body: StudentCalendarPage()),
      ),
    );
    await tester.pumpAndSettle();
    final initialCount = controller.events.length;
    await tester.tap(find.byTooltip('Novo Evento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Minha lista de tarefas'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Tarefa de teste');
    await tester.enterText(find.byType(TextField).at(2), '25:99');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um horário válido (HH:mm).'), findsOneWidget);
    expect(controller.events.length, initialCount);
  });
}
