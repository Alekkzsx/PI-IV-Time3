// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// [AvaBannerSurfaceCard]
///
/// Cartão institucional canônico do Cockpit AVA com cabeçalho superior em tom
/// areia quente (`#FAF8F5`), divisória horizontal de `1px #E5E7EB` e corpo branco
/// puro (`#FFFFFF`), seguindo fielmente a estética unificada das telas de referência.
class AvaBannerSurfaceCard extends StatelessWidget {
  /// Tag regimental em caixa alta exibida acima do título (ex.: `'UNIDADE 1 • 40 HORAS'`).
  final String? overlineTag;

  /// Título principal do cabeçalho do cartão.
  final String title;

  /// Subtítulo complementar opcional exibido abaixo do título no banner.
  final String? subtitle;

  /// Widget opcional alinhado à direita do cabeçalho (ex.: contador, status badge ou ação).
  final Widget? headerTrailing;

  /// Conteúdo principal renderizado na superfície branca inferior.
  final Widget child;

  /// Espaçamento interno do corpo branco (padrão: `EdgeInsets.all(16)`).
  final EdgeInsetsGeometry bodyPadding;

  /// Widget opcional exibido à esquerda do título no banner.
  final Widget? bannerLeading;

  /// Espaçamento interno do banner superior `#FAF8F5`.
  final EdgeInsetsGeometry headerPadding;

  /// Margem externa opcional do cartão.
  final EdgeInsetsGeometry? margin;

  /// Cria uma nova instância de [AvaBannerSurfaceCard].
  const AvaBannerSurfaceCard({
    super.key,
    this.overlineTag,
    String? title,
    String? bannerTitle,
    this.subtitle,
    Widget? headerTrailing,
    Widget? bannerBadge,
    this.bannerLeading,
    Widget? child,
    Widget? body,
    this.bodyPadding = const EdgeInsets.all(16),
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.margin,
  })  : title = title ?? bannerTitle ?? '',
        headerTrailing = headerTrailing ?? bannerBadge,
        child = child ?? body ?? const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overlineTag != null && overlineTag!.trim().isNotEmpty) ...[
          Text(
            overlineTag!.toUpperCase(),
            style: jakarta(
              size: 10,
              weight: FontWeight.w700,
              color: const Color(0xFF71717A),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          title,
          style: jakarta(
            size: 14.5,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: jakarta(
              size: 12,
              weight: FontWeight.w400,
              color: const Color(0xFF71717A),
            ),
          ),
        ],
      ],
    );

    final titleBlock = bannerLeading == null
        ? textBlock
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              bannerLeading!,
              const SizedBox(width: 10),
              Expanded(child: textBlock),
            ],
          );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: headerPadding,
            decoration: const BoxDecoration(
              color: Color(0xFFFAF8F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: headerTrailing == null
                ? titleBlock
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 460) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleBlock,
                            const SizedBox(height: 8),
                            headerTrailing!,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: titleBlock),
                          const SizedBox(width: 12),
                          headerTrailing!,
                        ],
                      );
                    },
                  ),
          ),
          Padding(
            padding: bodyPadding,
            child: child,
          ),
        ],
      ),
    );
  }
}
