// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';

/// Medidor visual de nível de volume RMS em tempo real.
///
/// Exibe uma barra horizontal preenchida proporcionalmente ao [level] (0.0 a 1.0).
/// Quando o nível ultrapassa o limiar de fala ativa (> 0.15), a cor de destaque
/// transiciona dinamicamente para verde esmeralda (`Colors.greenAccent`),
/// mantendo azul claro (`Colors.lightBlueAccent`) em silêncio ou fala baixa.
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
        color: Colors.white24,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clampedLevel,
        child: Container(
          decoration: BoxDecoration(
            color: isSpeaking ? Colors.greenAccent : Colors.lightBlueAccent,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
