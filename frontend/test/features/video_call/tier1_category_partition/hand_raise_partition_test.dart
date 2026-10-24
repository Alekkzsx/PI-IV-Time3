// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter_test/flutter_test.dart';
import '../helpers/video_call_test_harness.dart';

void main() {
  group('Tier 1: Category-Partition - Hand Raising System & Queue Management', () {
    late VideoCallTestHarness harness;

    setUp(() async {
      harness = await VideoCallTestHarness.createDualPeer();
    });

    tearDown(() {
      harness.dispose();
    });

    test('Toggle hand raise adds local participant to queue and updates peer queue',
        () async {
      expect(harness.peerA.localParticipant.isHandRaised, isFalse);
      expect(harness.peerA.raisedHandsQueue, isEmpty);
      expect(harness.peerB.raisedHandsQueue, isEmpty);

      // Peer A raises hand
      harness.peerA.toggleHandRaise();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Assert Peer A state
      expect(harness.peerA.localParticipant.isHandRaised, isTrue);
      expect(harness.peerA.raisedHandsQueue.length, 1);
      expect(harness.peerA.raisedHandsQueue.first.peerId, 'peer_a_id');
      expect(harness.peerA.raisedHandsQueue.first.name, 'Alex Sousa');

      // Assert Peer B received hand raise event
      expect(harness.peerB.raisedHandsQueue.length, 1);
      expect(harness.peerB.raisedHandsQueue.first.peerId, 'peer_a_id');
      expect(harness.peerB.raisedHandsQueue.first.name, 'Alex Sousa');
    });

    test('Toggling hand raise again lowers hand and removes participant from queue',
        () async {
      // Raise
      harness.peerA.toggleHandRaise();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(harness.peerA.raisedHandsQueue.length, 1);

      // Lower
      harness.peerA.toggleHandRaise();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(harness.peerA.localParticipant.isHandRaised, isFalse);
      expect(harness.peerA.raisedHandsQueue, isEmpty);
      expect(harness.peerB.raisedHandsQueue, isEmpty);
    });

    test('Multiple participants raising hands preserves exact FIFO queue ordering',
        () async {
      // Peer A raises hand first
      harness.peerA.toggleHandRaise();
      await Future<void>.delayed(const Duration(milliseconds: 15));

      // Peer B raises hand second
      harness.peerB.toggleHandRaise();
      await Future<void>.delayed(const Duration(milliseconds: 15));

      // Check Peer A queue: A is index 0, B is index 1
      expect(harness.peerA.raisedHandsQueue.length, 2);
      expect(harness.peerA.raisedHandsQueue[0].name, 'Alex Sousa');
      expect(harness.peerA.raisedHandsQueue[1].name, 'Beatriz Lima');

      // Lower A's hand -> B advances to position 0
      harness.peerA.toggleHandRaise();
      await Future<void>.delayed(const Duration(milliseconds: 15));

      expect(harness.peerA.raisedHandsQueue.length, 1);
      expect(harness.peerA.raisedHandsQueue[0].name, 'Beatriz Lima');
    });
  });
}
