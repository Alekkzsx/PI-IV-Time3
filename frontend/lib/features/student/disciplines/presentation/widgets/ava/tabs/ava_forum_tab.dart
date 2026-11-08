// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:agmrm_security/student/student_security.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaForumTab]
///
/// Aba 3 do Cockpit AVA: Fórum de Dúvidas e Discussões.
/// Apresenta os tópicos da disciplina vindos do backend/MongoDB em cartões brancos
/// desacoplados com badge semântica "Respondido", autor, tempo e contador de respostas.
class AvaForumTab extends StatelessWidget {
  /// Controlador reativo do portal do estudante.
  final StudentPortalController controller;

  /// Cria uma nova instância de [AvaForumTab].
  const AvaForumTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final classCode = controller.selectedDiscipline?.code ?? '';
    final displayList = controller.forumTopics(classCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvaOpenSectionHeader(
          title: 'Fórum de Dúvidas e Discussões',
          subtitle:
              'Tire dúvidas com o professor, monitores e interaja com os colegas da disciplina.',
          trailing: ElevatedButton.icon(
            onPressed: () => _showNewTopicDialog(context),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: Text(
              'Nova Dúvida',
              style: jakarta(
                size: 13,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (displayList.isEmpty)
          const AvaEmptyStateCard(
            icon: Icons.forum_outlined,
            title: 'Nenhuma dúvida ou tópico aberto',
            subtitle:
                'Seja o primeiro a publicar uma dúvida utilizando o botão "+ Nova Dúvida".',
          )
        else
          for (final topic in displayList) _buildForumTopicCard(context, topic),
      ],
    );
  }

  Widget _buildForumTopicCard(
    BuildContext context,
    Map<String, dynamic> topic,
  ) {
    final title = (topic['title'] ?? 'Tópico de Discussão').toString();
    final body = (topic['body'] ?? topic['content'] ?? '').toString();
    final authorName =
        (topic['authorName'] ?? topic['author'] ?? 'Discente').toString();
    final authorProfile = (topic['authorProfile'] ?? 'Estudante').toString();
    final timeAgo = (topic['timeAgo'] ?? 'Há 2 dias').toString();
    final status = (topic['status'] ?? 'Respondido').toString();
    final replies =
        topic['repliesCount'] ??
        (topic['replies'] is List ? (topic['replies'] as List).length : 4);
    final isAnswered = status.toLowerCase().contains('respondido');

    return AvaSurfaceCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      onTap: () => _showTopicDiscussionModal(context, topic),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      title,
                      style: jakarta(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    if (isAnswered)
                      const AvaStatusBadge(
                        label: 'Respondido',
                        variant: AvaBadgeVariant.success,
                        icon: Icons.check_circle_outline,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 12,
                      color: Color(0xFF71717A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      replies.toString(),
                      style: jakarta(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF52525B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFFA1A1AA),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Por $authorName ($authorProfile) • $timeAgo',
            style: jakarta(
              size: 11.5,
              weight: FontWeight.w500,
              color: const Color(0xFFA1A1AA),
            ),
          ),
        ],
      ),
    );
  }

  void _showTopicDiscussionModal(
    BuildContext context,
    Map<String, dynamic> topic,
  ) {
    final rawReplies = topic['replies'];
    final repliesList = rawReplies is List
        ? rawReplies.whereType<Map>().toList()
        : const <Map>[];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      topic['title']?.toString() ?? 'Tópico',
                      style: jakarta(
                        size: 16,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                topic['body']?.toString() ?? 'Sem descrição detalhada.',
                style: jakarta(
                  size: 13,
                  color: const Color(0xFF52525B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'Respostas da Comunidade Acadêmica:',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),
              if (repliesList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    'Aguardando resposta oficial do docente ou monitor da turma.',
                    style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
                  ),
                )
              else
                for (final r in repliesList)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      '${r['authorName'] ?? 'Docente'}: ${r['body'] ?? ''}',
                      style: jakarta(
                        size: 12.5,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  void _showNewTopicDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Publicar Nova Dúvida no Fórum',
          style: jakarta(
            size: 18,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: jakarta(size: 13.5, color: const Color(0xFF18181B)),
                decoration: InputDecoration(
                  labelText: 'Título da Dúvida',
                  labelStyle: jakarta(
                    size: 13,
                    color: const Color(0xFF71717A),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descController,
                maxLines: 4,
                style: jakarta(size: 13.5, color: const Color(0xFF18181B)),
                decoration: InputDecoration(
                  labelText: 'Descrição detalhada do problema',
                  labelStyle: jakarta(
                    size: 13,
                    color: const Color(0xFF71717A),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: jakarta(size: 13, color: const Color(0xFF71717A)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final classCode = controller.selectedDiscipline?.code;
              if (classCode == null || classCode.isEmpty) return;

              if (!StudentActionRateLimiter.instance.canExecute(
                StudentActionType.createForumTopic,
              )) {
                final cooldown = StudentActionRateLimiter.instance
                    .getRemainingCooldownSeconds(
                      StudentActionType.createForumTopic,
                    );
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Aguarde $cooldown s antes de publicar outro tópico.',
                    ),
                    backgroundColor: const Color(0xFFD97706),
                  ),
                );
                return;
              }

              final safeTitle =
                  StudentForumContentSanitizer.sanitizeForumTitle(
                    titleController.text,
                  );
              final safeBody = StudentForumContentSanitizer.sanitizeForumBody(
                descController.text,
              );

              if (safeTitle.length <
                  StudentSecurityLimits.minForumTitleLength) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      'O título deve conter pelo menos ${StudentSecurityLimits.minForumTitleLength} caracteres válidos.',
                    ),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
                return;
              }

              try {
                await controller.createForumTopic(
                  classCode: classCode,
                  title: safeTitle,
                  body: safeBody,
                );
                StudentActionRateLimiter.instance.recordAction(
                  StudentActionType.createForumTopic,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              } catch (error) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text(error.toString())));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }
}
