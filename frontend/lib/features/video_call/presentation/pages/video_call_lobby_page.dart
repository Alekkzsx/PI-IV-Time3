// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../../../../core/state/academic_bridge_service.dart';
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
  bool _argumentsApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentsApplied) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        if (args['name'] != null && _nameController.text.isEmpty) {
          _nameController.text = args['name'].toString();
          _lobbyController.setName(_nameController.text);
        }
        if (args['ra'] != null && _raController.text.isEmpty) {
          _raController.text = args['ra'].toString();
          _lobbyController.setRa(_raController.text);
        }
        if (args['roomCode'] != null) {
          _roomCodeController.text = args['roomCode'].toString();
          _lobbyController.setRoomCode(_roomCodeController.text);
        }
        if (args['role'] != null) {
          _userRole = args['role'].toString();
        }
      }
      _argumentsApplied = true;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _lobbyController = widget.controller!;
    } else {
      _lobbyController = VideoCallLobbyController(
        repository: widget.repository,
      );
      _ownsController = true;
    }

    _nameController = TextEditingController(text: _lobbyController.name);
    _raController = TextEditingController(text: _lobbyController.ra);
    _roomCodeController = TextEditingController(
      text: _lobbyController.roomCode,
    );

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

      final name = _nameController.text.trim();
      final ra = _raController.text.trim();
      final roomCode = _roomCodeController.text.trim().toUpperCase();
      final isAudioMuted = _lobbyController.isAudioMuted;
      final isVideoOff = _lobbyController.isVideoOff;

      // Validação de Permissão Institucional: Quem pode abrir a sala é o Docente da turma ou Admin.
      final isClassroomSession = roomCode.contains('APS') ||
          roomCode.contains('BD') ||
          roomCode.contains('FSO') ||
          _userRole == 'aluno';

      final isTeacherOrAdmin = _userRole == 'docente' ||
          _userRole == 'admin' ||
          ra.toUpperCase().startsWith('DOC-') ||
          ra.toUpperCase().startsWith('ADM-');

      if (isClassroomSession && !isTeacherOrAdmin && widget.onJoin == null) {
        final isRoomOpen = AcademicBridgeService.instance.isSessionOpen(roomCode);
        if (!isRoomOpen) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF18181B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF3F3F46)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_clock_outlined, color: Color(0xFFF59E0B)),
                  SizedBox(width: 10),
                  Text(
                    'Sessão Aguardando Início',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              content: Text(
                'A videochamada da turma $roomCode ainda não foi aberta pelo docente responsável nem pela administração.\n\nApenas o professor titular ou a coordenação podem iniciar esta sessão ao vivo.',
                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Compreendi', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          return;
        }
      } else if (isTeacherOrAdmin) {
        // Docente ou Admin abre a sala automaticamente no barramento institucional
        AcademicBridgeService.instance.openSession(
          rawCourseCode: roomCode,
          openedByRole: _userRole ?? (ra.toUpperCase().startsWith('ADM') ? 'admin' : 'docente'),
          openedByName: name,
          roomCode: roomCode,
        );
      }

      final resolvedRole = isTeacherOrAdmin
          ? (_userRole ?? (ra.toUpperCase().startsWith('ADM') ? 'admin' : 'docente'))
          : 'participant';

      if (widget.onJoin != null) {
        widget.onJoin!(name, ra, roomCode, isAudioMuted, isVideoOff);
      } else {
        final videoCallController = _lobbyController.createCallController(
          name: name,
          ra: ra,
          roomCode: roomCode,
          role: resolvedRole,
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
