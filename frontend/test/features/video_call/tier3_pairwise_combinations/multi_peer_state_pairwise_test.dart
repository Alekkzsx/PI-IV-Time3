// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_test_components.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 3: Pairwise Combinations - Multi-Peer Concurrent State Matrix', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer();
    });

    tearDown(() {
      harness.dispose();
    });

    testWidgets('Pairwise: [Peer A Speaking] x [Peer B Hand Raised] x [Recording Active]',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 1. Peer A começa a falar
      harness.peerA.setAudioLevel(0.45);
      // 2. Peer B levanta a mão
      harness.peerB.toggleHandRaise();
      // 3. Peer A inicia a gravação
      harness.peerA.toggleRecording();

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pump();

      // Verifica se o bloco do Peer A exibe o destaque de fala ativa
      final peerABox = tester.widget<Container>(
        find.byKey(const Key('participant_tile_peer_a_id')),
      );
      final borderA = (peerABox.decoration as BoxDecoration).border as Border;
      expect(borderA.top.color, Colors.greenAccent);

      // Verifica se o Peer B possui o emblema de mão levantada e se o banner de mãos levantadas está visível
      expect(find.byKey(const Key('raised_hands_banner')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('raised_hands_banner')),
          matching: find.text('Beatriz Lima (24801122)'),
        ),
        findsOneWidget,
      );

      // Verifica se o banner e o emblema de gravação estão ativos
      expect(find.byKey(const Key('institutional_recording_banner')), findsOneWidget);
      expect(find.byKey(const Key('recording_timer_badge')), findsOneWidget);

      // Limpa o temporizador de gravação antes de encerrar o teste
      harness.peerA.toggleRecording();
      await tester.pump();
    });

    testWidgets('Pairwise: [Peer A Silent] x [Peer B Hand Lowered] x [ScreenShare Active]',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Peer A inicia o compartilhamento de tela enquanto está em silêncio
      harness.peerA.toggleScreenShare();

      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallRoomPage(controller: harness.peerA),
        ),
      );
      await tester.pumpAndSettle();

      // Tela principal de apresentação visível
      expect(find.byKey(const Key('screen_share_view')), findsOneWidget);
      // Nenhum banner de mãos levantadas
      expect(find.byKey(const Key('raised_hands_banner')), findsNothing);
      // A faixa horizontal contém ambos os participantes
      expect(find.byType(ListView), findsOneWidget);
    });

    test('Concurrent message and reaction dispatch during active recording', () async {
      // Inicia a gravação
      harness.peerA.toggleRecording();

      // Peer B envia mensagem no chat e reação simultaneamente
      harness.peerB.sendChatMessage('Pergunta importante durante a gravação');
      harness.peerB.sendReaction('❤️');

      expect(harness.peerA.chatMessages.length, 1);
      expect(harness.peerA.chatMessages.first.text, 'Pergunta importante durante a gravação');
      expect(harness.peerA.activeReactions.length, 1);
      expect(harness.peerA.activeReactions.first.emoji, '❤️');
      expect(harness.peerA.recordingState.isRecording, isTrue);

      harness.peerA.toggleRecording();
    });
  });
}
