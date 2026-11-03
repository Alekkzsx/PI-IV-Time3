// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/student_portal_controller.dart';
import 'ava_section_card.dart';

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
    final classCode = controller.selectedDiscipline?.code ?? '';
    final topics = controller.forumTopics(classCode);
    return AvaSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fórum de Dúvidas & Discussões Acadêmicas',
                style: AvaSectionStyles.title,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showNewTopicDialog(context),
                  icon: const Icon(Icons.add_comment, size: 16),
                  label: const Text('Publicar Nova Dúvida'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (topics.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Ainda não há tópicos para esta disciplina.'),
            ),
          ...topics.map((topic) {
            final replies = topic['replies'] is List
                ? (topic['replies'] as List).length
                : 0;
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
                      Expanded(
                        child: Text(
                          topic['authorName']?.toString() ?? 'Participante',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF18181B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        topic['createdAt']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topic['title']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$replies ${replies == 1 ? 'resposta' : 'respostas'}',
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
    return AvaSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Participantes da Disciplina (34 Discentes Matriculados)',
            style: AvaSectionStyles.title,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(AppUserSession.instance.effectiveName),
            subtitle: const Text('Discente autenticado'),
          ),
          const Text('A lista de participantes não é fornecida pelo serviço acadêmico.'),
        ],
      ),
    );
  }

  // --- ABA 10: Caderno Pessoal ---
  Widget _buildNotebookTab(BuildContext context) {
    final textController = TextEditingController(
      text: controller.studentPersonalNotes,
    );
    return AvaSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Caderno Pessoal de Anotações (Markdown)',
                style: AvaSectionStyles.title,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    () async {
                      try {
                        await controller.updatePersonalNotes(textController.text);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Anotações salvas.')),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    }();
                  },
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Salvar Anotações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    foregroundColor: Colors.white,
                  ),
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
    return AvaSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chat da Turma (${controller.selectedDiscipline?.code ?? '—'})',
                style: AvaSectionStyles.title,
              ),
              const SizedBox(height: 8),
              const Chip(label: Text('Chat não disponível')),
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
            child: const Center(
              child: Text('Este serviço não possui integração de chat.'),
            ),
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
              () async {
                final classCode = controller.selectedDiscipline?.code;
                if (classCode == null || classCode.isEmpty) return;
                try {
                  await controller.createForumTopic(
                    classCode: classCode,
                    title: titleController.text,
                    body: descController.text,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                } catch (error) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              }();
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
