// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_contracts.dart';
import '../helpers/video_call_test_components.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 2: Boundary Value Analysis - Recording Timer & Session Export Ledger', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer();
    });

    tearDown(() {
      harness.dispose();
    });

    test('Initial recording state is inactive with zero elapsed duration', () {
      expect(harness.peerA.recordingState.isRecording, isFalse);
      expect(harness.peerA.recordingState.elapsedDuration, Duration.zero);
      expect(harness.peerA.recordingState.startedAt, isNull);
    });

    test('Toggling recording activates state and synchronizes across peers', () async {
      harness.peerA.toggleRecording();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Peer A state
      expect(harness.peerA.recordingState.isRecording, isTrue);
      expect(harness.peerA.recordingState.startedByPeerId, 'peer_a_id');
      expect(harness.peerA.recordingState.startedAt, isNotNull);

      // Peer B synchronized state
      expect(harness.peerB.recordingState.isRecording, isTrue);
      expect(harness.peerB.recordingState.startedByPeerId, 'peer_a_id');
    });

    test('Stopping recording creates SessionExport ledger with accurate session metrics',
        () async {
      // 1. Send chat message during session
      harness.peerA.sendChatMessage('Mensagem da aula gravada');
      // 2. Send reaction during session
      harness.peerB.sendReaction('🎉');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 3. Start recording
      harness.peerA.toggleRecording();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 4. Stop recording
      harness.peerA.toggleRecording();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(harness.peerA.recordingState.isRecording, isFalse);

      final export = harness.peerA.lastSessionExport;
      expect(export, isNotNull);
      expect(export!.roomCode, 'SALA-101');
      expect(export.totalParticipants, 2);
      expect(export.attendeeNames, containsAll(['Alex Sousa', 'Beatriz Lima']));
      expect(export.chatMessageCount, 1);
      expect(export.toJson()['exportFormat'], 'academic_session_ledger_v1');
    });

    testWidgets('Recording active renders institutional banner and pulsating REC badge',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, no recording banner or badge
      expect(find.byKey(const Key('institutional_recording_banner')), findsNothing);
      expect(find.byKey(const Key('recording_timer_badge')), findsNothing);

      // Start recording
      harness.peerA.toggleRecording();
      await tester.pumpAndSettle();

      // Now both institutional banner and timer badge are rendered
      expect(find.byKey(const Key('institutional_recording_banner')), findsOneWidget);
      expect(
        find.text('● REC — Esta reunião está sendo gravada para fins acadêmicos e pedagógicos.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('recording_timer_badge')), findsOneWidget);
      expect(find.textContaining('● REC 00:00'), findsOneWidget);

      // Stop recording to cleanly cancel timer before widget tree teardown
      harness.peerA.toggleRecording();
      await tester.pumpAndSettle();
    });
  });
}
