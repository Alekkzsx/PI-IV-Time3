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
      // Act
      harness.peerA.sendChatMessage('Olá turma, bom dia!');

      // Allow in-memory bus async event dispatch
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Assert Peer A has message
      expect(harness.peerA.chatMessages.length, 1);
      expect(harness.peerA.chatMessages.first.text, 'Olá turma, bom dia!');
      expect(harness.peerA.chatMessages.first.senderName, 'Alex Sousa');
      expect(harness.peerA.chatMessages.first.senderRa, '24802449');

      // Assert Peer B received message over P2P bus
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
      // Drawer is initially closed
      expect(harness.peerB.isChatDrawerOpen, isFalse);
      expect(harness.peerB.unreadChatCount, 0);

      // Peer A sends 2 messages
      harness.peerA.sendChatMessage('Mensagem 1');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      harness.peerA.sendChatMessage('Mensagem 2');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Assert unread count is 2
      expect(harness.peerB.unreadChatCount, 2);

      // Peer B opens chat drawer
      harness.peerB.toggleChatDrawer();
      expect(harness.peerB.isChatDrawerOpen, isTrue);
      expect(harness.peerB.unreadChatCount, 0);

      // Subsequent message while drawer is open does NOT increment unread counter
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
