// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/repositories/video_call_repository.dart';
import '../controllers/video_call_lobby_controller.dart';
import '../widgets/audio_level_meter.dart';
import 'video_call_room_page.dart';

/// Página de pré-chamada (Lobby) para validação de identidade, preview de áudio/vídeo e entrada na sala.
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

  void _submit() {
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                VideoCallRoomPage(controller: videoCallController),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialLetter = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      appBar: AppBar(
        title: const Text('Pré-chamada (Lobby)'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Moldura de preview da câmera
                  Container(
                    key: const Key('lobby_camera_preview'),
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _lobbyController.isVideoOff
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: const Color(0xFF1E293B),
                                  child: Text(
                                    initialLetter,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Câmera Desativada',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            )
                          : const Icon(
                              Icons.videocam,
                              color: Colors.white54,
                              size: 64,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Indicador de nível de áudio do microfone
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _lobbyController.isAudioMuted
                            ? Icons.mic_off
                            : Icons.mic,
                        color: _lobbyController.isAudioMuted
                            ? Colors.redAccent
                            : Colors.white70,
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
                        icon: Icon(
                          _lobbyController.isAudioMuted
                              ? Icons.mic_off
                              : Icons.mic,
                          color: _lobbyController.isAudioMuted
                              ? Colors.redAccent
                              : Colors.white,
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
                        icon: Icon(
                          _lobbyController.isVideoOff
                              ? Icons.videocam_off
                              : Icons.videocam,
                          color: _lobbyController.isVideoOff
                              ? Colors.redAccent
                              : Colors.white,
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
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nome de Exibição',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
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
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'RA Institucional',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _lobbyController.setRa,
                    validator: _lobbyController.validateRa,
                  ),
                  const SizedBox(height: 16),
                  // Campo Código da Sala
                  TextFormField(
                    key: const Key('lobby_room_code_field'),
                    controller: _roomCodeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Código da Sala (ex: SALA-101)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _lobbyController.setRoomCode,
                    validator: _lobbyController.validateRoomCode,
                  ),
                  const SizedBox(height: 24),
                  // Botão de entrada na reunião
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('lobby_join_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                      ),
                      onPressed: _submit,
                      child: const Text(
                        'Entrar na Reunião',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
