// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaChatTab]
///
/// Aba 10 do Cockpit AVA: Canal de Avisos e Chat da Turma.
/// Apresenta o histórico síncrono de mensagens e comunicados da turma com
/// persistência em tempo real no MongoDB e publicação instantânea.
class AvaChatTab extends StatefulWidget {
  /// Controlador opcional injetado ou obtido do singleton.
  final StudentPortalController? controller;

  /// Cria uma nova instância de [AvaChatTab].
  const AvaChatTab({super.key, this.controller});

  @override
  State<AvaChatTab> createState() => _AvaChatTabState();
}

class _AvaChatTabState extends State<AvaChatTab> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  StudentPortalController get _controller =>
      widget.controller ?? StudentPortalController.instance;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String classCode) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _controller.sendClassChatMessage(classCode, text);
      _inputController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final discipline = _controller.selectedDiscipline;
        final classCode = discipline?.code ?? '';
        final messages =
            discipline?.chatMessages ?? const <Map<String, dynamic>>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvaOpenSectionHeader(
              title: 'Canal de Avisos e Chat da Turma',
              subtitle:
                  'Mensagens rápidas, avisos do docente e interação síncrona dos participantes da turma.',
            ),
            const SizedBox(height: 20),

            AvaBannerSurfaceCard(
              title: 'Canal Geral • $classCode',
              subtitle: 'Interação e comunicados da turma em tempo real',
              headerTrailing: AvaStatusBadge(
                label: '${messages.length} Mensagens',
                variant: AvaBadgeVariant.neutral,
              ),
              child: Column(
                children: [
                  if (messages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: AvaEmptyStateCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Nenhuma mensagem enviada ainda.',
                        subtitle:
                            'Envie uma mensagem ou comunicado para a turma no campo abaixo.',
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 460),
                      child: ListView.separated(
                        controller: _scrollController,
                        shrinkWrap: true,
                        itemCount: messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final role = (msg['authorRole'] ?? 'aluno').toString();
                          final authorName =
                              (msg['authorName'] ?? 'Participante').toString();
                          final content =
                              (msg['message'] ?? msg['body'] ?? '').toString();
                          final timestamp =
                              (msg['timestamp'] ?? msg['createdAt'] ?? '')
                                  .toString();

                          final isDocente = role == 'docente';
                          final isMonitor = role == 'monitor';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDocente
                                  ? const Color(0xFFFFFBEB)
                                  : const Color(0xFFFAF8F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDocente
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 13,
                                      backgroundColor: isDocente
                                          ? const Color(0xFFD97706)
                                          : (isMonitor
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF71717A)),
                                      child: Text(
                                        authorName.isNotEmpty
                                            ? authorName[0].toUpperCase()
                                            : 'U',
                                        style: jakarta(
                                          size: 11,
                                          weight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              authorName,
                                              style: jakarta(
                                                size: 13,
                                                weight: FontWeight.w700,
                                                color: const Color(0xFF18181B),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          AvaStatusBadge(
                                            label: isDocente
                                                ? 'Docente'
                                                : (isMonitor
                                                    ? 'Monitor'
                                                    : 'Aluno'),
                                            variant: isDocente
                                                ? AvaBadgeVariant.warning
                                                : (isMonitor
                                                    ? AvaBadgeVariant.neutral
                                                    : AvaBadgeVariant.neutral),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (timestamp.isNotEmpty)
                                      Text(
                                        timestamp.length > 10
                                            ? timestamp.substring(0, 10)
                                            : timestamp,
                                        style: jakarta(
                                          size: 11,
                                          color: const Color(0xFFA1A1AA),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  content,
                                  style: jakarta(
                                    size: 13,
                                    color: const Color(0xFF27272A),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF4F4F5)),
                  const SizedBox(height: 14),

                  // Barra de input
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _inputController,
                            style: jakarta(
                              size: 13,
                              color: const Color(0xFF18181B),
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Digite uma mensagem ou aviso para a turma...',
                              hintStyle: jakarta(
                                size: 13,
                                color: const Color(0xFFA1A1AA),
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) {
                              if (classCode.isNotEmpty) {
                                _sendMessage(classCode);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: (_isSending || classCode.isEmpty)
                            ? null
                            : () => _sendMessage(classCode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF18181B),
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                          elevation: 0,
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
