// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:agmrm_security/student/student_security.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaForumTab]
///
/// Aba 3 do Cockpit AVA: Fórum de Dúvidas e Discussões Acadêmicas.
/// Permite pesquisar tópicos, filtrar por status ('Todos', 'Respondidos', 'Abertos'),
/// publicar novas dúvidas com segurança e interagir respondendo diretamente aos tópicos.
class AvaForumTab extends StatefulWidget {
  /// Controlador reativo do portal do estudante.
  final StudentPortalController controller;

  /// Cria uma nova instância de [AvaForumTab].
  const AvaForumTab({super.key, required this.controller});

  @override
  State<AvaForumTab> createState() => _AvaForumTabState();
}

class _AvaForumTabState extends State<AvaForumTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  String _searchQuery = '';

  static const List<String> _filterOptions = [
    'Todos',
    'Respondidos',
    'Abertos',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classCode = widget.controller.selectedDiscipline?.code ?? '';
    final allTopics = widget.controller.forumTopics(classCode);

    final filteredTopics = allTopics.where((t) {
      final title = (t['title'] ?? '').toString().toLowerCase();
      final body = (t['body'] ?? '').toString().toLowerCase();
      final author = (t['authorName'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty || title.contains(q) || body.contains(q) || author.contains(q);

      final status = (t['status'] ?? '').toString().toLowerCase();
      final isAnswered = status.contains('respondido') || t['isResolved'] == true;
      final matchesFilter = switch (_selectedFilter) {
        'Respondidos' => isAnswered,
        'Abertos' => !isAnswered,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    final answeredCount = allTopics.where((t) {
      final s = (t['status'] ?? '').toString().toLowerCase();
      return s.contains('respondido') || t['isResolved'] == true;
    }).length;

    final openCount = allTopics.length - answeredCount;

    final counts = <String, int>{
      'Todos': allTopics.length,
      'Respondidos': answeredCount,
      'Abertos': openCount,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvaOpenSectionHeader(
          title: 'Fórum de Dúvidas e Discussões',
          subtitle:
              'Tire dúvidas com o professor, monitores e interaja com os colegas da disciplina.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AvaSearchPillField(
                controller: _searchController,
                hintText: 'Buscar tópicos...',
                width: 200,
                onChanged: (q) => setState(() => _searchQuery = q.trim()),
              ),
              AvaActionPillButton(
                label: 'Nova Dúvida',
                icon: Icons.add_rounded,
                onPressed: () => _showNewTopicDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AvaFilterPillBar(
          options: _filterOptions,
          selected: _selectedFilter,
          counts: counts,
          onSelected: (filter) => setState(() => _selectedFilter = filter),
        ),
        const SizedBox(height: 20),
        if (filteredTopics.isEmpty)
          const AvaEmptyStateCard(
            icon: Icons.forum_outlined,
            title: 'Nenhuma dúvida ou discussão encontrada.',
            subtitle:
                'Publique uma nova dúvida utilizando o botão "+ Nova Dúvida" ou altere os filtros.',
          )
        else
          for (final topic in filteredTopics) _buildForumTopicCard(context, topic),
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
        (topic['replies'] is List ? (topic['replies'] as List).length : 0);
    final isAnswered = status.toLowerCase().contains('respondido') || topic['isResolved'] == true;

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
                        size: 14,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    if (isAnswered)
                      const AvaStatusBadge(
                        label: 'Respondido',
                        variant: AvaBadgeVariant.success,
                        icon: Icons.check_circle_outline,
                      )
                    else
                      const AvaStatusBadge(
                        label: 'Aberto',
                        variant: AvaBadgeVariant.warning,
                        icon: Icons.help_outline_rounded,
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
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFA1A1AA),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
                height: 1.45,
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
    final topicId = (topic['id'] ?? topic['_id'] ?? '').toString();
    final classCode = widget.controller.selectedDiscipline?.code ?? '';
    final replyController = TextEditingController();

    var isSending = false;

    AvaStandardModal.show<void>(
      context: context,
      overlineTag: 'DISCUSSÃO DO FÓRUM',
      title: topic['title']?.toString() ?? 'Tópico de Discussão',
      subtitle: 'Iniciado por ${topic['authorName'] ?? 'Estudante'} • ${topic['category'] ?? 'Geral'}',
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final rawReplies = topic['replies'];
            final repliesList = rawReplies is List
                ? rawReplies.whereType<Map>().toList()
                : const <Map>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descrição da dúvida
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic['body']?.toString() ?? 'Sem descrição detalhada.',
                        style: jakarta(
                          size: 13,
                          color: const Color(0xFF3F3F46),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Publicado em: ${topic['createdAt'] ?? topic['timeAgo'] ?? 'Recentemente'}',
                        style: jakarta(size: 11, color: const Color(0xFF71717A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Respostas da Comunidade Acadêmica (${repliesList.length}):',
                  style: jakarta(
                    size: 13,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 10),
                if (repliesList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Center(
                      child: Text(
                        'Aguardando resposta do docente, monitores ou colegas.',
                        style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
                      ),
                    ),
                  )
                else
                  for (final r in repliesList) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${r['authorName'] ?? 'Participante'}',
                                style: jakarta(
                                  size: 12.5,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF18181B),
                                ),
                              ),
                              if ((r['authorRole'] ?? '').toString() == 'docente')
                                const AvaStatusBadge(
                                  label: 'Docente',
                                  variant: AvaBadgeVariant.success,
                                  isPill: false,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r['body']?.toString() ?? '',
                            style: jakarta(
                              size: 12.5,
                              color: const Color(0xFF52525B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF4F4F5)),
                const SizedBox(height: 14),

                // Campo de resposta funcional
                Text(
                  'Sua Contribuição ou Resposta:',
                  style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: replyController,
                  maxLines: 3,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    hintText: 'Escreva sua contribuição ou resposta ao tópico...',
                    hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: AvaActionPillButton(
                    label: 'Publicar Resposta',
                    icon: Icons.send_rounded,
                    isLoading: isSending,
                    onPressed: isSending
                        ? null
                        : () async {
                            final text = replyController.text.trim();
                            if (text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Digite sua resposta antes de enviar.')),
                              );
                              return;
                            }
                            setModalState(() => isSending = true);
                            try {
                              await widget.controller.replyForumTopic(
                                classCode: classCode,
                                topicId: topicId,
                                body: text,
                              );
                              if (!context.mounted) return;
                              Navigator.of(modalCtx).pop();
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Resposta publicada com sucesso no fórum!')),
                              );
                            } catch (e) {
                              setModalState(() => isSending = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNewTopicDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var isPosting = false;

    AvaStandardModal.show<void>(
      context: context,
      overlineTag: 'NOVA PUBLICAÇÃO',
      title: 'Publicar Nova Dúvida no Fórum',
      subtitle: 'Sua postagem ficará visível para o professor, monitores e todos os colegas.',
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Título da Dúvida',
                  style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    hintText: 'Ex.: Dúvida sobre a modelagem de agregados no TP2',
                    hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Descrição Detalhada do Problema',
                  style: jakarta(size: 12, weight: FontWeight.w600, color: const Color(0xFF18181B)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  decoration: InputDecoration(
                    hintText: 'Descreva detalhadamente sua dúvida, trecho de código ou contexto da disciplina...',
                    hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AvaActionPillButton(
                      label: 'Cancelar',
                      variant: AvaButtonVariant.secondary,
                      onPressed: () => Navigator.of(modalCtx).pop(),
                    ),
                    const SizedBox(width: 8),
                    AvaActionPillButton(
                      label: 'Publicar Dúvida',
                      icon: Icons.send_rounded,
                      isLoading: isPosting,
                      onPressed: isPosting
                          ? null
                          : () async {
                              final classCode = widget.controller.selectedDiscipline?.code;
                              if (classCode == null || classCode.isEmpty) return;

                              if (!StudentActionRateLimiter.instance.canExecute(StudentActionType.createForumTopic)) {
                                final cooldown = StudentActionRateLimiter.instance.getRemainingCooldownSeconds(
                                  StudentActionType.createForumTopic,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Aguarde $cooldown s antes de publicar outro tópico.')),
                                );
                                return;
                              }

                              final safeTitle = StudentForumContentSanitizer.sanitizeForumTitle(titleController.text);
                              final safeBody = StudentForumContentSanitizer.sanitizeForumBody(descController.text);

                              if (safeTitle.length < StudentSecurityLimits.minForumTitleLength) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('O título deve conter pelo menos ${StudentSecurityLimits.minForumTitleLength} caracteres.'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isPosting = true);
                              try {
                                await widget.controller.createForumTopic(
                                  classCode: classCode,
                                  title: safeTitle,
                                  body: safeBody,
                                );
                                StudentActionRateLimiter.instance.recordAction(StudentActionType.createForumTopic);
                                if (!context.mounted) return;
                                Navigator.of(modalCtx).pop();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Dúvida publicada no fórum com sucesso!')),
                                );
                              } catch (e) {
                                setModalState(() => isPosting = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
