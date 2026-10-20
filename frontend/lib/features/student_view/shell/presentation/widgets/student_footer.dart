// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';

/// Rodapé institucional fixado na base do portal do estudante.
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
        horizontal: isDesktop ? 48 : 20,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: const [
              Text(
                '© 2026 AGMRM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
              Text(
                '|',
                style: TextStyle(fontSize: 10, color: Color(0xFFD4D4D8)),
              ),
              Text(
                'Portal AVA AGMRM • Ambiente Virtual de Aprendizagem Universitário',
                style: TextStyle(fontSize: 10, color: Color(0xFFA3A3A3)),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Ajuda',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFA3A3A3),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Privacidade',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFA3A3A3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

