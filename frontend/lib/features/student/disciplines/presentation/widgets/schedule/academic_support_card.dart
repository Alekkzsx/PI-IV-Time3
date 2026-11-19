// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';

/// [AcademicSupportCard]
///
/// Card de Apoio Acadêmico & Recursos Oficiais Universitários.
/// Consome dinamicamente os recursos cadastrados em `admin_settings.academicResources` via MongoDB.
class AcademicSupportCard extends StatelessWidget {
  /// Cria uma nova instância de [AcademicSupportCard].
  const AcademicSupportCard({super.key});

  IconData _resolveIcon(dynamic iconKey) {
    final k = iconKey?.toString().toLowerCase() ?? '';
    if (k.contains('book') || k.contains('biblioteca')) {
      return Icons.menu_book_outlined;
    }
    if (k.contains('laptop') || k.contains('lab') || k.contains('docker')) {
      return Icons.laptop_chromebook_rounded;
    }
    if (k.contains('people') || k.contains('monitoria')) {
      return Icons.people_outline_rounded;
    }
    if (k.contains('download') || k.contains('file') || k.contains('template')) {
      return Icons.file_download_outlined;
    }
    return Icons.link_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final resources = PortalController.instance.academicResources;

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
          if (resources.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text(
                  'Nenhum recurso de apoio cadastrado pela coordenação acadêmica.',
                  style: jakarta(size: 12, color: const Color(0xFF71717A)),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            for (final res in resources)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
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
                        _resolveIcon(res['icon'] ?? res['iconName']),
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
                            (res['title'] ?? res['name'] ?? 'Recurso').toString(),
                            style: jakarta(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (res['desc'] ??
                                    res['description'] ??
                                    res['subtitle'] ??
                                    '')
                                .toString(),
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
                      res['isDownload'] == true
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

typedef StudentAcademicSupportCard = AcademicSupportCard;
