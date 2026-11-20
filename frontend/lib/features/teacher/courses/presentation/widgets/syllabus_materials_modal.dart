// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';
import 'components/course_material_item_tile.dart';
import 'components/material_file_dropzone.dart';
import 'components/syllabus_unit_card.dart';

/// Modal que exibe as unidades do plano de ensino da disciplina e o repositório de materiais didáticos.
class SyllabusMaterialsModal extends StatefulWidget {
  final DocenteCourse course;
  final DocenteController controller;
  final void Function(String courseId)? onOpenCourseHub;

  const SyllabusMaterialsModal({
    super.key,
    required this.course,
    required this.controller,
    this.onOpenCourseHub,
  });

  @override
  State<SyllabusMaterialsModal> createState() => _SyllabusMaterialsModalState();
}

class _SyllabusMaterialsModalState extends State<SyllabusMaterialsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _materialTitleController = TextEditingController();
  PickedPlatformFile? _selectedMaterial;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _materialTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickMaterialFile() async {
    final selected = await PlatformFileHelper.pickFile(
      allowedExtensions: const ['pdf', 'zip', 'docx', 'sql'],
    );
    if (mounted && selected != null) {
      setState(() => _selectedMaterial = selected);
    }
  }

  Future<void> _publishMaterial(String courseId) async {
    setState(() => _isPublishing = true);
    await widget.controller.publishMaterial(
      courseId,
      _materialTitleController.text.trim(),
      _selectedMaterial,
    );
    if (!mounted) return;
    setState(() => _isPublishing = false);
    final error = widget.controller.remoteError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Material disponibilizado no AVA.'),
      ),
    );
    if (error == null) {
      _materialTitleController.clear();
      _selectedMaterial = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consulta o estado atual da disciplina no controlador
    final currentCourse = widget.controller.courses.firstWhere(
      (c) => c.id == widget.course.id,
      orElse: () => widget.course,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: DocenteColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 820),
        child: Column(
          children: [
            // Cabeçalho
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentCourse.code,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DocenteColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentCourse.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: DocenteColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentCourse.shift} • Carga Horária Total: ${currentCourse.totalHours} h/aula',
                          style: const TextStyle(
                            fontSize: 13,
                            color: DocenteColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onOpenCourseHub?.call(currentCourse.id);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Abrir no AVA'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DocenteColors.textPrimary,
                      side: const BorderSide(color: DocenteColors.borderDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: DocenteColors.textSecondary,
                  ),
                ],
              ),
            ),

            // Barra de abas
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: DocenteColors.border)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: DocenteColors.textPrimary,
                unselectedLabelColor: DocenteColors.textSecondary,
                indicatorColor: DocenteColors.textPrimary,
                indicatorWeight: 2,
                tabs: [
                  Tab(
                    text:
                        'Unidades do Plano de Ensino (${currentCourse.syllabusUnits.length})',
                  ),
                  const Tab(text: 'Repositório de Materiais de Apoio'),
                ],
              ),
            ),

            // Conteúdo das abas
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSyllabusTab(currentCourse),
                  _buildMaterialsTab(currentCourse),
                ],
              ),
            ),

            // Rodapé
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(color: DocenteColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyllabusTab(DocenteCourse course) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: course.syllabusUnits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final unit = course.syllabusUnits[index];
        return SyllabusUnitCard(
          unit: unit,
          onAdvanceClasses: () {
            widget.controller.advanceSyllabusClasses(course.id, unit.id);
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildMaterialsTab(DocenteCourse course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formulário de Envio
          MaterialFileDropzone(
            titleController: _materialTitleController,
            selectedMaterial: _selectedMaterial,
            isPublishing: _isPublishing,
            onPickFile: _pickMaterialFile,
            onPublish: () => _publishMaterial(course.id),
          ),
          const SizedBox(height: 24),

          // Arquivos Acessíveis
          const Text(
            'Arquivos Atualmente Acessíveis pelos Alunos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DocenteColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: course.materials.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final mat = course.materials[index];
              return CourseMaterialItemTile(material: mat);
            },
          ),
        ],
      ),
    );
  }
}
