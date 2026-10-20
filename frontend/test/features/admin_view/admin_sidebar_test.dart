// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/admin_view/shell/presentation/widgets/admin_sidebar.dart';

void main() {
  group('AdminSidebar Widget Tests', () {
    testWidgets('Renderiza todos os 8 itens institucionais e o botão Sair', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      AdminNavTab activeTab = AdminNavTab.painelGeral;
      bool logoutCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSidebar(
              activeTab: activeTab,
              onTabSelected: (tab) => activeTab = tab,
              onLogout: () => logoutCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica o logotipo institucional
      expect(find.text('ALEX'), findsOneWidget);
      expect(find.text('PORTAL GESTÃO'), findsOneWidget);

      // Verifica os 8 itens de menu
      expect(find.text('Painel Geral'), findsOneWidget);
      expect(find.text('Usuários'), findsOneWidget);
      expect(find.text('Cursos'), findsOneWidget);
      expect(find.text('Turmas'), findsOneWidget);
      expect(find.text('Secretaria'), findsOneWidget);
      expect(find.text('Calendário'), findsOneWidget);
      expect(find.text('Auditoria'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);

      // Clica em Usuários e verifica callback
      await tester.tap(find.text('Usuários'));
      await tester.pumpAndSettle();
      expect(activeTab, equals(AdminNavTab.usuarios));

      // Clica em Sair e verifica callback de logout
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(logoutCalled, isTrue);
    });

    testWidgets('Alterna estado recolhido/expandido através do botão flutuante', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool isCollapsed = false;
      bool toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Row(
                  children: [
                    AdminSidebar(
                      activeTab: AdminNavTab.painelGeral,
                      isCollapsed: isCollapsed,
                      onToggleCollapse: () {
                        toggleCalled = true;
                        setState(() => isCollapsed = !isCollapsed);
                      },
                      onTabSelected: (_) {},
                      onLogout: () {},
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clica no botão flutuante de colapso
      final toggleButton = find.byKey(const Key('sidebar_toggle_collapse_btn'));
      expect(toggleButton, findsOneWidget);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(toggleCalled, isTrue);
      expect(isCollapsed, isTrue);
      expect(find.text('ALE'), findsOneWidget);
    });
  });
}
