import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';
import 'package:pi_iv_time3/shared/widgets/academic_modal_dialog.dart';

class AdminAnnouncementsPanel extends StatelessWidget {
  const AdminAnnouncementsPanel({super.key});

  Future<void> _edit(
    BuildContext context,
    Map<String, dynamic> announcement,
  ) async {
    final title = TextEditingController(
      text: announcement['title']?.toString() ?? '',
    );
    final body = TextEditingController(
      text: announcement['body']?.toString() ?? '',
    );
    String audience = announcement['audience']?.toString().trim() ?? '';
    const audiences = [
      'Toda a Comunidade Acadêmica',
      'Somente Discentes',
      'Somente Docentes',
    ];
    if (!audiences.contains(audience)) {
      audience = 'Toda a Comunidade Acadêmica';
    }
    final category = TextEditingController(
      text: announcement['category']?.toString() ?? '',
    );

    final values = await AcademicModalDialog.show<Map<String, Object?>>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AcademicModalDialog(
          title: 'Editar Comunicado Institucional',
          subtitle: 'Atualize conteúdo ou público destinatário no mural dos portais.',
          icon: Icons.campaign_outlined,
          cancelLabel: 'Cancelar',
          confirmLabel: 'Salvar alterações',
          onConfirm: () {
            if (title.text.trim().isEmpty || body.text.trim().isEmpty) return;
            Navigator.pop(dialogCtx, {
              'title': title.text.trim(),
              'body': body.text.trim(),
              'audience': audience,
              if (category.text.trim().isNotEmpty)
                'category': category.text.trim(),
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: title,
                decoration: InstText.inputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: audience,
                decoration: InstText.inputDecoration(labelText: 'Público-alvo'),
                items: audiences
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setModalState(() => audience = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: category,
                decoration: InstText.inputDecoration(labelText: 'Categoria'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: body,
                maxLines: 4,
                decoration: InstText.inputDecoration(labelText: 'Texto do comunicado'),
              ),
            ],
          ),
        ),
      ),
    );
    title.dispose();
    body.dispose();
    category.dispose();
    if (values == null || values.isEmpty) return;
    final id = announcement['id']?.toString() ?? '';
    final saved = await AdminPortalController.instance.updateAnnouncement(
      id,
      values,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Comunicado atualizado.'
              : AdminPortalController.instance.remoteError ??
                    'Não foi possível atualizar o comunicado.',
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    Map<String, dynamic> announcement,
  ) async {
    final id = announcement['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final confirmed = await AcademicModalDialog.show<bool>(
      context: context,
      builder: (dialogCtx) => AcademicModalDialog(
        title: 'Excluir Comunicado',
        subtitle: 'Esta ação remove o comunicado do mural administrativo, docente e discente.',
        icon: Icons.delete_outline_rounded,
        confirmLabel: 'Excluir comunicado',
        isConfirmDestructive: true,
        onConfirm: () => Navigator.pop(dialogCtx, true),
        child: Text(
          'Deseja remover "${announcement['title'] ?? ''}"?',
          style: jakarta(size: 13.5, color: InstColors.ink),
        ),
      ),
    );
    if (confirmed != true) return;
    final ok = await AdminPortalController.instance.deleteAnnouncement(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Comunicado removido.'
              : AdminPortalController.instance.remoteError ??
                    'Não foi possível remover o comunicado.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminPortalController.instance,
      builder: (context, _) {
        final announcements = AdminPortalController.instance.announcements;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: InstColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comunicados Institucionais',
                    style: jakarta(
                      size: 18,
                      weight: FontWeight.w700,
                      color: InstColors.ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: InstColors.stoneActive,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: InstColors.border),
                    ),
                    child: Text(
                      '${announcements.length} publicados',
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: InstColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (announcements.isEmpty)
                Text(
                  'Nenhum comunicado cadastrado.',
                  style: jakarta(size: 13.5, color: InstColors.muted),
                )
              else
                for (int i = 0; i < announcements.take(5).length; i++) ...[
                  if (i > 0)
                    const Divider(height: 20, color: Color(0xFFF0F0F0)),
                  _AnnouncementRow(
                    announcement: announcements[i],
                    onEdit: () => _edit(context, announcements[i]),
                    onDelete: () => _delete(context, announcements[i]),
                  ),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _AnnouncementRow extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementRow({
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final audience = announcement['audience']?.toString().trim() ?? 'Comunidade';
    final category = announcement['category']?.toString().trim() ?? 'Geral';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    announcement['title']?.toString() ?? '',
                    style: jakarta(
                      size: 14,
                      weight: FontWeight.w600,
                      color: InstColors.ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: InstColors.stone,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: InstColors.border),
                    ),
                    child: Text(
                      '$category • $audience',
                      style: jakarta(
                        size: 11,
                        weight: FontWeight.w600,
                        color: InstColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                announcement['body']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: jakarta(size: 13, color: InstColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Editar comunicado',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18, color: InstColors.ink),
        ),
        IconButton(
          tooltip: 'Excluir comunicado',
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: InstColors.danger,
          ),
        ),
      ],
    );
  }
}
