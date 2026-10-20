// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/admin/data/admin_mock_data.dart';
import 'package:pi_iv_time3/features/admin/presentation/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/features/admin/admin_panel/presentation/pages/panel_geral_page.dart';
import 'package:pi_iv_time3/features/admin/users/presentations/pages/users_page.dart';
import 'package:pi_iv_time3/features/admin/course/presentation/pages/courses_page.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/pages/classes_page.dart';
import 'package:pi_iv_time3/features/admin/classes/presentation/pages/supervision_cockpit_page.dart';
import 'package:pi_iv_time3/features/admin/secretary/presentation/pages/secretary_page.dart';
import 'package:pi_iv_time3/features/admin/calendar/presentation/pages/calendar_page.dart';
import 'package:pi_iv_time3/features/admin/audit/presentation/pages/audit_page.dart';

void main() {
  group('AdminPortalController Unit Tests', () {
    test('Filtra usuários por perfil e realiza busca', () {
      final controller = AdminPortalController();
      controller.setUserFilter('Discente');
      expect(controller.filteredUsers.every((u) => u.profile == 'Discente'), true);

      controller.setUserFilter('Todos');
      controller.setUserSearchQuery('Helena');
      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first.name, contains('Helena Bittencourt'));
      controller.setUserSearchQuery('');
    });

    test('Alterna suspensão de usuário e cadastra novo discente com 2FA', () {
      final controller = AdminPortalController();
      final targetUser = controller.users.first;
      final initialStatus = targetUser.status;

      controller.toggleUserStatus(targetUser.id);
      expect(targetUser.status, initialStatus == 'Ativo' ? 'Suspenso' : 'Ativo');

      final initialUsersCount = controller.users.length;
      controller.addUser(
        name: 'Novo Aluno de Teste',
        email: 'novo.aluno@universidade.edu.br',
        profile: 'Discente',
        department: 'Engenharia de Software',
        require2FA: true,
      );

      expect(controller.users.length, initialUsersCount + 1);
      expect(controller.users.first.name, 'Novo Aluno de Teste');
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

    test('Decide protocolo na secretaria acadêmica com despacho', () {
      final controller = AdminPortalController();
      final protocol = controller.protocols.firstWhere((p) => p.status == 'Aguardando Parecer');

      controller.decideProtocol(
        protocolId: protocol.id,
        defer: true,
        parecerNote: 'Aprovado pelo comitê acadêmico.',
      );

      expect(protocol.status, 'Deferido');
      expect(protocol.decisionNote, 'Aprovado pelo comitê acadêmico.');
      expect(protocol.signedBy, contains('Carlos Eduardo Mendes'));
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
    testWidgets('Renderiza PainelGeralPage com KPIs e botão de comunicado', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PainelGeralPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo, Carlos.'), findsOneWidget);
      expect(find.text('Emitir Comunicado Institucional'), findsOneWidget);
    });

    testWidgets('Renderiza UsersPage com tabela e botão de novo cadastro', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UsersPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gestão de Usuários & Controle de Acessos'), findsOneWidget);
      expect(find.text('Novo Cadastro Institucional'), findsOneWidget);
      expect(find.text('Discentes'), findsWidgets);
    });

    testWidgets('Renderiza CoursesPage com matrizes curriculares e modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CoursesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cursos & Matrizes Curriculares (PPC)'), findsOneWidget);
      expect(find.text('Bacharelado em Engenharia de Software'), findsOneWidget);
      expect(find.text('Ver Matriz & Ementário'), findsWidgets);
    });

    testWidgets('Renderiza ClassesPage com tabela de turmas e botão supervisionar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ClassesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gestão de Turmas, Ensalamento & Atribuição Docente'), findsOneWidget);
      expect(find.text('Supervisionar'), findsWidgets);
    });

    testWidgets('Renderiza SupervisionCockpitPage com 5 abas de auditoria', (tester) async {
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
    });

    testWidgets('Renderiza SecretaryPage com protocolos e ações de análise', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SecretaryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secretaria Acadêmica Geral & Protocolos'), findsOneWidget);
      expect(find.text('Aguardando Parecer'), findsWidgets);
    });

    testWidgets('Renderiza CalendarPage com resolução CONSEPE e travas', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CalendarPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Calendário Acadêmico Oficial & Prazos Regimentais'), findsOneWidget);
      expect(find.text('RESOLUÇÃO CONSEPE 2026/04'), findsOneWidget);
    });

    testWidgets('Renderiza AuditPage com logs de segurança e severidades', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AuditPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Auditoria de Segurança & Trilha Documental (Audit Trail)'), findsOneWidget);
      expect(find.text('Exportar Log Criptografado'), findsOneWidget);
    });
  });
}
