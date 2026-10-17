// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/services.dart';
import '../../domain/entities/session_export.dart';
import 'call_media_engine.dart';

/// Cria a instância de [ICallMediaEngine] conectada às APIs reais do navegador Web.
ICallMediaEngine createCallMediaEngine() => WebCallMediaEngine();

/// Motor de mídia e WebRTC real para navegador Web.
///
/// Integra:
/// - `navigator.mediaDevices.getUserMedia` para câmera e microfone físicos.
/// - `AudioContext` + `AnalyserNode` para leitura em tempo real da voz no microfone.
/// - `navigator.mediaDevices.getDisplayMedia` para compartilhamento de tela real.
/// - `RTCPeerConnection` para streaming P2P de vídeo e áudio entre abas/usuários reais.
/// - `MediaRecorder` + download automático de `.webm` e ata `.txt` da sessão.
class WebCallMediaEngine implements ICallMediaEngine {
  static int _viewSequence = 0;

  final StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();
  final StreamController<void> _screenShareStoppedController =
      StreamController<void>.broadcast();
  final StreamController<Map<String, dynamic>> _outboundWebRtcController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _videoStreamUpdatedController =
      StreamController<String>.broadcast();

  final Map<String, String> _registeredViewTypes = {};
  final Map<String, html.VideoElement> _videoElements = {};
  final Map<String, html.RtcPeerConnection> _peerConnections = {};
  final Map<String, html.MediaStream> _remoteStreams = {};

  html.MediaStream? _localStream;
  html.MediaStream? _screenStream;
  Object? _audioContext;
  Object? _analyserNode;
  Timer? _audioMeterTimer;

  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _recordedChunks = [];

  bool _isInitialized = false;
  bool _isAudioMuted = false;
  bool _isVideoOff = false;
  bool _isDisposed = false;

  @override
  Stream<double> get onLocalAudioLevel => _audioLevelController.stream;

  @override
  Stream<void> get onScreenShareStoppedExternally =>
      _screenShareStoppedController.stream;

  @override
  Stream<Map<String, dynamic>> get onOutboundWebRtcSignal =>
      _outboundWebRtcController.stream;

  @override
  Stream<String> get onVideoStreamUpdated =>
      _videoStreamUpdatedController.stream;

  @override
  bool get isInitialized => _isInitialized;

  @override
  String? getVideoViewType(String streamKey) => _registeredViewTypes[streamKey];

  void _bindStreamToVideoView(
    String streamKey,
    html.MediaStream stream, {
    required bool muted,
    required bool mirror,
  }) {
    final existingElement = _videoElements[streamKey];
    if (existingElement != null) {
      existingElement.srcObject = stream;
      existingElement.muted = muted;
      existingElement.play().catchError((_) {});
      if (!_videoStreamUpdatedController.isClosed) {
        _videoStreamUpdatedController.add(streamKey);
      }
      return;
    }

    _viewSequence++;
    final viewType = 'agmrm-video-$streamKey-$_viewSequence';
    final videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = muted
      ..controls = false
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.backgroundColor = '#09090B';

    if (mirror) {
      videoElement.style.transform = 'scaleX(-1)';
    }

    videoElement.setAttribute('playsinline', 'true');
    videoElement.srcObject = stream;

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => videoElement,
    );

    _videoElements[streamKey] = videoElement;
    _registeredViewTypes[streamKey] = viewType;
    videoElement.play().catchError((_) {});

    if (!_videoStreamUpdatedController.isClosed) {
      _videoStreamUpdatedController.add(streamKey);
    }
  }

  @override
  Future<bool> initializeLocalMedia({
    bool audioMuted = false,
    bool videoOff = false,
  }) async {
    if (_isDisposed) return false;
    _isAudioMuted = audioMuted;
    _isVideoOff = videoOff;

    if (_localStream != null) {
      await setMicrophoneMuted(audioMuted);
      await setCameraOff(videoOff);
      _bindStreamToVideoView(
        'local',
        _localStream!,
        muted: true,
        mirror: true,
      );
      _isInitialized = true;
      return true;
    }

    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) return false;

    try {
      _localStream = await mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'facingMode': 'user',
        },
      });
    } catch (_) {
      // Caso o computador tenha apenas microfone ou apenas câmera, tenta individualmente
      try {
        _localStream = await mediaDevices.getUserMedia({'audio': true, 'video': false});
      } catch (_) {
        try {
          _localStream = await mediaDevices.getUserMedia({'audio': false, 'video': true});
        } catch (_) {
          return false;
        }
      }
    }

    if (_localStream == null) return false;

    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !_isAudioMuted;
    }
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = !_isVideoOff;
    }

    _bindStreamToVideoView(
      'local',
      _localStream!,
      muted: true,
      mirror: true,
    );
    _startRealAudioAnalyser(_localStream!);

    _isInitialized = true;
    return true;
  }

  void _startRealAudioAnalyser(html.MediaStream stream) {
    _audioMeterTimer?.cancel();
    if (stream.getAudioTracks().isEmpty) return;

    try {
      final audioCtxConstructor = js_util.getProperty<Object?>(
            html.window,
            'AudioContext',
          ) ??
          js_util.getProperty<Object?>(
            html.window,
            'webkitAudioContext',
          );
      if (audioCtxConstructor == null) return;

      final audioCtx = js_util.callConstructor<Object>(audioCtxConstructor, []);
      final source = js_util.callMethod<Object>(
        audioCtx,
        'createMediaStreamSource',
        [stream],
      );
      final analyser = js_util.callMethod<Object>(
        audioCtx,
        'createAnalyser',
        [],
      );
      js_util.setProperty(analyser, 'fftSize', 256);
      js_util.setProperty(analyser, 'smoothingTimeConstant', 0.5);
      js_util.callMethod<void>(source, 'connect', [analyser]);

      _audioContext = audioCtx;
      _analyserNode = analyser;

      final bufferLength =
          js_util.getProperty<int>(analyser, 'frequencyBinCount');
      final dataArray = Uint8List(bufferLength);

      _audioMeterTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) {
          if (_isDisposed || _analyserNode == null) return;
          if (_isAudioMuted) {
            if (!_audioLevelController.isClosed) {
              _audioLevelController.add(0.0);
            }
            return;
          }

          try {
            final state = js_util.getProperty<String?>(audioCtx, 'state');
            if (state == 'suspended') {
              js_util.callMethod<void>(audioCtx, 'resume', []);
            }

            js_util.callMethod<void>(
              _analyserNode!,
              'getByteFrequencyData',
              [dataArray],
            );

            double sumSquares = 0.0;
            for (var i = 0; i < dataArray.length; i++) {
              final normalized = dataArray[i] / 255.0;
              sumSquares += normalized * normalized;
            }
            final rms = math.sqrt(sumSquares / dataArray.length);
            // Amplifica suavemente para sensibilidade natural de voz humana
            final scaledLevel = (rms * 2.4).clamp(0.0, 1.0);

            if (!_audioLevelController.isClosed) {
              _audioLevelController.add(scaledLevel);
            }
          } catch (_) {}
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {
    _isAudioMuted = muted;
    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getAudioTracks()) {
        track.enabled = !muted;
      }
    }
    if (muted && !_audioLevelController.isClosed) {
      _audioLevelController.add(0.0);
    }
  }

  @override
  Future<void> setCameraOff(bool videoOff) async {
    _isVideoOff = videoOff;
    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getVideoTracks()) {
        track.enabled = !videoOff;
      }
      if (!videoOff) {
        _videoElements['local']?.play().catchError((_) {});
      }
    }
    if (!_videoStreamUpdatedController.isClosed) {
      _videoStreamUpdatedController.add('local');
    }
  }

  @override
  Future<bool> startScreenShare() async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) return false;

    try {
      final streamObj = await js_util.promiseToFuture<Object>(
        js_util.callMethod<Object>(
          mediaDevices,
          'getDisplayMedia',
          [
            js_util.jsify({
              'video': {'cursor': 'always'},
              'audio': true,
            }),
          ],
        ),
      );

      final displayStream = streamObj as html.MediaStream;
      _screenStream = displayStream;

      _bindStreamToVideoView(
        'screen',
        displayStream,
        muted: true,
        mirror: false,
      );

      final videoTracks = displayStream.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        videoTracks.first.onEnded.listen((_) {
          _screenStream = null;
          _replaceOutboundVideoTrack(_localStream?.getVideoTracks().firstOrNull);
          if (!_screenShareStoppedController.isClosed) {
            _screenShareStoppedController.add(null);
          }
        });
        _replaceOutboundVideoTrack(videoTracks.first);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stopScreenShare() async {
    final stream = _screenStream;
    _screenStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }
    _replaceOutboundVideoTrack(_localStream?.getVideoTracks().firstOrNull);
    if (!_videoStreamUpdatedController.isClosed) {
      _videoStreamUpdatedController.add('screen');
    }
  }

  void _replaceOutboundVideoTrack(html.MediaStreamTrack? newTrack) {
    if (newTrack == null) return;
    for (final pc in _peerConnections.values) {
      try {
        final senders = js_util.callMethod<List<dynamic>>(pc, 'getSenders', []);
        for (final sender in senders) {
          final track = js_util.getProperty<html.MediaStreamTrack?>(
            sender as Object,
            'track',
          );
          if (track != null && track.kind == 'video') {
            js_util.callMethod<Object>(sender, 'replaceTrack', [newTrack]);
          }
        }
      } catch (_) {}
    }
  }

  Future<html.RtcPeerConnection> _getOrCreatePeerConnection(
    String remotePeerId,
  ) async {
    if (_peerConnections.containsKey(remotePeerId)) {
      return _peerConnections[remotePeerId]!;
    }

    final pc = html.RtcPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    });

    _peerConnections[remotePeerId] = pc;

    // Anexa trilhas locais de áudio e vídeo
    final streamToSend = _screenStream ?? _localStream;
    if (streamToSend != null) {
      for (final track in streamToSend.getTracks()) {
        js_util.callMethod<void>(pc, 'addTrack', [track, streamToSend]);
      }
    }

    // Escuta candidatos ICE locais e publica no barramento P2P
    pc.onIceCandidate.listen((html.RtcPeerConnectionIceEvent event) {
      final candidate = event.candidate;
      if (candidate != null && !_outboundWebRtcController.isClosed) {
        _outboundWebRtcController.add({
          'targetPeerId': remotePeerId,
          'signalType': 'ice',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    });

    // Escuta trilhas remotas recebidas (ontrack / onAddStream)
    js_util.setProperty(
      pc,
      'ontrack',
      js_util.allowInterop((html.Event event) {
        final streams = js_util.getProperty<List<dynamic>?>(event, 'streams');
        if (streams != null && streams.isNotEmpty) {
          final remoteStream = streams.first as html.MediaStream;
          _remoteStreams[remotePeerId] = remoteStream;
          _bindStreamToVideoView(
            remotePeerId,
            remoteStream,
            muted: false,
            mirror: false,
          );
        }
      }),
    );

    pc.onAddStream.listen((html.MediaStreamEvent event) {
      final remoteStream = event.stream;
      if (remoteStream != null) {
        _remoteStreams[remotePeerId] = remoteStream;
        _bindStreamToVideoView(
          remotePeerId,
          remoteStream,
          muted: false,
          mirror: false,
        );
      }
    });

    return pc;
  }

  @override
  Future<void> connectToPeer(
    String remotePeerId, {
    required bool isInitiator,
  }) async {
    if (_isDisposed) return;
    try {
      final pc = await _getOrCreatePeerConnection(remotePeerId);
      if (isInitiator) {
        final offer = await pc.createOffer({
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': true,
        });
        await pc.setLocalDescription(offer);
        if (!_outboundWebRtcController.isClosed) {
          _outboundWebRtcController.add({
            'targetPeerId': remotePeerId,
            'signalType': 'offer',
            'sdp': offer.sdp,
            'type': offer.type,
          });
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> handleInboundWebRtcSignal(
    String remotePeerId,
    Map<String, dynamic> signalData,
  ) async {
    if (_isDisposed) return;
    try {
      final signalType = signalData['signalType'] as String? ?? '';
      final pc = await _getOrCreatePeerConnection(remotePeerId);

      if (signalType == 'offer') {
        final sdp = signalData['sdp'] as String?;
        final type = signalData['type'] as String? ?? 'offer';
        if (sdp == null) return;

        await pc.setRemoteDescription(
          html.RtcSessionDescription({'sdp': sdp, 'type': type}),
        );
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);

        if (!_outboundWebRtcController.isClosed) {
          _outboundWebRtcController.add({
            'targetPeerId': remotePeerId,
            'signalType': 'answer',
            'sdp': answer.sdp,
            'type': answer.type,
          });
        }
      } else if (signalType == 'answer') {
        final sdp = signalData['sdp'] as String?;
        final type = signalData['type'] as String? ?? 'answer';
        if (sdp == null) return;

        await pc.setRemoteDescription(
          html.RtcSessionDescription({'sdp': sdp, 'type': type}),
        );
      } else if (signalType == 'ice') {
        final candidateStr = signalData['candidate'] as String?;
        if (candidateStr == null || candidateStr.isEmpty) return;

        final ice = html.RtcIceCandidate({
          'candidate': candidateStr,
          'sdpMid': signalData['sdpMid'],
          'sdpMLineIndex': signalData['sdpMLineIndex'],
        });
        await pc.addIceCandidate(ice);
      }
    } catch (_) {}
  }

  @override
  Future<void> disconnectPeer(String remotePeerId) async {
    final pc = _peerConnections.remove(remotePeerId);
    try {
      pc?.close();
    } catch (_) {}

    final stream = _remoteStreams.remove(remotePeerId);
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }
    _videoElements.remove(remotePeerId)?.srcObject = null;
    _registeredViewTypes.remove(remotePeerId);
  }

  @override
  Future<void> startRecording() async {
    _recordedChunks.clear();
    final targetStream = _screenStream ?? _localStream;
    if (targetStream == null) return;

    try {
      _mediaRecorder = html.MediaRecorder(targetStream);
      _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
        final blob = js_util.getProperty<html.Blob?>(event, 'data');
        if (blob != null && blob.size > 0) {
          _recordedChunks.add(blob);
        }
      });
      _mediaRecorder!.start(1000);
    } catch (_) {
      _mediaRecorder = null;
    }
  }

  @override
  Future<String?> stopRecordingAndDownload(SessionExport exportSummary) async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;

    try {
      if (_mediaRecorder != null && _mediaRecorder!.state != 'inactive') {
        final completer = Completer<void>();
        _mediaRecorder!.addEventListener('stop', (_) {
          if (!completer.isCompleted) completer.complete();
        });
        _mediaRecorder!.stop();
        await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }
    } catch (_) {}

    // 1. Se houver vídeo/áudio capturado pelo MediaRecorder, baixa o arquivo .webm real
    if (_recordedChunks.isNotEmpty) {
      try {
        final videoBlob = html.Blob(_recordedChunks, 'video/webm');
        final videoUrl = html.Url.createObjectUrlFromBlob(videoBlob);
        final videoFileName =
            'gravacao_${exportSummary.roomCode}_$timestamp.webm';
        final anchor = html.AnchorElement(href: videoUrl)
          ..setAttribute('download', videoFileName)
          ..click();
        anchor.remove();
        html.Url.revokeObjectUrl(videoUrl);
        _recordedChunks.clear();
        return videoFileName;
      } catch (_) {}
    }

    // 2. Baixa também o relatório/ata oficial da sessão gravada
    try {
      final reportContent = StringBuffer()
        ..writeln('=====================================================')
        ..writeln('ATA E REGISTRO DE GRAVAÇÃO — PORTAL AVA AGMRM')
        ..writeln('=====================================================')
        ..writeln('Sala: ${exportSummary.roomCode}')
        ..writeln('Início: ${exportSummary.startedAt.toIso8601String()}')
        ..writeln('Término: ${exportSummary.endedAt.toIso8601String()}')
        ..writeln('Duração Total: ${exportSummary.totalDuration.inSeconds}s')
        ..writeln(
          'Participantes Presentes (${exportSummary.totalParticipants}): ${exportSummary.attendeeNames.join(", ")}',
        )
        ..writeln('Mensagens no Chat: ${exportSummary.chatMessageCount}')
        ..writeln('Reações Registradas: ${exportSummary.reactionCount}')
        ..writeln('=====================================================');

      final reportBlob = html.Blob([reportContent.toString()], 'text/plain;charset=utf-8');
      final reportUrl = html.Url.createObjectUrlFromBlob(reportBlob);
      final reportFileName = 'ata_${exportSummary.roomCode}_$timestamp.txt';
      final anchor = html.AnchorElement(href: reportUrl)
        ..setAttribute('download', reportFileName)
        ..click();
      anchor.remove();
      html.Url.revokeObjectUrl(reportUrl);
      return reportFileName;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> copyToClipboard(String text) async {
    try {
      await html.window.navigator.clipboard?.writeText(text);
    } catch (_) {
      try {
        await Clipboard.setData(ClipboardData(text: text));
      } catch (_) {}
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _audioMeterTimer?.cancel();
    _audioMeterTimer = null;

    try {
      if (_audioContext != null) {
        js_util.callMethod<void>(_audioContext!, 'close', []);
      }
    } catch (_) {}
    _audioContext = null;
    _analyserNode = null;

    for (final peerId in _peerConnections.keys.toList()) {
      await disconnectPeer(peerId);
    }

    if (_screenStream != null) {
      for (final track in _screenStream!.getTracks()) {
        track.stop();
      }
      _screenStream = null;
    }

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
      _localStream = null;
    }

    for (final video in _videoElements.values) {
      video.srcObject = null;
    }
    _videoElements.clear();
    _registeredViewTypes.clear();

    await _audioLevelController.close();
    await _screenShareStoppedController.close();
    await _outboundWebRtcController.close();
    await _videoStreamUpdatedController.close();
  }
}
