// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/student_models.dart';

/// Aba "Página Inicial" do AVA: Módulos & Conteúdos de Aprendizagem.
/// Exibe os cartões das unidades didáticas com banner superior e lista de itens didáticos.
class StudentAvaHomeTab extends StatelessWidget {
  final StudentDisciplineModel discipline;
  final VoidCallback onNavigateToAssignments;

  const StudentAvaHomeTab({
    super.key,
    required this.discipline,
    required this.onNavigateToAssignments,
  });

  @override
  Widget build(BuildContext context) {
    final units = discipline.syllabusUnits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Módulos & Conteúdos de Aprendizagem',
          style: jakarta(
            size: 20,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Acesse as unidades didáticas, assista às videoaulas e baixe os materiais disponibilizados pelo professor.',
          style: jakarta(
            size: 13,
            weight: FontWeight.w400,
            color: const Color(0xFF71717A),
          ),
        ),
        const SizedBox(height: 20),
        if (units.isEmpty)
          _buildEmptyUnits()
        else
          for (var uIdx = 0; uIdx < units.length; uIdx++)
            _buildUnitCard(context, units[uIdx], uIdx),
      ],
    );
  }

  Widget _buildEmptyUnits() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Center(
        child: Text(
          'Nenhuma unidade didática cadastrada para esta disciplina.',
          style: jakarta(size: 13, color: const Color(0xFF71717A)),
        ),
      ),
    );
  }

  Widget _buildUnitCard(
    BuildContext context,
    Map<String, dynamic> unit,
    int uIndex,
  ) {
    final rawItems = unit['items'];
    final List<Map<String, dynamic>> items;

    if (rawItems is List && rawItems.isNotEmpty) {
      items = rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      // Fallback para materiais cadastrados no modelo
      final uNum = unit['unitNumber'] ?? (uIndex + 1);
      final unitTitle = (unit['title'] ?? unit['name'] ?? '').toString();
      final unitMaterials = discipline.materials.where((m) {
        final ua = m.unitAssociated.toLowerCase();
        return ua.contains('unidade $uNum') ||
            ua.contains('unidade 1') && uNum == 1 ||
            ua == unitTitle.toLowerCase() ||
            (uNum == 1 && discipline.materials.length == 1);
      }).toList();

      items = [
        for (final m in unitMaterials)
          {
            'id': m.id,
            'type': m.fileType.toLowerCase(),
            'title': m.title,
            'subtitle': '${m.fileType} • ${m.size}',
            'actionType': 'access',
            'material': m,
          },
      ];
    }

    final tagText = (unit['tag'] ??
            'UNIDADE ${unit['unitNumber'] ?? (uIndex + 1)} • ${unit['hours'] ?? 20} HORAS LETIVAS')
        .toString();
    final titleText =
        (unit['title'] ?? unit['name'] ?? 'Unidade ${uIndex + 1}').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
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
          // Banner Superior da Unidade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF8F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: Color(0xFFE4E4E7))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tagText,
                        style: jakarta(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF52525B),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        titleText,
                        style: jakarta(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${items.length} itens didáticos',
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),

          // Itens Didáticos da Unidade
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
              child: Text(
                'Nenhum item didático publicado para esta unidade.',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
              _buildItemRow(context, items[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, Map<String, dynamic> item) {
    final type = (item['type'] ?? 'pdf').toString().toLowerCase();
    final actionType = (item['actionType'] ?? '').toString().toLowerCase();
    final isTask = type == 'task' || actionType == 'delivery';

    final actionButton = isTask
        ? OutlinedButton(
            onPressed: onNavigateToAssignments,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFBEB),
              side: const BorderSide(color: Color(0xFFFDE68A)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Ver Entrega',
              style: jakarta(
                size: 11,
                weight: FontWeight.w600,
                color: const Color(0xFFB45309),
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: () => _handleItemAccess(context, item),
            icon: const Icon(
              Icons.download_rounded,
              size: 12,
              color: Color(0xFF18181B),
            ),
            label: Text(
              'Acessar',
              style: jakarta(
                size: 11,
                weight: FontWeight.w600,
                color: const Color(0xFF18181B),
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE4E4E7)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4D4D8),
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTypeIcon(type),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']?.toString() ?? '',
                            style: jakarta(
                              size: 13,
                              weight: FontWeight.w600,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['subtitle']?.toString() ?? '',
                            style: jakarta(
                              size: 11.5,
                              weight: FontWeight.w400,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: actionButton),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4D4D8),
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildTypeIcon(type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']?.toString() ?? '',
                      style: jakarta(
                        size: 13,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['subtitle']?.toString() ?? '',
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w400,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              actionButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    switch (type) {
      case 'video':
        return const Icon(
          Icons.videocam_outlined,
          size: 18,
          color: Color(0xFF2563EB),
        );
      case 'task':
        return const Icon(
          Icons.access_time_rounded,
          size: 16,
          color: Color(0xFFF59E0B),
        );
      case 'reading':
        return const Icon(
          Icons.menu_book_outlined,
          size: 17,
          color: Color(0xFF8B5CF6),
        );
      case 'code':
        return const Icon(
          Icons.code_rounded,
          size: 17,
          color: Color(0xFF2563EB),
        );
      case 'archive':
        return const Icon(
          Icons.folder_open_outlined,
          size: 17,
          color: Color(0xFF52525B),
        );
      default:
        return const Icon(
          Icons.description_outlined,
          size: 17,
          color: Color(0xFF52525B),
        );
    }
  }

  void _handleItemAccess(BuildContext context, Map<String, dynamic> item) async {
    final material = item['material'] as StudentMaterialItem?;
    if (material != null) {
      try {
        final path = await StudentPortalController.instance.downloadMaterial(material);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              path == null
                  ? 'Não foi possível salvar o material.'
                  : 'Material salvo em $path',
            ),
          ),
        );
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Abrindo ${item['title'] ?? "material"}...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
