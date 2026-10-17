// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/data/channel/in_memory_signaling_bus.dart';

void main() {
  late InMemorySignalingBus bus;

  setUp(() {
    bus = InMemorySignalingBus();
    bus.reset();
  });

  tearDown(() {
    bus.reset();
  });

  group('InMemorySignalingChannel & InMemorySignalingBus', () {
    test('delivers message to peers on the same channel name and NEVER to the sender', () async {
      final ch1 = InMemorySignalingChannel('room_101', bus);
      final ch2 = InMemorySignalingChannel('room_101', bus);

      final ch1Messages = <String>[];
      final ch2Messages = <String>[];

      final sub1 = ch1.messageStream.listen(ch1Messages.add);
      final sub2 = ch2.messageStream.listen(ch2Messages.add);

      await ch1.send('{"hello": "from_peer_1"}');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(ch2Messages, equals(['{"hello": "from_peer_1"}']));
      expect(ch1Messages, isEmpty, reason: 'Sender must never receive its own broadcast');

      await sub1.cancel();
      await sub2.cancel();
      await ch1.close();
      await ch2.close();
    });

    test('isolates messages between distinct channel names', () async {
      final chA = InMemorySignalingChannel('room_A', bus);
      final chB = InMemorySignalingChannel('room_B', bus);

      final chBMessages = <String>[];
      final subB = chB.messageStream.listen(chBMessages.add);

      await chA.send('{"secret": "for_room_A"}');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(chBMessages, isEmpty);

      await subB.cancel();
      await chA.close();
      await chB.close();
    });

    test('supports teardown hook registration and simulation', () {
      final ch = InMemorySignalingChannel('room_101', bus);
      var teardownCalled = false;

      ch.registerTeardownHook(() {
        teardownCalled = true;
      });

      ch.simulateTeardown();
      expect(teardownCalled, isTrue);
    });

    test('throws StateError when sending on a closed channel', () async {
      final ch = InMemorySignalingChannel('room_101', bus);
      await ch.close();

      expect(() => ch.send('data'), throwsA(isA<StateError>()));
    });

    test('resetAll clears all bus channels', () async {
      final ch1 = InMemorySignalingChannel('room_101', bus);
      final ch2 = InMemorySignalingChannel('room_101', bus);

      InMemorySignalingBus.resetAll();

      final ch2Messages = <String>[];
      final sub2 = ch2.messageStream.listen(ch2Messages.add);

      // Since bus was reset, ch1 cannot send to ch2
      await ch1.send('msg');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(ch2Messages, isEmpty);
      await sub2.cancel();
    });
  });
}
