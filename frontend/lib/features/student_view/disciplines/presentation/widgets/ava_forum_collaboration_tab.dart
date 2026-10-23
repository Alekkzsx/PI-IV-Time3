// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/student_view/shared/controllers/student_portal_controller.dart';

/// Abas do AVA para Fórum de Dúvidas, Pessoas & Turma, Caderno Pessoal e Chat.
class AvaForumCollaborationTab extends StatelessWidget {
  final int activeTabIndex;
  final StudentPortalController controller;

  const AvaForumCollaborationTab({
    super.key,
    required this.activeTabIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    switch (activeTabIndex) {
      case 3:
        return _buildForumsTab(context);
      case 5:
        return _buildPeopleTab();
      case 9:
        return _buildNotebookTab(context);
      case 10:
        return _buildClassChatTab(context);
      default:
        return _buildForumsTab(context);
    }
  }

  // --- ABA 4: Fórum de Dúvidas ---
  Widget _buildForumsTab(BuildContext context) {
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
                'Fórum de Dúvidas & Discussões Acadêmicas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showNewTopicDialog(context),
                icon: const Icon(Icons.add_comment, size: 16),
                label: const Text('Publicar Nova Dúvida'),
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
          ...controller.forumTopics.map((topic) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        topic['autor']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      Text(
                        topic['tempo']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topic['titulo']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topic['respostas']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- ABA 6: Pessoas & Turma ---
  Widget _buildPeopleTab() {
    final people = [
      {
        'nome': 'Profa. Dra. Helena Bittencourt',
        'papel': 'Docente Titular',
        'status': 'Online na Sala',
        'isTeacher': true,
      },
      {
        'nome': 'Victor Hugo Mendonça',
        'papel': 'Monitor de Ensino',
        'status': 'Online',
        'isTeacher': false,
      },
      {
        'nome': 'Gabriel Soares de Oliveira (Você)',
        'papel': 'Discente',
        'status': 'Online',
        'isTeacher': false,
      },
      {
        'nome': 'Mariana Rios Costa',
        'papel': 'Discente',
        'status': 'Online',
        'isTeacher': false,
      },
      {
        'nome': 'Lucas Silva Santos',
        'papel': 'Discente',
        'status': 'Offline',
        'isTeacher': false,
      },
      {
        'nome': 'Beatriz Castro Lima',
        'papel': 'Discente',
        'status': 'Online',
        'isTeacher': false,
      },
    ];

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
          const Text(
            'Participantes da Disciplina (34 Discentes Matriculados)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...people.map((p) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: (p['isTeacher'] as bool)
                    ? const Color(0xFF18181B)
                    : const Color(0xFFE2E8F0),
                foregroundColor: (p['isTeacher'] as bool)
                    ? Colors.white
                    : const Color(0xFF18181B),
                child: Text((p['nome'] as String)[0]),
              ),
              title: Text(
                p['nome'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                p['papel'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              trailing: Chip(
                label: Text(
                  p['status'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: p['status'] == 'Offline'
                        ? Colors.grey
                        : const Color(0xFF16A34A),
                  ),
                ),
                backgroundColor: p['status'] == 'Offline'
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFDCFCE7),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- ABA 10: Caderno Pessoal ---
  Widget _buildNotebookTab(BuildContext context) {
    final textController =
        TextEditingController(text: controller.studentPersonalNotes);
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
                'Caderno Pessoal de Anotações (Markdown)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  controller.updatePersonalNotes(textController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Anotações salvas com sucesso!'),
                    ),
                  );
                },
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Salvar Anotações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: textController,
            maxLines: 12,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              hintText: 'Escreva suas anotações aqui em formato Markdown...',
            ),
          ),
        ],
      ),
    );
  }

  // --- ABA 11: Chat da Turma ---
  Widget _buildClassChatTab(BuildContext context) {
    final chatInput = TextEditingController();
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
            children: const [
              Text(
                'Chat da Turma (APS-II 2026/2)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text(
                  '18 alunos conectados',
                  style: TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
                ),
                backgroundColor: Color(0xFFDCFCE7),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView(
              children: const [
                Text(
                  'Profa. Dra. Helena Bittencourt: Pessoal, iniciamos a aula ao vivo na Sala Virtual!',
                ),
                SizedBox(height: 8),
                Text(
                  'Mariana Rios Costa: Professora, o link do GitHub da entrega já está liberado?',
                ),
                SizedBox(height: 8),
                Text(
                  'Profa. Dra. Helena Bittencourt: Sim, na aba Tarefas você pode anexar o zip ou informar o repositório.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatInput,
                  decoration: const InputDecoration(
                    hintText: 'Digite uma mensagem para a turma...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF18181B)),
                onPressed: () {
                  chatInput.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensagem enviada no chat!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNewTopicDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Publicar Nova Dúvida no Fórum',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título da Dúvida',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição detalhada do problema',
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
              if (titleController.text.isNotEmpty) {
                controller.postForumTopic(
                  titleController.text,
                  descController.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dúvida publicada no fórum da disciplina!'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }
}

