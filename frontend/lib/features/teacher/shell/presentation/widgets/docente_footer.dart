// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';

/// Rodapé institucional padronizado e reutilizável para todas as telas do Portal Docente.
/// Mantém a identidade corporativa do portal AVA AGMRM com links institucionais e suporte.
class DocenteFooter extends StatelessWidget {
  final EdgeInsetsGeometry? padding;

  const DocenteFooter({super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: DocenteColors.surface,
        border: Border(top: BorderSide(color: Color(0xFFE4E4E7), width: 1)),
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
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Central de Ajuda ao Docente: suporte@agmrm.edu.br',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
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
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Termos de Privacidade e Proteção de Dados (LGPD) • AGMRM 2026',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
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
                const SizedBox(height: 10),
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
}
