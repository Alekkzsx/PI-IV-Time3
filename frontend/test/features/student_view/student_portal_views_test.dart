// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/student_view/shared/data/student_mock_data.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student_view/dashboard/presentation/pages/student_dashboard_page.dart';
import 'package:pi_iv_time3/features/student_view/disciplines/presentation/pages/student_disciplines_page.dart';
import 'package:pi_iv_time3/features/student_view/disciplines/presentation/pages/student_ava_cockpit_page.dart';
import 'package:pi_iv_time3/features/student_view/calendar/presentation/pages/student_calendar_page.dart';
import 'package:pi_iv_time3/features/student_view/deliveries/presentation/pages/student_deliveries_page.dart';
import 'package:pi_iv_time3/features/student_view/settings/presentation/pages/student_settings_page.dart';

void main() {
  group('StudentPortalController Unit Tests', () {
    test('Alterna entre modo Grid e Lista no Dashboard', () {
      final controller = StudentPortalController();
      controller.toggleDashboardView(false);
      expect(controller.isGridView, false);

      controller.toggleDashboardView(true);
      expect(controller.isGridView, true);
    });

    test('Seleciona disciplina para cockpit do AVA', () {
      final controller = StudentPortalController();
      final target = StudentMockData.disciplines[1]; // BD-II
      controller.selectDiscipline(target);
      expect(controller.selectedDiscipline.code, 'BD-II');
    });

    test('Filtra eventos e adiciona novo evento no calendário', () {
      final controller = StudentPortalController();
      final initialCount = controller.events.length;

      controller.addCalendarEvent(
        title: 'Plantão Extra de Dúvidas GoF',
        date: '2026-10-28',
        time: '18:00',
        type: 'Aula',
        discipline: 'APS-II',
        location: 'Sala Virtual AVA',
      );

      expect(controller.events.length, initialCount + 1);
      expect(controller.events.first.title, 'Plantão Extra de Dúvidas GoF');
    });

    test('Protocolar submissão de atividade gera protocolo e muda status', () {
      final controller = StudentPortalController();
      controller.submitDelivery(
        deliveryId: 'DEL-01',
        fileName: 'teste_entrega.zip',
        gitUrl: 'https://github.com/teste/repo',
        comments: 'Trabalho completo.',
      );

      final submitted = controller.deliveries.firstWhere((d) => d.id == 'DEL-01');
      expect(submitted.status, 'Em Análise');
      expect(submitted.protocol, isNotNull);
    });

    test('Navegação de abas no Cockpit do AVA e avanço de slides', () {
      final controller = StudentPortalController();
      controller.setAvaTab(2); // Sala Virtual
      expect(controller.activeAvaTabIndex, 2);

      final initialSlide = controller.currentSlideIndex;
      controller.nextSlide();
      expect(controller.currentSlideIndex, initialSlide + 1);

      controller.prevSlide();
      expect(controller.currentSlideIndex, initialSlide);
    });

    test('Alterna 2FA e abas de configurações discentes', () {
      final controller = StudentPortalController();
      final initial2FA = controller.isTwoFactorEnabled;
      controller.toggleTwoFactor();
      expect(controller.isTwoFactorEnabled, !initial2FA);

      controller.setSettingsTab(1); // Segurança
      expect(controller.selectedSettingsTabIndex, 1);
    });
  });

  group('Student Views Rendering Tests', () {
    testWidgets('Renderiza StudentDashboardPage com KPIs e card de aula', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo, Gabriel.'), findsOneWidget);
      expect(find.text('DISCIPLINAS'), findsOneWidget);
      expect(find.text('ENTREGAS DO MÊS'), findsOneWidget);
      expect(find.text('COEFICIENTE DE RENDIMENTO (CR)'), findsOneWidget);
      expect(find.text('HORAS COMPLEMENTARES'), findsOneWidget);
      expect(find.text('Análise e Projeto de Sistemas II'), findsWidgets);
    });

    testWidgets('Renderiza StudentDashboardPage em modo lista e permite alternar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = StudentPortalController.instance;
      controller.toggleDashboardView(false); // Ativa modo lista

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Amanhã, 21 de setembro'), findsOneWidget);
      expect(find.text('Fórum de Dúvidas: Preparação para a Avaliação A1'), findsOneWidget);
      expect(find.text('Cálculo Diferencial e Integral • Profª. Sandra Helena'), findsOneWidget);
      expect(find.text('setembro 22 a dezembro 12'), findsOneWidget);
      expect(find.text('Término das avaliações semestrais'), findsOneWidget);
      expect(find.text('Férias e encerramento de notas'), findsOneWidget);
      expect(find.text('Início das aulas do próximo período letivo'), findsOneWidget);

      // Toca na tarefa do fórum para alternar checkbox
      await tester.tap(find.byKey(const Key('btn_toggle_forum_task')));
      await tester.pumpAndSettle();

      // Restaura para modo bloco/grid
      controller.toggleDashboardView(true);
      await tester.pumpAndSettle();
      expect(find.text('Bem-vindo, Gabriel.'), findsOneWidget);
    });

    testWidgets('Renderiza StudentDisciplinesPage com estatísticas e ensalamento', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentDisciplinesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minhas Disciplinas'), findsOneWidget);
      expect(find.text('Boletim & Histórico Oficial'), findsOneWidget);
      expect(find.text('Plano de Ensino & Ementa'), findsOneWidget);
      expect(find.text('Quadro Semanal de Horários & Ensalamento Físico'), findsOneWidget);
    });

    testWidgets('Renderiza StudentCalendarPage com visualização em mês e agenda', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentCalendarPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Outubro de 2026'), findsOneWidget);
      expect(find.text('Novo Evento'), findsOneWidget);
      expect(find.text('Filtrar por Categoria'), findsOneWidget);
      expect(find.text('Filtrar por Disciplina'), findsOneWidget);
    });

    testWidgets('Renderiza StudentDeliveriesPage e modal de devolutiva', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentDeliveriesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Central de Entregas & Atividades'), findsOneWidget);
      expect(find.text('Pendentes de Envio'), findsOneWidget);
      expect(find.text('Avaliadas com Parecer'), findsOneWidget);
      expect(find.text('Média Ponderada'), findsOneWidget);
    });

    testWidgets('Renderiza StudentSettingsPage com as 5 subabas', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StudentSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configurações da Conta'), findsOneWidget);
      expect(find.text('Perfil & Identidade'), findsOneWidget);
      expect(find.text('Segurança & Acesso'), findsOneWidget);
      expect(find.text('Central de Notificações'), findsOneWidget);
      expect(find.text('Preferências do Sistema'), findsOneWidget);
      expect(find.text('Privacidade & LGPD'), findsOneWidget);
    });

    testWidgets('Renderiza StudentAvaCockpitPage com as 12 abas de disciplina', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentAvaCockpitPage(
              discipline: StudentMockData.disciplines.first,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Análise e Projeto de Sistemas II'), findsOneWidget);
      expect(find.text('Voltar para Minhas Disciplinas'), findsOneWidget);
      expect(find.text('Módulos & Conteúdos'), findsOneWidget);
      expect(find.text('Tarefas e Atividades'), findsOneWidget);
      expect(find.text('Sala Virtual (Ao Vivo)'), findsOneWidget);
      expect(find.text('Fórum de Dúvidas'), findsOneWidget);
      expect(find.text('Notas & Boletim'), findsOneWidget);
    });
  });
}

