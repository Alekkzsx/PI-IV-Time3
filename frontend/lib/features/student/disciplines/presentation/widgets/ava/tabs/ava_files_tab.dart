// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/models.dart';
import '../common/ava_common.dart';

/// [AvaFilesTab]
///
/// Aba 6 do Cockpit AVA: Repositório de Arquivos e Materiais.
/// Apresenta os arquivos didáticos vindos do backend/MongoDB em grid responsivo
/// de 2 colunas com busca integrada, tags de categoria e download com tooltip regimental.
class AvaFilesTab extends StatefulWidget {
  /// Cria uma nova instância de [AvaFilesTab].
  const AvaFilesTab({super.key});

  @override
  State<AvaFilesTab> createState() => _AvaFilesTabState();
}

class _AvaFilesTabState extends State<AvaFilesTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final controller = StudentPortalController.instance;
    final sourceMaterials =
        controller.selectedDiscipline?.materials ??
        const <StudentMaterialItem>[];

    final filteredMaterials = sourceMaterials.where((mat) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return mat.title.toLowerCase().contains(q) ||
          mat.fileName.toLowerCase().contains(q) ||
          mat.unitAssociated.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvaOpenSectionHeader(
          title: 'Repositório de Arquivos e Materiais',
          subtitle:
              'Baixe slides de aulas, listas de exercícios, templates de código e apostilas oficiais.',
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: SizedBox(
              height: 38,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: jakarta(size: 13, color: const Color(0xFF18181B)),
                decoration: InputDecoration(
                  hintText: 'Buscar material...',
                  hintStyle: jakarta(
                    size: 12.5,
                    color: const Color(0xFFA1A1AA),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: Color(0xFFA1A1AA),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF18181B)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (filteredMaterials.isEmpty)
          AvaEmptyStateCard(
            icon: Icons.folder_open_outlined,
            title: _searchQuery.isEmpty
                ? 'Nenhum material didático disponibilizado'
                : 'Nenhum material encontrado para "$_searchQuery"',
            subtitle: _searchQuery.isEmpty
                ? 'O docente titular ainda não fez o upload de arquivos para esta disciplina.'
                : 'Tente utilizar outras palavras-chave para sua busca.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoColumns = constraints.maxWidth >= 600;
              final halfLength = (filteredMaterials.length / 2).ceil();

              if (!isTwoColumns) {
                return Column(
                  children: [
                    for (final mat in filteredMaterials)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMaterialCard(context, mat),
                      ),
                  ],
                );
              }

              final col1 = filteredMaterials.take(halfLength).toList();
              final col2 = filteredMaterials.skip(halfLength).toList();

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        for (final mat in col1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMaterialCard(context, mat),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        for (final mat in col2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMaterialCard(context, mat),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildMaterialCard(
    BuildContext context,
    StudentMaterialItem material,
  ) {
    final category = _resolveCategory(material);

    return AvaSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 20,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: jakarta(
                      size: 9,
                      weight: FontWeight.w700,
                      color: const Color(0xFF52525B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  material.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${material.size} • Atualizado em ${material.date.isNotEmpty ? material.date : "01/08/2026"}',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip: 'Baixar ${material.fileName}',
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.file_download_outlined,
                size: 16,
                color: Color(0xFF18181B),
              ),
              onPressed: () async {
                try {
                  final path = await StudentPortalController.instance
                      .downloadMaterial(material);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        path == null
                            ? 'O download de "${material.fileName}" ainda não está disponível.'
                            : 'Material salvo em $path',
                      ),
                    ),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'O download de "${material.fileName}" ainda não está disponível.',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _resolveCategory(StudentMaterialItem mat) {
    if (mat.category != null && mat.category!.trim().isNotEmpty) {
      return mat.category!.trim().toUpperCase();
    }
    final text = '${mat.fileName} ${mat.title} ${mat.unitAssociated}'
        .toLowerCase();
    if (text.contains('plano_de_ensino') ||
        text.contains('plano de ensino') ||
        text.contains('oficial')) {
      return 'INSTITUCIONAL';
    }
    if (text.contains('aula') || text.contains('slide')) {
      return 'SLIDES DE AULA';
    }
    if (text.contains('guia') ||
        text.contains('uml') ||
        text.contains('complementar')) {
      return 'MATERIAL COMPLEMENTAR';
    }
    if (text.contains('template') ||
        text.contains('spring') ||
        text.contains('codigo') ||
        text.contains('.zip')) {
      return 'LABORATÓRIOS & CÓDIGOS';
    }
    if (text.contains('lista') ||
        text.contains('exercicio') ||
        text.contains('padroes')) {
      return 'EXERCÍCIOS';
    }
    if (text.contains('artigo') ||
        text.contains('leitura') ||
        text.contains('livro')) {
      return 'LEITURAS OBRIGATÓRIAS';
    }
    return 'MATERIAL DIDÁTICO';
  }
}
