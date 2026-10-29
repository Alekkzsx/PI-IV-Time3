// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Estrutura padronizada de modais/diálogos institucionais para o portal acadêmico.
class AcademicModalDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isConfirmDestructive;
  final bool isLoading;
  final double maxWidth;
  final List<Widget>? customActions;

  const AcademicModalDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
    this.cancelLabel = 'Cancelar',
    this.confirmLabel = 'Salvar',
    this.onCancel,
    this.onConfirm,
    this.isConfirmDestructive = false,
    this.isLoading = false,
    this.maxWidth = 580,
    this.customActions,
  });

  /// Exibe o diálogo com estilo modal padronizado.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: InstColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho do Modal
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 20, color: InstColors.ink),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: jakarta(
                                size: 17,
                                weight: FontWeight.w700,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle!,
                                style: jakarta(
                                  size: 13,
                                  color: const Color(0xFF71717A),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF71717A)),
                        onPressed: () {
                          if (onCancel != null) {
                            onCancel!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),

                // Conteúdo rolável
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),

                // Rodapé de Ações
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: customActions ??
                        [
                          OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : (onCancel ?? () => Navigator.of(context).pop()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3F3F46),
                              side: const BorderSide(color: InstColors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              cancelLabel,
                              style: jakarta(size: 13.5, weight: FontWeight.w600),
                            ),
                          ),
                          if (onConfirm != null) ...[
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: isLoading ? null : onConfirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isConfirmDestructive
                                    ? InstColors.danger
                                    : InstColors.ink,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      confirmLabel,
                                      style: jakarta(size: 13.5, weight: FontWeight.w600),
                                    ),
                            ),
                          ],
                        ],
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
