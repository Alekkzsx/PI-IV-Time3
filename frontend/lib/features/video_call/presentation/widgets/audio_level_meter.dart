// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../theme/video_call_theme.dart';

/// Medidor visual de nível de volume RMS em tempo real (Estética Preto, Cinza e Branco).
///
/// Exibe uma barra horizontal preenchida proporcionalmente ao [level] (0.0 a 1.0).
/// Quando o nível ultrapassa o limiar de fala ativa (> 0.15), a cor de destaque
/// transiciona dinamicamente para branco puro ([VideoCallColors.accentWhite]),
/// mantendo cinza médio ([VideoCallColors.textSecondary]) em silêncio ou fala baixa.
class AudioLevelMeter extends StatelessWidget {
  /// Nível de áudio normalizado entre 0.0 (silêncio total) e 1.0 (pico máximo).
  final double level;

  /// Largura total da barra do medidor em pixels lógicos (padrão: 80.0).
  final double width;

  /// Altura da barra do medidor em pixels lógicos (padrão: 6.0).
  final double height;

  const AudioLevelMeter({
    super.key,
    required this.level,
    this.width = 80.0,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final clampedLevel = level.clamp(0.0, 1.0);
    final isSpeaking = clampedLevel > 0.15;

    return Container(
      key: const Key('audio_level_meter'),
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: VideoCallColors.border,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clampedLevel,
        child: Container(
          decoration: BoxDecoration(
            color: isSpeaking
                ? VideoCallColors.accentWhite
                : VideoCallColors.textSecondary,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
