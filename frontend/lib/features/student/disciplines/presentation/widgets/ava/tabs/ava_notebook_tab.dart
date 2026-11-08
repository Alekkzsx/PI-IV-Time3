// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/utils/platform_file_helper.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaNotebookTab]
///
/// Aba 9 do Cockpit AVA: Caderno Pessoal de Anotações.
/// Permite ao discente criar, formatar e persistir notas privadas em Markdown no MongoDB
/// e exportá-las localmente como arquivos `.md`.
class AvaNotebookTab extends StatefulWidget {
  /// Controlador reativo do portal do estudante.
  final StudentPortalController controller;

  /// Cria uma nova instância de [AvaNotebookTab].
  const AvaNotebookTab({super.key, required this.controller});

  @override
  State<AvaNotebookTab> createState() => _AvaNotebookTabState();
}

class _AvaNotebookTabState extends State<AvaNotebookTab> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  String? _loadedDisciplineCode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadedDisciplineCode = widget.controller.selectedDiscipline?.code;
    _textController = TextEditingController(
      text: widget.controller.studentPersonalNotes,
    );
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant AvaNotebookTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentCode = widget.controller.selectedDiscipline?.code;
    if (currentCode != _loadedDisciplineCode) {
      _loadedDisciplineCode = currentCode;
      _textController.text = widget.controller.studentPersonalNotes;
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _wordCount {
    final text = _textController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  int get _charCount => _textController.text.length;

  void _insertMarkdownSnippet(String snippet, {int cursorOffset = 0}) {
    final text = _textController.text;
    final selection = _textController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, snippet);
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + snippet.length + cursorOffset,
      ),
    );
    _focusNode.requestFocus();
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);
    try {
      await widget.controller.updatePersonalNotes(_textController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anotações sincronizadas na nuvem com sucesso.'),
          backgroundColor: Color(0xFF18181B),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar anotações: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _exportMarkdown() async {
    final code = widget.controller.selectedDiscipline?.code.toLowerCase() ??
        'disciplina';
    final fileName = 'anotacoes_$code.md';
    final bytes = utf8.encode(_textController.text);

    await PlatformFileHelper.saveOrDownloadFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'text/markdown',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anotações exportadas como ($fileName) com sucesso.'),
          backgroundColor: const Color(0xFF18181B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvaOpenSectionHeader(
          title: 'Caderno Pessoal de Anotações',
          subtitle:
              'Suas anotações privadas em formato Markdown vinculadas à disciplina.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _exportMarkdown,
                icon: const Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: Color(0xFF18181B),
                ),
                label: Text(
                  'Exportar .md',
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveNotes,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.cloud_upload_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                label: Text(
                  _isSaving ? 'Salvando...' : 'Salvar na Nuvem',
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        AvaBannerSurfaceCard(
          title: 'Editor de Notas Privadas',
          subtitle:
              'Anotações em formato Markdown sincronizadas com a disciplina',
          headerTrailing: AvaStatusBadge(
            label: '$_wordCount palavras • $_charCount caracteres',
            variant: AvaBadgeVariant.neutral,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de formatação Markdown rápida
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MarkdownPill(
                      label: '# Título',
                      onTap: () => _insertMarkdownSnippet('\n# '),
                    ),
                    const SizedBox(width: 6),
                    _MarkdownPill(
                      label: '## Subtítulo',
                      onTap: () => _insertMarkdownSnippet('\n## '),
                    ),
                    const SizedBox(width: 6),
                    _MarkdownPill(
                      label: '**Negrito**',
                      onTap: () => _insertMarkdownSnippet('**texto**', cursorOffset: -2),
                    ),
                    const SizedBox(width: 6),
                    _MarkdownPill(
                      label: '*Itálico*',
                      onTap: () => _insertMarkdownSnippet('*texto*', cursorOffset: -1),
                    ),
                    const SizedBox(width: 6),
                    _MarkdownPill(
                      label: '- Lista',
                      onTap: () => _insertMarkdownSnippet('\n- '),
                    ),
                    const SizedBox(width: 6),
                    _MarkdownPill(
                      label: '`Código`',
                      onTap: () => _insertMarkdownSnippet('`código`', cursorOffset: -1),
                    ),
                    const SizedBox(width: 6),
                    _MarkdownPill(
                      label: '> Citação',
                      onTap: () => _insertMarkdownSnippet('\n> '),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
              const SizedBox(height: 8),

              TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 15,
                minLines: 8,
                style: jakarta(
                  size: 13.5,
                  color: const Color(0xFF18181B),
                  height: 1.55,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      'Escreva seus resumos, anotações de aula, dúvidas e trechos de código aqui...',
                  hintStyle: jakarta(size: 13, color: const Color(0xFFA1A1AA)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MarkdownPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MarkdownPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: jakarta(
            size: 11.5,
            weight: FontWeight.w600,
            color: const Color(0xFF3F3F46),
          ),
        ),
      ),
    );
  }
}
