// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:ui_web' as ui_web;
import 'dart:web_audio' as web_audio;
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

  html.MediaStream? _localStream;
  html.MediaStream? _screenStream;
  final Map<String, html.MediaStream> _remoteStreams = {};
  final Map<String, html.RtcPeerConnection> _peerConnections = {};
  final Map<String, html.VideoElement> _videoElements = {};
  final Map<String, String> _registeredViewTypes = {};

  web_audio.AudioContext? _audioContext;
  web_audio.AnalyserNode? _analyserNode;
  Timer? _audioMeterTimer;

  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _recordedChunks = [];
  Completer<void>? _recorderStopCompleter;

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
  bool get hasLocalMediaStream => _localStream != null;

  @override
  String? getVideoViewType(String streamKey) => _registeredViewTypes[streamKey];

  /// Registra um `<video>` HTML5 no `platformViewRegistry` para um `streamKey`
  /// (`'local'`, `'screen'` ou `remotePeerId`) e vincula o [stream].
  String _bindStreamToVideoView(
    String streamKey,
    html.MediaStream stream, {
    required bool muted,
    required bool mirror,
  }) {
    var element = _videoElements[streamKey];
    if (element == null) {
      element = html.VideoElement()
        ..autoplay = true
        ..muted = muted
        ..controls = false
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = streamKey == 'screen' ? 'contain' : 'cover'
        ..style.backgroundColor = '#09090B';

      element.setAttribute('playsinline', 'true');
      element.setAttribute('webkit-playsinline', 'true');
      if (mirror) {
        element.style.transform = 'scaleX(-1)';
      }

      _videoElements[streamKey] = element;
      final viewType = 'agmrm-video-$streamKey-${++_viewSequence}';
      _registeredViewTypes[streamKey] = viewType;

      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) => element!,
      );
    }

    element.muted = muted;
    element.srcObject = stream;
    element.play().catchError((_) {});

    if (!_videoStreamUpdatedController.isClosed) {
      _videoStreamUpdatedController.add(streamKey);
    }
    return _registeredViewTypes[streamKey]!;
  }

  @override
  Future<bool> initializeLocalMedia({
    bool audio = true,
    bool video = true,
  }) async {
    if (_isDisposed) return false;

    if (_localStream != null) {
      await setMicrophoneMuted(!audio);
      await setCameraOff(!video);
      return true;
    }

    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) return false;

    html.MediaStream? stream;
    try {
      stream = await mediaDevices.getUserMedia({
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
      // Fallback: tenta apenas áudio se a câmera não estiver disponível
      try {
        stream = await mediaDevices.getUserMedia({'audio': true, 'video': false});
      } catch (_) {
        // Fallback: tenta apenas vídeo se o microfone falhar
        try {
          stream = await mediaDevices.getUserMedia({'audio': false, 'video': true});
        } catch (_) {
          return false;
        }
      }
    }

    if (_isDisposed) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      return false;
    }

    _localStream = stream;
    _isAudioMuted = !audio;
    _isVideoOff = !video;

    for (final track in stream.getAudioTracks()) {
      track.enabled = audio;
    }
    for (final track in stream.getVideoTracks()) {
      track.enabled = video;
    }

    _bindStreamToVideoView(
      'local',
      stream,
      muted: true,
      mirror: true,
    );

    _startRealMicrophoneAnalyser(stream);
    return true;
  }

  /// Inicializa o `AudioContext` + `AnalyserNode` da Web Audio API para medir
  /// o volume RMS real captado pelo microfone físico a cada 100ms.
  void _startRealMicrophoneAnalyser(html.MediaStream stream) {
    _audioMeterTimer?.cancel();
    if (stream.getAudioTracks().isEmpty) return;

    try {
      final audioCtx = web_audio.AudioContext();
      final source = audioCtx.createMediaStreamSource(stream);
      final analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      analyser.smoothingTimeConstant = 0.5;
      source.connectNode(analyser);

      _audioContext = audioCtx;
      _analyserNode = analyser;

      final bufferLength = analyser.frequencyBinCount ?? 128;
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
            if (audioCtx.state == 'suspended') {
              audioCtx.resume();
            }

            _analyserNode!.getByteFrequencyData(dataArray);

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
      final displayStream = await mediaDevices.getDisplayMedia({
        'video': {'cursor': 'always'},
        'audio': true,
      });

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
          if (!_screenShareStoppedController.isClosed) {
            _screenShareStoppedController.add(null);
          }
        });
      }

      // Renegocia streams com os pares conectados para transmitir a tela
      for (final remotePeerId in _peerConnections.keys.toList()) {
        final pc = _peerConnections[remotePeerId];
        if (pc != null) {
          try {
            pc.addStream(displayStream);
            connectToPeer(remotePeerId, isInitiator: true);
          } catch (_) {}
        }
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
    if (_localStream != null) {
      for (final remotePeerId in _peerConnections.keys.toList()) {
        final pc = _peerConnections[remotePeerId];
        if (pc != null) {
          try {
            pc.addStream(_localStream!);
            connectToPeer(remotePeerId, isInitiator: true);
          } catch (_) {}
        }
      }
    }
    if (!_videoStreamUpdatedController.isClosed) {
      _videoStreamUpdatedController.add('screen');
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

    // Anexa stream local de áudio e vídeo
    final streamToSend = _screenStream ?? _localStream;
    if (streamToSend != null) {
      try {
        pc.addStream(streamToSend);
      } catch (_) {}
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

    // Escuta stream remoto recebido
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
        await pc.setLocalDescription({
          'type': offer.type,
          'sdp': offer.sdp,
        });
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

        await pc.setRemoteDescription({'sdp': sdp, 'type': type});
        final answer = await pc.createAnswer();
        await pc.setLocalDescription({
          'type': answer.type,
          'sdp': answer.sdp,
        });

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

        await pc.setRemoteDescription({'sdp': sdp, 'type': type});
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

    final remoteStream = _remoteStreams.remove(remotePeerId);
    if (remoteStream != null) {
      for (final track in remoteStream.getTracks()) {
        track.stop();
      }
    }

    final videoEl = _videoElements.remove(remotePeerId);
    if (videoEl != null) {
      videoEl.pause();
      videoEl.srcObject = null;
    }
    _registeredViewTypes.remove(remotePeerId);
  }

  @override
  Future<bool> startMediaRecording() async {
    _recordedChunks.clear();
    final streamToRecord = _screenStream ?? _localStream;
    if (streamToRecord == null) return false;

    try {
      String mimeType = 'video/webm;codecs=vp8,opus';
      if (!html.MediaRecorder.isTypeSupported(mimeType)) {
        mimeType = 'video/webm';
      }

      final recorder = html.MediaRecorder.isTypeSupported(mimeType)
          ? html.MediaRecorder(streamToRecord, {'mimeType': mimeType})
          : html.MediaRecorder(streamToRecord);

      recorder.addEventListener('dataavailable', (html.Event event) {
        final blobEvent = event as html.BlobEvent;
        final data = blobEvent.data;
        if (data != null && data.size > 0) {
          _recordedChunks.add(data);
        }
      });

      recorder.addEventListener('stop', (html.Event _) {
        if (_recorderStopCompleter != null &&
            !_recorderStopCompleter!.isCompleted) {
          _recorderStopCompleter!.complete();
        }
      });

      _mediaRecorder = recorder;
      recorder.start(1000);
      return true;
    } catch (_) {
      _mediaRecorder = null;
      return false;
    }
  }

  @override
  Future<String?> stopMediaRecordingAndDownload({
    required String roomCode,
    required SessionExport sessionReport,
  }) async {
    final sanitizedCode =
        roomCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').toUpperCase();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;

    try {
      if (_mediaRecorder != null && _mediaRecorder!.state != 'inactive') {
        _recorderStopCompleter = Completer<void>();
        _mediaRecorder!.stop();
        await _recorderStopCompleter!.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      }
    } catch (_) {}
    _mediaRecorder = null;

    if (_recordedChunks.isNotEmpty) {
      try {
        final videoBlob = html.Blob(_recordedChunks, 'video/webm');
        final fileName = 'gravacao_${sanitizedCode}_$timestamp.webm';
        _triggerBrowserDownload(videoBlob, fileName);
        _recordedChunks.clear();
        return fileName;
      } catch (_) {}
    }

    // Fallback ou complemento: baixa o relatório consolidado (.txt) da sessão
    try {
      final reportText = sessionReport.toFormattedReport();
      final textBlob = html.Blob([reportText], 'text/plain;charset=utf-8');
      final fileName = 'relatorio_reuniao_${sanitizedCode}_$timestamp.txt';
      _triggerBrowserDownload(textBlob, fileName);
      return fileName;
    } catch (_) {
      return null;
    }
  }

  void _triggerBrowserDownload(html.Blob blob, String fileName) {
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    Timer(const Duration(seconds: 3), () {
      html.Url.revokeObjectUrl(url);
    });
  }

  @override
  Future<bool> copyTextToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      try {
        await html.window.navigator.clipboard?.writeText(text);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _audioMeterTimer?.cancel();
    _audioMeterTimer = null;

    try {
      if (_mediaRecorder != null && _mediaRecorder!.state != 'inactive') {
        _mediaRecorder!.stop();
      }
    } catch (_) {}
    _mediaRecorder = null;
    _recordedChunks.clear();

    for (final peerId in _peerConnections.keys.toList()) {
      await disconnectPeer(peerId);
    }
    _peerConnections.clear();

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

    for (final videoEl in _videoElements.values) {
      videoEl.pause();
      videoEl.srcObject = null;
    }
    _videoElements.clear();
    _registeredViewTypes.clear();

    try {
      await _audioContext?.close();
    } catch (_) {}
    _audioContext = null;
    _analyserNode = null;

    await _audioLevelController.close();
    await _screenShareStoppedController.close();
    await _outboundWebRtcController.close();
    await _videoStreamUpdatedController.close();
  }
}
