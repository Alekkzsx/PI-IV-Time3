// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaNotebookTab]
///
/// Aba 9 do Cockpit AVA: Caderno Pessoal de Anotações.
/// Gerencia o ciclo de vida do [TextEditingController] em um [StatefulWidget]
/// dedicado e persiste as anotações privadas do discente no backend/MongoDB.
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
  String? _loadedDisciplineCode;

  @override
  void initState() {
    super.initState();
    _loadedDisciplineCode = widget.controller.selectedDiscipline?.code;
    _textController = TextEditingController(
      text: widget.controller.studentPersonalNotes,
    );
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
    _textController.dispose();
    super.dispose();
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
          trailing: ElevatedButton.icon(
            onPressed: () async {
              try {
                await widget.controller.updatePersonalNotes(
                  _textController.text,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Anotações salvas com sucesso.'),
                  ),
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.toString())));
              }
            },
            icon: const Icon(
              Icons.save_outlined,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              'Salvar Anotações',
              style: jakarta(
                size: 13,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 20),
        AvaSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _textController,
            maxLines: 12,
            style: jakarta(
              size: 13.5,
              color: const Color(0xFF18181B),
              height: 1.5,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText:
                  'Escreva seus resumos, anotações de aula e dúvidas aqui...',
              hintStyle: jakarta(size: 13, color: const Color(0xFFA1A1AA)),
            ),
          ),
        ),
      ],
    );
  }
}
