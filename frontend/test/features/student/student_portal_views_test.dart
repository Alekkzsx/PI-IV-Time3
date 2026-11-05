// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/data/student_remote_data_source.dart';
import 'package:pi_iv_time3/features/student/dashboard/presentation/pages/student_dashboard_page.dart';
import 'package:pi_iv_time3/features/student/dashboard/presentation/widgets/student_dashboard_list_view.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/pages/student_disciplines_page.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/pages/student_ava_cockpit_page.dart';
import 'package:pi_iv_time3/features/student/disciplines/presentation/widgets/ava_evaluations_grades_tab.dart';
import 'package:pi_iv_time3/features/student/calendar/presentation/pages/student_calendar_page.dart';
import 'package:pi_iv_time3/features/student/deliveries/presentation/pages/student_deliveries_page.dart';
import 'package:pi_iv_time3/features/student/settings/presentation/pages/student_settings_page.dart';
import '../../helpers/student_fixtures.dart';

class _StudentDashboardDataSource extends StudentRemoteDataSource {
  bool submitted = false;
  final List<Map<String, dynamic>> reminders = [];

  @override
  Future<StudentDashboardSnapshot> getBootstrap() async =>
      StudentDashboardSnapshot.fromJson({
        'studentInfo': {
          'name': 'Gabriel',
          'courseName': 'Engenharia de Software',
          'semester': '5º Semestre',
        },
        'stats': {
          'activeDisciplines': 1,
          'averageAttendance': 94.8,
          'cr': 8.8,
          'academicStatus': 'Regular',
          'completedHoursSemester': 40,
          'totalHoursSemester': 80,
        },
        'todayClass': {
          'roomCode': 'APS-II',
          'disciplineName': 'Análise e Projeto de Sistemas II',
          'time': '19:00 - 20:40',
          'teacher': 'Profa. Responsável',
          'isLive': false,
        },
        'disciplines': [
          {
            'code': 'APS-II',
            'fullCode': '218131 - APS-II',
            'name': 'Análise e Projeto de Sistemas II',
            'professor': 'Profa. Responsável',
            'progress': 0.5,
          },
        ],
        'deliveries': [
          {
            'id': 'assignment-1',
            'title': 'Entrega real de teste',
            'disciplineCode': 'APS-II',
            'disciplineName': 'Análise e Projeto de Sistemas II',
            'dueDate': '20/09/2026',
            'dueHour': '23:59',
            'status': submitted ? 'Em Análise' : 'Pendente',
            'protocol': submitted ? 'AGR-TEST-001' : null,
            'weight': 2,
          },
        ],
        'events': [
          {
            'id': 'event-1',
            'title': 'Aula registrada no servidor',
            'date': '2026-09-20T19:00:00.000Z',
            'timeRange': '19:00 - 20:40',
            'category': 'aula',
            'courseCode': 'APS-II',
          },
          ...reminders,
        ],
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

  @override
  Future<Map<String, dynamic>> addReminder({
    required String title,
    required String date,
    required String timeRange,
    required String courseCode,
    required String location,
  }) async {
    final reminder = {
      'id': 'reminder-${reminders.length + 1}',
      'title': title,
      'date': date,
      'timeRange': timeRange,
      'category': 'lembrete',
      'courseCode': courseCode,
      'location': location,
    };
    reminders.add(reminder);
    return reminder;
  }
}

void main() {
  testWidgets('Boletim mostra notas da disciplina selecionada', (tester) async {
    AppUserSession.instance.signIn(
      identity: StudentFixtures.studentRa,
      profile: 'aluno',
    );
    addTearDown(AppUserSession.instance.signOut);
    final discipline = StudentFixtures.disciplines.firstWhere(
      (item) => item.code == 'BD-II',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AvaEvaluationsGradesTab(discipline: discipline),
          ),
        ),
      ),
    );

    expect(find.text('9.0 / 10.0'), findsNWidgets(2));
    expect(find.text('8.5 / 10.0'), findsOneWidget);
    expect(find.text('Projeto Final Integrador (N2)'), findsNothing);
  });

  group('StudentPortalController Unit Tests', () {
    setUp(() {
      AppUserSession.instance.signIn(
        identity: StudentFixtures.studentRa,
        profile: 'aluno',
      );
      addTearDown(AppUserSession.instance.signOut);
    });

    test('Alterna entre modo Grid e Lista no Dashboard', () {
      final controller = StudentPortalController();
      controller.toggleDashboardView(false);
      expect(controller.isGridView, false);

      controller.toggleDashboardView(true);
      expect(controller.isGridView, true);
    });

    test('Seleciona disciplina para cockpit do AVA', () {
      final controller = StudentPortalController();
      final target = StudentFixtures.disciplines[1];
      controller.selectDiscipline(target);
      expect(controller.selectedDiscipline!.code, 'BD-II');
    });

    test('Persiste lembrete acadêmico pelo datasource', () async {
      final source = _StudentDashboardDataSource();
      final controller = StudentPortalController.withRemoteDataSource(source);
      AppUserSession.instance.signIn(
        identity: StudentFixtures.studentRa,
        profile: 'aluno',
        accessToken: 'test-student-token',
      );
      await controller.loadRemote();
      final initialCount = controller.events.length;

      await controller.addCalendarEvent(
        title: 'Plantão Extra de Dúvidas GoF',
        date: '2026-10-28',
        time: '18:00',
        type: 'Aula',
        discipline: 'APS-II',
        location: 'Sala Virtual AVA',
      );

      expect(controller.events.length, initialCount + 1);
      expect(
        controller.events.any((event) => event.title == 'Plantão Extra de Dúvidas GoF'),
        isTrue,
      );
    });

    test('Identidade sem registro demo persiste lembrete no servidor', () async {
      final source = _StudentDashboardDataSource();
      final controller = StudentPortalController.withRemoteDataSource(source);
      AppUserSession.instance.signIn(
        identity: '2024.1.00001',
        profile: 'aluno',
        accessToken: 'test-student-token',
      );
      await controller.loadRemote();
      final initialCount = controller.events.length;

      await controller.addCalendarEvent(
        title: 'Evento sem vínculo',
        date: '2026-10-28',
        time: '18:00',
        type: 'Aula',
        discipline: 'APS-II',
        location: 'Sala Virtual',
      );

      expect(controller.events, hasLength(initialCount + 1));
      expect(
        controller.events.any((event) => event.title == 'Evento sem vínculo'),
        isTrue,
      );
    });

    test('Protocolar submissão de atividade gera protocolo e muda status', () async {
      final source = _StudentDashboardDataSource();
      final controller = StudentPortalController.withRemoteDataSource(source);
      AppUserSession.instance.signIn(
        identity: StudentFixtures.studentRa,
        profile: 'aluno',
        accessToken: 'test-student-token',
      );
      await controller.loadRemote();
      final protocol = await controller.submitDelivery(
        deliveryId: 'assignment-1',
        fileName: 'teste_entrega.zip',
        fileSize: '4 KB',
        mimeType: 'application/zip',
        contentBase64: 'dGVzdA==',
        gitUrl: 'https://github.com/teste/repo',
        comments: 'Trabalho completo.',
      );

      final submitted = controller.deliveries.single;
      expect(protocol['protocolCode'], 'AGR-TEST-001');
      expect(submitted.status, 'Em Análise');
      expect(submitted.protocol, 'AGR-TEST-001');
    });

    test('Navegação de abas no Cockpit do AVA', () {
      final controller = StudentPortalController();
      controller.setAvaTab(2); // Sala Virtual
      expect(controller.activeAvaTabIndex, 2);
    });

    test('Atualiza estado do 2FA e seleciona aba de configurações', () {
      final controller = StudentPortalController();
      final initial2FA = controller.isTwoFactorEnabled;
      controller.setTwoFactorEnabled(!initial2FA);
      expect(controller.isTwoFactorEnabled, !initial2FA);

      controller.setSettingsTab(1); // Segurança
      expect(controller.selectedSettingsTabIndex, 1);
    });
  });

  group('Student Views Rendering Tests', () {
    testWidgets('Renderiza StudentDashboardPage com KPIs e card de aula', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      AppUserSession.instance.signIn(
        identity: '2024.1.00892',
        profile: 'aluno',
        accessToken: 'test-student-token',
      );
      addTearDown(AppUserSession.instance.signOut);
      final controller = StudentPortalController.withRemoteDataSource(
        _StudentDashboardDataSource(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StudentDashboardPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo, Gabriel.'), findsOneWidget);
      expect(find.text('DISCIPLINAS'), findsOneWidget);
      expect(find.text('ENTREGAS PENDENTES'), findsOneWidget);
      expect(find.text('COEFICIENTE DE RENDIMENTO (CR)'), findsOneWidget);
      expect(find.text('CARGA HORÁRIA DO SEMESTRE'), findsOneWidget);
      expect(find.text('Análise e Projeto de Sistemas II'), findsWidgets);
    });

    testWidgets(
      'Renderiza StudentDashboardPage em modo lista e permite alternar',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        AppUserSession.instance.signIn(
          identity: '2024.1.00892',
          profile: 'aluno',
          accessToken: 'test-student-token',
        );
        addTearDown(AppUserSession.instance.signOut);
        final controller = StudentPortalController.withRemoteDataSource(
          _StudentDashboardDataSource(),
        );
        controller.toggleDashboardView(false); // Ativa modo lista

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StudentDashboardPage(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('20/09/2026'), findsOneWidget);
        expect(find.text('Entrega real de teste'), findsOneWidget);

        // Restaura para modo bloco/grid
        controller.toggleDashboardView(true);
        await tester.pumpAndSettle();
        expect(find.text('Bem-vindo, Gabriel.'), findsOneWidget);
      },
    );

    testWidgets(
      'Renderiza StudentDisciplinesPage com estatísticas e ensalamento',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: StudentDisciplinesPage())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Minhas Disciplinas'), findsOneWidget);
        expect(find.text('Boletim & Histórico Oficial'), findsOneWidget);
        expect(find.text('Nenhuma disciplina disponível.'), findsOneWidget);
      },
    );

    testWidgets(
      'Renderiza StudentCalendarPage com visualização em mês e agenda',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = StudentPortalController.instance;
        controller.setCalendarFocusedDate(DateTime(2026, 10, 20));

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: StudentCalendarPage())),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(_monthLabel(controller.calendarFocusedDate)),
          findsWidgets,
        );
        expect(find.byTooltip('Novo Evento'), findsOneWidget);
        expect(find.text('CALENDÁRIOS'), findsOneWidget);
        expect(find.text('Semana'), findsOneWidget);
        expect(find.text('Mês'), findsOneWidget);
        expect(find.text('Agenda'), findsOneWidget);
      },
    );

    testWidgets('Renderiza StudentDeliveriesPage e modal de devolutiva', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StudentDeliveriesPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Central de Entregas & Atividades'), findsOneWidget);
      expect(find.text('PENDENTES'), findsOneWidget);
      expect(find.text('AVALIADAS'), findsOneWidget);
      expect(find.text('MÉDIA PONDERADA'), findsOneWidget);
    });

    testWidgets('Renderiza StudentSettingsPage com as 5 subabas', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: StudentSettingsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configurações da Conta Discente'), findsOneWidget);
      expect(find.text('Perfil & Identidade'), findsOneWidget);
      expect(find.text('Segurança & Acessos'), findsOneWidget);
      expect(find.text('Central de Notificações'), findsOneWidget);
      expect(find.text('Preferências do Sistema'), findsOneWidget);
      expect(find.text('Privacidade & LGPD'), findsOneWidget);
    });

    testWidgets('Renderiza StudentAvaCockpitPage com as 12 abas de disciplina', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fisDiscipline = StudentFixtures.disciplines.firstWhere(
        (d) => d.code == 'FIS',
      );
      final controller = StudentPortalController.instance;
      controller.selectDiscipline(fisDiscipline);
      controller.setAvaTab(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentAvaCockpitPage(
              discipline: fisDiscipline,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Filosofia, Informação e Sociedade'), findsOneWidget);
      expect(
        find.byKey(const Key('btn_voltar_minhas_disciplinas')),
        findsOneWidget,
      );
      expect(find.text('Página inicial'), findsOneWidget);
      expect(find.text('Módulos & Conteúdos de Aprendizagem'), findsOneWidget);
      expect(find.text('Tarefas e Atividades'), findsOneWidget);
      expect(find.text('Sala Virtual'), findsOneWidget);
      expect(find.text('Fóruns'), findsOneWidget);
      expect(find.text('Notas'), findsOneWidget);
      expect(
        find.text(
          'Unidade 1: Ética na Sociedade Algorítmica e Inteligência Artificial',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Texto Base: O Dilema das Redes e a Automação do Julgamento Moral',
        ),
        findsOneWidget,
      );
      expect(find.text('DADOS DA MATRÍCULA DISCENTE'), findsOneWidget);
      expect(find.text('FREQUÊNCIA & RENDIMENTO'), findsOneWidget);
      expect(find.text('ATENDIMENTO COM DOCENTE'), findsOneWidget);
      expect(find.text('PLANO DE ENSINO'), findsOneWidget);
    });

    testWidgets('Abas do AVA permanecem sem overflow em tela mobile', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      AppUserSession.instance.signIn(
        identity: StudentFixtures.studentRa,
        profile: 'aluno',
      );
      addTearDown(AppUserSession.instance.signOut);

      final controller = StudentPortalController.instance;
      final discipline = StudentFixtures.disciplines.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentAvaCockpitPage(discipline: discipline, onBack: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var index = 0; index < 11; index++) {
        controller.setAvaTab(index);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Aba $index');
      }
    });

    testWidgets('Renderiza StudentDashboardListView com blocos da timeline e Sir Nicolau único', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final timeline = StudentTimelineResponse(
        generatedAt: '2026-09-20T12:00:00.000Z',
        blocks: [
          const StudentTimelineBlock(
            type: 'day',
            label: 'Quinta-feira, 17 de setembro',
            items: [
              StudentTimelineItem(
                id: 'asg-1',
                kind: 'assignment',
                title: 'Entrega: Atividade 2 - Modelagem de Banco de Dados Relacional',
                subtitle: 'Banco de Dados II • Profª. Dra. Eliane Ramos',
                completed: true,
                trailingType: 'text',
                trailingText: 'Concluído',
              ),
            ],
          ),
          const StudentTimelineBlock(
            type: 'day',
            label: 'Hoje, 20 de setembro',
            items: [
              StudentTimelineItem(
                id: 'asg-2',
                kind: 'assignment',
                title: 'Atividade Prática 03: Implementação de API REST',
                subtitle: 'Engenharia de Software • Envio pelo AVA até 23:59',
                completed: false,
                trailingType: 'deadline',
                trailingText: 'até 23:59',
              ),
            ],
          ),
          const StudentTimelineBlock(
            type: 'gap',
            label: 'setembro 22 a dezembro 12',
            mascot: true,
            message: 'Nada planejado ainda',
          ),
          const StudentTimelineBlock(
            type: 'milestone',
            label: 'domingo, 13 de dezembro',
            description: 'Término das avaliações semestrais',
          ),
          const StudentTimelineBlock(
            type: 'milestone',
            label: 'fevereiro 2027',
            description: 'Início das aulas do próximo período letivo',
          ),
        ],
      );

      final dummyDashboard = StudentDashboardSnapshot(
        studentInfo: const {'name': 'Aluno Teste'},
        stats: const {'completedHoursSemester': 20, 'totalHoursSemester': 80},
        recordSummary: const {},
        todayClass: null,
        freeSchedule: null,
        disciplines: const [],
        deliveries: const [],
        events: const [],
        messages: const [],
        personalNotes: const {},
        protocols: const [],
        forumTopics: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentDashboardListView(
              dashboard: dummyDashboard,
              timeline: timeline,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quinta-feira, 17 de setembro'), findsOneWidget);
      expect(find.text('Entrega: Atividade 2 - Modelagem de Banco de Dados Relacional'), findsOneWidget);
      expect(find.text('Hoje, 20 de setembro'), findsOneWidget);
      expect(find.text('Atividade Prática 03: Implementação de API REST'), findsOneWidget);
      expect(find.text('até 23:59'), findsOneWidget);
      expect(find.text('setembro 22 a dezembro 12'), findsOneWidget);
      expect(find.text('Nada planejado ainda'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('domingo, 13 de dezembro'), findsOneWidget);
      expect(find.text('Término das avaliações semestrais'), findsOneWidget);
      expect(find.text('fevereiro 2027'), findsOneWidget);
      expect(find.text('Início das aulas do próximo período letivo'), findsOneWidget);
    });
  });
}

String _monthLabel(DateTime date) {
  const months = [
    'JANEIRO',
    'FEVEREIRO',
    'MARÇO',
    'ABRIL',
    'MAIO',
    'JUNHO',
    'JULHO',
    'AGOSTO',
    'SETEMBRO',
    'OUTUBRO',
    'NOVEMBRO',
    'DEZEMBRO',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
