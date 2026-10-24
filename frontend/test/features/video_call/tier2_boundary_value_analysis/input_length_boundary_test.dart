// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_test_components.dart';

void main() {
  group('Tier 2: Boundary Value Analysis - Input String Length Boundaries', () {
    testWidgets('Boundary Name min=1 char passes validation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool joinCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallLobbyPage(
            onJoin: (name, ra, room, muted, videoOff) {
              joinCalled = true;
              expect(name, 'A');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lobby_name_field')), 'A');
      await tester.enterText(find.byKey(const Key('lobby_ra_field')), '24802449');
      await tester.enterText(find.byKey(const Key('lobby_room_code_field')), 'SALA-101');
      await tester.tap(find.byKey(const Key('lobby_join_button')));
      await tester.pumpAndSettle();

      expect(joinCalled, isTrue);
    });

    testWidgets('Boundary Room Code min=3 chars (S-1) passes validation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool joinCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallLobbyPage(
            onJoin: (name, ra, room, muted, videoOff) {
              joinCalled = true;
              expect(room, 'S-1');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lobby_name_field')), 'Alex');
      await tester.enterText(find.byKey(const Key('lobby_ra_field')), '24802449');
      await tester.enterText(find.byKey(const Key('lobby_room_code_field')), 'S-1');
      await tester.tap(find.byKey(const Key('lobby_join_button')));
      await tester.pumpAndSettle();

      expect(joinCalled, isTrue);
    });

    testWidgets('Boundary Room Code under min length (2 chars) fails validation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool joinCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallLobbyPage(
            onJoin: (_, __, ___, ____, _____) => joinCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lobby_name_field')), 'Alex');
      await tester.enterText(find.byKey(const Key('lobby_ra_field')), '24802449');
      await tester.enterText(find.byKey(const Key('lobby_room_code_field')), 'SA');
      await tester.tap(find.byKey(const Key('lobby_join_button')));
      await tester.pumpAndSettle();

      expect(joinCalled, isFalse);
      expect(find.text('Código da sala inválido'), findsOneWidget);
    });

    testWidgets('Boundary Room Code max=32 chars passes validation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final max32Room = 'A' * 32;
      bool joinCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallLobbyPage(
            onJoin: (name, ra, room, muted, videoOff) {
              joinCalled = true;
              expect(room, max32Room);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lobby_name_field')), 'Alex');
      await tester.enterText(find.byKey(const Key('lobby_ra_field')), '24802449');
      await tester.enterText(find.byKey(const Key('lobby_room_code_field')), max32Room);
      await tester.tap(find.byKey(const Key('lobby_join_button')));
      await tester.pumpAndSettle();

      expect(joinCalled, isTrue);
    });

    testWidgets('Boundary Room Code exceeding max (33 chars) fails validation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final over32Room = 'A' * 33;
      bool joinCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallLobbyPage(
            onJoin: (_, __, ___, ____, _____) => joinCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lobby_name_field')), 'Alex');
      await tester.enterText(find.byKey(const Key('lobby_ra_field')), '24802449');
      await tester.enterText(find.byKey(const Key('lobby_room_code_field')), over32Room);
      await tester.tap(find.byKey(const Key('lobby_join_button')));
      await tester.pumpAndSettle();

      expect(joinCalled, isFalse);
      expect(find.text('Código da sala inválido'), findsOneWidget);
    });
  });
}
