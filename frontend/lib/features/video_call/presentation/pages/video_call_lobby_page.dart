// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../../../../core/state/app_user_session.dart';
import '../../data/datasources/video_call_room_remote_data_source.dart';
import '../../domain/repositories/video_call_repository.dart';
import '../controllers/video_call_lobby_controller.dart';
import '../theme/video_call_theme.dart';
import '../widgets/audio_level_meter.dart';
import '../widgets/real_video_renderer.dart';
import 'video_call_room_page.dart';

/// Pre-call lobby page for identity validation, real audio/video preview,
/// and room entry (Black, Gray, and White design system).
class VideoCallLobbyPage extends StatefulWidget {
  final VideoCallLobbyController? controller;
  final VideoCallRepository? repository;
  final VideoCallRoomRemoteDataSource? roomDataSource;
  final String? initialRoomCode;
  final Function(
    String name,
    String ra,
    String roomCode,
    bool isAudioMuted,
    bool isVideoOff,
  )?
  onJoin;

  const VideoCallLobbyPage({
    super.key,
    this.controller,
    this.repository,
    this.roomDataSource,
    this.initialRoomCode,
    this.onJoin,
  });

  @override
  State<VideoCallLobbyPage> createState() => _VideoCallLobbyPageState();
}

class _VideoCallLobbyPageState extends State<VideoCallLobbyPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _raController;
  late final TextEditingController _roomCodeController;
  late final VideoCallLobbyController _lobbyController;
  bool _ownsController = false;
  bool _isInRoom = false;
  String? _userRole;
  late final VideoCallRoomRemoteDataSource _roomDataSource;

  @override
  void initState() {
    super.initState();
    _roomDataSource =
        widget.roomDataSource ?? VideoCallRoomRemoteDataSource();
    if (widget.controller != null) {
      _lobbyController = widget.controller!;
    } else {
      _lobbyController = VideoCallLobbyController(
        repository: widget.repository,
      );
      _ownsController = true;
    }

    final userSession = AppUserSession.instance;
    _userRole = userSession.role;
    final identity = userSession.identity ?? '';
    _nameController = TextEditingController(
      text: identity.isNotEmpty ? identity : _lobbyController.name,
    );
    _raController = TextEditingController(
      text: identity.isNotEmpty ? identity : _lobbyController.ra,
    );
    _roomCodeController = TextEditingController(
      text: widget.initialRoomCode ?? _lobbyController.roomCode,
    );
    _lobbyController.setName(_nameController.text);
    _lobbyController.setRa(_raController.text);
    _lobbyController.setRoomCode(_roomCodeController.text);

    _lobbyController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _showAccessDenied(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _lobbyController.removeListener(_onControllerUpdate);
    if (_ownsController) {
      _lobbyController.dispose();
    }
    _nameController.dispose();
    _raController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final session = AppUserSession.instance;
      final role = session.role;
      final identity = session.identity;
      if (role == null || identity == null || identity.isEmpty) {
        _showAccessDenied('Faça login para acessar uma videochamada.');
        return;
      }

      final name = identity;
      final ra = identity;
      final requestedRoomCode = _roomCodeController.text.trim().toUpperCase();
      final roomCode = requestedRoomCode;

      await _lobbyController.mediaEngine.unlockAudioPlayback();
      final mediaReady = await _lobbyController.ensureMediaReady();
      if (!mounted) return;
      if (!mediaReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _lobbyController.mediaStatus ??
                  'Ative a câmera ou o microfone nas permissões do navegador para entrar.',
            ),
          ),
        );
        return;
      }

      late final VideoCallRoomAccess roomAccess;
      try {
        roomAccess = await _roomDataSource.enterRoom(roomCode);
      } on VideoCallRoomApiException catch (error) {
        if (mounted) _showAccessDenied(error.message);
        return;
      }
      if (!mounted) return;

      final isAudioMuted = _lobbyController.isAudioMuted;
      final isVideoOff = _lobbyController.isVideoOff;
      final resolvedRole = role;

      if (widget.onJoin != null) {
        widget.onJoin!(name, ra, roomCode, isAudioMuted, isVideoOff);
      } else {
        final videoCallController = _lobbyController.createCallController(
          name: name,
          ra: ra,
          roomCode: roomCode,
          role: resolvedRole,
          webSocketTicket: roomAccess.webSocketTicket,
        );
        setState(() {
          _isInRoom = true;
        });
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                VideoCallRoomPage(controller: videoCallController),
          ),
        );
        if (roomAccess.opened) {
          try {
            await _roomDataSource.closeRoom(roomCode);
          } on VideoCallRoomApiException catch (error) {
            if (mounted) _showAccessDenied(error.message);
          }
        }
        if (mounted) {
          setState(() {
            _isInRoom = false;
          });
        }
      }
    }
  }

  InputDecoration _buildMonochromeInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: VideoCallColors.textSecondary),
      filled: true,
      fillColor: VideoCallColors.background,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: VideoCallColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: VideoCallColors.accentWhite,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: VideoCallColors.borderStrong),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: VideoCallColors.accentWhite,
          width: 1.5,
        ),
      ),
      errorStyle: const TextStyle(color: VideoCallColors.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLetter = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: VideoCallColors.background,
      appBar: AppBar(
        title: const Text(
          'Pré-chamada (Lobby)',
          style: TextStyle(
            color: VideoCallColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: VideoCallColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: VideoCallColors.textPrimary),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: VideoCallColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VideoCallColors.border, width: 1),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Moldura de preview real da câmera (WebRTC / HTML5 <video>)
                  Container(
                    key: const Key('lobby_camera_preview'),
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: VideoCallColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: VideoCallColors.border,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: _lobbyController.isVideoOff
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor:
                                        VideoCallColors.surfaceElevated,
                                    child: Text(
                                      initialLetter,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        color: VideoCallColors.accentWhite,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Câmera Desativada',
                                    style: TextStyle(
                                      color: VideoCallColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RealVideoRenderer(
                              viewType: _isInRoom
                                  ? null
                                  : _lobbyController.localVideoViewType,
                              fallbackIcon: Icons.videocam,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Indicador de nível de áudio do microfone em tempo real
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _lobbyController.isAudioMuted
                            ? Icons.mic_off
                            : Icons.mic,
                        color: _lobbyController.isAudioMuted
                            ? VideoCallColors.textMuted
                            : VideoCallColors.accentWhite,
                      ),
                      const SizedBox(width: 8),
                      AudioLevelMeter(level: _lobbyController.audioLevel),
                    ],
                  ),
                  if (_lobbyController.mediaStatus case final status?) ...[
                    const SizedBox(height: 10),
                    Container(
                      key: const Key('lobby_media_status'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: VideoCallColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: VideoCallColors.border),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: VideoCallColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Botões de alternância de hardware
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        key: const Key('lobby_toggle_mic_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lobbyController.isAudioMuted
                              ? VideoCallColors.background
                              : VideoCallColors.surfaceElevated,
                          foregroundColor: VideoCallColors.textPrimary,
                          side: const BorderSide(color: VideoCallColors.border),
                          elevation: 0,
                        ),
                        icon: Icon(
                          _lobbyController.isAudioMuted
                              ? Icons.mic_off
                              : Icons.mic,
                          color: _lobbyController.isAudioMuted
                              ? VideoCallColors.textMuted
                              : VideoCallColors.accentWhite,
                        ),
                        label: Text(
                          _lobbyController.isAudioMuted
                              ? 'Mudo'
                              : 'Microfone Ativo',
                        ),
                        onPressed: _lobbyController.toggleAudio,
                      ),
                      ElevatedButton.icon(
                        key: const Key('lobby_toggle_cam_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lobbyController.isVideoOff
                              ? VideoCallColors.background
                              : VideoCallColors.surfaceElevated,
                          foregroundColor: VideoCallColors.textPrimary,
                          side: const BorderSide(color: VideoCallColors.border),
                          elevation: 0,
                        ),
                        icon: Icon(
                          _lobbyController.isVideoOff
                              ? Icons.videocam_off
                              : Icons.videocam,
                          color: _lobbyController.isVideoOff
                              ? VideoCallColors.textMuted
                              : VideoCallColors.accentWhite,
                        ),
                        label: Text(
                          _lobbyController.isVideoOff
                              ? 'Câmera Desligada'
                              : 'Câmera Ligada',
                        ),
                        onPressed: _lobbyController.toggleVideo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Campo Nome
                  TextFormField(
                    key: const Key('lobby_name_field'),
                    controller: _nameController,
                    readOnly: _userRole != null,
                    style: const TextStyle(color: VideoCallColors.textPrimary),
                    decoration: _buildMonochromeInputDecoration(
                      'Nome de Exibição',
                    ),
                    onChanged: (val) {
                      _lobbyController.setName(val);
                      setState(() {});
                    },
                    validator: _lobbyController.validateName,
                  ),
                  const SizedBox(height: 16),
                  // Campo RA
                  TextFormField(
                    key: const Key('lobby_ra_field'),
                    controller: _raController,
                    readOnly: _userRole != null,
                    style: const TextStyle(color: VideoCallColors.textPrimary),
                    decoration: _buildMonochromeInputDecoration(
                      'RA Institucional',
                    ),
                    onChanged: _lobbyController.setRa,
                    validator: _lobbyController.validateRa,
                  ),
                  const SizedBox(height: 16),
                  // Campo Código da Sala
                  TextFormField(
                    key: const Key('lobby_room_code_field'),
                    controller: _roomCodeController,
                    readOnly: _userRole != null,
                    style: const TextStyle(color: VideoCallColors.textPrimary),
                    decoration: _buildMonochromeInputDecoration(
                      'Código da Sala (ex: SALA-101)',
                    ),
                    onChanged: _lobbyController.setRoomCode,
                    validator: _lobbyController.validateRoomCode,
                  ),
                  const SizedBox(height: 24),
                  // Botão de entrada na reunião (Alto Contraste Branco sobre Preto)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('lobby_join_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VideoCallColors.accentWhite,
                        foregroundColor: VideoCallColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _lobbyController.isInitializingMedia
                          ? null
                          : _submit,
                      child: _lobbyController.isInitializingMedia
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Entrar na Reunião',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: VideoCallColors.background,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
