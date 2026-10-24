// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_test_components.dart';

void main() {
  group('Tier 1: Category-Partition - Lobby Input Validation & Preview', () {
    testWidgets('Valid inputs trigger onJoin callback with sanitized values',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? joinedName;
      String? joinedRa;
      String? joinedRoom;
      bool? isMuted;
      bool? isVideoOff;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallLobbyPage(
            onJoin: (name, ra, room, muted, videoOff) {
              joinedName = name;
              joinedRa = ra;
              joinedRoom = room;
              isMuted = muted;
              isVideoOff = videoOff;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in valid fields
      await tester.enterText(
        find.byKey(const Key('lobby_name_field')),
        'Alex Sousa',
      );
      await tester.enterText(
        find.byKey(const Key('lobby_ra_field')),
        '24802449',
      );
      await tester.enterText(
        find.byKey(const Key('lobby_room_code_field')),
        'SALA-101',
      );

      // Toggle camera off
      await tester.tap(find.byKey(const Key('lobby_toggle_cam_button')));
      await tester.pumpAndSettle();

      // Click "Entrar na Reunião"
      await tester.tap(find.byKey(const Key('lobby_join_button')));
      await tester.pumpAndSettle();

      expect(joinedName, 'Alex Sousa');
      expect(joinedRa, '24802449');
      expect(joinedRoom, 'SALA-101');
      expect(isMuted, isFalse);
      expect(isVideoOff, isTrue);
    });

    testWidgets('Empty display name rejects submission and shows error message',
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

      // Enter empty name and submit
      await tester.enterText(
        find.byKey(const Key('lobby_name_field')),
        '   ',
      );
      await tester.enterText(
        find.byKey(const Key('lobby_ra_field')),
        '24802449',
      );
      await tester.tap(find.byKey(const Key('lobby_join_button')));
      await tester.pumpAndSettle();

      expect(joinCalled, isFalse);
      expect(find.text('Informe seu nome'), findsOneWidget);
    });

    testWidgets('Invalid short RA rejects submission and shows validation error',
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

      await tester.enterText(
        find.byKey(const Key('lobby_name_field')),
        'Carlos Silva',
      );
      await tester.enterText(
        find.byKey(const Key('lobby_ra_field')),
        '12',
      );
      await tester.tap(find.byKey(const Key('lobby_join_button')));
      await tester.pumpAndSettle();

      expect(joinCalled, isFalse);
      expect(find.text('RA inválido'), findsOneWidget);
    });

    testWidgets('Invalid Room Code format shows error and prevents navigation',
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

      await tester.enterText(
        find.byKey(const Key('lobby_name_field')),
        'Carlos Silva',
      );
      await tester.enterText(
        find.byKey(const Key('lobby_ra_field')),
        '24802449',
      );
      // Malformed room code with invalid symbols
      await tester.enterText(
        find.byKey(const Key('lobby_room_code_field')),
        'SALA*#@!',
      );
      await tester.tap(find.byKey(const Key('lobby_join_button')));
      await tester.pumpAndSettle();

      expect(joinCalled, isFalse);
      expect(find.text('Código da sala inválido'), findsOneWidget);
    });

    testWidgets('Hardware preview toggles mic and cam state visually',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: VideoCallLobbyPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: Camera Active inside preview box
      expect(
        find.descendant(
          of: find.byKey(const Key('lobby_camera_preview')),
          matching: find.byIcon(Icons.videocam),
        ),
        findsOneWidget,
      );
      expect(find.text('Câmera Ligada'), findsOneWidget);

      // Toggle camera off
      await tester.tap(find.byKey(const Key('lobby_toggle_cam_button')));
      await tester.pumpAndSettle();

      expect(find.text('Câmera Desativada'), findsOneWidget);
      expect(find.text('Câmera Desligada'), findsOneWidget);

      // Toggle mic muted
      expect(find.text('Microfone Ativo'), findsOneWidget);
      await tester.tap(find.byKey(const Key('lobby_toggle_mic_button')));
      await tester.pumpAndSettle();

      expect(find.text('Mudo'), findsOneWidget);
    });
  });
}
