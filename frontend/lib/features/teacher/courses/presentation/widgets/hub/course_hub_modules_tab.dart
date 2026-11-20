// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'course_hub_ui.dart';

/// Aba de módulos didáticos, progresso programático e repositório de materiais da turma.
class CourseHubModulesTab extends StatefulWidget {
  final DocenteCourse course;
  final DocenteController controller;
  final VoidCallback onAddContent;

  const CourseHubModulesTab({
    super.key,
    required this.course,
    required this.controller,
    required this.onAddContent,
  });

  @override
  State<CourseHubModulesTab> createState() => _CourseHubModulesTabState();
}

class _CourseHubModulesTabState extends State<CourseHubModulesTab> {
  String _selectedCategory = 'Todos';

  static const List<String> _categories = [
    'Todos',
    'Slides de Aula',
    'Institucional',
    'Material Complementar',
    'Laboratórios & Códigos',
  ];

  Future<void> _downloadMaterial(
    BuildContext context,
    CourseMaterial mat,
  ) async {
    final res = await widget.controller.downloadMaterial(mat.id);
    if (!context.mounted) return;
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível baixar o material selecionado.'),
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
      return;
    }
    final b64 = res['contentBase64']?.toString() ?? '';
    final bytes = b64.isNotEmpty
        ? base64Decode(b64)
        : Uint8List.fromList(utf8.encode(mat.title));
    await PlatformFileHelper.saveAndLaunchFile(
      bytes: bytes,
      fileName: res['fileName']?.toString() ??
          (mat.fileName.isNotEmpty ? mat.fileName : '${mat.title}.txt'),
      mimeType: 'application/octet-stream',
    );
  }

  Future<void> _confirmDeleteMaterial(
    BuildContext context,
    CourseMaterial mat,
  ) async {
    final confirmed = await CourseHubModal.show<bool>(
      context: context,
      overlineTag: 'CONFIRMAÇÃO',
      title: 'Remover material didático',
      subtitle: mat.title,
      maxWidth: 440,
      actionsBuilder: (ctx) => [
        CourseHubPillButton(
          label: 'Cancelar',
          variant: CourseHubButtonVariant.secondary,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        CourseHubPillButton(
          label: 'Remover arquivo',
          variant: CourseHubButtonVariant.danger,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
      builder: (_) => Text(
        'O material deixará de aparecer no Repositório e nos Módulos dos discentes desta turma.',
        style: jakarta(size: 13, color: const Color(0xFF52525B)),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final removed = await widget.controller.deleteMaterial(
      widget.course.id,
      mat.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed
              ? 'Material removido com sucesso.'
              : (widget.controller.remoteError ??
                    'Erro ao remover material.'),
        ),
        backgroundColor: removed
            ? const Color(0xFF166534)
            : const Color(0xFFB91C1C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final units = widget.course.syllabusUnits;
    final filteredMaterials = widget.course.materials.where((mat) {
      if (_selectedCategory == 'Todos') return true;
      return mat.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CourseHubSectionHeader(
          overline: 'CONTEÚDO PROGRAMÁTICO • ${widget.course.code}',
          title: 'Módulos, Unidades e Materiais',
          subtitle:
              'Organize unidades didáticas, avance a carga horária cumprida e publique apostilas visíveis aos alunos.',
          trailing: CourseHubPillButton(
            label: 'Publicar Material',
            icon: Icons.upload_file_outlined,
            onPressed: widget.onAddContent,
          ),
        ),
        const SizedBox(height: 18),

        // Progresso da carga horária
        CourseHubSurfaceCard(
          overlineTag: 'CUMPRIMENTO DA CARGA HORÁRIA',
          title:
              '${widget.course.workloadCompletedLabel}${widget.course.workloadTotalLabel} ministradas',
          subtitle: widget.course.progressCaption,
          headerTrailing: CourseHubBadge(
            label: widget.course.progressPercentageFormatted,
            tone: CourseHubBadgeTone.info,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.course.progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF4F4F5),
              color: InstColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Lista de Unidades Programáticas
        Text(
          'Unidades Didáticas (${units.length})',
          style: jakarta(
            size: 14.5,
            weight: FontWeight.w700,
            color: InstColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        if (units.isEmpty)
          const CourseHubEmptyState(
            icon: Icons.layers_outlined,
            title: 'Nenhuma unidade curricular cadastrada.',
            subtitle:
                'As unidades programadas do componente aparecerão aqui para controle de progresso.',
          )
        else
          for (final unit in units)
            CourseHubSurfaceCard(
              margin: const EdgeInsets.only(bottom: 12),
              overlineTag: 'UNIDADE ${unit.unitNumber}',
              title: unit.title,
              headerTrailing: CourseHubBadge(
                label: '${unit.completedClasses}/${unit.totalClasses} aulas',
                tone: unit.isCompleted
                    ? CourseHubBadgeTone.success
                    : CourseHubBadgeTone.neutral,
                icon: unit.isCompleted ? Icons.check_circle_outline : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unit.topics.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: unit.topics.map((topic) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            topic,
                            style: jakarta(
                              size: 11.5,
                              color: const Color(0xFF52525B),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: unit.progress.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF4F4F5),
                            color: unit.isCompleted
                                ? const Color(0xFF16A34A)
                                : InstColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      CourseHubPillButton(
                        label: unit.isCompleted
                            ? 'Unidade Concluída'
                            : '+ Avançar 1 aula',
                        variant: CourseHubButtonVariant.secondary,
                        compact: true,
                        onPressed: unit.isCompleted
                            ? null
                            : () => widget.controller.advanceSyllabusClasses(
                                widget.course.id,
                                unit.id,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

        const SizedBox(height: 22),

        // Repositório de Materiais
        CourseHubSectionHeader(
          title: 'Repositório de Materiais (${widget.course.materials.length})',
          subtitle:
              'Arquivos disponíveis imediatamente nas abas Página Inicial e Arquivos do portal discente.',
          trailing: CourseHubFilterBar(
            options: _categories,
            selected: _selectedCategory,
            onSelected: (cat) => setState(() => _selectedCategory = cat),
          ),
        ),
        const SizedBox(height: 14),
        if (filteredMaterials.isEmpty)
          CourseHubEmptyState(
            icon: Icons.folder_open_outlined,
            title: 'Nenhum material encontrado neste filtro',
            subtitle:
                'Envie slides, listas de exercícios ou códigos-fonte para disponibilizar à turma.',
            actionLabel: 'Publicar Material',
            onAction: widget.onAddContent,
          )
        else
          for (final mat in filteredMaterials)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Center(
                      child: Text(
                        mat.type.toUpperCase(),
                        style: jakarta(
                          size: 10,
                          weight: FontWeight.w700,
                          color: InstColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mat.title,
                          style: jakarta(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: InstColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${mat.unitAssociated} • ${mat.category} • ${mat.date} • ${mat.size}',
                          style: jakarta(
                            size: 11.5,
                            color: const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _downloadMaterial(context, mat),
                    tooltip: 'Baixar material',
                    icon: const Icon(
                      Icons.download_outlined,
                      size: 18,
                      color: Color(0xFF52525B),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _confirmDeleteMaterial(context, mat),
                    tooltip: 'Remover material',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
