// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
// Atualizado com fidelidade estrita aos tokens institucionais (InstColors)

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';

/// Design tokens e paleta institucional para o Portal Docente.
class DocenteColors {
  DocenteColors._();

  static const Color background = InstColors.stone;
  static const Color surface = InstColors.surface;
  static const Color headerBackground = InstColors.headerBg;
  static const Color border = InstColors.border;
  static const Color borderDark = InstColors.borderStrong;

  static const Color textPrimary = InstColors.ink;
  static const Color textSecondary = InstColors.muted;
  static const Color textMuted = InstColors.faint;

  static const Color navActiveBackground = InstColors.stoneActive;
  static const Color navHoverBackground = InstColors.stone;

  static const Color success = InstColors.success;
  static const Color successLight = InstColors.successBg;

  static const Color warning = InstColors.warning;
  static const Color warningLight = InstColors.warningBg;

  static const Color danger = InstColors.danger;
  static const Color dangerLight = InstColors.dangerBg;

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
