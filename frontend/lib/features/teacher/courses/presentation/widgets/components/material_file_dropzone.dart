// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import '../../../../shared/theme/docente_colors.dart';

/// Card atômico com formulário e seletor de arquivos para disponibilização de material didático aos discentes.
class MaterialFileDropzone extends StatelessWidget {
  final TextEditingController titleController;
  final PickedPlatformFile? selectedMaterial;
  final bool isPublishing;
  final VoidCallback onPickFile;
  final VoidCallback onPublish;

  const MaterialFileDropzone({
    super.key,
    required this.titleController,
    required this.selectedMaterial,
    required this.isPublishing,
    required this.onPickFile,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
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
            controller: titleController,
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
          OutlinedButton.icon(
            onPressed: isPublishing ? null : onPickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(selectedMaterial?.name ?? 'Selecionar arquivo'),
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
                onPressed: isPublishing ? null : onPublish,
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
    );
  }
}
