// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shared/theme/docente_colors.dart';

/// Modal dialog displaying course syllabus units and teaching materials repository.
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

  @override
  Widget build(BuildContext context) {
    // Look up current course state in controller
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
            // Header
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

            // Tab bar
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

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSyllabusTab(currentCourse),
                  _buildMaterialsTab(currentCourse),
                ],
              ),
            ),

            // Footer
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
        final pct = (unit.progress * 100).round();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DocenteColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DocenteColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'UNIDADE ${unit.unitNumber.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: DocenteColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      widget.controller.advanceSyllabusClasses(
                        course.id,
                        unit.id,
                      );
                      setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      side: const BorderSide(color: DocenteColors.borderDark),
                    ),
                    child: const Text(
                      'Avançar Aulas',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                unit.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tópicos previstos no PPC:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DocenteColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              ...unit.topics.map(
                (topic) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: DocenteColors.textMuted),
                      ),
                      Expanded(
                        child: Text(
                          topic,
                          style: const TextStyle(
                            fontSize: 13,
                            color: DocenteColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: unit.progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E5E5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    DocenteColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aulas ministradas: ${unit.completedClasses} de ${unit.totalClasses}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: DocenteColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          // Upload Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DocenteColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DocenteColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Disponibilizar Novo Arquivo para os Discentes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DocenteColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _materialTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Título do Documento / Material Didático',
                    hintText:
                        'Ex: Slides Aula 11 - Diagrama de Atividades e Concorrência',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Formatos aceitos: PDF, ZIP, DOCX, SQL (máx. 25 MB)',
                      style: TextStyle(
                        fontSize: 12,
                        color: DocenteColors.textSecondary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_materialTitleController.text.trim().isNotEmpty) {
                          widget.controller.publishMaterial(
                            course.id,
                            _materialTitleController.text.trim(),
                          );
                          _materialTitleController.clear();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Material disponibilizado no AVA com sucesso!',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Publicar Material'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DocenteColors.textPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Accessible Files
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
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: DocenteColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DocenteColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DocenteColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 22,
                        color: DocenteColors.danger,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mat.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: DocenteColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Publicado em ${mat.date} • ${mat.size} • ${mat.type}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: DocenteColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DocenteColors.successLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Disponível no AVA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: DocenteColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
