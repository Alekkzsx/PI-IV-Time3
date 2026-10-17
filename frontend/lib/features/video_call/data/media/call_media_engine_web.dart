// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:math' as math;
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
/// - Web Audio API (`AudioContext` + `AnalyserNode`) para leitura em tempo real da voz no microfone.
/// - `navigator.mediaDevices.getDisplayMedia` via ponte JS nativa para compartilhamento de tela real.
/// - `RTCPeerConnection` para streaming P2P de vídeo e áudio entre abas/usuários reais.
/// - `MediaRecorder` + download automático de `.webm` e ata `.txt` da sessão.
class WebCallMediaEngine implements ICallMediaEngine {
  static int _viewSequence = 0;
  static bool _bridgeInitialized = false;

  final StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();
  final StreamController<void> _screenShareStoppedController =
      StreamController<void>.broadcast();
  final StreamController<Map<String, dynamic>> _outboundWebRtcController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _videoStreamUpdatedController =
      StreamController<String>.broadcast();

  html.MediaStream? _localStream;
  Object? _screenStreamObj;
  final Map<String, html.MediaStream> _remoteStreams = {};
  final Map<String, html.RtcPeerConnection> _peerConnections = {};
  final Map<String, List<html.VideoElement>> _videoElementsByKey = {};
  final Map<String, String> _registeredViewTypes = {};

  js.JsObject? _audioContext;
  js.JsObject? _analyserNode;
  Timer? _audioMeterTimer;
  Timer? _videoPlaybackWatchdog;

  html.MediaRecorder? _mediaRecorder;
  final List<html.Blob> _recordedChunks = [];
  Completer<void>? _recorderStopCompleter;

  bool _isAudioMuted = false;
  bool _isVideoOff = false;
  bool _isDisposed = false;

  WebCallMediaEngine() {
    _ensureJsBridge();
    _startVideoPlaybackWatchdog();
  }

  /// Inicializa uma ponte JavaScript nativa em `window.__agmrmMediaBridge`
  /// para garantir reprodução contínua de `<video>` (sem congelar ao trocar de rota)
  /// e suporte direto a `navigator.mediaDevices.getDisplayMedia`.
  static void _ensureJsBridge() {
    if (_bridgeInitialized) return;
    _bridgeInitialized = true;
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          if (window.__agmrmMediaBridge) return;
          window.__agmrmMediaBridge = {
            streams: {},
            setStream: function(key, stream) {
              this.streams[key] = stream;
            },
            getStream: function(key) {
              return this.streams[key] || null;
            },
            clearStream: function(key) {
              var s = this.streams[key];
              if (s && s.getTracks) {
                try {
                  s.getTracks().forEach(function(t) { t.stop(); });
                } catch (e) {}
              }
              delete this.streams[key];
            },
            attachStreamToElement: function(videoEl, key, muted) {
              var self = this;
              if (!videoEl) return;
              videoEl.muted = !!muted;
              videoEl.defaultMuted = !!muted;
              videoEl.autoplay = true;
              videoEl.playsInline = true;

              var ensurePlaying = function() {
                var s = self.streams[key];
                if (!s) return;
                if (videoEl.srcObject !== s) {
                  videoEl.srcObject = s;
                }
                videoEl.muted = !!muted;
                if (videoEl.paused) {
                  var p = videoEl.play();
                  if (p && p.catch) {
                    p.catch(function() {});
                  }
                }
              };

              videoEl.addEventListener('loadedmetadata', ensurePlaying);
              videoEl.addEventListener('loadeddata', ensurePlaying);
              videoEl.addEventListener('canplay', ensurePlaying);
              videoEl.addEventListener('pause', function() {
                setTimeout(ensurePlaying, 60);
              });

              ensurePlaying();
              setTimeout(ensurePlaying, 50);
              setTimeout(ensurePlaying, 200);
              setTimeout(ensurePlaying, 500);
            },
            resumeAllForKey: function(key, muted) {
              var s = this.streams[key];
              if (!s) return;
              var videos = document.querySelectorAll('video[data-agmrm-key="' + key + '"]');
              for (var i = 0; i < videos.length; i++) {
                var v = videos[i];
                if (v.srcObject !== s) {
                  v.srcObject = s;
                }
                v.muted = !!muted;
                if (v.paused) {
                  var p = v.play();
                  if (p && p.catch) p.catch(function() {});
                }
              }
            },
            startDisplayMedia: function(onSuccess, onError, onEnded) {
              var self = this;
              if (!navigator.mediaDevices || !navigator.mediaDevices.getDisplayMedia) {
                onError('getDisplayMedia not supported');
                return;
              }
              navigator.mediaDevices.getDisplayMedia({
                video: { cursor: 'always' },
                audio: false
              }).then(function(stream) {
                self.streams['screen'] = stream;
                var tracks = stream.getVideoTracks();
                if (tracks && tracks.length > 0) {
                  tracks[0].addEventListener('ended', function() {
                    delete self.streams['screen'];
                    onEnded();
                  });
                }
                onSuccess(stream);
              }).catch(function(err) {
                onError(String(err));
              });
            }
          };
        })();
        '''
      ]);
    } catch (_) {}
  }

  js.JsObject? get _bridge {
    try {
      return js.context['__agmrmMediaBridge'] as js.JsObject?;
    } catch (_) {
      return null;
    }
  }

  /// Watchdog leve (a cada 600ms) que garante que nenhum `<video>` ativo fique pausado
  /// como imagem estática após transições de rota ou redimensionamentos do DOM.
  void _startVideoPlaybackWatchdog() {
    _videoPlaybackWatchdog?.cancel();
    _videoPlaybackWatchdog = Timer.periodic(
      const Duration(milliseconds: 600),
      (_) {
        if (_isDisposed) return;
        final bridge = _bridge;
        if (_localStream != null && !_isVideoOff) {
          bridge?.callMethod('resumeAllForKey', ['local', true]);
          for (final el in _videoElementsByKey['local'] ?? const []) {
            if (el.paused) {
              el.muted = true;
              el.play().catchError((_) {});
            }
          }
        }
        if (_screenStreamObj != null) {
          bridge?.callMethod('resumeAllForKey', ['screen', true]);
          for (final el in _videoElementsByKey['screen'] ?? const []) {
            if (el.paused) {
              el.muted = true;
              el.play().catchError((_) {});
            }
          }
        }
        for (final peerId in _remoteStreams.keys) {
          bridge?.callMethod('resumeAllForKey', [peerId, false]);
          for (final el in _videoElementsByKey[peerId] ?? const []) {
            if (el.paused) {
              el.play().catchError((_) {});
            }
          }
        }
      },
    );
  }

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
  bool get isInitialized => _localStream != null;

  @override
  String? getVideoViewType(String streamKey) => _registeredViewTypes[streamKey];

  /// Registra uma factory no `platformViewRegistry` que cria um `<video>` HTML5
  /// dedicado para cada montagem de `HtmlElementView` (evitando conflito entre Lobby e Sala).
  String _registerStreamViewFactory(
    String streamKey,
    Object stream, {
    required bool muted,
    required bool mirror,
    bool forceNewViewType = false,
  }) {
    _bridge?.callMethod('setStream', [streamKey, stream]);

    if (forceNewViewType || !_registeredViewTypes.containsKey(streamKey)) {
      final viewType = 'agmrm-video-$streamKey-${++_viewSequence}';
      _registeredViewTypes[streamKey] = viewType;

      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          final element = html.VideoElement()
            ..autoplay = true
            ..muted = muted
            ..defaultMuted = muted
            ..controls = false
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = streamKey == 'screen' ? 'contain' : 'cover'
            ..style.backgroundColor = '#09090B'
            ..style.pointerEvents = 'none';

          element.setAttribute('playsinline', 'true');
          element.setAttribute('webkit-playsinline', 'true');
          element.setAttribute('data-agmrm-key', streamKey);
          if (mirror) {
            element.style.transform = 'scaleX(-1)';
          }

          _videoElementsByKey.putIfAbsent(streamKey, () => []).add(element);

          final currentStream =
              streamKey == 'local' ? (_localStream ?? stream) : stream;
          if (currentStream is html.MediaStream) {
            element.srcObject = currentStream;
          }
          _bridge?.callMethod(
            'attachStreamToElement',
            [element, streamKey, muted],
          );
          element.play().catchError((_) {});

          return element;
        },
      );
    } else {
      // Atualiza elementos existentes caso a mesma viewType continue montada
      for (final element in _videoElementsByKey[streamKey] ?? const []) {
        if (stream is html.MediaStream) {
          element.srcObject = stream;
        }
        _bridge?.callMethod(
          'attachStreamToElement',
          [element, streamKey, muted],
        );
        element.play().catchError((_) {});
      }
    }

    if (!_videoStreamUpdatedController.isClosed) {
      _videoStreamUpdatedController.add(streamKey);
    }
    return _registeredViewTypes[streamKey]!;
  }

  @override
  Future<bool> initializeLocalMedia({
    bool audioMuted = false,
    bool videoOff = false,
  }) async {
    if (_isDisposed) return false;

    if (_localStream != null) {
      await setMicrophoneMuted(audioMuted);
      await setCameraOff(videoOff);
      _bridge?.callMethod('setStream', ['local', _localStream]);
      _bridge?.callMethod('resumeAllForKey', ['local', true]);
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
      try {
        stream =
            await mediaDevices.getUserMedia({'audio': true, 'video': false});
      } catch (_) {
        try {
          stream =
              await mediaDevices.getUserMedia({'audio': false, 'video': true});
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
    _isAudioMuted = audioMuted;
    _isVideoOff = videoOff;

    for (final track in stream.getAudioTracks()) {
      track.enabled = !audioMuted;
    }
    for (final track in stream.getVideoTracks()) {
      track.enabled = !videoOff;
    }

    _registerStreamViewFactory(
      'local',
      stream,
      muted: true,
      mirror: true,
    );

    _startRealMicrophoneAnalyser(stream);
    return true;
  }

  /// Inicializa o `AudioContext` + `AnalyserNode` da Web Audio API via JS interop
  /// para medir o volume RMS real captado pelo microfone físico a cada 100ms.
  void _startRealMicrophoneAnalyser(html.MediaStream stream) {
    _audioMeterTimer?.cancel();
    if (stream.getAudioTracks().isEmpty) return;

    try {
      final audioCtxClass =
          (js.context['AudioContext'] ?? js.context['webkitAudioContext'])
              as js.JsFunction?;
      if (audioCtxClass == null) return;

      final audioCtx = js.JsObject(audioCtxClass);
      final source =
          audioCtx.callMethod('createMediaStreamSource', [stream]) as js.JsObject;
      final analyser =
          audioCtx.callMethod('createAnalyser', []) as js.JsObject;
      analyser['fftSize'] = 256;
      analyser['smoothingTimeConstant'] = 0.5;
      source.callMethod('connect', [analyser]);

      _audioContext = audioCtx;
      _analyserNode = analyser;

      final bufferLength = (analyser['frequencyBinCount'] as int?) ?? 128;
      final uint8ArrayCtor = js.context['Uint8Array'] as js.JsFunction;
      final jsDataArray = js.JsObject(uint8ArrayCtor, [bufferLength]);

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
            if (audioCtx['state'] == 'suspended') {
              audioCtx.callMethod('resume', []);
            }

            _analyserNode!.callMethod('getByteFrequencyData', [jsDataArray]);

            double sumSquares = 0.0;
            for (var i = 0; i < bufferLength; i++) {
              final val = (jsDataArray[i] as num?)?.toDouble() ?? 0.0;
              final normalized = val / 255.0;
              sumSquares += normalized * normalized;
            }
            final rms = math.sqrt(sumSquares / bufferLength);
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
        _bridge?.callMethod('resumeAllForKey', ['local', true]);
        for (final el in _videoElementsByKey['local'] ?? const []) {
          el.play().catchError((_) {});
        }
      }
    }
    if (!_videoStreamUpdatedController.isClosed) {
      _videoStreamUpdatedController.add('local');
    }
  }

  @override
  Future<bool> startScreenShare() async {
    if (_isDisposed) return false;
    _ensureJsBridge();
    final bridge = _bridge;
    if (bridge == null) return false;

    final completer = Completer<bool>();

    try {
      bridge.callMethod('startDisplayMedia', [
        // onSuccess(stream)
        (dynamic rawStream) {
          if (_isDisposed) {
            bridge.callMethod('clearStream', ['screen']);
            if (!completer.isCompleted) completer.complete(false);
            return;
          }

          _screenStreamObj = rawStream as Object?;
          _registerStreamViewFactory(
            'screen',
            rawStream as Object,
            muted: true,
            mirror: false,
            forceNewViewType: true,
          );

          if (rawStream is html.MediaStream) {
            for (final remotePeerId in _peerConnections.keys.toList()) {
              final pc = _peerConnections[remotePeerId];
              if (pc != null) {
                try {
                  pc.addStream(rawStream);
                  connectToPeer(remotePeerId, isInitiator: true);
                } catch (_) {}
              }
            }
          }

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        // onError(err)
        (dynamic _) {
          _screenStreamObj = null;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
        // onEnded() — disparado quando o usuário clica em "Parar compartilhamento" na barra do navegador
        () {
          _screenStreamObj = null;
          _videoElementsByKey.remove('screen');
          _registeredViewTypes.remove('screen');
          if (!_screenShareStoppedController.isClosed) {
            _screenShareStoppedController.add(null);
          }
        },
      ]);
    } catch (_) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  @override
  Future<void> stopScreenShare() async {
    _screenStreamObj = null;
    _bridge?.callMethod('clearStream', ['screen']);
    final elements = _videoElementsByKey.remove('screen') ?? const [];
    for (final el in elements) {
      el.pause();
      el.srcObject = null;
    }
    _registeredViewTypes.remove('screen');

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

    final streamToSend = (_screenStreamObj is html.MediaStream)
        ? (_screenStreamObj as html.MediaStream)
        : _localStream;
    if (streamToSend != null) {
      try {
        pc.addStream(streamToSend);
      } catch (_) {}
    }

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

    pc.onAddStream.listen((html.MediaStreamEvent event) {
      final remoteStream = event.stream;
      if (remoteStream != null) {
        _remoteStreams[remotePeerId] = remoteStream;
        _registerStreamViewFactory(
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
    _bridge?.callMethod('clearStream', [remotePeerId]);

    final videoEls = _videoElementsByKey.remove(remotePeerId) ?? const [];
    for (final videoEl in videoEls) {
      videoEl.pause();
      videoEl.srcObject = null;
    }
    _registeredViewTypes.remove(remotePeerId);
  }

  @override
  Future<void> startRecording() async {
    _recordedChunks.clear();
    final streamToRecord = (_screenStreamObj is html.MediaStream)
        ? (_screenStreamObj as html.MediaStream)
        : _localStream;
    if (streamToRecord == null) return;

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
    } catch (_) {
      _mediaRecorder = null;
    }
  }

  @override
  Future<String?> stopRecordingAndDownload(SessionExport exportSummary) async {
    final sanitizedCode = exportSummary.roomCode
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .toUpperCase();
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

    try {
      final reportText = _formatSessionReport(exportSummary);
      final textBlob = html.Blob([reportText], 'text/plain;charset=utf-8');
      final fileName = 'relatorio_reuniao_${sanitizedCode}_$timestamp.txt';
      _triggerBrowserDownload(textBlob, fileName);
      return fileName;
    } catch (_) {
      return null;
    }
  }

  String _formatSessionReport(SessionExport s) {
    final buffer = StringBuffer()
      ..writeln('====================================================')
      ..writeln('ATA DE SESSÃO DE VIDEOCONFERÊNCIA ACADÊMICA (AGMRM)')
      ..writeln('====================================================')
      ..writeln('Sala: ${s.roomCode}')
      ..writeln('Início: ${s.startedAt.toIso8601String()}')
      ..writeln('Término: ${s.endedAt.toIso8601String()}')
      ..writeln('Duração Total: ${s.totalDuration.inSeconds} segundos')
      ..writeln('Total de Participantes Reais: ${s.totalParticipants}')
      ..writeln('Participantes: ${s.attendeeNames.join(", ")}')
      ..writeln('Mensagens no Chat: ${s.chatMessageCount}')
      ..writeln('Reações Enviadas: ${s.reactionCount}')
      ..writeln('====================================================');
    return buffer.toString();
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
  Future<void> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      try {
        await html.window.navigator.clipboard?.writeText(text);
      } catch (_) {}
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _audioMeterTimer?.cancel();
    _audioMeterTimer = null;
    _videoPlaybackWatchdog?.cancel();
    _videoPlaybackWatchdog = null;

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

    _screenStreamObj = null;
    _bridge?.callMethod('clearStream', ['screen']);

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
      _localStream = null;
    }
    _bridge?.callMethod('clearStream', ['local']);

    for (final list in _videoElementsByKey.values) {
      for (final videoEl in list) {
        videoEl.pause();
        videoEl.srcObject = null;
      }
    }
    _videoElementsByKey.clear();
    _registeredViewTypes.clear();

    try {
      _audioContext?.callMethod('close', []);
    } catch (_) {}
    _audioContext = null;
    _analyserNode = null;

    await _audioLevelController.close();
    await _screenShareStoppedController.close();
    await _outboundWebRtcController.close();
    await _videoStreamUpdatedController.close();
  }
}
