// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';

/// [SubmissionFileDropzone]
///
/// Área interativa de seleção, substituição e remoção de artefato digital
/// para submissão de entregas acadêmicas.
class SubmissionFileDropzone extends StatelessWidget {
  /// Nome do arquivo anexado, se selecionado.
  final String? attachedFileName;

  /// Tamanho formatado do arquivo anexado.
  final String? attachedFileSize;

  /// Rótulo dos formatos aceitos pela tarefa.
  final String? allowedFormats;

  /// Callback acionado para selecionar ou substituir o arquivo.
  final VoidCallback onPickFile;

  /// Callback acionado para remover o arquivo selecionado.
  final VoidCallback onRemoveFile;

  /// Cria uma nova instância de [SubmissionFileDropzone].
  const SubmissionFileDropzone({
    super.key,
    required this.attachedFileName,
    required this.attachedFileSize,
    required this.allowedFormats,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    if (attachedFileName != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.insert_drive_file,
                color: Color(0xFF16A34A),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachedFileName!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tamanho: ${attachedFileSize ?? "—"} • Arquivo selecionado',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onPickFile,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              child: const Text('Substituir', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Color(0xFFEF4444),
              ),
              onPressed: onRemoveFile,
              tooltip: 'Remover anexo',
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onPickFile,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 36,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 10),
            const Text(
              'Clique ou arraste o arquivo do trabalho aqui',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              allowedFormats ??
                  'Formatos não informados • Tamanho máximo: 7 MB',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
