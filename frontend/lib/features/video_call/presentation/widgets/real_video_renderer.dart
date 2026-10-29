// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/video_call_theme.dart';

/// Renderiza o elemento de vídeo real HTML5 (`<video>`) via [HtmlElementView] na Web,
/// com fallback visual monocromático para execução em testes de widget (VM).
class RealVideoRenderer extends StatelessWidget {
  /// Identificador da view registrada no `platformViewRegistry` (`null` em modo VM/Stub).
  final String? viewType;

  /// Rótulo opcional exibido no modo fallback ou indicador de stream ao vivo.
  final String? streamLabel;

  /// Ícone exibido caso o ambiente não possua renderizador nativo HTML5 (ex: testes VM).
  final IconData fallbackIcon;

  const RealVideoRenderer({
    super.key,
    required this.viewType,
    this.streamLabel,
    this.fallbackIcon = Icons.videocam,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && viewType != null && viewType!.isNotEmpty) {
      return SizedBox.expand(
        child: ClipRect(
          child: HtmlElementView(
            key: ValueKey('html_video_$viewType'),
            viewType: viewType!,
          ),
        ),
      );
    }

    return Container(
      color: VideoCallColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fallbackIcon,
              color: VideoCallColors.textSecondary,
              size: 48,
            ),
            if (streamLabel != null && streamLabel!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                streamLabel!,
                style: const TextStyle(
                  color: VideoCallColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
