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

      expect(find.text('Quinta-feira, 17 de setembro'), findsOneWidget);
      expect(find.text('Entrega: Atividade 2 - Modelagem de Banco de Dados Relacional'), findsOneWidget);
      expect(find.text('Sexta-feira, 18 de setembro'), findsOneWidget);
      expect(find.text('Fórum Avaliativo: Impactos éticos da IA em Sistemas Críticos'), findsOneWidget);
      expect(find.text('Ontem, 19 de setembro'), findsOneWidget);
      expect(find.text('Material Complementar: Estudo de Caso de Microsserviços'), findsOneWidget);
      expect(find.text('Hoje, 20 de setembro'), findsOneWidget);
      expect(find.text('Atividade Prática 03: Implementação de API REST'), findsOneWidget);
      expect(find.text('Fórum Temático: Desafios da Concorrência em Sistemas Distribuídos'), findsOneWidget);
      expect(find.text('Amanhã, 21 de setembro'), findsOneWidget);
      expect(find.text('Fórum de Dúvidas: Preparação para a Avaliação A1'), findsOneWidget);
      expect(find.text('Cálculo Diferencial e Integral • Profª. Sandra Helena'), findsOneWidget);
      expect(find.text('setembro 22 a dezembro 12'), findsOneWidget);
      expect(find.text('Término das avaliações semestrais'), findsOneWidget);
      expect(find.text('Férias e encerramento de notas'), findsOneWidget);
      expect(find.text('Início das aulas do próximo período letivo'), findsOneWidget);

      // Toca na tarefa do fórum para alternar checkbox
      await tester.tap(find.byKey(const Key('btn_toggle_item_21_sep')));
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
      expect(find.text('SESSÃO ATIVA NO AVA • CONTINUAR DE ONDE PAROU'), findsOneWidget);
      expect(find.textContaining('Plano de Ensino & Ementa'), findsWidgets);
      expect(find.textContaining('Quadro Semanal de Horários'), findsOneWidget);
      expect(find.text('Próximas Avaliações & Entregas'), findsOneWidget);
      expect(find.text('Mural de Avisos & Comunicados Docentes'), findsOneWidget);
      expect(find.text('Apoio Acadêmico & Recursos Oficiais'), findsOneWidget);

      // Alterna para visualização em lista
      await tester.tap(find.byKey(const Key('btn_modo_lista_disciplinas')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('btn_entrar_disciplina_list_APS-II')), findsOneWidget);

      // Alterna de volta para grade de cards
      await tester.tap(find.byKey(const Key('btn_modo_grade_disciplinas')));
      await tester.pumpAndSettle();

      // Clica no card de retomada de aula (Fast-Resume) para entrar no AVA Cockpit
      await tester.tap(find.byKey(const Key('btn_retomar_aula_ava')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('btn_voltar_minhas_disciplinas')), findsOneWidget);
      expect(find.text('Análise e Projeto de Sistemas II'), findsWidgets);

      // Troca de disciplina diretamente dentro do Cockpit
      await tester.tap(find.text('BD-II'));
      await tester.pumpAndSettle();
      expect(find.text('Estudos de Banco de Dados II'), findsWidgets);

      // Retorna para a página principal de Minhas Disciplinas
      await tester.tap(find.byKey(const Key('btn_voltar_minhas_disciplinas')));
      await tester.pumpAndSettle();
      expect(find.text('Minhas Disciplinas'), findsWidgets);
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

      expect(find.text('SETEMBRO 2026'), findsWidgets);
      expect(find.byTooltip('Novo Evento'), findsOneWidget);
      expect(find.text('CALENDÁRIOS'), findsOneWidget);
      expect(find.text('Semana'), findsOneWidget);
      expect(find.text('Mês'), findsOneWidget);
      expect(find.text('Agenda'), findsOneWidget);
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

      final fisDiscipline = StudentMockData.disciplines.firstWhere((d) => d.code == 'FIS');

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
      expect(find.byKey(const Key('btn_voltar_minhas_disciplinas')), findsOneWidget);
      expect(find.text('Página inicial'), findsOneWidget);
      expect(find.text('Módulos & Conteúdos de Aprendizagem'), findsOneWidget);
      expect(find.text('Tarefas e Atividades'), findsOneWidget);
      expect(find.text('Sala Virtual'), findsOneWidget);
      expect(find.text('Fóruns'), findsOneWidget);
      expect(find.text('Notas'), findsOneWidget);
      expect(find.text('Unidade 1: Ética na Sociedade Algorítmica e Inteligência Artificial'), findsOneWidget);
      expect(find.text('Texto Base: O Dilema das Redes e a Automação do Julgamento Moral'), findsOneWidget);
      expect(find.text('Fórum Temático: Vieses Algorítmicos e Responsabilidade Civil de IAs Autônomas'), findsOneWidget);
      expect(find.text('DADOS DA MATRÍCULA DISCENTE'), findsOneWidget);
      expect(find.text('FREQUÊNCIA & RENDIMENTO'), findsOneWidget);
      expect(find.text('ATENDIMENTO COM DOCENTE'), findsOneWidget);
      expect(find.text('PLANO DE ENSINO'), findsOneWidget);
    });
  });
}

