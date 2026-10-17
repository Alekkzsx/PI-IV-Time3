// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter_test/flutter_test.dart';
import 'package:pi_iv_time3/features/video_call/data/models/chat_message_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/emoji_reaction_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/participant_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/recording_state_model.dart';
import 'package:pi_iv_time3/features/video_call/data/models/signaling_envelope_model.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/participant.dart';
import 'package:pi_iv_time3/features/video_call/domain/entities/recording_state.dart';

void main() {
  group('SignalingEnvelopeModel', () {
    test('serializes to and from Map JSON and raw JSON string', () {
      final envelope = SignalingEnvelopeModel.create(
        type: SignalingEnvelopeType.join,
        roomId: 'SALA-101',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        timestamp: 1729169480000,
        payload: {'custom': 'payload_val'},
      );

      final raw = envelope.toRawJson();
      final decoded = SignalingEnvelopeModel.fromRawJson(raw);

      expect(decoded.type, equals(SignalingEnvelopeType.join));
      expect(decoded.roomId, equals('SALA-101'));
      expect(decoded.senderId, equals('peer_1'));
      expect(decoded.senderName, equals('Alex Sousa'));
      expect(decoded.timestamp, equals(1729169480000));
      expect(decoded.payload['custom'], equals('payload_val'));
      expect(decoded, equals(envelope));
    });

    test('validates all 10 envelope types in SignalingEnvelopeType', () {
      expect(SignalingEnvelopeType.values.length, equals(10));
      expect(SignalingEnvelopeType.matches('JOIN', SignalingEnvelopeType.join), isTrue);
      expect(SignalingEnvelopeType.matches('presence_sync', SignalingEnvelopeType.presenceSync), isTrue);
      expect(SignalingEnvelopeType.matches('HEARTBEAT', SignalingEnvelopeType.heartbeat), isTrue);
      expect(SignalingEnvelopeType.matches('leave', SignalingEnvelopeType.leave), isTrue);
      expect(SignalingEnvelopeType.matches('chat', SignalingEnvelopeType.chat), isTrue);
      expect(SignalingEnvelopeType.matches('emoji', SignalingEnvelopeType.emoji), isTrue);
      expect(SignalingEnvelopeType.matches('hand_raise', SignalingEnvelopeType.handRaise), isTrue);
      expect(SignalingEnvelopeType.matches('media_state', SignalingEnvelopeType.mediaState), isTrue);
      expect(SignalingEnvelopeType.matches('recording_state', SignalingEnvelopeType.recordingState), isTrue);
      expect(SignalingEnvelopeType.matches('webrtc_signal', SignalingEnvelopeType.webrtcSignal), isTrue);
    });
  });

  group('ParticipantModel', () {
    test('JSON serialization round-trip', () {
      const model = ParticipantModel(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
        isAudioMuted: true,
        isVideoOff: false,
        isScreenSharing: true,
        isHandRaised: true,
        audioLevel: 0.72,
        isSpeaking: false,
        lastHeartbeat: 1729169480000,
        role: 'participant',
      );

      final json = model.toJson();
      final fromJson = ParticipantModel.fromJson(json);

      expect(fromJson.id, equals(model.id));
      expect(fromJson.name, equals(model.name));
      expect(fromJson.ra, equals(model.ra));
      expect(fromJson.isAudioMuted, isTrue);
      expect(fromJson.isScreenSharing, isTrue);
      expect(fromJson.audioLevel, closeTo(0.72, 0.001));
      expect(fromJson, equals(model));
    });

    test('entity round-trip conversion', () {
      final entity = Participant(
        id: 'peer_1',
        name: 'Alex Sousa',
        ra: '24802449',
        isAudioMuted: false,
        audioLevel: 0.35,
      );

      final model = ParticipantModel.fromEntity(entity);
      final convertedEntity = model.toEntity(isLocal: true);

      expect(convertedEntity.id, equals(entity.id));
      expect(convertedEntity.name, equals(entity.name));
      expect(convertedEntity.ra, equals(entity.ra));
      expect(convertedEntity.isLocal, isTrue);
      expect(convertedEntity.isSpeaking, isTrue);
    });
  });

  group('ChatMessageModel', () {
    test('serializes to JSON and maps to domain entity', () {
      const model = ChatMessageModel(
        id: 'msg_1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        senderRa: '24802449',
        text: 'Boa tarde a todos!',
        timestamp: 1729169480000,
      );

      final json = model.toJson();
      final fromJson = ChatMessageModel.fromJson(json);
      expect(fromJson.text, equals('Boa tarde a todos!'));
      expect(fromJson.content, equals('Boa tarde a todos!'));
      expect(fromJson, equals(model));

      final entity = model.toEntity(isLocal: true);
      expect(entity.id, equals('msg_1'));
      expect(entity.isLocal, isTrue);
      expect(entity.text, equals('Boa tarde a todos!'));

      final backToModel = ChatMessageModel.fromEntity(entity);
      expect(backToModel, equals(model));
    });

    test('parses ISO8601 string timestamp if provided in JSON', () {
      final json = {
        'id': 'msg_2',
        'senderId': 'peer_2',
        'senderName': 'Maria',
        'senderRa': '24801122',
        'text': 'Oi',
        'timestamp': '2026-10-17T12:00:00.000Z',
      };
      final model = ChatMessageModel.fromJson(json);
      expect(model.timestamp, equals(DateTime.parse('2026-10-17T12:00:00.000Z').millisecondsSinceEpoch));
    });
  });

  group('EmojiReactionModel', () {
    test('serializes to JSON and maps to domain entity', () {
      const model = EmojiReactionModel(
        id: 'react_1',
        senderId: 'peer_1',
        senderName: 'Alex Sousa',
        emoji: '❤️',
        timestamp: 1729169480000,
        startX: 0.35,
      );

      final json = model.toJson();
      final fromJson = EmojiReactionModel.fromJson(json);
      expect(fromJson.emoji, equals('❤️'));
      expect(fromJson.peerId, equals('peer_1'));
      expect(fromJson.peerName, equals('Alex Sousa'));
      expect(fromJson.startX, closeTo(0.35, 0.001));
      expect(fromJson, equals(model));

      final entity = model.toEntity();
      expect(entity.emoji, equals('❤️'));
      expect(entity.startX, closeTo(0.35, 0.001));

      final backToModel = EmojiReactionModel.fromEntity(entity);
      expect(backToModel, equals(model));
    });
  });

  group('RecordingStateModel', () {
    test('serializes to JSON and maps to domain entity', () {
      final now = DateTime.now();
      final entity = RecordingState(
        status: RecordingStatus.recording,
        isRecording: true,
        startedByPeerId: 'peer_1',
        startedByName: 'Alex Sousa',
        startedAt: now,
        elapsedDuration: const Duration(seconds: 45),
        outputPath: 'blob:http://localhost/rec.webm',
      );

      final model = RecordingStateModel.fromEntity(entity);
      expect(model.isRecording, isTrue);
      expect(model.status, equals('recording'));
      expect(model.recordedById, equals('peer_1'));
      expect(model.recordedByName, equals('Alex Sousa'));
      expect(model.elapsedDurationMs, equals(45000));

      final json = model.toJson();
      final fromJson = RecordingStateModel.fromJson(json);
      expect(fromJson, equals(model));

      final convertedEntity = fromJson.toEntity();
      expect(convertedEntity.isRecording, isTrue);
      expect(convertedEntity.status, equals(RecordingStatus.recording));
      expect(convertedEntity.elapsedDuration.inSeconds, equals(45));
    });

    test('initial factory returns idle state', () {
      final initial = RecordingStateModel.initial();
      expect(initial.isRecording, isFalse);
      expect(initial.status, equals('idle'));
      expect(initial.toEntity().isIdle, isTrue);
    });
  });
}
