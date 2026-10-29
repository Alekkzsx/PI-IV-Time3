import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/core/widgets/access_denied_view.dart';

void main() {
  testWidgets('standalone restriction includes a return action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccessDeniedView(
          message: 'A área requer outro perfil.',
          fullPage: true,
          onReturn: () {},
        ),
      ),
    );

    expect(find.text('Acesso restrito'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.text('A área requer outro perfil.'), findsOneWidget);
    expect(find.text('Voltar ao login'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('embedded restriction uses the same style without login action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: AccessDeniedView(
              message: 'Seu perfil não pode acessar este conteúdo.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Área não disponível'), findsOneWidget);
    expect(
      find.text('Seu perfil não pode acessar este conteúdo.'),
      findsOneWidget,
    );
    expect(find.text('Voltar ao login'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
