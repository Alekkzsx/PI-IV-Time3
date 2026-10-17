// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';

/// Paleta monocromática estrita em Preto, Cinza e Branco para a feature de Videochamada.
class VideoCallColors {
  VideoCallColors._();

  /// Fundo principal profundo (Preto Carbono - #09090B).
  static const Color background = Color(0xFF09090B);

  /// Superfície primária de cards, gavetas e painéis (Cinza Grafite Escuro - #18181B).
  static const Color surface = Color(0xFF18181B);

  /// Superfície elevada de botões, inputs e cabeçalhos (Cinza Chumbo - #27272A).
  static const Color surfaceElevated = Color(0xFF27272A);

  /// Superfície de destaque sutil (Cinza Médio Escuro - #3F3F46).
  static const Color surfaceHighlight = Color(0xFF3F3F46);

  /// Bordas e divisores sutis (Cinza Médio - #3F3F46).
  static const Color border = Color(0xFF3F3F46);

  /// Bordas mais visíveis para foco e cards ativos (Cinza Claro Escuro - #52525B).
  static const Color borderStrong = Color(0xFF52525B);

  /// Texto e ícones primários (Branco Puro - #FFFFFF).
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Texto secundário (Cinza Prata - #D4D4D8).
  static const Color textSecondary = Color(0xFFD4D4D8);

  /// Texto terciário e legendas (Cinza Neutro - #A1A1AA).
  static const Color textMuted = Color(0xFFA1A1AA);

  /// Destaque máximo em Branco Puro para botões primários, orador ativo e indicadores.
  static const Color accentWhite = Color(0xFFFFFFFF);

  /// Fundo de elementos ativos invertidos (Branco Suave - #F4F4F5).
  static const Color invertedSurface = Color(0xFFF4F4F5);

  /// Texto sobre fundo branco invertido (Preto Carbono - #09090B).
  static const Color invertedText = Color(0xFF09090B);
}
