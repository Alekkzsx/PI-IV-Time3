// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_contracts.dart';
import '../helpers/video_call_test_components.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 2: Boundary Value Analysis - Audio Level Threshold & Speaker Detection', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer();
    });

    tearDown(() {
      harness.dispose();
    });

    test('Volume below threshold (0.14) leaves isSpeaking as false', () async {
      harness.peerA.setAudioLevel(0.14);
      await Future<void>.delayed(const Duration(milliseconds: 15));

      expect(harness.peerA.localParticipant.isSpeaking, isFalse);
      expect(harness.peerA.localParticipant.audioLevel, 0.14);
    });

    test('Volume at exact boundary threshold (0.15) leaves isSpeaking as false', () async {
      harness.peerA.setAudioLevel(0.15);
      await Future<void>.delayed(const Duration(milliseconds: 15));

      expect(harness.peerA.localParticipant.isSpeaking, isFalse);
    });

    test('Volume strictly above boundary threshold (0.16) triggers isSpeaking=true and broadcasts',
        () async {
      harness.peerA.setAudioLevel(0.16);
      await Future<void>.delayed(const Duration(milliseconds: 15));

      expect(harness.peerA.localParticipant.isSpeaking, isTrue);

      // Verifica se o Peer B recebe o destaque de fala
      final peerAOnRemote = harness.peerB.remoteParticipants.firstWhere(
        (p) => p.id == 'peer_a_id',
      );
      expect(peerAOnRemote.isSpeaking, isTrue);
      expect(peerAOnRemote.audioLevel, 0.16);
    });

    test('Hysteresis: isSpeaking remains true for 800ms cooldown after volume drops to 0.05',
        () async {
      // Passo 1: o volume sobe acima de 0.15
      harness.peerA.setAudioLevel(0.60);
      expect(harness.peerA.localParticipant.isSpeaking, isTrue);

      // Passo 2: o volume cai de volta para 0.05
      harness.peerA.setAudioLevel(0.05);

      // Dentro da janela de histerese de 800ms, isSpeaking permanece TRUE
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(harness.peerA.localParticipant.isSpeaking, isTrue);

      // Após 850ms, o temporizador de resfriamento expira e redefine isSpeaking para false
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(harness.peerA.localParticipant.isSpeaking, isFalse);
    });

    test('Muting audio immediately zeroes audioLevel and disables isSpeaking', () async {
      harness.peerA.setAudioLevel(0.85);
      expect(harness.peerA.localParticipant.isSpeaking, isTrue);

      // Desativa o áudio (silenciar)
      harness.peerA.toggleAudio();
      expect(harness.peerA.localParticipant.isAudioMuted, isTrue);
      expect(harness.peerA.localParticipant.isSpeaking, isFalse);
      expect(harness.peerA.localParticipant.audioLevel, 0.0);
    });

    testWidgets('Active speaker renders emerald highlight border on ParticipantVideoTile',
        (tester) async {
      const silentParticipant = Participant(
        id: 'p_silent',
        name: 'Alex',
        ra: '24802449',
        isSpeaking: false,
      );

      const speakingParticipant = Participant(
        id: 'p_speaking',
        name: 'Beatriz',
        ra: '24801122',
        isSpeaking: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ParticipantVideoTile(participant: silentParticipant),
                ParticipantVideoTile(participant: speakingParticipant),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final silentBox = tester.widget<Container>(
        find.byKey(const Key('participant_tile_p_silent')),
      );
      final speakingBox = tester.widget<Container>(
        find.byKey(const Key('participant_tile_p_speaking')),
      );

      final silentBorder = (silentBox.decoration as BoxDecoration).border as Border;
      final speakingBorder = (speakingBox.decoration as BoxDecoration).border as Border;

      expect(silentBorder.top.color, Colors.transparent);
      expect(speakingBorder.top.color, Colors.greenAccent);
      expect(speakingBorder.top.width, 3.0);
    });
  });
}
