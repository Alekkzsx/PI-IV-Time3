// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'package:pi_iv_time3/features/student/shared/models/student_models.dart';
import 'ava_section_card.dart';

/// Abas do AVA para Módulos, Arquivos e Materiais, Programa (Syllabus) e Colaborações em Equipe.
class AvaSyllabusMaterialsTab extends StatelessWidget {
  final int activeTabIndex;

  const AvaSyllabusMaterialsTab({super.key, required this.activeTabIndex});

  @override
  Widget build(BuildContext context) {
    switch (activeTabIndex) {
      case 0:
        return _buildModulesTab(context);
      case 6:
        return _buildFilesTab(context);
      case 7:
        return _buildSyllabusTab();
      case 8:
        return _buildCollaborationsTab();
      default:
        return _buildModulesTab(context);
    }
  }

  // --- ABA 1: Módulos & Conteúdos ---
  Widget _buildModulesTab(BuildContext context) {
    final modules =
        StudentPortalController.instance.selectedDiscipline?.syllabusUnits ??
        const <Map<String, dynamic>>[];

    return Column(
      children: modules.isEmpty
          ? const [AvaSectionCard(child: Text('Nenhum módulo publicado.'))]
          : modules.map((m) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ExpansionTile(
              backgroundColor: Colors.white,
              collapsedBackgroundColor: Colors.white,
              title: Text(
                (m['title'] ?? m['name'] ?? 'Unidade').toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                '${m['week'] ?? m['period'] ?? ''} • ${m['lessons'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              trailing: Chip(
                label: Text(
                  (m['status'] ?? '').toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: m['status'] == 'Concluído'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF18181B),
                  ),
                ),
                backgroundColor: m['status'] == 'Concluído'
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFF1F5F9),
              ),
              children: const [],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- ABA 7: Arquivos & Materiais ---
  Widget _buildFilesTab(BuildContext context) {
    final controller = StudentPortalController.instance;
    final materials = controller.selectedDiscipline?.materials ?? const [];
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AvaSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Repositório Institucional de Arquivos e Slides',
                style: AvaSectionStyles.title,
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // Materiais publicados pelo docente
              if (materials.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nenhum material disponível para download.'),
                ),
              for (final material in materials)
                _buildFileRow(context, material),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileRow(BuildContext context, StudentMaterialItem material) {
    return ListTile(
      leading: const Icon(Icons.insert_drive_file, color: Color(0xFF18181B)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              material.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${material.courseCode} • ${material.fileType} • ${material.size}',
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      trailing: IconButton(
        tooltip: 'Baixar ${material.fileName}',
        icon: const Icon(Icons.file_download_outlined),
        onPressed: () async {
          try {
            final path = await StudentPortalController.instance
                .downloadMaterial(material);
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
        },
      ),
    );
  }

  // --- ABA 8: Programa / Syllabus ---
  Widget _buildSyllabusTab() {
    final discipline = StudentPortalController.instance.selectedDiscipline;
    final units = discipline?.syllabusUnits ?? const <Map<String, dynamic>>[];
    return AvaSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Programa da Disciplina${discipline == null ? '' : ' • ${discipline.name}'}',
            style: AvaSectionStyles.title,
          ),
          const SizedBox(height: 16),
          if (units.isEmpty)
            const Text('O plano de ensino não possui unidades publicadas.')
          else
            for (final unit in units)
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(
                  (unit['title'] ?? unit['name'] ?? 'Unidade').toString(),
                ),
                subtitle: Text(
                  (unit['description'] ?? unit['topics'] ?? '').toString(),
                ),
              ),
        ],
      ),
    );
  }

  // --- ABA 9: Colaborações ---
  Widget _buildCollaborationsTab() {
    final squads =
        StudentPortalController.instance.selectedDiscipline?.squads ??
        const <Map<String, dynamic>>[];
    return AvaSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grupos de trabalho',
            style: AvaSectionStyles.title,
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (squads.isEmpty)
            const Text('Nenhum grupo foi cadastrado para esta disciplina.')
          else
            for (final squad in squads)
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text(
                  (squad['name'] ?? squad['title'] ?? 'Grupo').toString(),
                ),
                subtitle: Text(
                  (squad['members'] ?? '').toString(),
                ),
              ),
        ],
      ),
    );
  }
}
