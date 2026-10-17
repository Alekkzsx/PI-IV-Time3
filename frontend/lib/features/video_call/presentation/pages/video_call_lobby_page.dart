// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/repositories/video_call_repository.dart';
import '../controllers/video_call_lobby_controller.dart';
import '../theme/video_call_theme.dart';
import '../widgets/audio_level_meter.dart';
import '../widgets/real_video_renderer.dart';
import 'video_call_room_page.dart';

/// Página de pré-chamada (Lobby) para validação de identidade, preview real de áudio/vídeo
/// e entrada na sala (Estética Preto, Cinza e Branco).
class VideoCallLobbyPage extends StatefulWidget {
  final VideoCallLobbyController? controller;
  final VideoCallRepository? repository;
  final Function(
    String name,
    String ra,
    String roomCode,
    bool isAudioMuted,
    bool isVideoOff,
  )? onJoin;

  const VideoCallLobbyPage({
    super.key,
    this.controller,
    this.repository,
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

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _lobbyController = widget.controller!;
    } else {
      _lobbyController =
          VideoCallLobbyController(repository: widget.repository);
      _ownsController = true;
    }

    _nameController = TextEditingController(text: _lobbyController.name);
    _raController = TextEditingController(text: _lobbyController.ra);
    _roomCodeController =
        TextEditingController(text: _lobbyController.roomCode);

    _lobbyController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
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
      final name = _nameController.text.trim();
      final ra = _raController.text.trim();
      final roomCode = _roomCodeController.text.trim().toUpperCase();
      final isAudioMuted = _lobbyController.isAudioMuted;
      final isVideoOff = _lobbyController.isVideoOff;

      if (widget.onJoin != null) {
        widget.onJoin!(name, ra, roomCode, isAudioMuted, isVideoOff);
      } else {
        final videoCallController = _lobbyController.createCallController(
          name: name,
          ra: ra,
          roomCode: roomCode,
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
        borderSide:
            const BorderSide(color: VideoCallColors.accentWhite, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: VideoCallColors.borderStrong),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: VideoCallColors.accentWhite, width: 1.5),
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
                      AudioLevelMeter(
                        level: _lobbyController.audioLevel,
                      ),
                    ],
                  ),
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
                    style: const TextStyle(color: VideoCallColors.textPrimary),
                    decoration:
                        _buildMonochromeInputDecoration('Nome de Exibição'),
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
                    style: const TextStyle(color: VideoCallColors.textPrimary),
                    decoration:
                        _buildMonochromeInputDecoration('RA Institucional'),
                    onChanged: _lobbyController.setRa,
                    validator: _lobbyController.validateRa,
                  ),
                  const SizedBox(height: 16),
                  // Campo Código da Sala
                  TextFormField(
                    key: const Key('lobby_room_code_field'),
                    controller: _roomCodeController,
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
                      onPressed: _submit,
                      child: const Text(
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
