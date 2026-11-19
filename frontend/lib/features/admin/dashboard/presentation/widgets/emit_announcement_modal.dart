// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';

/// Exibe o modal institucional para disparo de comunicados gerais do campus.
void showEmitirComunicadoModal(BuildContext context) {
  AcademicModalDialog.show<void>(
    context: context,
    builder: (ctx) => _EmitAnnouncementDialog(parentContext: context),
  );
}

class _EmitAnnouncementDialog extends StatefulWidget {
  final BuildContext parentContext;

  const _EmitAnnouncementDialog({required this.parentContext});

  @override
  State<_EmitAnnouncementDialog> createState() =>
      _EmitAnnouncementDialogState();
}

class _EmitAnnouncementDialogState extends State<_EmitAnnouncementDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedAudience = 'Toda a Comunidade Acadêmica';
  String _selectedCategory = 'Institucional';
  String? _validationError;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().length < 2 ||
        _bodyController.text.trim().length < 2) {
      setState(() {
        _validationError =
            'Informe o título e o corpo do comunicado antes de disparar.';
      });
      return;
    }
    setState(() {
      _validationError = null;
      _submitting = true;
    });
    final controller = AdminPortalController.instance;
    final ok = await controller.broadcastAnnouncement(
      title: _titleController.text,
      audience: _selectedAudience,
      category: _selectedCategory,
      body: _bodyController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      setState(() {
        _validationError =
            controller.remoteError ?? 'Não foi possível publicar o comunicado.';
      });
      return;
    }
    Navigator.of(context).pop();
    if (widget.parentContext.mounted) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text('Comunicado institucional publicado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AcademicModalDialog(
      title: 'Emitir Comunicado Institucional Geral',
      subtitle:
          'O comunicado será direcionado exclusivamente ao público selecionado.',
      icon: Icons.campaign_outlined,
      cancelLabel: 'Cancelar',
      confirmLabel: 'Disparar Comunicado',
      isLoading: _submitting,
      onConfirm: _submit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_validationError != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: InstColors.dangerBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: InstColors.danger.withValues(alpha: 0.3)),
              ),
              child: Text(
                _validationError!,
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: InstColors.danger,
                ),
              ),
            ),
          ],
          TextField(
            controller: _titleController,
            decoration: InstText.inputDecoration(
              labelText: 'Título do Comunicado',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedAudience,
            decoration: InstText.inputDecoration(
              labelText: 'Público-Alvo Destinatário',
            ),
            items: [
              'Toda a Comunidade Acadêmica',
              'Somente Discentes',
              'Somente Docentes',
            ].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedAudience = val);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InstText.inputDecoration(
              labelText: 'Classificação / Severidade',
            ),
            items: [
              'Institucional',
              'Calendário Acadêmico',
              'Urgente / Alerta',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: InstText.inputDecoration(
              labelText: 'Corpo do Comunicado',
            ),
          ),
        ],
      ),
    );
  }
}
