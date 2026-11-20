// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/services.dart';
import '../../domain/entities/session_export.dart';
import 'call_media_engine.dart';

/// Cria a instância de [ICallMediaEngine] conectada às APIs reais do navegador Web.
ICallMediaEngine createCallMediaEngine() => WebCallMediaEngine();

/// Motor de mídia e WebRTC real para navegador Web.
///
/// Executa toda a manipulação de `MediaStream`, `HTMLVideoElement.srcObject`,
/// `AudioContext` + `AnalyserNode`, `getDisplayMedia`, `RTCPeerConnection` e
/// `MediaRecorder` diretamente na ponte nativa JavaScript (`window.__agmrmMediaBridge`),
/// eliminando falhas de empacotamento `DartObject` entre `dart:html` e `dart:js`.
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
  final StreamController<String> _mediaStatusController =
      StreamController<String>.broadcast();

  final Map<String, String> _registeredViewTypes = {};
  Timer? _videoPlaybackWatchdog;

  bool _isInitialized = false;
  bool _isDisposed = false;
  Future<bool>? _initFuture;

  WebCallMediaEngine() {
    _ensureJsBridge();
    _bindBridgeCallbacks();
    _startVideoPlaybackWatchdog();
  }

  /// Inicializa a ponte JavaScript nativa `window.__agmrmMediaBridge` no navegador.
  static void _ensureJsBridge() {
    if (_bridgeInitialized) return;
    _bridgeInitialized = true;
    try {
      js.context.callMethod('eval', [_bridgeScriptSource]);
    } catch (_) {}
    try {
      if (js.context['__agmrmMediaBridge'] == null) {
        final script = html.ScriptElement()
          ..type = 'text/javascript'
          ..text = _bridgeScriptSource;
        (html.document.head ?? html.document.body)?.append(script);
      }
    } catch (_) {}
  }

  static const String _bridgeScriptSource = r'''
        (function() {
          if (window.__agmrmMediaBridge) return;

          function unwrap(obj) {
            if (!obj) return obj;
            if (obj.o && typeof obj.o === 'object') return obj.o;
            return obj;
          }

          window.__agmrmMediaBridge = {
            streams: {},
            peers: {},
            remoteAudioSources: {},
            remoteAudioElements: {},
            pendingIceCandidates: {},
            audioCtx: null,
            playbackAudioCtx: null,
            analyser: null,
            audioTimer: null,
            audioMuted: false,
            videoOff: false,
            mediaRecorder: null,
            recordedChunks: [],
            onAudioLevelCb: null,
            onMediaStatusCb: null,
            onRemoteStreamCb: null,
            onOutboundSignalCb: null,

            findVideosByKey: function(key) {
              var result = [];
              function scan(root) {
                if (!root || !root.querySelectorAll) return;
                var selector = key
                  ? 'video[data-agmrm-key="' + key + '"]'
                  : 'video[data-agmrm-key]';
                var matches = root.querySelectorAll(selector);
                for (var i = 0; i < matches.length; i++) {
                  result.push(matches[i]);
                }
                var all = root.querySelectorAll('*');
                for (var j = 0; j < all.length; j++) {
                  if (all[j].shadowRoot) {
                    scan(all[j].shadowRoot);
                  }
                }
              }
              scan(document);
              return result;
            },

            reportMediaStatus: function(message) {
              if (this.onMediaStatusCb && message) {
                this.onMediaStatusCb(String(message));
              }
            },

            unlockAudioPlayback: function() {
              var self = this;
              var AudioCtx = window.AudioContext || window.webkitAudioContext;
              if (AudioCtx) {
                try {
                  if (!this.playbackAudioCtx || this.playbackAudioCtx.state === 'closed') {
                    this.playbackAudioCtx = new AudioCtx();
                  }
                  if (this.playbackAudioCtx.state === 'suspended') {
                    this.playbackAudioCtx.resume().catch(function() {
                      self.reportMediaStatus('O navegador bloqueou a reprodução de áudio. Toque novamente na tela e confira as permissões de som.');
                    });
                  }
                } catch (e) {
                  this.reportMediaStatus('O navegador bloqueou a reprodução de áudio. Toque novamente na tela e confira as permissões de som.');
                }
              }
              this.resumeAllStreams();
            },

            attachRemoteAudio: function(peerId, track) {
              var self = this;
              if (!track || track.kind !== 'audio') return;
              var AudioCtx = window.AudioContext || window.webkitAudioContext;
              if (AudioCtx) {
                try {
                  if (!self.playbackAudioCtx || self.playbackAudioCtx.state === 'closed') {
                    self.playbackAudioCtx = new AudioCtx();
                  }
                  var audioStream = new MediaStream([track]);
                  var source = self.playbackAudioCtx.createMediaStreamSource(audioStream);
                  source.connect(self.playbackAudioCtx.destination);
                  var key = peerId + ':' + track.id;
                  self.remoteAudioSources[key] = source;
                  if (self.playbackAudioCtx.state === 'suspended') {
                    self.playbackAudioCtx.resume().catch(function() {
                      self.reportMediaStatus('O navegador bloqueou o áudio recebido. Toque na tela para liberar o som.');
                    });
                  }
                  return;
                } catch (e) {
                  self.reportMediaStatus('Não foi possível iniciar o áudio recebido neste navegador.');
                }
              }

              try {
                var audio = document.createElement('audio');
                audio.autoplay = true;
                audio.playsInline = true;
                audio.setAttribute('playsinline', 'true');
                audio.srcObject = new MediaStream([track]);
                audio.style.display = 'none';
                document.body.appendChild(audio);
                self.remoteAudioElements[peerId] = audio;
                var playPromise = audio.play();
                if (playPromise && playPromise.catch) {
                  playPromise.catch(function() {
                    self.reportMediaStatus('O navegador bloqueou o áudio recebido. Interaja com a página para liberar a reprodução.');
                  });
                }
              } catch (e) {
                self.reportMediaStatus('Este navegador não conseguiu reproduzir o áudio recebido.');
              }
            },

            clearRemoteAudio: function(peerId) {
              var self = this;
              Object.keys(self.remoteAudioSources).forEach(function(key) {
                if (key.indexOf(peerId + ':') === 0) {
                  try { self.remoteAudioSources[key].disconnect(); } catch (e) {}
                  delete self.remoteAudioSources[key];
                }
              });
              var audio = self.remoteAudioElements[peerId];
              if (audio) {
                try {
                  audio.pause();
                  audio.srcObject = null;
                  audio.remove();
                } catch (e) {}
                delete self.remoteAudioElements[peerId];
              }
            },

            attachStreamToElement: function(rawVideoEl, key, muted) {
              var self = this;
              var videoEl = unwrap(rawVideoEl);
              if (!videoEl) return;

              try {
                videoEl.muted = !!muted;
                videoEl.defaultMuted = !!muted;
                videoEl.autoplay = true;
                videoEl.playsInline = true;
                videoEl.setAttribute('playsinline', 'true');
                videoEl.setAttribute('webkit-playsinline', 'true');
                if (muted) {
                  videoEl.setAttribute('muted', 'true');
                }
              } catch (e) {}

              var ensurePlaying = function() {
                try {
                  var s = unwrap(self.streams[key]);
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
                } catch (e) {}
              };

              videoEl.addEventListener('loadedmetadata', ensurePlaying);
              videoEl.addEventListener('loadeddata', ensurePlaying);
              videoEl.addEventListener('canplay', ensurePlaying);
              videoEl.addEventListener('pause', function() {
                setTimeout(ensurePlaying, 80);
              });

              ensurePlaying();
              setTimeout(ensurePlaying, 50);
              setTimeout(ensurePlaying, 200);
              setTimeout(ensurePlaying, 500);
            },

            resumeAllForKey: function(key, muted) {
              var s = unwrap(this.streams[key]);
              if (!s) return;
              var videos = this.findVideosByKey(key);
              for (var i = 0; i < videos.length; i++) {
                var v = videos[i];
                try {
                  if (v.srcObject !== s) {
                    v.srcObject = s;
                  }
                  v.muted = !!muted;
                  if (v.paused) {
                    var p = v.play();
                    if (p && p.catch) p.catch(function() {});
                  }
                } catch (e) {}
              }
            },

            resumeAllStreams: function() {
              var keys = Object.keys(this.streams);
              for (var i = 0; i < keys.length; i++) {
                var k = keys[i];
                this.resumeAllForKey(k, true);
              }
            },

            startLocalMedia: function(audioMuted, videoOff, onSuccess, onError) {
              var self = this;
              self.audioMuted = !!audioMuted;
              self.videoOff = !!videoOff;

              if (!window.isSecureContext) {
                onError('A câmera e o microfone exigem HTTPS ou localhost neste navegador.');
                return;
              }

              var existing = unwrap(self.streams['local']);
              if (existing && existing.getTracks && existing.getTracks().some(function(t) { return t.readyState === 'live'; })) {
                self.setMicMuted(self.audioMuted);
                self.setCamOff(self.videoOff);
                self.resumeAllForKey('local', true);
                onSuccess(true);
                return;
              }

              if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                onError('Este navegador não oferece suporte à captura de câmera e microfone.');
                return;
              }

              var applyStream = function(stream) {
                self.streams['local'] = stream;
                self.setMicMuted(self.audioMuted);
                self.setCamOff(self.videoOff);
                self.startAudioAnalyser(stream);
                self.resumeAllForKey('local', true);
                var hasAudio = stream.getAudioTracks && stream.getAudioTracks().length > 0;
                var hasVideo = stream.getVideoTracks && stream.getVideoTracks().length > 0;
                if (!hasAudio || !hasVideo) {
                  var unavailable = [];
                  if (!hasAudio) unavailable.push('microfone');
                  if (!hasVideo) unavailable.push('câmera');
                  self.reportMediaStatus('A captura foi iniciada sem ' + unavailable.join(' e ') + '. Verifique as permissões e os dispositivos disponíveis.');
                }
                onSuccess(true);
              };

              var captureAttempts = [
                {
                  audio: {
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true
                  },
                  video: {
                    width: { ideal: 1280 },
                    height: { ideal: 720 },
                    facingMode: 'user'
                  }
                },
                { audio: true, video: true },
                { audio: true, video: false },
                { audio: false, video: true }
              ];
              var attemptCapture = function(index, lastError) {
                if (index >= captureAttempts.length) {
                  onError(self.describeMediaError(lastError));
                  return;
                }
                navigator.mediaDevices.getUserMedia(captureAttempts[index])
                  .then(applyStream)
                  .catch(function(error) {
                    if (error && (
                      error.name === 'NotAllowedError' ||
                      error.name === 'PermissionDeniedError' ||
                      error.name === 'SecurityError'
                    )) {
                      onError(self.describeMediaError(error));
                      return;
                    }
                    attemptCapture(index + 1, error);
                  });
              };
              attemptCapture(0, null);
            },

            describeMediaError: function(error) {
              var name = error && error.name ? error.name : '';
              if (name === 'NotAllowedError' || name === 'PermissionDeniedError') {
                return 'A permissão para câmera ou microfone foi negada. Libere o acesso nas configurações do navegador e tente novamente.';
              }
              if (name === 'NotFoundError' || name === 'DevicesNotFoundError') {
                return 'Nenhuma câmera ou entrada de microfone compatível foi encontrada.';
              }
              if (name === 'NotReadableError' || name === 'TrackStartError') {
                return 'A câmera ou o microfone está sendo usado por outro aplicativo ou não pode ser iniciado.';
              }
              if (name === 'OverconstrainedError' || name === 'ConstraintNotSatisfiedError') {
                return 'O navegador não conseguiu atender às configurações de câmera solicitadas.';
              }
              return error && error.message ? error.message : 'Falha ao acessar câmera e microfone.';
            },

            startAudioAnalyser: function(rawStream) {
              var self = this;
              var stream = unwrap(rawStream);
              if (!stream || !stream.getAudioTracks || stream.getAudioTracks().length === 0) {
                return;
              }

              try {
                if (self.audioTimer) {
                  clearInterval(self.audioTimer);
                  self.audioTimer = null;
                }
                if (self.audioCtx && self.audioCtx.close) {
                  try { self.audioCtx.close(); } catch (e) {}
                }

                var AudioCtx = window.AudioContext || window.webkitAudioContext;
                if (!AudioCtx) return;

                var ctx = new AudioCtx();
                var source = ctx.createMediaStreamSource(stream);
                var analyser = ctx.createAnalyser();
                analyser.fftSize = 256;
                analyser.smoothingTimeConstant = 0.4;
                source.connect(analyser);

                self.audioCtx = ctx;
                self.analyser = analyser;

                var resumeCtx = function() {
                  if (self.audioCtx && self.audioCtx.state === 'suspended') {
                    self.audioCtx.resume().catch(function() {});
                  }
                };
                window.addEventListener('click', resumeCtx, { passive: true });
                window.addEventListener('keydown', resumeCtx, { passive: true });
                window.addEventListener('pointerdown', resumeCtx, { passive: true });
                resumeCtx();

                var freqData = new Uint8Array(analyser.frequencyBinCount);
                var timeData = new Uint8Array(analyser.fftSize);

                self.audioTimer = setInterval(function() {
                  if (self.audioMuted || !self.analyser) {
                    if (self.onAudioLevelCb) self.onAudioLevelCb(0.0);
                    return;
                  }
                  try {
                    if (self.audioCtx && self.audioCtx.state === 'suspended') {
                      self.audioCtx.resume().catch(function() {});
                    }
                    self.analyser.getByteFrequencyData(freqData);
                    self.analyser.getByteTimeDomainData(timeData);

                    var sumFreq = 0;
                    for (var i = 0; i < freqData.length; i++) {
                      var nf = freqData[i] / 255.0;
                      sumFreq += nf * nf;
                    }
                    var rmsFreq = Math.sqrt(sumFreq / freqData.length);

                    var sumTime = 0;
                    for (var j = 0; j < timeData.length; j++) {
                      var nt = (timeData[j] - 128.0) / 128.0;
                      sumTime += nt * nt;
                    }
                    var rmsTime = Math.sqrt(sumTime / timeData.length);

                    var combined = Math.max(rmsFreq * 2.4, rmsTime * 4.0);
                    var clamped = Math.min(1.0, Math.max(0.0, combined));
                    if (self.onAudioLevelCb) {
                      self.onAudioLevelCb(clamped);
                    }
                  } catch (e) {}
                }, 100);
              } catch (e) {}
            },

            setMicMuted: function(muted) {
              this.audioMuted = !!muted;
              var s = unwrap(this.streams['local']);
              if (s && s.getAudioTracks) {
                s.getAudioTracks().forEach(function(t) {
                  t.enabled = !muted;
                });
              }
              if (muted && this.onAudioLevelCb) {
                this.onAudioLevelCb(0.0);
              }
            },

            setCamOff: function(videoOff) {
              this.videoOff = !!videoOff;
              var s = unwrap(this.streams['local']);
              if (s && s.getVideoTracks) {
                s.getVideoTracks().forEach(function(t) {
                  t.enabled = !videoOff;
                });
              }
              if (!videoOff) {
                this.resumeAllForKey('local', true);
              }
            },

            replaceOutgoingVideoTrack: function(newVideoTrack) {
              var peerIds = Object.keys(this.peers);
              for (var i = 0; i < peerIds.length; i++) {
                var pc = this.peers[peerIds[i]];
                if (pc && pc.getSenders) {
                  var senders = pc.getSenders();
                  for (var j = 0; j < senders.length; j++) {
                    var sender = senders[j];
                    if (sender.track && sender.track.kind === 'video' && newVideoTrack) {
                      try { sender.replaceTrack(newVideoTrack); } catch (e) {}
                    }
                  }
                }
              }
            },

            startDisplayMedia: function(onSuccess, onError, onEnded) {
              var self = this;
              if (!navigator.mediaDevices || !navigator.mediaDevices.getDisplayMedia) {
                onError('getDisplayMedia nao suportado');
                return;
              }
              navigator.mediaDevices.getDisplayMedia({
                video: { cursor: 'always' },
                audio: false
              }).then(function(stream) {
                self.streams['screen'] = stream;
                var videoTracks = stream.getVideoTracks();
                if (videoTracks && videoTracks.length > 0) {
                  self.replaceOutgoingVideoTrack(videoTracks[0]);
                  videoTracks[0].addEventListener('ended', function() {
                    delete self.streams['screen'];
                    var localS = unwrap(self.streams['local']);
                    if (localS && localS.getVideoTracks && localS.getVideoTracks().length > 0) {
                      self.replaceOutgoingVideoTrack(localS.getVideoTracks()[0]);
                    }
                    onEnded();
                  });
                }
                self.resumeAllForKey('screen', true);
                onSuccess();
              }).catch(function(err) {
                onError(String(err));
              });
            },

            stopDisplayMedia: function() {
              var s = unwrap(this.streams['screen']);
              if (s && s.getTracks) {
                try {
                  s.getTracks().forEach(function(t) { t.stop(); });
                } catch (e) {}
              }
              delete this.streams['screen'];
              var localS = unwrap(this.streams['local']);
              if (localS && localS.getVideoTracks && localS.getVideoTracks().length > 0) {
                this.replaceOutgoingVideoTrack(localS.getVideoTracks()[0]);
              }
            },

            getOrCreatePeer: function(remotePeerId) {
              var self = this;
              if (self.peers[remotePeerId]) {
                return self.peers[remotePeerId];
              }
              if (typeof RTCPeerConnection === 'undefined') {
                self.reportMediaStatus('Este navegador não oferece suporte a chamadas WebRTC.');
                throw new Error('RTCPeerConnection is unavailable');
              }
              var configuredIceServers = window.__AGMRM_ICE_SERVERS__;
              var pc = new RTCPeerConnection({
                iceServers: Array.isArray(configuredIceServers) && configuredIceServers.length
                  ? configuredIceServers
                  : [
                  { urls: 'stun:stun.l.google.com:19302' },
                  { urls: 'stun:stun1.l.google.com:19302' }
                  ]
              });
              self.peers[remotePeerId] = pc;
              self.pendingIceCandidates[remotePeerId] = [];

              var localStream = unwrap(self.streams['local']);
              var screenStream = unwrap(self.streams['screen']);
              var activeStream = screenStream || localStream;
              if (activeStream && activeStream.getTracks) {
                activeStream.getTracks().forEach(function(track) {
                  try {
                    pc.addTrack(track, activeStream);
                  } catch (e) {
                    self.reportMediaStatus('Não foi possível compartilhar a trilha de ' + track.kind + ' com o outro participante.');
                  }
                });
              }
              if (screenStream && localStream && localStream.getAudioTracks) {
                localStream.getAudioTracks().forEach(function(audioTrack) {
                  try {
                    pc.addTrack(audioTrack, screenStream);
                  } catch (e) {
                    self.reportMediaStatus('Não foi possível compartilhar o áudio durante o compartilhamento de tela.');
                  }
                });
              }

              pc.onicecandidate = function(event) {
                if (event.candidate && self.onOutboundSignalCb) {
                  self.onOutboundSignalCb(
                    remotePeerId,
                    'ice',
                    '',
                    '',
                    event.candidate.candidate || '',
                    event.candidate.sdpMid || '',
                    event.candidate.sdpMLineIndex || 0
                  );
                }
              };

              pc.ontrack = function(event) {
                var remoteStream = (event.streams && event.streams[0])
                  ? event.streams[0]
                  : new MediaStream([event.track]);
                self.streams[remotePeerId] = remoteStream;
                if (event.track.kind === 'audio') {
                  self.attachRemoteAudio(remotePeerId, event.track);
                }
                event.track.addEventListener('ended', function() {
                  if (event.track.kind === 'audio') {
                    self.clearRemoteAudio(remotePeerId);
                  }
                }, { once: true });
                if (self.onRemoteStreamCb) {
                  self.onRemoteStreamCb(remotePeerId);
                }
                self.resumeAllForKey(remotePeerId, true);
              };

              pc.oniceconnectionstatechange = function() {
                if (pc.iceConnectionState === 'failed') {
                  self.reportMediaStatus('A conexão de mídia falhou. Verifique a rede ou a configuração de um servidor TURN.');
                }
              };

              return pc;
            },

            flushPendingIceCandidates: function(remotePeerId, pc) {
              var self = this;
              var queued = self.pendingIceCandidates[remotePeerId] || [];
              self.pendingIceCandidates[remotePeerId] = [];
              return queued.reduce(function(chain, candidate) {
                return chain.then(function() {
                  return pc.addIceCandidate(candidate);
                });
              }, Promise.resolve()).catch(function(error) {
                self.reportMediaStatus('Não foi possível aplicar os candidatos de rede WebRTC recebidos.');
              });
            },

            connectPeer: function(remotePeerId, isInitiator) {
              var self = this;
              try {
                var pc = self.getOrCreatePeer(remotePeerId);
                if (isInitiator) {
                  pc.createOffer({
                    offerToReceiveAudio: true,
                    offerToReceiveVideo: true
                  }).then(function(offer) {
                    return pc.setLocalDescription(offer).then(function() {
                      if (self.onOutboundSignalCb) {
                        self.onOutboundSignalCb(
                          remotePeerId,
                          'offer',
                          offer.type || 'offer',
                          offer.sdp || '',
                          '',
                          '',
                          0
                        );
                      }
                    });
                  }).catch(function(error) {
                    self.reportMediaStatus('Não foi possível iniciar a conexão de mídia: ' + (error.message || error.name || 'erro WebRTC') + '.');
                  });
                }
              } catch (e) {
                self.reportMediaStatus('Não foi possível criar a conexão WebRTC com o participante.');
              }
            },

            handleSignal: function(remotePeerId, signalType, sdpType, sdp, candidate, sdpMid, sdpMLineIndex) {
              var self = this;
              try {
                var pc = self.getOrCreatePeer(remotePeerId);
                if (signalType === 'offer') {
                  if (!sdp) return;
                  pc.setRemoteDescription({
                    type: sdpType || 'offer',
                    sdp: sdp
                  }).then(function() {
                    return self.flushPendingIceCandidates(remotePeerId, pc);
                  }).then(function() {
                    return pc.createAnswer();
                  }).then(function(answer) {
                    return pc.setLocalDescription(answer).then(function() {
                      if (self.onOutboundSignalCb) {
                        self.onOutboundSignalCb(
                          remotePeerId,
                          'answer',
                          answer.type || 'answer',
                          answer.sdp || '',
                          '',
                          '',
                          0
                        );
                      }
                    });
                  }).catch(function(error) {
                    self.reportMediaStatus('Não foi possível negociar a chamada WebRTC: ' + (error.message || error.name || 'erro WebRTC') + '.');
                  });
                } else if (signalType === 'answer') {
                  if (!sdp) return;
                  pc.setRemoteDescription({
                    type: sdpType || 'answer',
                    sdp: sdp
                  }).then(function() {
                    return self.flushPendingIceCandidates(remotePeerId, pc);
                  }).catch(function(error) {
                    self.reportMediaStatus('Não foi possível aplicar a resposta WebRTC recebida.');
                  });
                } else if (signalType === 'ice') {
                  if (!candidate) return;
                  var iceCandidate = {
                    candidate: candidate,
                    sdpMid: sdpMid || '0',
                    sdpMLineIndex: sdpMLineIndex || 0
                  };
                  if (!pc.remoteDescription) {
                    self.pendingIceCandidates[remotePeerId].push(iceCandidate);
                    return;
                  }
                  pc.addIceCandidate(iceCandidate).catch(function() {
                    self.reportMediaStatus('Não foi possível aplicar um candidato de rede WebRTC.');
                  });
                }
              } catch (e) {
                self.reportMediaStatus('Não foi possível processar a sinalização da conexão WebRTC.');
              }
            },

            disconnectPeer: function(remotePeerId) {
              var pc = this.peers[remotePeerId];
              if (pc) {
                try { pc.close(); } catch (e) {}
                delete this.peers[remotePeerId];
              }
              delete this.streams[remotePeerId];
              delete this.pendingIceCandidates[remotePeerId];
              this.clearRemoteAudio(remotePeerId);
            },

            startRecording: function() {
              var self = this;
              self.recordedChunks = [];
              var stream = unwrap(self.streams['screen']) || unwrap(self.streams['local']);
              if (!stream || typeof MediaRecorder === 'undefined') return;
              try {
                var mimeType = 'video/webm;codecs=vp8,opus';
                if (!MediaRecorder.isTypeSupported(mimeType)) {
                  mimeType = 'video/webm';
                }
                var options = MediaRecorder.isTypeSupported(mimeType)
                  ? { mimeType: mimeType }
                  : {};
                var recorder = new MediaRecorder(stream, options);
                recorder.ondataavailable = function(e) {
                  if (e.data && e.data.size > 0) {
                    self.recordedChunks.push(e.data);
                  }
                };
                self.mediaRecorder = recorder;
                recorder.start(1000);
              } catch (e) {
                self.mediaRecorder = null;
              }
            },

            stopRecordingAndDownload: function(webmName, txtName, txtContent, onDone) {
              var self = this;
              var finish = function() {
                var downloaded = txtName;
                try {
                  if (self.recordedChunks && self.recordedChunks.length > 0) {
                    var webmBlob = new Blob(self.recordedChunks, { type: 'video/webm' });
                    self.triggerDownload(webmBlob, webmName);
                    downloaded = webmName;
                  }
                  self.recordedChunks = [];
                  var txtBlob = new Blob([txtContent], { type: 'text/plain;charset=utf-8' });
                  self.triggerDownload(txtBlob, txtName);
                } catch (e) {}
                onDone(downloaded);
              };

              try {
                if (self.mediaRecorder && self.mediaRecorder.state !== 'inactive') {
                  self.mediaRecorder.onstop = function() {
                    self.mediaRecorder = null;
                    finish();
                  };
                  self.mediaRecorder.stop();
                  return;
                }
              } catch (e) {}
              self.mediaRecorder = null;
              finish();
            },

            triggerDownload: function(blob, fileName) {
              try {
                var url = URL.createObjectURL(blob);
                var a = document.createElement('a');
                a.style.display = 'none';
                a.href = url;
                a.download = fileName;
                document.body.appendChild(a);
                a.click();
                setTimeout(function() {
                  try {
                    document.body.removeChild(a);
                    URL.revokeObjectURL(url);
                  } catch (e) {}
                }, 400);
              } catch (e) {}
            },

            disposeAll: function() {
              if (this.audioTimer) {
                clearInterval(this.audioTimer);
                this.audioTimer = null;
              }
              if (this.audioCtx && this.audioCtx.close) {
                try { this.audioCtx.close(); } catch (e) {}
                this.audioCtx = null;
              }
              if (this.playbackAudioCtx && this.playbackAudioCtx.close) {
                try { this.playbackAudioCtx.close(); } catch (e) {}
                this.playbackAudioCtx = null;
              }
              var audioPeerIds = Object.keys(this.remoteAudioElements);
              for (var a = 0; a < audioPeerIds.length; a++) {
                this.clearRemoteAudio(audioPeerIds[a]);
              }
              Object.keys(this.remoteAudioSources).forEach(function(key) {
                try { this.remoteAudioSources[key].disconnect(); } catch (e) {}
              }, this);
              this.remoteAudioSources = {};
              this.remoteAudioElements = {};
              this.pendingIceCandidates = {};
              var peerIds = Object.keys(this.peers);
              for (var i = 0; i < peerIds.length; i++) {
                try { this.peers[peerIds[i]].close(); } catch (e) {}
              }
              this.peers = {};
              var streamKeys = Object.keys(this.streams);
              for (var j = 0; j < streamKeys.length; j++) {
                var s = unwrap(this.streams[streamKeys[j]]);
                if (s && s.getTracks) {
                  try {
                    s.getTracks().forEach(function(t) { t.stop(); });
                  } catch (e) {}
                }
              }
              this.streams = {};
            }
          };
        })();
  ''';

  js.JsObject? get _bridge {
    try {
      return js.context['__agmrmMediaBridge'] as js.JsObject?;
    } catch (_) {
      return null;
    }
  }

  void _bindBridgeCallbacks() {
    final bridge = _bridge;
    if (bridge == null) return;

    bridge['onAudioLevelCb'] = (num level) {
      if (!_isDisposed && !_audioLevelController.isClosed) {
        _audioLevelController.add(level.toDouble().clamp(0.0, 1.0));
      }
    };

    bridge['onRemoteStreamCb'] = (String remotePeerId) {
      if (_isDisposed) return;
      _registerStreamViewFactory(remotePeerId, muted: true, mirror: false);
    };

    bridge['onMediaStatusCb'] = (String message) {
      if (!_isDisposed && !_mediaStatusController.isClosed) {
        _mediaStatusController.add(message);
      }
    };

    bridge['onOutboundSignalCb'] =
        (
          String targetPeerId,
          String signalType,
          String sdpType,
          String sdp,
          String candidate,
          String sdpMid,
          num sdpMLineIndex,
        ) {
          if (_isDisposed || _outboundWebRtcController.isClosed) return;
          if (signalType == 'ice') {
            _outboundWebRtcController.add({
              'targetPeerId': targetPeerId,
              'signalType': 'ice',
              'candidate': candidate,
              'sdpMid': sdpMid,
              'sdpMLineIndex': sdpMLineIndex.toInt(),
            });
          } else {
            _outboundWebRtcController.add({
              'targetPeerId': targetPeerId,
              'signalType': signalType,
              'type': sdpType,
              'sdp': sdp,
            });
          }
        };
  }

  void _startVideoPlaybackWatchdog() {
    _videoPlaybackWatchdog?.cancel();
    _videoPlaybackWatchdog = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) {
      if (_isDisposed) return;
      _bridge?.callMethod('resumeAllStreams', []);
    });
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
  Stream<String> get onMediaStatus => _mediaStatusController.stream;

  @override
  bool get isInitialized => _isInitialized;

  @override
  String? getVideoViewType(String streamKey) => _registeredViewTypes[streamKey];

  /// Registra uma factory no `platformViewRegistry` que cria um `<video>` HTML5
  /// limpo e anexa o `MediaStream` nativo em JavaScript sem risco de exceção `DartObject`.
  String _registerStreamViewFactory(
    String streamKey, {
    required bool muted,
    required bool mirror,
    bool forceNewViewType = false,
  }) {
    if (forceNewViewType || !_registeredViewTypes.containsKey(streamKey)) {
      final viewType = 'agmrm-video-$streamKey-${++_viewSequence}';
      _registeredViewTypes[streamKey] = viewType;

      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final element = html.VideoElement()
          ..autoplay = true
          ..muted = muted
          ..controls = false
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = streamKey == 'screen' ? 'contain' : 'cover'
          ..style.backgroundColor = '#09090B'
          ..style.pointerEvents = 'none';

        element.setAttribute('playsinline', 'true');
        element.setAttribute('webkit-playsinline', 'true');
        element.setAttribute('data-agmrm-key', streamKey);
        if (muted) {
          element.setAttribute('muted', 'true');
        }
        if (mirror) {
          element.style.transform = 'scaleX(-1)';
        }

        try {
          _bridge?.callMethod('attachStreamToElement', [
            element,
            streamKey,
            muted,
          ]);
        } catch (_) {}

        // Também agenda varredura no próximo microtask/frame após inserção no Shadow DOM
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!_isDisposed) {
            _bridge?.callMethod('resumeAllForKey', [streamKey, muted]);
          }
        });

        return element;
      });
    } else {
      _bridge?.callMethod('resumeAllForKey', [streamKey, muted]);
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
    _ensureJsBridge();
    _bindBridgeCallbacks();

    // Registra imediatamente a viewFactory 'local' para que o HtmlElementView
    // já esteja montado no DOM assim que o stream da câmera ficar pronto.
    _registerStreamViewFactory('local', muted: true, mirror: true);

    if (_isInitialized) {
      _registerStreamViewFactory(
        'local',
        muted: true,
        mirror: true,
        forceNewViewType: true,
      );
      await setMicrophoneMuted(audioMuted);
      await setCameraOff(videoOff);
      _bridge?.callMethod('resumeAllForKey', ['local', true]);
      return true;
    }

    if (_initFuture != null) {
      final result = await _initFuture!;
      _registerStreamViewFactory(
        'local',
        muted: true,
        mirror: true,
        forceNewViewType: true,
      );
      await setMicrophoneMuted(audioMuted);
      await setCameraOff(videoOff);
      _bridge?.callMethod('resumeAllForKey', ['local', true]);
      return result;
    }

    final completer = Completer<bool>();
    _initFuture = completer.future;

    final bridge = _bridge;
    if (bridge == null) {
      _initFuture = null;
      if (!_mediaStatusController.isClosed) {
        _mediaStatusController.add(
          'O mecanismo de mídia não pôde ser iniciado neste navegador.',
        );
      }
      completer.complete(false);
      return false;
    }

    try {
      bridge.callMethod('startLocalMedia', [
        audioMuted,
        videoOff,
        (dynamic _) {
          _isInitialized = true;
          _registerStreamViewFactory('local', muted: true, mirror: true);
          _bridge?.callMethod('resumeAllForKey', ['local', true]);
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        (dynamic error) {
          _initFuture = null;
          if (!_mediaStatusController.isClosed) {
            _mediaStatusController.add(
              error?.toString() ??
                  'Não foi possível acessar câmera ou microfone.',
            );
          }
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ]);
    } catch (error) {
      _initFuture = null;
      if (!_mediaStatusController.isClosed) {
        _mediaStatusController.add(
          'Falha ao iniciar câmera ou microfone: $error',
        );
      }
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  @override
  Future<void> unlockAudioPlayback() async {
    if (_isDisposed) return;
    _ensureJsBridge();
    _bridge?.callMethod('unlockAudioPlayback', []);
  }

  @override
  Future<void> setMicrophoneMuted(bool muted) async {
    _bridge?.callMethod('setMicMuted', [muted]);
    if (muted && !_audioLevelController.isClosed) {
      _audioLevelController.add(0.0);
    }
  }

  @override
  Future<void> setCameraOff(bool videoOff) async {
    _bridge?.callMethod('setCamOff', [videoOff]);
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
        () {
          if (_isDisposed) {
            bridge.callMethod('stopDisplayMedia', []);
            if (!completer.isCompleted) completer.complete(false);
            return;
          }
          _registerStreamViewFactory(
            'screen',
            muted: true,
            mirror: false,
            forceNewViewType: true,
          );
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        (dynamic _) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
        () {
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
    _bridge?.callMethod('stopDisplayMedia', []);
    _registeredViewTypes.remove('screen');
    if (!_videoStreamUpdatedController.isClosed) {
      _videoStreamUpdatedController.add('screen');
    }
  }

  @override
  Future<void> connectToPeer(
    String remotePeerId, {
    required bool isInitiator,
  }) async {
    if (_isDisposed) return;
    _bridge?.callMethod('connectPeer', [remotePeerId, isInitiator]);
  }

  @override
  Future<void> handleInboundWebRtcSignal(
    String remotePeerId,
    Map<String, dynamic> signalData,
  ) async {
    if (_isDisposed) return;
    final signalType = signalData['signalType'] as String? ?? '';
    final sdpType = signalData['type'] as String? ?? '';
    final sdp = signalData['sdp'] as String? ?? '';
    final candidate = signalData['candidate'] as String? ?? '';
    final sdpMid = signalData['sdpMid'] as String? ?? '';
    final sdpMLineIndex = (signalData['sdpMLineIndex'] as num?)?.toInt() ?? 0;

    _bridge?.callMethod('handleSignal', [
      remotePeerId,
      signalType,
      sdpType,
      sdp,
      candidate,
      sdpMid,
      sdpMLineIndex,
    ]);
  }

  @override
  Future<void> disconnectPeer(String remotePeerId) async {
    _bridge?.callMethod('disconnectPeer', [remotePeerId]);
    _registeredViewTypes.remove(remotePeerId);
  }

  @override
  Future<void> startRecording() async {
    if (_isDisposed) return;
    _bridge?.callMethod('startRecording', []);
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

    final webmFileName = 'gravacao_${sanitizedCode}_$timestamp.webm';
    final txtFileName = 'ata_${sanitizedCode}_$timestamp.txt';
    final summaryText = _formatExportReport(exportSummary);

    final completer = Completer<String?>();
    final bridge = _bridge;
    if (bridge == null) {
      return txtFileName;
    }

    try {
      bridge.callMethod('stopRecordingAndDownload', [
        webmFileName,
        txtFileName,
        summaryText,
        (dynamic downloadedName) {
          if (!completer.isCompleted) {
            completer.complete(downloadedName?.toString() ?? txtFileName);
          }
        },
      ]);
    } catch (_) {
      if (!completer.isCompleted) {
        completer.complete(txtFileName);
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => txtFileName,
    );
  }

  String _formatExportReport(SessionExport exportSummary) {
    final buffer = StringBuffer()
      ..writeln('==========================================================')
      ..writeln('         ATA DE SESSÃO ACADÊMICA - PLATAFORMA AGMRM       ')
      ..writeln('==========================================================')
      ..writeln('Sala: ${exportSummary.roomCode}')
      ..writeln('Início: ${exportSummary.startedAt.toIso8601String()}')
      ..writeln('Término: ${exportSummary.endedAt.toIso8601String()}')
      ..writeln(
        'Duração Gravada: ${exportSummary.totalDuration.inSeconds} segundos',
      )
      ..writeln(
        'Total de Participantes Reais: ${exportSummary.totalParticipants}',
      )
      ..writeln('Presentes: ${exportSummary.attendeeNames.join(", ")}')
      ..writeln('Mensagens no Chat: ${exportSummary.chatMessageCount}')
      ..writeln('Reações Registradas: ${exportSummary.reactionCount}')
      ..writeln('==========================================================');
    return buffer.toString();
  }

  @override
  Future<void> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return;
    } catch (_) {}

    try {
      await html.window.navigator.clipboard?.writeText(text);
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _videoPlaybackWatchdog?.cancel();
    _videoPlaybackWatchdog = null;
    _bridge?.callMethod('disposeAll', []);
    _registeredViewTypes.clear();

    await _audioLevelController.close();
    await _screenShareStoppedController.close();
    await _outboundWebRtcController.close();
    await _videoStreamUpdatedController.close();
    await _mediaStatusController.close();
  }
}
