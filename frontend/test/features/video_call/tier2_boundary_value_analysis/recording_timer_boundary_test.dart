// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

      // Estado do Peer A
      expect(harness.peerA.recordingState.isRecording, isTrue);
      expect(harness.peerA.recordingState.startedByPeerId, 'peer_a_id');
      expect(harness.peerA.recordingState.startedAt, isNotNull);

      // Estado sincronizado do Peer B
      expect(harness.peerB.recordingState.isRecording, isTrue);
      expect(harness.peerB.recordingState.startedByPeerId, 'peer_a_id');
    });

    test('Stopping recording creates SessionExport ledger with accurate session metrics',
        () async {
      // 1. Envia mensagem no chat durante a sessão
      harness.peerA.sendChatMessage('Mensagem da aula gravada');
      // 2. Envia reação durante a sessão
      harness.peerB.sendReaction('🎉');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 3. Inicia a gravação
      harness.peerA.toggleRecording();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 4. Para a gravação
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

      // Inicialmente, não há banner nem emblema de gravação
      expect(find.byKey(const Key('institutional_recording_banner')), findsNothing);
      expect(find.byKey(const Key('recording_timer_badge')), findsNothing);

      // Inicia a gravação
      harness.peerA.toggleRecording();
      await tester.pump();

      // Agora tanto o banner institucional quanto o emblema do temporizador são renderizados
      expect(find.byKey(const Key('institutional_recording_banner')), findsOneWidget);
      expect(
        find.text('● REC — Esta reunião está sendo gravada para fins acadêmicos e pedagógicos.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('recording_timer_badge')), findsOneWidget);
      expect(find.textContaining('● REC 00:00'), findsOneWidget);

      // Para a gravação para cancelar o temporizador de forma limpa antes da desmontagem da árvore de widgets
      harness.peerA.toggleRecording();
      await tester.pumpAndSettle();
    });
  });
}
