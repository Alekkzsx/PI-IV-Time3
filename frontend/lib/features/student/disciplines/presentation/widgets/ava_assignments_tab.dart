// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';

/// Aba do AVA que exibe as atividades avaliativas e o modal de submissão de entregas.
class AvaAssignmentsTab extends StatelessWidget {
  final StudentPortalController controller;

  const AvaAssignmentsTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Atividades Avaliativas da Disciplina',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showSubmissionModal(context),
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Enviar Atividade'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildTaskItem(
            'Implementação dos Padrões Adapter e Facade',
            'Prazo: Hoje às 23:59 • Peso 3.0',
            'Pendente de Envio',
            const Color(0xFFFEF3C7),
            const Color(0xFFD97706),
          ),
          const SizedBox(height: 12),
          _buildTaskItem(
            'Modelagem Arquitetural no PlantUML',
            'Enviado em 12/09/2026 • Nota: 9.5 / 10.0',
            'Avaliado pelo Professor',
            const Color(0xFFDCFCE7),
            const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    String title,
    String subtitle,
    String statusText,
    Color bg,
    Color fg,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              statusText,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: bg,
          ),
        ],
      ),
    );
  }

  void _showSubmissionModal(BuildContext context) {
    final gitController = TextEditingController();
    final obsController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Submeter Atividade no AVA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Anexar Arquivo da Entrega (PDF, ZIP até 25MB):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: const [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 36,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Arraste o arquivo ou clique para selecionar',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Link do Repositório Git (Opcional):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: gitController,
                decoration: const InputDecoration(
                  hintText: 'https://github.com/...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Observações para o Docente:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: obsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Observações sobre a implementação...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.submitDelivery(
                deliveryId: 'DEL-01',
                fileName: 'entrega_padroes_adapter.zip',
                gitUrl: gitController.text,
                comments: obsController.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Atividade submetida com sucesso! Protocolo gerado.',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Submissão'),
          ),
        ],
      ),
    );
  }
}

