// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/in_memory_signaling_bus.dart';
import '../helpers/mock_video_call_repository.dart';
import '../helpers/video_call_contracts.dart';
import '../helpers/video_call_test_components.dart';

void main() {
  group('Tier 4: Real-World Scenarios - Zero Bots Multi-User Lifecycle E2E', () {
    tearDown(() {
      InMemorySignalingBus.resetAll();
    });

    testWidgets(
        'E2E: 1 person enters = 1 tile -> 2nd person enters = 2 tiles -> 2nd leaves = 1 tile immediately',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final room = const MeetingRoom(
        id: 'SALA-101',
        code: 'SALA-101',
        title: 'Sala de Aula Virtual',
      );

      // --- PHASE 1: User 1 Enters Alone (Strict Zero-Bots Invariant) ---
      final repo1 = MockVideoCallRepository();
      const user1 = Participant(
        id: 'user_1_id',
        name: 'Alex Sousa',
        ra: '24802449',
        role: 'student',
      );

      final controller1 = VideoCallTestController(
        repository: repo1,
        room: room,
        localParticipant: user1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: controller1),
        ),
      );
      await tester.pumpAndSettle();

      // STRICT ZERO BOTS VERIFICATION:
      // Exactly 1 tile is displayed (Alex Sousa). No fake or bot participants appear.
      expect(controller1.allParticipants.length, 1);
      expect(controller1.remoteParticipants, isEmpty);
      expect(find.byType(ParticipantVideoTile), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_user_1_id')), findsOneWidget);
      expect(find.text('Alex Sousa (24802449)'), findsOneWidget);

      // --- PHASE 2: User 2 Joins Room from Second Tab ---
      final repo2 = MockVideoCallRepository();
      const user2 = Participant(
        id: 'user_2_id',
        name: 'Beatriz Lima',
        ra: '24801122',
        role: 'student',
      );

      final controller2 = VideoCallTestController(
        repository: repo2,
        room: room,
        localParticipant: user2,
      );

      // Connect both peers directly across the room signaling bus
      controller1.registerRemoteParticipant(user2);
      controller2.registerRemoteParticipant(user1);

      await tester.pumpAndSettle();

      // DUAL TILE VERIFICATION:
      // Both participants are now visible in real time on User 1's screen.
      expect(controller1.allParticipants.length, 2);
      expect(controller1.remoteParticipants.length, 1);
      expect(find.byType(ParticipantVideoTile), findsNWidgets(2));
      expect(find.byKey(const Key('participant_tile_user_1_id')), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_user_2_id')), findsOneWidget);
      expect(find.text('Beatriz Lima (24801122)'), findsOneWidget);

      // --- PHASE 3: User 2 Clicks "Sair" / Leaves Room ---
      controller2.leaveCall();
      // Leave envelope broadcast prunes User 2 immediately on User 1
      repo1.leaveRoom(room.code, user2.id);

      await tester.pumpAndSettle();

      // IMMEDIATE PRUNING VERIFICATION:
      // User 2's tile is removed immediately, returning strictly to 1 tile.
      expect(controller1.allParticipants.length, 1);
      expect(controller1.remoteParticipants, isEmpty);
      expect(find.byType(ParticipantVideoTile), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_user_1_id')), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_user_2_id')), findsNothing);

      // Clean up
      controller1.dispose();
      repo1.dispose();
      repo2.dispose();
    });
  });
}
