// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/admin_view/shared/controllers/admin_portal_controller.dart';

/// Exibe o modal institucional para disparo de comunicados gerais do campus.
void showEmitirComunicadoModal(BuildContext context) {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  String selectedAudience = 'Toda a Comunidade Acadêmica';
  String selectedCategory = 'Institucional';

  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Emitir Comunicado Institucional Geral',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título do Comunicado',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedAudience,
                  decoration: const InputDecoration(
                    labelText: 'Público-Alvo Destinatário',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Toda a Comunidade Acadêmica',
                    'Somente Discentes',
                    'Somente Docentes',
                  ]
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedAudience = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Classificação / Severidade',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Institucional',
                    'Calendário Acadêmico',
                    'Urgente / Alerta',
                  ]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Corpo do Comunicado',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                AdminPortalController.instance.broadcastAnnouncement(
                  title: titleController.text,
                  audience: selectedAudience,
                  category: selectedCategory,
                  body: bodyController.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Comunicado institucional transmitido a todos os usuários!',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Disparar Comunicado'),
          ),
        ],
      ),
    ),
  );
}

