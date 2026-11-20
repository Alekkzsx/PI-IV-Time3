// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 1: Category-Partition - Chat Messaging & Unread Synchronization', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer();
    });

    tearDown(() {
      harness.dispose();
    });

    test('Valid chat message sent by Peer A appears in Peer B chat list with sender details',
        () async {
      // Ação
      harness.peerA.sendChatMessage('Olá turma, bom dia!');

      // Aguarda o despacho assíncrono de eventos no barramento em memória
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Verifica se o Peer A possui a mensagem
      expect(harness.peerA.chatMessages.length, 1);
      expect(harness.peerA.chatMessages.first.text, 'Olá turma, bom dia!');
      expect(harness.peerA.chatMessages.first.senderName, 'Alex Sousa');
      expect(harness.peerA.chatMessages.first.senderRa, '24802449');

      // Verifica se o Peer B recebeu a mensagem pelo barramento P2P
      expect(harness.peerB.chatMessages.length, 1);
      expect(harness.peerB.chatMessages.first.text, 'Olá turma, bom dia!');
      expect(harness.peerB.chatMessages.first.senderName, 'Alex Sousa');
      expect(harness.peerB.chatMessages.first.senderRa, '24802449');
    });

    test('Empty and whitespace-only chat messages are discarded without dispatching',
        () async {
      harness.peerA.sendChatMessage('   ');
      harness.peerA.sendChatMessage('');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(harness.peerA.chatMessages, isEmpty);
      expect(harness.peerB.chatMessages, isEmpty);
    });

    test('Unread chat counter increments when drawer is closed and resets to 0 when opened',
        () async {
      // A gaveta está inicialmente fechada
      expect(harness.peerB.isChatDrawerOpen, isFalse);
      expect(harness.peerB.unreadChatCount, 0);

      // Peer A envia 2 mensagens
      harness.peerA.sendChatMessage('Mensagem 1');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      harness.peerA.sendChatMessage('Mensagem 2');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Verifica se a contagem de não lidas é 2
      expect(harness.peerB.unreadChatCount, 2);

      // Peer B abre a gaveta do chat
      harness.peerB.toggleChatDrawer();
      expect(harness.peerB.isChatDrawerOpen, isTrue);
      expect(harness.peerB.unreadChatCount, 0);

      // Mensagem subsequente enquanto a gaveta está aberta NÃO incrementa o contador de não lidas
      harness.peerA.sendChatMessage('Mensagem 3 enquanto aberto');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(harness.peerB.unreadChatCount, 0);
      expect(harness.peerB.chatMessages.length, 3);
    });

    test('Bidirectional chat conversation preserves exact chronological ordering',
        () async {
      harness.peerA.sendChatMessage('Alex: Pergunta 1');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      harness.peerB.sendChatMessage('Beatriz: Resposta 1');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      harness.peerA.sendChatMessage('Alex: Obrigado Beatriz');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(harness.peerA.chatMessages.length, 3);
      expect(harness.peerB.chatMessages.length, 3);

      expect(harness.peerB.chatMessages[0].text, 'Alex: Pergunta 1');
      expect(harness.peerB.chatMessages[1].text, 'Beatriz: Resposta 1');
      expect(harness.peerB.chatMessages[2].text, 'Alex: Obrigado Beatriz');
    });
  });
}
