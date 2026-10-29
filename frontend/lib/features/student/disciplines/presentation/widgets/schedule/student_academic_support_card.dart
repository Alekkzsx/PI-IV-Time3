// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Card de Apoio Acadêmico & Recursos Oficiais
class StudentAcademicSupportCard extends StatelessWidget {
  const StudentAcademicSupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final resources = [
      {
        'icon': Icons.menu_book_outlined,
        'title': 'Biblioteca Virtual Universitária',
        'desc': 'Mais de 15.000 títulos técnicos Pearson & Minha Biblioteca',
        'isDownload': false,
      },
      {
        'icon': Icons.laptop_chromebook_rounded,
        'title': 'Laboratórios Virtuais & Docker',
        'desc': 'Ambientes conteinerizados de PostgreSQL e Linux',
        'isDownload': false,
      },
      {
        'icon': Icons.people_outline_rounded,
        'title': 'Monitoria & Nivelamento',
        'desc': 'Plantões com discentes bolsistas de Seg a Sex',
        'isDownload': false,
      },
      {
        'icon': Icons.file_download_outlined,
        'title': 'Templates Oficiais ABNT & TCC',
        'desc': 'Modelos LaTeX e Word aprovados pelo Colegiado',
        'isDownload': true,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apoio Acadêmico & Recursos Oficiais',
            style: jakarta(
              size: 16,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Serviços integrados de suporte ao aprendizado e pesquisa.',
            style: jakarta(
              size: 11.5,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 16),
          for (final res in resources)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      res['icon'] as IconData,
                      size: 18,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res['title'] as String,
                          style: jakarta(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          res['desc'] as String,
                          style: jakarta(
                            size: 11,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    (res['isDownload'] as bool)
                        ? Icons.download_rounded
                        : Icons.open_in_new_rounded,
                    size: 16,
                    color: const Color(0xFFA1A1AA),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
