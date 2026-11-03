// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/admin/audit/presentation/pages/audit_page.dart';
import 'package:pi_iv_time3/features/admin/calendar/presentation/pages/calendar_page.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/pages/classes_page.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/pages/supervision_cockpit_page.dart';
import 'package:pi_iv_time3/features/admin/courses/presentation/pages/courses_page.dart';
import 'package:pi_iv_time3/features/admin/dashboard/presentation/pages/painel_geral_page.dart';
import 'package:pi_iv_time3/features/admin/secretary/presentation/pages/secretary_page.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/pages/admin_shell_page.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/pages/users_page.dart';
import '../../helpers/admin_fixtures.dart';
import '../../helpers/fake_admin_academic_data_source.dart';

void main() {
  group('AdminPortalController Unit Tests', () {
    setUp(() {
      AppUserSession.instance.signIn(identity: 'ADM-00129', profile: 'admin');
      addTearDown(AppUserSession.instance.signOut);
    });

    testWidgets('Admin usa um perfil único com permissões administrativas', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = AdminPortalController.instance;

      await tester.pumpWidget(const MaterialApp(home: AdminShellPage()));

      expect(controller.currentOperatorRole, 'admin');
      expect(controller.canPerform('manage_users'), isTrue);
      expect(controller.canPerform('system_settings_2fa'), isTrue);
    });

    testWidgets('Admin pode consultar pauta sem receber permissão docente', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: AdminShellPage()));

      final controller = AdminPortalController.instance;
      expect(controller.currentOperatorRole, 'admin');
      expect(controller.hasPermission('admin', 'view_class_grades'), isTrue);
      expect(controller.hasPermission('admin', 'edit_grades'), isFalse);
    });

    test('Filtros não inventam usuários antes do bootstrap remoto', () {
      final controller = AdminPortalController();
      controller.setUserFilter('Alunos');
      expect(controller.filteredUsers, isEmpty);

      controller.setUserFilter('Todos');
      controller.setUserSearchQuery('Helena');
      expect(controller.filteredUsers, isEmpty);
      controller.setUserSearchQuery('');
    });

    test('RBAC controla ações mesmo sem usuários carregados', () async {
      final controller = AdminPortalController();

      AppUserSession.instance.signIn(
        identity: '2024.1.00892',
        profile: 'aluno',
      );
      expect(await controller.toggleUserStatus('missing-user'), isFalse);
      expect(controller.canPerform('manage_classes'), isFalse);

      AppUserSession.instance.signIn(identity: 'ADM-00129', profile: 'admin');
      expect(controller.canPerform('manage_users'), isTrue);
      expect(controller.canPerform('edit_grades'), isFalse);
      expect(controller.hasPermission('aluno', 'view_own_grades'), isTrue);
      expect(controller.hasPermission('aluno', 'view_class_grades'), isFalse);
      expect(controller.hasPermission('docente', 'view_class_grades'), isTrue);
      expect(controller.hasPermission('docente', 'edit_grades'), isTrue);
      expect(
        controller.hasPermission('Coordenador', 'manage_classes'),
        isFalse,
      );
      expect(await controller.toggleUserStatus('missing-user'), isFalse);
      expect(controller.currentOperatorRole, 'admin');
    });

    test('Não disponibiliza usuários locais sem bootstrap autenticado', () async {
      final controller = AdminPortalController();
      await controller.loadRemote();
      expect(controller.users, isEmpty);
      expect(
        controller.remoteError,
        'Entre como administrador para carregar os dados.',
      );
    });

    test('Não cria turmas locais antes do bootstrap remoto', () {
      final controller = AdminPortalController();
      expect(controller.classes, isEmpty);
    });

    test('Pautas ficam abertas enquanto não há turma carregada', () {
      final controller = AdminPortalController();
      const apsClassCode = '218131 - APS-II';
      const bdClassCode = '218131 - BD-II';

      expect(controller.isGradeLockedFor(apsClassCode), isFalse);
      expect(controller.isGradeLockedFor(bdClassCode), isFalse);
    });

    test('Não expõe protocolos sintéticos antes do bootstrap remoto', () {
      final controller = AdminPortalController();
      expect(controller.protocols, isEmpty);
    });

    test('Trava regimental não muda sem persistência no servidor', () async {
      final controller = AdminPortalController();
      final initialLock = controller.isRegimentalLockActive;

      expect(await controller.toggleRegimentalLock(), isFalse);
      expect(controller.isRegimentalLockActive, initialLock);
      expect(controller.remoteError, isNotNull);
    });
  });

  group('Admin Views Rendering Tests', () {
    setUp(() {
      AppUserSession.instance.signIn(identity: 'ADM-00129', profile: 'admin');
      addTearDown(AppUserSession.instance.signOut);
    });

    testWidgets('Renderiza PainelGeralPage com KPIs e botão de comunicado', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1680, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PainelGeralPage())),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Bem-vindo,'), findsOneWidget);
      expect(find.text('Emitir Comunicado Institucional'), findsOneWidget);
      expect(find.text('DISCENTES ATIVOS'), findsOneWidget);
      expect(find.text('CORPO DOCENTE'), findsOneWidget);
      expect(find.text('TURMAS EM ANDAMENTO'), findsOneWidget);
      expect(find.text('PROTOCOLOS DE SECRETARIA'), findsOneWidget);
      expect(find.text('Alertas da Secretaria'), findsOneWidget);
      expect(find.text('Requerimentos Discentes'), findsOneWidget);
      expect(find.text('Fechamento do Período'), findsOneWidget);
      expect(find.text('Cursos & Matrizes Ativas'), findsOneWidget);
      expect(find.text('Prazos Regimentais'), findsOneWidget);
      expect(find.text('Últimos Requerimentos'), findsOneWidget);
    });

    testWidgets(
      'Renderiza UsersPage com tabela e modal de novo cadastro institucional',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: UsersPage())),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Gestão de Usuários & Controle de Acessos'),
          findsOneWidget,
        );
        expect(find.text('Novo Cadastro Institucional'), findsOneWidget);
        expect(find.text('IDENTIFICAÇÃO'), findsOneWidget);
        expect(find.text('NOME DO USUÁRIO'), findsOneWidget);
        expect(find.text('PERFIL'), findsOneWidget);
        expect(find.text('CURSO / LOTAÇÃO'), findsOneWidget);
        expect(find.text('STATUS'), findsOneWidget);
        expect(find.text('AÇÕES DE SEGURANÇA & GOVERNANÇA'), findsOneWidget);

        // Abre modal de Novo Cadastro Institucional
        await tester.tap(find.text('Novo Cadastro Institucional'));
        await tester.pumpAndSettle();

        expect(find.text('GESTÃO DE IDENTIDADES & ACESSOS'), findsOneWidget);
        expect(find.text('Tipo de Vínculo Acadêmico'), findsOneWidget);
        expect(find.text('Discente (Aluno)'), findsOneWidget);
        expect(find.text('Nome Completo do Usuário'), findsOneWidget);
        expect(find.text('E-mail Institucional'), findsOneWidget);
        expect(find.text('R.A. / Matrícula'), findsOneWidget);
        expect(find.text('Curso de Ingresso'), findsOneWidget);
        expect(find.text('Concluir Cadastro'), findsOneWidget);

        // Fecha modal
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.text('GESTÃO DE IDENTIDADES & ACESSOS'), findsNothing);
      },
    );

    testWidgets('Renderiza CoursesPage com matrizes curriculares e modal', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CoursesPage(dataSource: FakeAdminAcademicDataSource()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cursos & Matrizes Curriculares (PPC)'), findsOneWidget);
      expect(
        find.text('Bacharelado em Engenharia de Software'),
        findsOneWidget,
      );
      expect(
        find.text('Bacharelado em Sistemas de Informação'),
        findsOneWidget,
      );
      expect(find.text('Bacharelado em Ciência da Computação'), findsOneWidget);
      expect(
        find.text('Tecnologia em Análise e Desenvolvimento de Sistemas'),
        findsOneWidget,
      );
      expect(
        find.text('Consultar Matriz Curricular & Ementário'),
        findsWidgets,
      );
      expect(find.text('© 2026 AGMRM'), findsOneWidget);

      // Abre modal da primeira matriz
      await tester.tap(
        find.text('Consultar Matriz Curricular & Ementário').first,
      );
      await tester.pumpAndSettle();

      expect(find.text('MATRIZ CURRICULAR & COMPONENTES'), findsOneWidget);
      expect(
        find.text(
          'Componentes Curriculares em Oferta no Período Letivo Vigente:',
        ),
        findsOneWidget,
      );

      // Fecha modal
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();

      expect(find.text('MATRIZ CURRICULAR & COMPONENTES'), findsNothing);
    });

    testWidgets(
      'Renderiza ClassesPage com tabela de turmas e modal de regime de avaliação',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1680, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ClassesPage(dataSource: FakeAdminAcademicDataSource()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Gestão de Turmas, Ensalamento & Atribuição Docente'),
          findsOneWidget,
        );
        expect(find.text('CÓDIGO / DISCIPLINA'), findsOneWidget);
        expect(find.text('CURSO & TURNO'), findsOneWidget);
        expect(find.text('LOCAL / ENSALAMENTO'), findsOneWidget);
        expect(find.text('VAGAS OCUPADAS'), findsOneWidget);
        expect(find.text('DOCENTE RESPONSÁVEL'), findsOneWidget);
        expect(find.text('REGIME DE AVALIAÇÃO'), findsOneWidget);
        expect(find.text('Análise e Projeto de Sistemas II'), findsOneWidget);
        expect(find.text('Estudos de Banco de Dados II'), findsOneWidget);
        expect(find.text('Supervisionar'), findsWidgets);
        expect(find.text('Regime'), findsWidgets);
        expect(find.text('Alocar'), findsWidgets);

        // Garante visibilidade e abre o modal de Regime de Avaliação da primeira turma
        await tester.ensureVisible(find.text('Regime').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Regime').first);
        await tester.pumpAndSettle();

        expect(
          find.text('GOVERNANÇA & PRERROGATIVAS DE AVALIAÇÃO'),
          findsOneWidget,
        );
        expect(find.text('Regime da Fórmula da Nota Final'), findsOneWidget);
        expect(
          find.text('DEFINIR PRERROGATIVA DA FÓRMULA DE AVALIAÇÃO'),
          findsOneWidget,
        );
        expect(find.text('Salvar Diretriz da Disciplina'), findsOneWidget);

        // Fecha o modal
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.text('Regime da Fórmula da Nota Final'), findsNothing);
      },
    );

    testWidgets('Salva uma turma sem usar controllers descartados', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final dataSource = FakeAdminAcademicDataSource();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ClassesPage(dataSource: dataSource)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir turma'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Código da turma'),
        'TESTE-2026-2',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sala/local'),
        'Lab 1',
      );
      await tester.tap(find.text('Salvar turma'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('TESTE-2026-2'), findsOneWidget);
    });

    testWidgets('Renderiza SupervisionCockpitPage com 5 abas de auditoria', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupervisionCockpitPage(
              classModel: AdminMockData.classes.first,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Voltar para Gestão de Turmas'), findsOneWidget);
      expect(find.text('Diretriz & Regime Avaliativo'), findsOneWidget);
      expect(find.text('Auditoria de Notas & Pauta'), findsOneWidget);
      expect(find.text('Atribuição Docente'), findsOneWidget);
      expect(find.text('Discentes & Vagas'), findsOneWidget);
      expect(find.text('Fechamento de Pauta & Homologação'), findsOneWidget);

      await tester.tap(find.text('Discentes & Vagas'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum estudante matriculado nesta turma.'), findsOneWidget);
    });

    testWidgets('Supervisão se adapta à largura mobile sem overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = AdminPortalController.instance;
      controller.setSupervisionTab(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupervisionCockpitPage(
              classModel: AdminMockData.classes.first,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diretrizes de cálculo da nota'), findsOneWidget);
      await tester.ensureVisible(find.text('Fórmula equitativa'));
      await tester.tap(find.text('Fórmula equitativa'));
      await tester.pumpAndSettle();

      expect(
        controller.selectedEvaluationFormula,
        'Equitativa (N1 50% / N2 50%)',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renderiza SecretaryPage com protocolos e ações de análise', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SecretaryPage())),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Secretaria Acadêmica Geral & Protocolos'),
        findsOneWidget,
      );
      expect(find.text('Aguardando Parecer'), findsWidgets);
    });

    testWidgets('Renderiza CalendarPage com resolução CONSEPE e travas', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CalendarPage())),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Calendário Acadêmico Oficial & Prazos Regimentais'),
        findsOneWidget,
      );
      expect(find.text('Nenhum marco cadastrado.'), findsOneWidget);

      // Testa botão de trava regimental
      final lockButton = find.text('Ativar trava');
      expect(lockButton, findsOneWidget);
      await tester.tap(lockButton);
      await tester.pumpAndSettle();

      expect(find.text('Ativar trava'), findsOneWidget);
    });

    testWidgets('Renderiza AuditPage com logs de segurança e severidades', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AuditPage())),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Auditoria de Segurança & Trilha Documental (Audit Trail)'),
        findsOneWidget,
      );
      expect(
        find.text('Buscar por ator, ação ou descrição nos logs...'),
        findsOneWidget,
      );
      expect(
        find.text('Nenhum registro de auditoria encontrado para o filtro informado.'),
        findsOneWidget,
      );
    });
  });
}
