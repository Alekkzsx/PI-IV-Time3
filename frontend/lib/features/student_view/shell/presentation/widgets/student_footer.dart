// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Rodapé institucional padronizado do Portal AVA (Visão do Aluno).
class StudentFooter extends StatelessWidget {
  final bool isDesktop;

  const StudentFooter({
    super.key,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE4E4E7), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '© 2026 AGMRM',
                style: jakarta(
                  size: 11,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '|',
                style: jakarta(
                  size: 11,
                  color: const Color(0xFFD4D4D8),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Portal AVA AGMRM • Ambiente Virtual de Aprendizagem Universitário',
                style: jakarta(
                  size: 11,
                  color: const Color(0xFF71717A),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Central de Ajuda do Estudante aberta.'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(
                  'Ajuda',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w500,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Termos de Privacidade e LGPD abertos.'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(
                  'Privacidade',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w500,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
