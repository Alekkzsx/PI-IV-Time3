// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de cores e tokens de design oficiais do Portal Acadêmico AVA.
class AppColors {
  AppColors._();

  /// Cor de fundo principal do scaffold da aplicação (Slate 50 / cinza claro).
  static const Color background = Color(0xFFF8FAFC); // bg-[#F8FAFC]

  /// Cor de fundo dos cartões, modais e containers de superfície.
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Cor de borda sutil e divisores de conteúdo.
  static const Color borderLight = Color(0xFFE2E8F0);

  /// Cor de borda em estado de foco ativo ou seleção.
  static const Color borderFocused = Color(0xFF0F172A);

  // Slate Palette
  /// Cor de texto primária com alto contraste para títulos e corpo principal (Slate 900).
  static const Color textPrimary = Color(0xFF0F172A); // slate-900

  /// Cor de texto secundária para subtítulos, rótulos e descrições auxiliares (Slate 500).
  static const Color textSecondary = Color(0xFF64748B); // slate-500

  /// Cor de texto atenuada para dicas e elementos desabilitados (Slate 400).
  static const Color textMuted = Color(0xFF94A3B8); // slate-400

  // Primary Action Button
  /// Cor de fundo padrão de botões escuros da interface (Dark Navy / Slate).
  static const Color buttonDark = Color(0xFF0B132B); // Dark Navy / Slate

  /// Cor de estado 'hover' ou pressionado para botões escuros.
  static const Color buttonDarkHover = Color(0xFF1E293B);

  /// Cor primária de destaque para botões de ação principal (Azul marinho ultra-escuro).
  static const Color buttonPrimary = Color(0xFF0B1325); // #0B1325 (Azul marinho ultra-escuro)

  // Hero & Dark Canvas
  /// Cor de fundo profundo cósmico para seções de destaque e hero.
  static const Color heroBackground = Color(0xFF05070B); // #05070B (Preto cósmico profundo)

  // Slate Scale
  /// Tom escuro da escala Slate (Slate 800) para superfícies elevadas.
  static const Color slate800 = Color(0xFF1E293B);

  /// Tom intermediário da escala Slate (Slate 700) para contraste moderado.
  static const Color slate700 = Color(0xFF334155);

  /// Tom claro da escala Slate (Slate 300) para bordas e separadores.
  static const Color slate300 = Color(0xFFCBD5E1);

  // Rose Error Alert (bg-rose-50, border-rose-200, text-rose-700)
  /// Fundo para banners e alertas de erro ou falha de autenticação (Rose 50).
  static const Color roseBackground = Color(0xFFFFF1F2); // bg-rose-50

  /// Borda para caixas de mensagens de erro (Rose 200).
  static const Color roseBorder = Color(0xFFFECDD3); // border-rose-200

  /// Cor tipográfica para mensagens de erro em destaque (Rose 700).
  static const Color roseText = Color(0xFFBE123C); // text-rose-700

  /// Cor de ícones em alertas e mensagens de erro (Rose 600).
  static const Color roseIcon = Color(0xFFE11D48); // rose-600

  // Amber Security Alert
  /// Fundo para caixas de alerta de segurança e avisos operacionais (Amber 50).
  static const Color alertBackground = Color(0xFFFFFBEB); // amber-50

  /// Borda para notificações e alertas em tom de aviso (Amber 200).
  static const Color alertBorder = Color(0xFFFDE68A); // amber-200

  /// Cor tipográfica para avisos de segurança e orientações (Amber 700).
  static const Color alertText = Color(0xFFB45309); // amber-700

  /// Cor de ícones de alerta de atenção (Amber 600).
  static const Color alertIcon = Color(0xFFD97706); // amber-600

  // Segmented Control Tabs
  /// Fundo do controle de abas segmentadas (Segmented Control / Slate 100).
  static const Color tabBackground = Color(0xFFF1F5F9); // slate-100

  /// Fundo da aba selecionada no controle segmentado.
  static const Color tabSelectedBackground = Color(0xFFFFFFFF);

  /// Cor do texto da aba ativa/selecionada.
  static const Color tabSelectedText = Color(0xFF0F172A);

  /// Cor do texto das abas inativas/não selecionadas.
  static const Color tabUnselectedText = Color(0xFF64748B);
}

/// Configuração central de tema Material 3 e tipografia do Portal AVA.
class AppTheme {
  AppTheme._();

  /// Tema claro institucional padrão com Material 3 e família tipográfica Plus Jakarta Sans.
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
