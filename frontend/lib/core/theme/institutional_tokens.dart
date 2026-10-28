// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449
// Design tokens compartilhados (cores, medidas e tipografia) dos portais institucionais

import 'package:flutter/material.dart';
import 'jakarta_text.dart';

/// Paleta oficial dos portais (Aluno, Docente, Admin).
class InstColors {
  const InstColors._();

  static const Color ink = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF737373);
  static const Color faint = Color(0xFFA3A3A3);
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderStrong = Color(0xFFD4D4D4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color stone = Color(0xFFFAF9F6);
  static const Color stoneActive = Color(0xFFF2F0EB);
  static const Color headerBg = Color(0xFFF5F5F5);
  static const Color hoverSurface = Color(0xFFFAFAFA);
  static const Color toggleIcon = Color(0xFF525252);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color live = Color(0xFF16A34A);
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
}

/// Medidas oficiais da barra lateral e cabeçalhos institucionais.
class InstSidebarMetrics {
  const InstSidebarMetrics._();

  static const double topHeaderHeight = 54;
  static const double widthExpanded = 280;
  static const double widthCollapsed = 76;
  static const double itemWidthExpanded = 124;
  static const double itemWidthCollapsed = 52;
  static const double iconSize = 28;
  static const double toggleWidth = 31;
  static const double toggleHeight = 50;
  static const Duration slide = Duration(milliseconds: 300);
  static const Duration hover = Duration(milliseconds: 200);
}

/// Estilos de texto oficiais (Plus Jakarta Sans).
class InstText {
  const InstText._();

  static TextStyle logo({required bool collapsed}) => jakarta(
        size: collapsed ? 18 : 24,
        weight: FontWeight.w700,
        color: InstColors.ink,
        height: 1.15,
      );

  static TextStyle logoSubtitle() => jakarta(
        size: 10,
        weight: FontWeight.w500,
        color: InstColors.muted,
        letterSpacing: 0.8,
      );

  static TextStyle navLabel(Color color) =>
      jakarta(size: 12.5, color: color, height: 1.15);

  static TextStyle pageTitle() => jakarta(size: 18, weight: FontWeight.w500);
}
