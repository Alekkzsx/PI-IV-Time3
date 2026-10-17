// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/video_call_theme.dart';
import 'real_video_renderer.dart';

/// Palco de apresentação de compartilhamento de tela em modo Spotlight (Estética Preto, Cinza e Branco).
///
/// Exibe a viewport primária de destaque da transmissão de tela real (`getDisplayMedia`)
/// com moldura monocromática de alto contraste, ícone representativo e título institucional.
class ScreenShareView extends StatelessWidget {
  /// Nome opcional do participante apresentador exibido no cabeçalho ou legenda.
  final String? presenterName;

  /// Identificador opcional da view HTML5 `<video>` de compartilhamento de tela.
  final String? videoViewType;

  /// Callback opcional disparado caso o usuário decida parar a própria apresentação.
  final VoidCallback? onStopSharing;

  const ScreenShareView({
    super.key,
    this.presenterName,
    this.videoViewType,
    this.onStopSharing,
  });

  @override
  Widget build(BuildContext context) {
    final hasLiveWebStream =
        kIsWeb && videoViewType != null && videoViewType!.isNotEmpty;

    return Container(
      key: const Key('screen_share_view'),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: VideoCallColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VideoCallColors.accentWhite, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasLiveWebStream)
              RealVideoRenderer(
                viewType: videoViewType,
                fallbackIcon: Icons.present_to_all,
              ),
            if (!hasLiveWebStream)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.present_to_all,
                      color: VideoCallColors.accentWhite,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Apresentação de Tela Ativa',
                      style: TextStyle(
                        color: VideoCallColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (presenterName != null && presenterName!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Apresentado por $presenterName',
                        style: const TextStyle(
                          color: VideoCallColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (hasLiveWebStream)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: VideoCallColors.background.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: VideoCallColors.borderStrong),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.present_to_all,
                        color: VideoCallColors.accentWhite,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Apresentação de Tela Ativa',
                        style: TextStyle(
                          color: VideoCallColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (presenterName != null &&
                          presenterName!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• Apresentado por $presenterName',
                          style: const TextStyle(
                            color: VideoCallColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
