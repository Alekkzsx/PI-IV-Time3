// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/datasources/video_call_signaling_datasource.dart';
import '../../data/media/call_media_engine.dart';
import '../../data/media/call_media_engine_factory.dart';
import '../../data/repositories/video_call_repository_impl.dart';
import '../../domain/entities/meeting_room.dart';
import '../../domain/entities/participant.dart';
import '../../domain/repositories/video_call_repository.dart';
import 'video_call_controller.dart';

/// Controlador para o estado da pré-chamada (Lobby), validações e preview real de hardware.
class VideoCallLobbyController extends ChangeNotifier {
  final VideoCallRepository? _injectedRepository;
  final ICallMediaEngine _mediaEngine;

  String _name = '';
  String _ra = '';
  String _roomCode = 'SALA-101';
  bool _isAudioMuted = false;
  bool _isVideoOff = false;
  double _audioLevel = 0.05;
  bool _handedOffMediaEngine = false;
  bool _isDisposed = false;
  late final Future<bool> _mediaInitialization;
  bool _isInitializingMedia = true;
  bool _isMediaReady = false;
  String? _mediaStatus;

  final List<StreamSubscription> _subscriptions = [];

  VideoCallLobbyController({
    VideoCallRepository? repository,
    ICallMediaEngine? mediaEngine,
  }) : _injectedRepository = repository,
       _mediaEngine = mediaEngine ?? createPlatformMediaEngine() {
    _mediaInitialization = _initHardwarePreview();
  }

  String get name => _name;
  String get ra => _ra;
  String get roomCode => _roomCode;
  bool get isAudioMuted => _isAudioMuted;
  bool get isVideoOff => _isVideoOff;
  double get audioLevel => _isAudioMuted ? 0.0 : _audioLevel;
  ICallMediaEngine get mediaEngine => _mediaEngine;
  String? get localVideoViewType => _mediaEngine.getVideoViewType('local');
  bool get isInitializingMedia => _isInitializingMedia;
  bool get isMediaReady => _isMediaReady;
  String? get mediaStatus => _mediaStatus;

  Future<bool> _initHardwarePreview() async {
    _subscriptions.add(
      _mediaEngine.onLocalAudioLevel.listen((level) {
        if (!_isDisposed && !_isAudioMuted) {
          _audioLevel = level;
          notifyListeners();
        }
      }),
    );
    _subscriptions.add(
      _mediaEngine.onVideoStreamUpdated.listen((_) {
        if (!_isDisposed) {
          notifyListeners();
        }
      }),
    );
    _subscriptions.add(
      _mediaEngine.onMediaStatus.listen((message) {
        if (!_isDisposed) {
          _mediaStatus = message;
          notifyListeners();
        }
      }),
    );
    final ready = await _mediaEngine.initializeLocalMedia(
      audioMuted: _isAudioMuted,
      videoOff: _isVideoOff,
    );
    if (!_isDisposed) {
      _isMediaReady = ready;
      _isInitializingMedia = false;
      if (!ready && _mediaStatus == null) {
        _mediaStatus =
            'Não foi possível acessar câmera ou microfone. Verifique as permissões do navegador e tente novamente.';
      }
      notifyListeners();
    }
    return ready;
  }

  Future<bool> ensureMediaReady() async {
    if (_isMediaReady) return true;
    await _mediaInitialization;
    if (_isMediaReady || _isDisposed) return _isMediaReady;

    _isInitializingMedia = true;
    _mediaStatus = null;
    notifyListeners();
    final ready = await _mediaEngine.initializeLocalMedia(
      audioMuted: _isAudioMuted,
      videoOff: _isVideoOff,
    );
    if (!_isDisposed) {
      _isMediaReady = ready;
      _isInitializingMedia = false;
      if (!ready && _mediaStatus == null) {
        _mediaStatus =
            'Não foi possível acessar câmera ou microfone. Verifique as permissões do navegador e tente novamente.';
      }
      notifyListeners();
    }
    return ready;
  }

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
    _mediaEngine.setMicrophoneMuted(_isAudioMuted);
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOff = !_isVideoOff;
    _mediaEngine.setCameraOff(_isVideoOff);
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

  /// Instancia o [VideoCallController] da sala com os parâmetros validados e o motor de mídia ativo.
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

    final repo =
        _injectedRepository ??
        VideoCallRepositoryImpl(dataSource: VideoCallSignalingDataSource());

    _handedOffMediaEngine = true;

    return VideoCallController(
      repository: repo,
      room: room,
      localParticipant: localParticipant,
      mediaEngine: _mediaEngine,
    );
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    if (!_handedOffMediaEngine) {
      _mediaEngine.dispose();
    }
    super.dispose();
  }
}
