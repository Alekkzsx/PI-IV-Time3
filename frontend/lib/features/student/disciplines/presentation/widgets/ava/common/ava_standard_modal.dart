// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// [AvaStandardModal]
///
/// Modal institucional canônico do ecossistema AVA do estudante.
/// Unifica todos os diálogos com superfície `#FFFFFF`, borda `#E5E7EB`,
/// cabeçalho superior em areia quente `#FAF8F5`, rolagem segura em mobile (`390x844`)
/// e rodapé opcional de ações em pílula.
class AvaStandardModal extends StatelessWidget {
  /// Tag opcional em caixa alta exibida acima do título do modal.
  final String? overlineTag;

  /// Título principal do modal.
  final String title;

  /// Subtítulo descritivo opcional.
  final String? subtitle;

  /// Conteúdo central rolável do modal.
  final Widget child;

  /// Lista opcional de botões de ação exibidos no rodapé.
  final List<Widget>? actions;

  /// Largura máxima do modal em telas desktop (padrão: `640`).
  final double maxWidth;

  /// Espaçamento interno do corpo (padrão: `EdgeInsets.all(20)`).
  final EdgeInsetsGeometry bodyPadding;

  /// Cria uma nova instância de [AvaStandardModal].
  const AvaStandardModal({
    super.key,
    this.overlineTag,
    required this.title,
    this.subtitle,
    Widget? child,
    Widget? content,
    this.actions,
    this.maxWidth = 640,
    this.bodyPadding = const EdgeInsets.all(20),
  }) : child = child ?? content ?? const SizedBox.shrink();

  /// Exibe o modal padronizado do AVA via [showDialog].
  static Future<T?> show<T>({
    required BuildContext context,
    String? overlineTag,
    required String title,
    String? subtitle,
    required WidgetBuilder builder,
    List<Widget>? actions,
    double maxWidth = 640,
    EdgeInsetsGeometry bodyPadding = const EdgeInsets.all(20),
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => AvaStandardModal(
        overlineTag: overlineTag,
        title: title,
        subtitle: subtitle,
        actions: actions,
        maxWidth: maxWidth,
        bodyPadding: bodyPadding,
        child: builder(dialogContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 520;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: isCompact ? 16 : 28,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: screenSize.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF8F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (overlineTag != null &&
                            overlineTag!.trim().isNotEmpty) ...[
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
                            size: 16.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        if (subtitle != null &&
                            subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: jakarta(
                              size: 12.5,
                              weight: FontWeight.w400,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Fechar',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: bodyPadding,
                child: child,
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(15),
                  ),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
