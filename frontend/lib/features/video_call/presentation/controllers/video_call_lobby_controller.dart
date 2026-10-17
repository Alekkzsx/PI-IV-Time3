// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/entities/meeting_room.dart';
import '../../domain/entities/participant.dart';
import '../../domain/repositories/video_call_repository.dart';
import '../../data/datasources/video_call_signaling_datasource.dart';
import '../../data/repositories/video_call_repository_impl.dart';
import 'video_call_controller.dart';

/// Controlador para o estado da pré-chamada (Lobby), validações e preview de hardware.
class VideoCallLobbyController extends ChangeNotifier {
  final VideoCallRepository? _injectedRepository;

  String _name = '';
  String _ra = '';
  String _roomCode = 'SALA-101';
  bool _isAudioMuted = false;
  bool _isVideoOff = false;
  double _audioLevel = 0.05;

  VideoCallLobbyController({
    VideoCallRepository? repository,
  }) : _injectedRepository = repository;

  String get name => _name;
  String get ra => _ra;
  String get roomCode => _roomCode;
  bool get isAudioMuted => _isAudioMuted;
  bool get isVideoOff => _isVideoOff;
  double get audioLevel => _isAudioMuted ? 0.0 : _audioLevel;

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setRa(String value) {
    _ra = value;
    notifyListeners();
  }

  void setRoomCode(String value) {
    _roomCode = value;
    notifyListeners();
  }

  void toggleAudio() {
    _isAudioMuted = !_isAudioMuted;
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOff = !_isVideoOff;
    notifyListeners();
  }

  void setAudioLevel(double level) {
    if (_isAudioMuted) return;
    _audioLevel = level;
    notifyListeners();
  }

  String? validateName(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Informe seu nome';
    }
    return null;
  }

  String? validateRa(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Informe seu RA';
    }
    if (val.trim().length < 4) {
      return 'RA inválido';
    }
    return null;
  }

  String? validateRoomCode(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Informe o código da sala';
    }
    final regex = RegExp(r'^[A-Z0-9\-]{3,32}$', caseSensitive: false);
    if (!regex.hasMatch(val.trim())) {
      return 'Código da sala inválido';
    }
    return null;
  }

  /// Instancia o [VideoCallController] da sala com os parâmetros validados.
  VideoCallController createCallController({
    required String name,
    required String ra,
    required String roomCode,
  }) {
    final sanitizedRoom = roomCode.trim().toUpperCase();
    final sanitizedName = name.trim();
    final sanitizedRa = ra.trim();

    final localParticipant = Participant(
      id: 'peer_${DateTime.now().microsecondsSinceEpoch}',
      name: sanitizedName,
      ra: sanitizedRa,
      role: 'participant',
      isAudioMuted: _isAudioMuted,
      isVideoOff: _isVideoOff,
      isLocal: true,
      audioLevel: _isAudioMuted ? 0.0 : _audioLevel,
    );

    final room = MeetingRoom(
      id: sanitizedRoom,
      code: sanitizedRoom,
      title: 'Sala $sanitizedRoom',
    );

    final repo = _injectedRepository ??
        VideoCallRepositoryImpl(
          dataSource: VideoCallSignalingDataSource(),
        );

    return VideoCallController(
      repository: repo,
      room: room,
      localParticipant: localParticipant,
    );
  }
}
