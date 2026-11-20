// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pi_iv_time3/core/network/server_health_monitor.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/core/widgets/server_unavailable_guard.dart';

void main() {
  tearDown(() {
    ServerHealthMonitor.instance.resetForTesting();
    AppUserSession.instance.signOut();
  });

  group('ServerHealthMonitor + ServerUnavailableGuard (Fail-Closed)', () {
    testWidgets(
      '1. Ambos online (200 + 200) mantém a interface totalmente liberada',
      (WidgetTester tester) async {
        final monitor = ServerHealthMonitor(
          authBaseUrl: 'http://127.0.0.1:8080',
          academicBaseUrl: 'http://127.0.0.1:3001',
          clientFactory: () => MockClient((request) async {
            if (request.url.path == '/health') {
              return http.Response('{"status":"ok"}', 200);
            }
            return http.Response('not found', 404);
          }),
        );
        addTearDown(monitor.dispose);

        final online = await monitor.checkNow();
        expect(online, isTrue);
        expect(monitor.snapshot.state, ServerConnectionState.online);
        expect(monitor.snapshot.authServerOnline, isTrue);
        expect(monitor.snapshot.academicServerOnline, isTrue);

        var buttonTapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: ServerUnavailableGuard(
              enabled: true,
              monitor: monitor,
              child: Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => buttonTapped = true,
                    child: const Text('Tela de Login Liberada'),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Serviço fora do ar'), findsNothing);
        expect(find.text('Tela de Login Liberada'), findsOneWidget);

        await tester.tap(find.text('Tela de Login Liberada'));
        expect(buttonTapped, isTrue);
      },
    );

    testWidgets(
      '2. Só Servidor Java (:8080) desligado bloqueia mesmo deslogado (tela de login) e avisa exatamente qual caiu',
      (WidgetTester tester) async {
        final monitor = ServerHealthMonitor(
          authBaseUrl: 'http://127.0.0.1:8080',
          academicBaseUrl: 'http://127.0.0.1:3001',
          clientFactory: () => MockClient((request) async {
            if (request.url.port == 8080) {
              throw http.ClientException('Connection refused');
            }
            return http.Response('{"status":"ok"}', 200);
          }),
        );
        addTearDown(monitor.dispose);

        final online = await monitor.checkNow();
        expect(online, isFalse);
        expect(monitor.snapshot.state, ServerConnectionState.offline);
        expect(monitor.snapshot.authServerOnline, isFalse);
        expect(monitor.snapshot.academicServerOnline, isTrue);

        var loginClicked = false;
        await tester.pumpWidget(
          MaterialApp(
            home: ServerUnavailableGuard(
              enabled: true,
              monitor: monitor,
              child: Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => loginClicked = true,
                    child: const Text('Entrar no AVA'),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Serviço fora do ar'), findsOneWidget);
        expect(
          find.text('O Servidor Java (porta 8080) está desligado ou fora do ar.'),
          findsOneWidget,
        );
        expect(find.text('Servidor Java (:8080)'), findsOneWidget);
        expect(find.text('Backend Acadêmico (:3001)'), findsOneWidget);
        expect(find.text('Desligado ou fora do ar'), findsOneWidget);
        expect(find.text('Online'), findsOneWidget);
        // Usuário deslogado não exibe botão de encerrar sessão local.
        expect(find.text('Encerrar sessão local'), findsNothing);

        // Interação com a tela de login atrás do bloqueio permanece impedida.
        await tester.tap(find.text('Entrar no AVA'), warnIfMissed: false);
        expect(loginClicked, isFalse);
      },
    );

    testWidgets(
      '3. Só Backend Acadêmico (:3001) desligado bloqueia a tela (inclusive logado) e oferece encerrar sessão local',
      (WidgetTester tester) async {
        AppUserSession.instance.signIn(
          identity: '24802449',
          profile: 'aluno',
          accessToken: 'fake-token',
          persist: false,
        );

        final monitor = ServerHealthMonitor(
          authBaseUrl: 'http://127.0.0.1:8080',
          academicBaseUrl: 'http://127.0.0.1:3001',
          clientFactory: () => MockClient((request) async {
            if (request.url.port == 3001) {
              throw http.ClientException('Connection refused');
            }
            return http.Response('{"status":"ok"}', 200);
          }),
        );
        addTearDown(monitor.dispose);

        final online = await monitor.checkNow();
        expect(online, isFalse);
        expect(monitor.snapshot.authServerOnline, isTrue);
        expect(monitor.snapshot.academicServerOnline, isFalse);

        await tester.pumpWidget(
          MaterialApp(
            home: ServerUnavailableGuard(
              enabled: true,
              monitor: monitor,
              child: const Scaffold(body: Center(child: Text('Portal do Aluno'))),
            ),
          ),
        );

        expect(find.text('Serviço fora do ar'), findsOneWidget);
        expect(
          find.text(
            'O Backend Acadêmico (porta 3001) está desligado ou fora do ar.',
          ),
          findsOneWidget,
        );
        expect(find.text('Encerrar sessão local'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Ambos desligados informa que Servidor Java (:8080) e Backend Acadêmico (:3001) estão fora do ar',
      (WidgetTester tester) async {
        final monitor = ServerHealthMonitor(
          authBaseUrl: 'http://127.0.0.1:8080',
          academicBaseUrl: 'http://127.0.0.1:3001',
          clientFactory: () => MockClient((_) async {
            throw http.ClientException('Connection refused');
          }),
        );
        addTearDown(monitor.dispose);

        await monitor.checkNow();

        await tester.pumpWidget(
          MaterialApp(
            home: ServerUnavailableGuard(
              enabled: true,
              monitor: monitor,
              child: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        );

        expect(
          find.text(
            'O Servidor Java (porta 8080) e o Backend Acadêmico (porta 3001) estão desligados ou fora do ar.',
          ),
          findsOneWidget,
        );
        expect(find.text('Desligado ou fora do ar'), findsNWidgets(2));
      },
    );

    testWidgets(
      '5. Queda no meio do uso via reportTransportFailure bloqueia imediatamente e recupera ao voltar online revalidando sessão',
      (WidgetTester tester) async {
        var authOnline = true;
        var academicOnline = true;
        var reconnectedCalls = 0;

        final monitor = ServerHealthMonitor(
          authBaseUrl: 'http://127.0.0.1:8080',
          academicBaseUrl: 'http://127.0.0.1:3001',
          onReconnected: () async {
            reconnectedCalls++;
          },
          clientFactory: () => MockClient((request) async {
            if (request.url.port == 8080 && !authOnline) {
              return http.Response('unavailable', 503);
            }
            if (request.url.port == 3001 && !academicOnline) {
              return http.Response('unavailable', 503);
            }
            return http.Response('{"status":"ok"}', 200);
          }),
        );
        addTearDown(monitor.dispose);

        await monitor.checkNow();

        await tester.pumpWidget(
          MaterialApp(
            home: ServerUnavailableGuard(
              enabled: true,
              monitor: monitor,
              child: const Scaffold(body: Center(child: Text('Sessão Ativa'))),
            ),
          ),
        );

        expect(find.text('Serviço fora do ar'), findsNothing);
        expect(find.text('Sessão Ativa'), findsOneWidget);

        // Simula queda repentina do servidor Java durante o uso
        authOnline = false;
        monitor.reportTransportFailure(isAuthServer: true);
        await tester.pumpAndSettle();

        expect(find.text('Serviço fora do ar'), findsOneWidget);
        expect(monitor.snapshot.state, ServerConnectionState.offline);

        // Simula retorno dos dois serviços e clique em reconectar
        authOnline = true;
        await tester.tap(find.text('Tentar reconectar agora'));
        await tester.pumpAndSettle();

        expect(find.text('Serviço fora do ar'), findsNothing);
        expect(find.text('Sessão Ativa'), findsOneWidget);
        expect(monitor.snapshot.state, ServerConnectionState.online);
        expect(reconnectedCalls, 1);

        // Simula queda repentina do Backend Acadêmico (:3001) durante o uso
        academicOnline = false;
        monitor.reportTransportFailure(isAuthServer: false);
        await tester.pumpAndSettle();

        expect(find.text('Serviço fora do ar'), findsOneWidget);
        expect(
          find.text(
            'O Backend Acadêmico (porta 3001) está desligado ou fora do ar.',
          ),
          findsOneWidget,
        );

        academicOnline = true;
        await tester.tap(find.text('Tentar reconectar agora'));
        await tester.pumpAndSettle();

        expect(find.text('Serviço fora do ar'), findsNothing);
        expect(reconnectedCalls, 2);
      },
    );

    test(
      '6. AppUserSession.verifySessionWithServer retorna unreachable em erro de rede e unauthorized (expirando sessão) em 401',
      () async {
        AppUserSession.instance.signIn(
          identity: '24802449',
          profile: 'aluno',
          accessToken: 'test-token',
          persist: false,
        );

        final offlineResult = await AppUserSession.instance
            .verifySessionWithServer(
              client: MockClient((_) async {
                throw http.ClientException('Connection refused');
              }),
            );
        expect(offlineResult, SessionRefreshResult.unreachable);
        expect(AppUserSession.instance.isAuthenticated, isTrue);

        final unauthorizedResult = await AppUserSession.instance
            .verifySessionWithServer(
              client: MockClient((_) async {
                return http.Response(
                  jsonEncode({'code': 'unauthorized'}),
                  401,
                );
              }),
            );
        expect(unauthorizedResult, SessionRefreshResult.unauthorized);
        expect(AppUserSession.instance.isAuthenticated, isFalse);
      },
    );
  });
}
