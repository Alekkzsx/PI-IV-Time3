// Desenvolvido por Guilherme Henrique Moreira
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/admin/users/presentation/widgets/user_form_modal.dart';

void main() {
  testWidgets('creates a docente with the identity returned by the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    Map<String, Object?>? createdUser;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => UserFormModal.show(
                context: context,
                onUserCreated:
                    ({
                      required String name,
                      required String email,
                      required String profile,
                      required String department,
                      required bool require2FA,
                    }) async {
                      createdUser = {
                        'name': name,
                        'email': email,
                        'profile': profile,
                        'department': department,
                      };
                      return 'DOC-1234567890';
                    },
              ),
              child: const Text('Abrir cadastro'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir cadastro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Docente (Professor)'));
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Ana Clara Ferreira',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'ana.ferreira@universidade.edu.br',
    );
    await tester.tap(find.text('Concluir Cadastro'));
    await tester.pumpAndSettle();

    expect(createdUser?['profile'], 'docente');
    expect(find.textContaining('DOC-1234567890'), findsOneWidget);
    expect(find.textContaining('Esqueci minha senha'), findsOneWidget);
  });

  testWidgets('validates required identity data before creating a user', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    Map<String, Object?>? createdUser;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => UserFormModal.show(
                context: context,
                onUserCreated:
                    ({
                      required String name,
                      required String email,
                      required String profile,
                      required String department,
                      required bool require2FA,
                    }) async {
                      createdUser = {
                        'name': name,
                        'email': email,
                        'profile': profile,
                        'department': department,
                        'require2FA': require2FA,
                      };
                      return null;
                    },
              ),
              child: const Text('Abrir cadastro'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir cadastro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir Cadastro'));
    await tester.pumpAndSettle();

    expect(createdUser, isNull);
    expect(find.text('Informe o nome completo.'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Novo Cadastro Institucional'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Ana Clara Ferreira',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'email-invalido');
    await tester.tap(find.text('Concluir Cadastro'));
    await tester.pumpAndSettle();

    expect(createdUser, isNull);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(1),
      'ana.ferreira@universidade.edu.br',
    );
    await tester.tap(find.text('Concluir Cadastro'));
    await tester.pumpAndSettle();

    expect(createdUser, isNotNull);
    expect(createdUser!['email'], 'ana.ferreira@universidade.edu.br');
    expect(find.text('Novo Cadastro Institucional'), findsNothing);
  });
}
