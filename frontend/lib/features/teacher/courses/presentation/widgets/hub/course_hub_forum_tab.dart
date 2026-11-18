// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'course_hub_ui.dart';

/// Aba de Fórum da Turma totalmente conectada para leitura de thread, resposta e resolução.
class CourseHubForumTab extends StatefulWidget {
  final DocenteCourse course;
  final DocenteController controller;
  final VoidCallback onNewTopic;

  const CourseHubForumTab({
    super.key,
    required this.course,
    required this.controller,
    required this.onNewTopic,
  });

  @override
  State<CourseHubForumTab> createState() => _CourseHubForumTabState();
}

class _CourseHubForumTabState extends State<CourseHubForumTab> {
  String _selectedFilter = 'Todos';
  String _searchQuery = '';

  static const List<String> _filters = [
    'Todos',
    'Sem Resposta',
    'Respondidos',
  ];

  bool _isAnswered(Map<String, dynamic> topic) {
    final replies = topic['replies'];
    return topic['isResolved'] == true ||
        (replies is List && replies.isNotEmpty);
  }

  Future<void> _openTopicModal(
    BuildContext context,
    Map<String, dynamic> initialTopic,
  ) async {
    final replyCtrl = TextEditingController();
    var isSending = false;

    await CourseHubModal.show<void>(
      context: context,
      overlineTag:
          '${(initialTopic['category'] ?? 'Fórum da Turma').toString()} • ${widget.course.code}',
      title: (initialTopic['title'] ?? 'Discussão').toString(),
      subtitle:
          'Publicado por ${(initialTopic['authorName'] ?? 'Integrante').toString()}',
      maxWidth: 680,
      disposeOnClose: [replyCtrl],
      builder: (_) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final freshTopic = widget.course.forumTopics
              .where((t) => t['id']?.toString() == initialTopic['id']?.toString())
              .firstOrNull ??
              initialTopic;
          final replies = (freshTopic['replies'] as List?)
                  ?.whereType<Map>()
                  .map((r) => Map<String, dynamic>.from(r))
                  .toList() ??
              const <Map<String, dynamic>>[];
          final isResolved = freshTopic['isResolved'] == true;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CourseHubBadge(
                    label: isResolved
                        ? 'Tópico Resolvido'
                        : (replies.isNotEmpty ? 'Com Respostas' : 'Aberto'),
                    tone: isResolved
                        ? CourseHubBadgeTone.success
                        : (replies.isNotEmpty
                              ? CourseHubBadgeTone.info
                              : CourseHubBadgeTone.warning),
                  ),
                  const Spacer(),
                  CourseHubPillButton(
                    label: isResolved
                        ? 'Reabrir Discussão'
                        : 'Marcar como Resolvido',
                    icon: isResolved
                        ? Icons.refresh_rounded
                        : Icons.check_circle_outline_rounded,
                    variant: CourseHubButtonVariant.secondary,
                    compact: true,
                    onPressed: () async {
                      final ok = await widget.controller.resolveForumTopic(
                        topicId: freshTopic['id'].toString(),
                        isResolved: !isResolved,
                      );
                      if (ok && modalCtx.mounted) setModalState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Enunciado inicial
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  (freshTopic['body'] ?? '').toString().isEmpty
                      ? '(Sem corpo detalhado)'
                      : (freshTopic['body'] ?? '').toString(),
                  style: jakarta(
                    size: 13.5,
                    color: InstColors.ink,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Respostas e Contribuições (${replies.length})',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: InstColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              if (replies.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Nenhuma resposta publicada ainda. Inicie a orientação abaixo.',
                    style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
                  ),
                )
              else
                for (final r in replies)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: r['authorRole']?.toString() == 'docente'
                          ? const Color(0xFFEFF6FF).withValues(alpha: 0.45)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              (r['authorName'] ?? 'Participante').toString(),
                              style: jakarta(
                                size: 12.5,
                                weight: FontWeight.w700,
                                color: InstColors.ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (r['authorRole']?.toString() == 'docente')
                              const CourseHubBadge(
                                label: 'Docente',
                                tone: CourseHubBadgeTone.info,
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          (r['body'] ?? '').toString(),
                          style: jakarta(
                            size: 12.5,
                            color: const Color(0xFF3F3F46),
                          ),
                        ),
                      ],
                    ),
                  ),

              const SizedBox(height: 10),
              TextField(
                controller: replyCtrl,
                maxLines: 3,
                style: jakarta(size: 13, color: InstColors.ink),
                decoration: courseHubInputDecoration(
                  hintText: 'Escreva uma resposta ou orientação para a turma...',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CourseHubPillButton(
                    label: 'Fechar',
                    variant: CourseHubButtonVariant.secondary,
                    onPressed: () => Navigator.of(modalCtx).pop(),
                  ),
                  const SizedBox(width: 8),
                  CourseHubPillButton(
                    label: 'Publicar Resposta',
                    icon: Icons.send_rounded,
                    isLoading: isSending,
                    onPressed: isSending
                        ? null
                        : () async {
                            final text = replyCtrl.text.trim();
                            if (text.isEmpty) return;
                            setModalState(() => isSending = true);
                            final ok = await widget.controller.replyForumTopic(
                              topicId: freshTopic['id'].toString(),
                              body: text,
                            );
                            if (!modalCtx.mounted) return;
                            setModalState(() => isSending = false);
                            if (ok) {
                              replyCtrl.clear();
                              Navigator.of(modalCtx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Resposta publicada no fórum da turma.',
                                  ),
                                  backgroundColor: Color(0xFF166534),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.controller.remoteError ??
                                        'Erro ao responder tópico.',
                                  ),
                                  backgroundColor: const Color(0xFFB91C1C),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTopics = widget.course.forumTopics;
    final filtered = allTopics.where((t) {
      final answered = _isAnswered(t);
      final matchesFilter = switch (_selectedFilter) {
        'Sem Resposta' => !answered,
        'Respondidos' => answered,
        _ => true,
      };
      if (!matchesFilter) return false;
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return (t['title'] ?? '').toString().toLowerCase().contains(q) ||
          (t['body'] ?? '').toString().toLowerCase().contains(q) ||
          (t['authorName'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CourseHubSectionHeader(
          overline: 'DISCUSSÃO COLABORATIVA • ${widget.course.code}',
          title: 'Fórum da Turma',
          subtitle:
              'Acompanhe dúvidas dos alunos, responda tópicos e promova debates técnicos sincronizados com o AVA.',
          trailing: CourseHubPillButton(
            label: 'Novo Tópico',
            icon: Icons.add_rounded,
            onPressed: widget.onNewTopic,
          ),
        ),
        const SizedBox(height: 18),

        if (allTopics.isEmpty)
          CourseHubEmptyState(
            icon: Icons.forum_outlined,
            title: 'Nenhum tópico aberto neste fórum',
            subtitle:
                'Crie um tópico orientador para que os discentes possam participar e tirar dúvidas.',
            actionLabel: 'Criar Primeiro Tópico',
            onAction: widget.onNewTopic,
          )
        else ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              CourseHubFilterBar(
                options: _filters,
                selected: _selectedFilter,
                counts: {
                  'Todos': allTopics.length,
                  'Sem Resposta':
                      allTopics.where((t) => !_isAnswered(t)).length,
                  'Respondidos': allTopics.where(_isAnswered).length,
                },
                onSelected: (f) => setState(() => _selectedFilter = f),
              ),
              CourseHubSearchField(
                hintText: 'Buscar tópico ou autor...',
                onChanged: (q) => setState(() => _searchQuery = q),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const CourseHubEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Nenhum tópico corresponde ao filtro',
              subtitle:
                  'Limpe a busca ou altere o filtro de status para visualizar outras discussões.',
            )
          else
            for (final topic in filtered) _buildTopicCard(context, topic),
        ],
      ],
    );
  }

  Widget _buildTopicCard(BuildContext context, Map<String, dynamic> topic) {
    final title = (topic['title'] ?? '').toString();
    final body = (topic['body'] ?? '').toString();
    final author = (topic['authorName'] ?? 'Docente').toString();
    final category = (topic['category'] ?? 'Discussão Acadêmica').toString();
    final replies = (topic['replies'] as List?) ?? const [];
    final isResolved = topic['isResolved'] == true;
    final answered = _isAnswered(topic);

    return CourseHubSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _openTopicModal(context, topic),
      overlineTag: '$category • Por $author',
      title: title,
      headerTrailing: CourseHubBadge(
        label: isResolved
            ? 'Resolvido (${replies.length})'
            : (answered
                  ? '${replies.length} resposta${replies.length > 1 ? 's' : ''}'
                  : 'Aberto'),
        tone: isResolved
            ? CourseHubBadgeTone.success
            : (answered
                  ? CourseHubBadgeTone.info
                  : CourseHubBadgeTone.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (body.isNotEmpty) ...[
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: jakarta(size: 12.5, color: const Color(0xFF52525B)),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 14,
                color: const Color(0xFF71717A),
              ),
              const SizedBox(width: 6),
              Text(
                '${replies.length} interação${replies.length == 1 ? '' : 'ões'}',
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
              const Spacer(),
              CourseHubPillButton(
                label: 'Participar',
                icon: Icons.reply_rounded,
                variant: CourseHubButtonVariant.secondary,
                compact: true,
                onPressed: () => _openTopicModal(context, topic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
