// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';

/// Modal para criação e agendamento de novos eventos acadêmicos.
class StudentCalendarModals {
  StudentCalendarModals._();

  static void showCreateEventModal(
      BuildContext context, StudentPortalController controller) {
    final titleController = TextEditingController();
    final dateController = TextEditingController(text: '2026-10-25');
    final timeController = TextEditingController(text: '19:00 - 20:40');
    final locController =
        TextEditingController(text: 'Sala Virtual AVA / Lab 04');
    String selectedType = 'Aula';
    String selectedDiscipline = 'APS-II';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Criar Novo Evento Acadêmico',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título do Evento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          decoration: const InputDecoration(
                            labelText: 'Data (AAAA-MM-DD)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          decoration: const InputDecoration(
                            labelText: 'Horário',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Evento',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Aula', 'Entrega', 'Avaliação', 'Fórum']
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDiscipline,
                    decoration: const InputDecoration(
                      labelText: 'Disciplina Vinculada',
                      border: OutlineInputBorder(),
                    ),
                    items: ['APS-II', 'BD-II', 'FIS', 'FSO']
                        .map((d) =>
                            DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedDiscipline = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locController,
                    decoration: const InputDecoration(
                      labelText: 'Local ou Link da Sala Virtual',
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
                  controller.addCalendarEvent(
                    title: titleController.text,
                    date: dateController.text,
                    time: timeController.text,
                    type: selectedType,
                    discipline: selectedDiscipline,
                    location: locController.text,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Evento acadêmico agendado com sucesso!'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar Evento'),
            ),
          ],
        ),
      ),
    );
  }
}
