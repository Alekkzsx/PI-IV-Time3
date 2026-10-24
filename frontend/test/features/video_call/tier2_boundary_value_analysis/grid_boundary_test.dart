// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_contracts.dart';
import '../helpers/video_call_test_components.dart';

void main() {
  group('Tier 2: Boundary Value Analysis - Dynamic Video Grid Sizing', () {
    testWidgets('Boundary N=0: Empty participant list renders fallback message',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicVideoGrid(participants: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhum participante conectado'), findsOneWidget);
    });

    testWidgets('Boundary N=1: Solitary participant renders exactly 1 full-size tile (Zero Bots)',
        (tester) async {
      final p1 = const Participant(
        id: 'user_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicVideoGrid(participants: [p1]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('participant_tile_user_1')), findsOneWidget);
      expect(find.text('Alex Sousa (24802449)'), findsOneWidget);
      // Strictly no other tiles exist
      expect(find.byType(ParticipantVideoTile), findsOneWidget);
    });

    testWidgets('Boundary N=2: Exactly two participants render dual split layout',
        (tester) async {
      final p1 = const Participant(id: 'user_1', name: 'Alex', ra: '24802449');
      final p2 = const Participant(id: 'user_2', name: 'Beatriz', ra: '24801122');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicVideoGrid(participants: [p1, p2]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ParticipantVideoTile), findsNWidgets(2));
      expect(find.byKey(const Key('participant_tile_user_1')), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_user_2')), findsOneWidget);
    });

    testWidgets('Boundary N=4: Four participants render 2x2 grid layout',
        (tester) async {
      final participants = List.generate(
        4,
        (i) => Participant(
          id: 'user_$i',
          name: 'Aluno $i',
          ra: '2480000$i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicVideoGrid(participants: participants),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ParticipantVideoTile), findsNWidgets(4));
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('Screen Share Spotlight Mode renders presentation viewport + horizontal filmstrip',
        (tester) async {
      final participants = [
        const Participant(id: 'host', name: 'Prof. Carlos', ra: 'DOC-01'),
        const Participant(id: 'student_1', name: 'Alex', ra: '24802449'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicVideoGrid(
              participants: participants,
              isScreenSharing: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Spotlight presentation stage is visible
      expect(find.byKey(const Key('screen_share_view')), findsOneWidget);
      expect(find.text('Apresentação de Tela Ativa'), findsOneWidget);

      // Horizontal filmstrip displays both participants
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ParticipantVideoTile), findsNWidgets(2));
    });
  });
}
