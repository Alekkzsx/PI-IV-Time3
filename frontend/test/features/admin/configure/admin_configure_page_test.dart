// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/admin/configure/presentation/pages/admin_configure_page.dart';
import 'package:pi_iv_time3/features/admin/configure/presentation/widgets/academic_guidelines_tab.dart';
import 'package:pi_iv_time3/features/admin/configure/presentation/widgets/admin_profile_tab.dart';
import 'package:pi_iv_time3/features/admin/configure/presentation/widgets/campus_alerts_tab.dart';
import 'package:pi_iv_time3/features/admin/configure/presentation/widgets/governance_lgpd_tab.dart';
import 'package:pi_iv_time3/features/admin/configure/presentation/widgets/security_credentials_tab.dart';
import 'package:pi_iv_time3/features/admin/configure/presentation/widgets/system_preferences_tab.dart';

void main() {
  group('AdminConfigurePage Widget Tests', () {
    testWidgets('renders initial header and default AcademicGuidelinesTab', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminConfigurePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configurações da Conta de Administração'), findsOneWidget);
      expect(find.byType(AcademicGuidelinesTab), findsOneWidget);
      expect(find.text('Diretrizes Acadêmicas Regimentais'), findsOneWidget);
      expect(find.text('MÉDIA DE APROVAÇÃO'), findsOneWidget);
      expect(find.text('FREQUÊNCIA PRESENCIAL'), findsOneWidget);
      expect(find.text('EXAME ESPECIAL'), findsOneWidget);
    });

    testWidgets('switches between all 6 configuration tabs cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminConfigurePage(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Administrative Profile Tab
      await tester.tap(find.text('Perfil Administrativo').first);
      await tester.pumpAndSettle();
      expect(find.byType(AdminProfileTab), findsOneWidget);
      expect(find.text('Identidade Visual & Foto'), findsOneWidget);
      expect(find.text('Carlos Eduardo Mendes'), findsOneWidget);

      // 2. Security & Credentials Tab
      await tester.tap(find.text('Segurança & Credenciais').first);
      await tester.pumpAndSettle();
      expect(find.byType(SecurityCredentialsTab), findsOneWidget);
      expect(find.text('Credencial de Acesso (Senha)'), findsOneWidget);
      expect(find.text('Autenticação em Duas Etapas (2FA)'), findsOneWidget);

      // 3. Campus Alerts Tab
      await tester.tap(find.text('Alertas do Campus').first);
      await tester.pumpAndSettle();
      expect(find.byType(CampusAlertsTab), findsOneWidget);
      expect(find.text('Canais de Comunicação'), findsOneWidget);
      expect(find.text('Prazos de Tarefas & Trabalhos'), findsOneWidget);

      // 4. System Preferences Tab
      await tester.tap(find.text('Preferências do Sistema').first);
      await tester.pumpAndSettle();
      expect(find.byType(SystemPreferencesTab), findsOneWidget);
      expect(find.text('Aparência & Tema'), findsOneWidget);
      expect(find.text('Acessibilidade & Leitura'), findsOneWidget);

      // 5. Governance & LGPD Tab
      await tester.tap(find.text('Governança & LGPD').first);
      await tester.pumpAndSettle();
      expect(find.byType(GovernanceLgpdTab), findsOneWidget);
      expect(find.text('Visibilidade de Perfil & Dados entre Colegas'), findsOneWidget);
      expect(find.text('Privacidade & Direitos do Titular (LGPD)'), findsOneWidget);
      expect(find.text('Salvar Preferências de Privacidade'), findsOneWidget);
    });

    testWidgets('renders individual tabs directly in isolation', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Renders GovernanceLgpdTab and asserts export buttons
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: GovernanceLgpdTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Exportar Relatório de Dados Cadastrais & Histórico'), findsOneWidget);
      expect(find.text('Arquivo JSON'), findsOneWidget);
      expect(find.text('Relatório (.txt)'), findsOneWidget);

      // Renders SecurityCredentialsTab and asserts backup codes badge and buttons
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: SecurityCredentialsTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('8 disponíveis'), findsOneWidget);
      expect(find.text('Gerenciar Códigos'), findsOneWidget);
    });
  });
}

