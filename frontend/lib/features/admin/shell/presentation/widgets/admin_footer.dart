// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Rodapé institucional padronizado e reutilizável para todas as telas do Painel Administrativo.
/// Mantém a identidade corporativa do portal AVA AGMRM com links de Ajuda e Privacidade.
class AdminFooter extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onHelpTap;
  final VoidCallback? onPrivacyTap;

  const AdminFooter({
    super.key,
    this.padding,
    this.onHelpTap,
    this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          final copyrightSection = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '© 2026 AGMRM',
                style: jakarta(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '|',
                style: jakarta(
                  size: 11.5,
                  weight: FontWeight.w400,
                  color: const Color(0xFFD4D4D8),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Portal AVA AGMRM • Ambiente Virtual de Aprendizagem Universitário',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF737373),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

          final linksSection = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onHelpTap ??
                    () => _showInformationDialog(
                      context,
                      title: 'Central de ajuda',
                      message:
                          'Para suporte administrativo, entre em contato com a DTI pelo canal institucional.',
                    ),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Ajuda',
                    style: jakarta(
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: const Color(0xFF737373),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: onPrivacyTap ??
                    () => _showInformationDialog(
                      context,
                      title: 'Privacidade',
                      message:
                          'O tratamento de dados segue as políticas institucionais de Governança e LGPD.',
                    ),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Privacidade',
                    style: jakarta(
                      size: 11.5,
                      weight: FontWeight.w500,
                      color: const Color(0xFF737373),
                    ),
                  ),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copyrightSection,
                const SizedBox(height: 12),
                linksSection,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: copyrightSection),
              const SizedBox(width: 16),
              linksSection,
            ],
          );
        },
      ),
    );
  }

  void _showInformationDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}
