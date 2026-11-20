// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';

/// Seção dedicada aos 6 blocos de código OTP enviados por e-mail.
///
/// Garante centralização geométrica e óptica sub-pixel dos dígitos (evitando
/// deslocamento por métricas de descendentes ou largura de cursor) e oferece
/// sinalização clara de progresso, foco, código completo, erro inline e dica
/// de colagem/validade do e-mail.
class OtpCodeInputSection extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool enabled;
  final bool isComplete;
  final bool isVerifying;
  final String? errorMessage;
  final void Function(String value, int index) onDigitChanged;
  final void Function(KeyEvent event, int index) onKeyEvent;
  final VoidCallback onClear;

  const OtpCodeInputSection({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.enabled,
    required this.isComplete,
    required this.isVerifying,
    required this.errorMessage,
    required this.onDigitChanged,
    required this.onKeyEvent,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final totalDigits = controllers.length;
    final filledCount = controllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;
    final hasAnyDigit = filledCount > 0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 356),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho de sinalização e progresso do código
          Row(
            children: [
              const Icon(
                Icons.mail_lock_outlined,
                size: 14,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CÓDIGO DE 6 DÍGITOS',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _OtpStatusPill(
                filledCount: filledCount,
                totalDigits: totalDigits,
                isComplete: isComplete,
                isVerifying: isVerifying,
                hasError: hasError,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grade dos 6 blocos OTP com separador central responsivo (3 - 3)
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth
                  .clamp(0.0, 356.0)
                  .toDouble();
              final showSeparator = availableWidth >= 330;
              final separatorWidth = showSeparator ? 14.0 : 0.0;
              final gap = availableWidth >= 330 ? 8.0 : 4.0;
              final totalGaps = (totalDigits - 1) * gap;
              final digitWidth =
                  ((availableWidth - totalGaps - separatorWidth) / totalDigits)
                      .clamp(36.0, 50.0)
                      .toDouble();
              final digitHeight = availableWidth >= 330 ? 56.0 : 50.0;

              final children = <Widget>[];
              for (int index = 0; index < totalDigits; index++) {
                if (index > 0) {
                  if (showSeparator && index == 3) {
                    children.add(
                      Container(
                        width: 8,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: hasError
                              ? const Color(0xFFFCA5A5)
                              : isComplete
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  } else {
                    children.add(SizedBox(width: gap));
                  }
                }

                children.add(
                  _OtpDigitSlot(
                    index: index,
                    totalDigits: totalDigits,
                    width: digitWidth,
                    height: digitHeight,
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    enabled: enabled,
                    isComplete: isComplete,
                    hasError: hasError,
                    onChanged: (val) => onDigitChanged(val, index),
                    onKeyEvent: (event) => onKeyEvent(event, index),
                  ),
                );
              }

              return SizedBox(
                width: availableWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: children,
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Sinalização contextual abaixo dos blocos (erro inline ou orientação)
          if (hasError)
            _OtpErrorBanner(
              message: errorMessage!,
              showClearAction: hasAnyDigit && enabled,
              onClear: onClear,
            )
          else
            _OtpHintBar(
              showClearAction: hasAnyDigit && enabled,
              onClear: onClear,
            ),
        ],
      ),
    );
  }
}

class _OtpStatusPill extends StatelessWidget {
  final int filledCount;
  final int totalDigits;
  final bool isComplete;
  final bool isVerifying;
  final bool hasError;

  const _OtpStatusPill({
    required this.filledCount,
    required this.totalDigits,
    required this.isComplete,
    required this.isVerifying,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color border;
    final Color foreground;
    final String label;
    final Widget? leading;

    if (isVerifying) {
      background = const Color(0xFFF1F5F9);
      border = const Color(0xFFCBD5E1);
      foreground = const Color(0xFF334155);
      label = 'Validando...';
      leading = const SizedBox(
        width: 11,
        height: 11,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF334155)),
        ),
      );
    } else if (hasError) {
      background = AppColors.roseBackground;
      border = AppColors.roseBorder;
      foreground = AppColors.roseText;
      label = 'Verifique o código';
      leading = const Icon(
        Icons.error_rounded,
        size: 13,
        color: AppColors.roseIcon,
      );
    } else if (isComplete) {
      background = const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      foreground = const Color(0xFF047857);
      label = 'Pronto para validar';
      leading = const Icon(
        Icons.check_circle_rounded,
        size: 13,
        color: Color(0xFF059669),
      );
    } else {
      background = const Color(0xFFF1F5F9);
      border = const Color(0xFFE2E8F0);
      foreground = const Color(0xFF475569);
      label = '$filledCount de $totalDigits dígitos';
      leading = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 5)],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpDigitSlot extends StatelessWidget {
  final int index;
  final int totalDigits;
  final double width;
  final double height;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isComplete;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpDigitSlot({
    required this.index,
    required this.totalDigits,
    required this.width,
    required this.height,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isComplete,
    required this.hasError,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    final digit = controller.text.trim();
    final hasDigit = digit.isNotEmpty;

    final Color backgroundColor;
    final Color borderColor;
    final double borderWidth;
    final Color digitColor;
    final List<BoxShadow> shadows;

    if (!enabled) {
      backgroundColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFE2E8F0);
      borderWidth = 1.2;
      digitColor = const Color(0xFF64748B);
      shadows = const [];
    } else if (hasError) {
      backgroundColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFEF4444);
      borderWidth = isFocused ? 2.0 : 1.6;
      digitColor = const Color(0xFFB91C1C);
      shadows = [
        BoxShadow(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          blurRadius: 6,
          spreadRadius: isFocused ? 1.5 : 0,
          offset: const Offset(0, 1),
        ),
      ];
    } else if (isComplete && !isFocused) {
      backgroundColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFF10B981);
      borderWidth = 1.5;
      digitColor = const Color(0xFF065F46);
      shadows = [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          blurRadius: 5,
          offset: const Offset(0, 1),
        ),
      ];
    } else if (isFocused) {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFF0F172A);
      borderWidth = 2.0;
      digitColor = const Color(0xFF0F172A);
      shadows = [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.09),
          blurRadius: 8,
          spreadRadius: 1.5,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (hasDigit) {
      backgroundColor = const Color(0xFFF8FAFC);
      borderColor = const Color(0xFF94A3B8);
      borderWidth = 1.4;
      digitColor = const Color(0xFF0F172A);
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];
    } else {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFCBD5E1);
      borderWidth = 1.2;
      digitColor = const Color(0xFF0F172A);
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];
    }

    return Semantics(
      label: 'Dígito ${index + 1} de $totalDigits',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => focusNode.requestFocus() : null,
        child: Focus(
          onKeyEvent: (node, event) {
            onKeyEvent(event);
            return KeyEventResult.ignored;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: shadows,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camada interativa nativa sempre na posição 0 com chave estável
                // (evita remontagem do EditableTextState ao alternar foco/dígito)
                Positioned.fill(
                  key: ValueKey('otp-input-$index'),
                  child: Center(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      showCursor: true,
                      cursorColor: hasDigit
                          ? Colors.transparent
                          : hasError
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0F172A),
                      cursorHeight: 22,
                      cursorWidth: 2,
                      cursorRadius: const Radius.circular(1),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      scrollPadding: EdgeInsets.zero,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        color: Colors.transparent,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: false,
                        fillColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                ),

                // Camada visual de exibição: centralização óptica e geométrica exata
                if (hasDigit)
                  IgnorePointer(
                    child: Text(
                      digit,
                      textAlign: TextAlign.center,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: digitColor,
                      ).copyWith(
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                    ),
                  )
                else if (!isFocused)
                  IgnorePointer(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: hasError
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                // Indicador sutil inferior de foco ativo
                if (isFocused && enabled)
                  Positioned(
                    bottom: 6,
                    child: IgnorePointer(
                      child: Container(
                        width: 18,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: hasError
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpErrorBanner extends StatelessWidget {
  final String message;
  final bool showClearAction;
  final VoidCallback onClear;

  const _OtpErrorBanner({
    required this.message,
    required this.showClearAction,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.roseBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.roseBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.roseIcon,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.roseText,
              ),
            ),
          ),
          if (showClearAction) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Limpar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.roseText,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.roseText,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OtpHintBar extends StatelessWidget {
  final bool showClearAction;
  final VoidCallback onClear;

  const _OtpHintBar({required this.showClearAction, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 14,
          color: Color(0xFF64748B),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Cole o código do e-mail (Ctrl+V) • Válido por 5 min — confira também o Spam.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              height: 1.4,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        if (showClearAction) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'Limpar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
