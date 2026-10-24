// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';

/// Design tokens and institutional color palette for the Docente Portal.
class DocenteColors {
  DocenteColors._();

  static const Color background = Color(0xFFFAF9F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color headerBackground = Color(0xFFF4F4F4);
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderDark = Color(0xFFD4D4D4);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF737373);
  static const Color textMuted = Color(0xFFA3A3A3);

  static const Color navActiveBackground = Color(0xFFF2F0EB);
  static const Color navHoverBackground = Color(0xFFFAF9F6);

  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEF2F2);

  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Semantic color aliases for high consistency across all widgets
  static const Color charcoal = textPrimary;
  static const Color emerald = success;
  static const Color crimson = danger;
  static const Color amber = warning;
  static const Color slate = textSecondary;
  static const Color muted = textMuted;
  static const Color white = surface;
  static const Color offWhite = background;
}
