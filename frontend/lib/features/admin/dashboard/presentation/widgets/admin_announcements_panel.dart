import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin/shared/controllers/admin_portal_controller.dart';

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
    final audience = TextEditingController(
      text: announcement['audience']?.toString() ?? '',
    );
    final category = TextEditingController(
      text: announcement['category']?.toString() ?? '',
    );
    final values = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar comunicado'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                TextField(
                  controller: body,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Texto'),
                ),
                TextField(
                  controller: audience,
                  decoration: const InputDecoration(labelText: 'Público'),
                ),
                TextField(
                  controller: category,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                if (title.text.trim().isNotEmpty) 'title': title.text.trim(),
                if (body.text.trim().isNotEmpty) 'body': body.text.trim(),
                if (audience.text.trim().isNotEmpty)
                  'audience': audience.text.trim(),
                if (category.text.trim().isNotEmpty)
                  'category': category.text.trim(),
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    title.dispose();
    body.dispose();
    audience.dispose();
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

  @override
  Widget build(BuildContext context) {
    final announcements = AdminPortalController.instance.announcements;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comunicados institucionais',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (announcements.isEmpty)
              const Text('Nenhum comunicado cadastrado.')
            else
              ...announcements.take(5).map(
                (announcement) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(announcement['title']?.toString() ?? ''),
                  subtitle: Text(announcement['body']?.toString() ?? ''),
                  trailing: IconButton(
                    tooltip: 'Editar comunicado',
                    onPressed: () => _edit(context, announcement),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
