// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 1: Category-Partition - Floating Emoji Reactions Broadcast', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer();
    });

    tearDown(() {
      harness.dispose();
    });

    test('Sending supported emojis broadcasts to peer and adds to active reactions',
        () async {
      final supportedEmojis = ['❤️', '👍', '👏', '😂', '😮', '🎉'];

      for (final emoji in supportedEmojis) {
        harness.peerA.sendReaction(emoji);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Check Peer A active reactions
        expect(harness.peerA.activeReactions.any((r) => r.emoji == emoji), isTrue);

        // Check Peer B active reactions
        expect(harness.peerB.activeReactions.any((r) => r.emoji == emoji), isTrue);
      }
    });

    test('Rapid burst of reactions does not crash controller and queues all items',
        () async {
      for (int i = 0; i < 5; i++) {
        harness.peerB.sendReaction('🎉');
      }

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(harness.peerA.activeReactions.length, 5);
      expect(harness.peerB.activeReactions.length, 5);
      for (final reaction in harness.peerA.activeReactions) {
        expect(reaction.emoji, '🎉');
        expect(reaction.peerName, 'Beatriz Lima');
      }
    });

    test('Reactions contain accurate peer attribution and timestamps', () async {
      final before = DateTime.now();
      harness.peerA.sendReaction('👍');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final after = DateTime.now();

      final reaction = harness.peerB.activeReactions.first;
      expect(reaction.emoji, '👍');
      expect(reaction.peerId, 'peer_a_id');
      expect(reaction.peerName, 'Alex Sousa');
      expect(reaction.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(reaction.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });
}
