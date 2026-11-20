// Desenvolvido por Marcelo Zarpelon - RA: 25015323

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

      // --- FASE 1: Usuário 1 Entra Sozinho (Invariante Estrita de Zero Bots) ---
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

      // VERIFICAÇÃO ESTRITA DE ZERO BOTS:
      // Exatamente 1 bloco é exibido (Alex Sousa). Nenhum participante falso ou bot aparece.
      expect(controller1.allParticipants.length, 1);
      expect(controller1.remoteParticipants, isEmpty);
      expect(find.byType(ParticipantVideoTile), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_user_1_id')), findsOneWidget);
      expect(find.text('Alex Sousa (24802449)'), findsOneWidget);

      // --- FASE 2: Usuário 2 Entra na Sala pela Segunda Aba ---
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

      // Conecta ambos os pares diretamente pelo barramento de sinalização da sala
      controller1.registerRemoteParticipant(user2);
      controller2.registerRemoteParticipant(user1);

      await tester.pumpAndSettle();

      // VERIFICAÇÃO DE BLOCO DUPLO:
      // Ambos os participantes agora estão visíveis em tempo real na tela do Usuário 1.
      expect(controller1.allParticipants.length, 2);
      expect(controller1.remoteParticipants.length, 1);
      expect(find.byType(ParticipantVideoTile), findsNWidgets(2));
      expect(find.byKey(const Key('participant_tile_user_1_id')), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_user_2_id')), findsOneWidget);
      expect(find.text('Beatriz Lima (24801122)'), findsOneWidget);

      // --- FASE 3: Usuário 2 Clica em "Sair" / Deixa a Sala ---
      controller2.leaveCall();
      // A transmissão do envelope de saída remove o Usuário 2 imediatamente no Usuário 1
      repo1.leaveRoom(room.code, user2.id);

      await tester.pumpAndSettle();

      // VERIFICAÇÃO DE REMOÇÃO IMEDIATA:
      // O bloco do Usuário 2 é removido imediatamente, retornando estritamente para 1 bloco.
      expect(controller1.allParticipants.length, 1);
      expect(controller1.remoteParticipants, isEmpty);
      expect(find.byType(ParticipantVideoTile), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_user_1_id')), findsOneWidget);
      expect(find.byKey(const Key('participant_tile_user_2_id')), findsNothing);

      // Limpeza
      controller1.dispose();
      repo1.dispose();
      repo2.dispose();
    });
  });
}
