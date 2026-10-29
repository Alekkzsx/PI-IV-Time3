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
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/shell/presentation/pages/admin_shell_page.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/pages/users_page.dart';

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

    test('Filtra usuários por perfil e realiza busca', () {
      final controller = AdminPortalController();
      controller.setUserFilter('Alunos');
      expect(controller.filteredUsers.every((u) => u.profile == 'aluno'), true);

      controller.setUserFilter('Todos');
      controller.setUserSearchQuery('Helena');
      expect(controller.filteredUsers.length, 1);
      expect(
        controller.filteredUsers.first.name,
        contains('Helena Bittencourt'),
      );
      controller.setUserSearchQuery('');
    });

    test('RBAC bloqueia ações sem permissão e libera as ações autorizadas', () {
      final controller = AdminPortalController();
      final user = controller.users.first;
      final initialStatus = user.status;

      AppUserSession.instance.signIn(
        identity: '2024.1.00892',
        profile: 'aluno',
      );
      expect(controller.toggleUserStatus(user.id), isFalse);
      expect(user.status, initialStatus);
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
      expect(controller.toggleUserStatus(user.id), isTrue);
      expect(user.status, isNot(initialStatus));
      expect(controller.currentOperatorRole, 'admin');
    });

    test('Alterna suspensão de usuário e cadastra novo discente com 2FA', () {
      final controller = AdminPortalController();
      final targetUser = controller.users.first;
      final initialStatus = targetUser.status;

      controller.toggleUserStatus(targetUser.id);
      expect(
        targetUser.status,
        initialStatus == 'Ativo' ? 'Suspenso' : 'Ativo',
      );

      final initialUsersCount = controller.users.length;
      controller.addUser(
        name: 'Novo Aluno de Teste',
        email: 'novo.aluno@universidade.edu.br',
        profile: 'aluno',
        department: 'Engenharia de Software',
        require2FA: true,
      );

      expect(controller.users.length, initialUsersCount + 1);
      expect(controller.users.first.name, 'Novo Aluno de Teste');
      expect(controller.users.first.profile, 'aluno');
      expect(controller.users.first.twoFactorRequired, true);
    });

    test('Atualiza regime de avaliação da turma e reatribui docente', () {
      final controller = AdminPortalController();
      final classModel = controller.classes.first;

      controller.updateFormulaRegime(classModel.code, 'Autonomia Docente');
      expect(classModel.formulaRegime, 'Autonomia Docente');

      controller.reallocateProfessor(classModel.code, 'Prof. Substituto Teste');
      expect(classModel.professor, 'Prof. Substituto Teste');
    });

    test('Fechamento de pauta fica restrito à turma homologada', () {
      final controller = AdminPortalController();
      const apsClassCode = '218131 - APS-II';
      const bdClassCode = '218131 - BD-II';

      controller.lockAndHomologateClassPauta(apsClassCode);

      expect(controller.isGradeLockedFor(apsClassCode), isTrue);
      expect(controller.isGradeLockedFor(bdClassCode), isFalse);
    });

    test('Decide protocolo na secretaria acadêmica com despacho', () {
      final controller = AdminPortalController();
      final protocol = controller.protocols.firstWhere(
        (p) => p.status.startsWith('Aguardando'),
      );

      controller.decideProtocol(
        protocolId: protocol.id,
        defer: true,
        parecerNote: 'Aprovado pelo comitê acadêmico.',
      );

      expect(protocol.status, 'Deferido');
      expect(protocol.decisionNote, 'Aprovado pelo comitê acadêmico.');
      expect(protocol.signedBy, 'Administrador institucional');
    });

    test('Alterna trava regimental CONSEPE e lacra pauta de turma', () {
      final controller = AdminPortalController();
      final initialLock = controller.isRegimentalLockActive;

      controller.toggleRegimentalLock();
      expect(controller.isRegimentalLockActive, !initialLock);

      controller.lockAndHomologateClassPauta('218131 - APS-II');
      expect(controller.isGradeLocked, true);
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
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PainelGeralPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo, Carlos.'), findsOneWidget);
      expect(find.text('Secretaria Geral Acadêmica'), findsOneWidget);
      expect(find.text('Gestão Integrada do Campus 2026/2'), findsOneWidget);
      expect(find.text('Emitir Comunicado Institucional'), findsOneWidget);
      expect(find.text('DISCENTES ATIVOS'), findsOneWidget);
      expect(find.text('CORPO DOCENTE'), findsOneWidget);
      expect(find.text('TURMAS EM ANDAMENTO'), findsOneWidget);
      expect(find.text('PROTOCOLOS DE SECRETARIA'), findsOneWidget);
      expect(find.text('Alertas da Secretaria'), findsOneWidget);
      expect(find.text('Requerimentos Discentes'), findsOneWidget);
      expect(find.text('Fechamento do Período'), findsOneWidget);
      expect(find.text('Cursos & Matrizes Ativas'), findsOneWidget);
      expect(
        find.text('Bacharelado em Engenharia de Software'),
        findsOneWidget,
      );
      expect(
        find.text('Bacharelado em Sistemas de Informação'),
        findsOneWidget,
      );
      expect(find.text('Prazos Regimentais'), findsOneWidget);
      expect(find.text('Últimos Requerimentos'), findsOneWidget);
      expect(find.text('Camila Duarte Fagundes'), findsOneWidget);
      expect(find.text('© 2026 AGMRM'), findsOneWidget);
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
        expect(find.text('Gabriel Soares de Oliveira'), findsOneWidget);
        expect(find.text('Profa. Dra. Helena Bittencourt'), findsOneWidget);
        expect(find.text('© 2026 AGMRM'), findsOneWidget);

        // Abre modal de Novo Cadastro Institucional
        await tester.tap(find.text('Novo Cadastro Institucional'));
        await tester.pumpAndSettle();

        expect(find.text('GESTÃO DE IDENTIDADES & ACESSOS'), findsOneWidget);
        expect(find.text('Tipo de Vínculo Acadêmico'), findsOneWidget);
        expect(find.text('Discente (Aluno)'), findsOneWidget);
        expect(find.text('Nome Completo do Usuário'), findsOneWidget);
        expect(find.text('E-mail Institucional'), findsOneWidget);
        expect(find.text('R.A. Gerado Oficial'), findsOneWidget);
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
        const MaterialApp(home: Scaffold(body: CoursesPage())),
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
          const MaterialApp(home: Scaffold(body: ClassesPage())),
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
      expect(find.text('Gabriel Soares de Oliveira'), findsOneWidget);
      expect(find.text('Mariana Rios Costa'), findsOneWidget);
      expect(find.text('Camila Duarte Fagundes'), findsOneWidget);
      expect(find.text('Lucas Mendes Santos'), findsNothing);
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
      expect(find.text('RESOLUÇÃO CONSEPE 2026/04'), findsOneWidget);
      expect(find.text('Semana 10 de 18'), findsOneWidget);
      expect(
        find.text('Janela de Avaliações Parciais e Trabalhos Práticos'),
        findsOneWidget,
      );
      expect(
        find.text('Prazo Final para Digitação e Homologação de Diários'),
        findsOneWidget,
      );
      expect(find.text('Em Andamento'), findsOneWidget);
      expect(find.text('Futuro'), findsWidgets);

      // Testa botão de trava regimental
      final lockButton = find.text('Ativar Trava Regimental');
      expect(lockButton, findsOneWidget);
      await tester.tap(lockButton);
      await tester.pumpAndSettle();

      expect(find.text('Liberar Diários'), findsOneWidget);
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
      expect(find.text('Profa. Dra. Helena Bittencourt'), findsOneWidget);
      expect(find.text('Docente (DOC-88410)'), findsOneWidget);
      expect(find.text('ALTERACAO NOTA'), findsOneWidget);
      expect(find.text('Sistema de Segurança'), findsOneWidget);
      expect(find.text('INFO'), findsWidgets);
      expect(find.text('ATENCAO'), findsWidgets);
    });
  });
}
