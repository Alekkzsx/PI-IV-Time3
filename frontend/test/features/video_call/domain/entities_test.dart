// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/chat_message.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/emoji_reaction.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/hand_raise_item.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/media_state_update.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/meeting_room.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/participant.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/recording_state.dart';

void main() {
  group('Participant Entity', () {
    test('dynamic speaking detection activates when audioLevel > 0.15 and not muted', () {
      final speakingParticipant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
        isAudioMuted: false,
        audioLevel: 0.25,
      );
      expect(speakingParticipant.isSpeaking, isTrue);

      final quietParticipant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
        isAudioMuted: false,
        audioLevel: 0.05,
      );
      expect(quietParticipant.isSpeaking, isFalse);

      final mutedParticipant = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
        isAudioMuted: true,
        audioLevel: 0.80,
      );
      expect(mutedParticipant.isSpeaking, isFalse);
    });

    test('supports explicit isSpeaking override when provided', () {
      final forcedSpeaking = Participant(
        id: 'peer_2',
        name: 'Maria Silva',
        ra: '24801122',
        isSpeaking: true,
        audioLevel: 0.0,
      );
      expect(forcedSpeaking.isSpeaking, isTrue);
    });

    test('copyWith updates properties and preserves unchanged fields', () {
      final original = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
        isAudioMuted: false,
      );
      final updated = original.copyWith(isAudioMuted: true, audioLevel: 0.5);

      expect(updated.id, equals('peer_1'));
      expect(updated.name, equals('Alex Sousa'));
      expect(updated.isAudioMuted, isTrue);
      expect(updated.audioLevel, equals(0.5));
    });

    test('value equality and hashCode behavior', () {
      final p1 = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );
      final p2 = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );
      final p3 = Participant(
        id: 'peer_2',
        name: 'Carlos Oliveira',
        ra: '24809988',
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    test('toString contains descriptive participant attributes', () {
      final p = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
      );
      expect(p.toString(), contains('Alex Sousa'));
      expect(p.toString(), contains('24802449'));
    });
  });

  group('MeetingRoom Entity', () {
    test('code getter aliases id and defaults properly', () {
      final room = MeetingRoom(id: 'SALA-101', title: 'Laboratório de Redes');
      expect(room.id, equals('SALA-101'));
      expect(room.code, equals('SALA-101'));
      expect(room.maxParticipants, equals(50));
      expect(room.isLocked, isFalse);
    });

    test('copyWith updates room fields correctly', () {
      final room = MeetingRoom(id: 'SALA-101', title: 'Lab');
      final updated = room.copyWith(isLocked: true, title: 'Lab Avançado');
      expect(updated.isLocked, isTrue);
      expect(updated.title, equals('Lab Avançado'));
      expect(updated.id, equals('SALA-101'));
    });

    test('value equality and hashCode', () {
      final r1 = MeetingRoom(id: 'SALA-101', title: 'Lab');
      final r2 = MeetingRoom(id: 'SALA-101', title: 'Lab');
      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
    });
  });

  group('ChatMessage Entity', () {
    test('content getter aliases text and preserves isLocal', () {
      final time = DateTime(2026, 10, 17, 10, 0);
      final msg = ChatMessage(
        id: 'msg_1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        senderRa: '24802449',
        text: 'Olá a todos!',
        timestamp: time,
        isLocal: true,
      );

      expect(msg.text, equals('Olá a todos!'));
      expect(msg.content, equals('Olá a todos!'));
      expect(msg.isLocal, isTrue);
    });

    test('copyWith and equality', () {
      final time = DateTime(2026, 10, 17, 10, 0);
      final msg1 = ChatMessage(
        id: 'msg_1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        senderRa: '24802449',
        text: 'Olá!',
        timestamp: time,
      );
      final msg2 = msg1.copyWith(text: 'Olá atualizado!');
      expect(msg2.text, equals('Olá atualizado!'));
      expect(msg2.id, equals('msg_1'));
      expect(msg1, isNot(equals(msg2)));
    });
  });

  group('EmojiReaction Entity', () {
    test('supportedEmojis contains canonical emojis', () {
      expect(EmojiReaction.supportedEmojis, contains('❤️'));
      expect(EmojiReaction.supportedEmojis, contains('👍'));
      expect(EmojiReaction.supportedEmojis, contains('👏'));
      expect(EmojiReaction.supportedEmojis, contains('😂'));
      expect(EmojiReaction.supportedEmojis, contains('😮'));
      expect(EmojiReaction.supportedEmojis, contains('🎉'));
      expect(EmojiReaction.isValidEmoji('❤️'), isTrue);
      expect(EmojiReaction.isValidEmoji('🚀'), isFalse);
    });

    test('peerId and peerName getters alias senderId and senderName', () {
      final reaction = EmojiReaction(
        id: 'react_1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        emoji: '👍',
        timestamp: DateTime(2026, 10, 17, 10, 5),
        startX: 0.75,
      );
      expect(reaction.peerId, equals('peer_1'));
      expect(reaction.peerName, equals('Alex Sousa'));
      expect(reaction.startX, equals(0.75));
    });
  });

  group('HandRaiseItem Entity', () {
    test('name and ra getters alias participantName and academicId', () {
      final item = HandRaiseItem(
        peerId: 'peer_1',
        participantName: 'Alex Sousa',
        academicId: '24802449',
        raisedAt: DateTime(2026, 10, 17, 10, 2),
      );
      expect(item.name, equals('Alex Sousa'));
      expect(item.ra, equals('24802449'));
      expect(item.isRaised, isTrue);
    });

    test('copyWith updates fields', () {
      final item = HandRaiseItem(
        peerId: 'peer_1',
        participantName: 'Alex Sousa',
        academicId: '24802449',
        raisedAt: DateTime(2026, 10, 17, 10, 2),
      );
      final lowered = item.copyWith(isRaised: false);
      expect(lowered.isRaised, isFalse);
    });
  });

  group('MediaStateUpdate Entity', () {
    test('instantiates with optional media properties', () {
      final update = MediaStateUpdate(
        peerId: 'peer_1',
        isAudioMuted: true,
        isVideoOff: false,
        audioLevel: 0.42,
        timestamp: DateTime(2026, 10, 17, 10, 3),
      );
      expect(update.peerId, equals('peer_1'));
      expect(update.isAudioMuted, isTrue);
      expect(update.isVideoOff, isFalse);
      expect(update.isScreenSharing, isNull);
      expect(update.audioLevel, closeTo(0.42, 0.001));
    });
  });

  group('RecordingState Entity', () {
    test('initial factory returns idle state with zero duration', () {
      final initial = RecordingState.initial();
      expect(initial.isIdle, isTrue);
      expect(initial.isRecording, isFalse);
      expect(initial.elapsedDuration, equals(Duration.zero));
      expect(initial.formattedDuration, equals('00:00:00'));
    });

    test('formattedDuration formats hours, minutes and seconds', () {
      const state = RecordingState(
        status: RecordingStatus.recording,
        elapsedDuration: Duration(hours: 1, minutes: 2, seconds: 34),
      );
      expect(state.formattedDuration, equals('01:02:34'));
      expect(state.isRecording, isTrue);
    });

    test('recordedById and recordedByName aliases', () {
      const state = RecordingState(
        status: RecordingStatus.recording,
        startedByPeerId: 'peer_1',
        startedByName: 'Alex Sousa',
      );
      expect(state.recordedById, equals('peer_1'));
      expect(state.recordedByName, equals('Alex Sousa'));
    });
  });
}
