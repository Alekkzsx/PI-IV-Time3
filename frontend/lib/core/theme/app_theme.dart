// Desenvolvido por Marcelo Zarpelon. RA 25015323

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFF8FAFC); // bg-[#F8FAFC]
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF0F172A);

  // Slate Palette
  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF64748B); // slate-500
  static const Color textMuted = Color(0xFF94A3B8); // slate-400

  // Primary Action Button
  static const Color buttonDark = Color(0xFF0B132B); // Dark Navy / Slate
  static const Color buttonDarkHover = Color(0xFF1E293B);
  static const Color buttonPrimary = Color(0xFF0B1325); // #0B1325 (Azul marinho ultra-escuro)

  // Hero & Dark Canvas
  static const Color heroBackground = Color(0xFF05070B); // #05070B (Preto cósmico profundo)

  // Slate Scale
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate300 = Color(0xFFCBD5E1);

  // Rose Error Alert (bg-rose-50, border-rose-200, text-rose-700)
  static const Color roseBackground = Color(0xFFFFF1F2); // bg-rose-50
  static const Color roseBorder = Color(0xFFFECDD3); // border-rose-200
  static const Color roseText = Color(0xFFBE123C); // text-rose-700
  static const Color roseIcon = Color(0xFFE11D48); // rose-600

  // Amber Security Alert
  static const Color alertBackground = Color(0xFFFFFBEB); // amber-50
  static const Color alertBorder = Color(0xFFFDE68A); // amber-200
  static const Color alertText = Color(0xFFB45309); // amber-700
  static const Color alertIcon = Color(0xFFD97706); // amber-600

  // Segmented Control Tabs
  static const Color tabBackground = Color(0xFFF1F5F9); // slate-100
  static const Color tabSelectedBackground = Color(0xFFFFFFFF);
  static const Color tabSelectedText = Color(0xFF0F172A);
  static const Color tabUnselectedText = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.buttonPrimary,
        surface: AppColors.cardBackground,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          height: 1.2,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
