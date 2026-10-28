// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Atalho tipográfico da família Plus Jakarta Sans usada nos portais institucionais.
///
/// Possui fallback seguro para a família nominal caso o carregamento via
/// Google Fonts falhe (ex.: ambiente de testes ou sem rede).
TextStyle jakarta({
  required double size,
  FontWeight weight = FontWeight.w400,
  Color color = const Color(0xFF1A1A1A),
  double? letterSpacing,
  double? height,
  TextDecoration? decoration,
}) {
  try {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  } catch (_) {
    return TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
}

