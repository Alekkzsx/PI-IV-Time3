// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/admin/admin_shell/presentation/pages/admin_shell_page.dart';
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

      // 1. Aba Perfil Administrativo
      await tester.tap(find.text('Perfil Administrativo').first);
      await tester.pumpAndSettle();
      expect(find.byType(AdminProfileTab), findsOneWidget);
      expect(find.text('Identidade Visual & Foto'), findsOneWidget);
      expect(find.text('Carlos Eduardo Mendes'), findsOneWidget);

      // 2. Aba Segurança & Credenciais
      await tester.tap(find.text('Segurança & Credenciais').first);
      await tester.pumpAndSettle();
      expect(find.byType(SecurityCredentialsTab), findsOneWidget);
      expect(find.text('Credencial de Acesso (Senha)'), findsOneWidget);
      expect(find.text('Autenticação em Duas Etapas (2FA)'), findsOneWidget);

      // 3. Aba Alertas do Campus
      await tester.tap(find.text('Alertas do Campus').first);
      await tester.pumpAndSettle();
      expect(find.byType(CampusAlertsTab), findsOneWidget);
      expect(find.text('Canais de Comunicação'), findsOneWidget);
      expect(find.text('Prazos de Tarefas & Trabalhos'), findsOneWidget);

      // 4. Aba Preferências do Sistema
      await tester.tap(find.text('Preferências do Sistema').first);
      await tester.pumpAndSettle();
      expect(find.byType(SystemPreferencesTab), findsOneWidget);
      expect(find.text('Aparência & Tema'), findsOneWidget);
      expect(find.text('Acessibilidade & Leitura'), findsOneWidget);

      // 5. Aba Governança & LGPD
      await tester.tap(find.text('Governança & LGPD').first);
      await tester.pumpAndSettle();
      expect(find.byType(GovernanceLgpdTab), findsOneWidget);
      expect(find.text('Visibilidade de Perfil & Dados entre Colegas'), findsOneWidget);
      expect(find.text('Privacidade & Direitos do Titular (LGPD)'), findsOneWidget);
      expect(find.text('Salvar Preferências de Privacidade'), findsOneWidget);
    });

    testWidgets('integrates with AdminShellPage and opens configure tab when clicked', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminShellPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Painel Geral'), findsWidgets);

      // Toca no item "Configurações" na barra lateral principal
      await tester.tap(find.widgetWithText(ListTile, 'Configurações'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminConfigurePage), findsOneWidget);
    });
  });
}
