// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../controllers/video_call_controller.dart';
import '../theme/video_call_theme.dart';

/// Gaveta lateral deslizante de chat interno durante a chamada de vídeo (Estética Preto, Cinza e Branco).
///
/// Permite o envio e recebimento de mensagens instantâneas sincronizadas via P2P,
/// exibindo cabeçalho institucional do remetente (Nome e RA), carimbo de data/hora
/// e rolagem automática para a mensagem mais recente.
class InCallChatDrawer extends StatefulWidget {
  final VideoCallController controller;

  const InCallChatDrawer({super.key, required this.controller});

  @override
  State<InCallChatDrawer> createState() => _InCallChatDrawerState();
}

class _InCallChatDrawerState extends State<InCallChatDrawer> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      widget.controller.sendChatMessage(text);
      _textController.clear();
      // Rola para a mensagem mais recente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('in_call_chat_drawer'),
      width: 320,
      decoration: const BoxDecoration(
        color: VideoCallColors.surface,
        border: Border(
          left: BorderSide(color: VideoCallColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          AppBar(
            backgroundColor: VideoCallColors.background,
            elevation: 0,
            title: const Text(
              'Chat da Chamada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: VideoCallColors.textPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                key: const Key('close_chat_drawer_button'),
                icon: const Icon(
                  Icons.close,
                  color: VideoCallColors.textSecondary,
                ),
                onPressed: widget.controller.toggleChatDrawer,
              ),
            ],
          ),
          const Divider(color: VideoCallColors.border, height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.controller.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = widget.controller.chatMessages[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${msg.senderName} (${msg.senderRa})',
                              style: const TextStyle(
                                color: VideoCallColors.accentWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                            key: const Key('chat_message_timestamp'),
                            style: const TextStyle(
                              color: VideoCallColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: VideoCallColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: VideoCallColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: const TextStyle(
                            color: VideoCallColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(color: VideoCallColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat_input_field'),
                    controller: _textController,
                    maxLength: 500,
                    style: const TextStyle(color: VideoCallColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      hintStyle:
                          const TextStyle(color: VideoCallColors.textMuted),
                      counterText: '',
                      filled: true,
                      fillColor: VideoCallColors.background,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: VideoCallColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: VideoCallColors.accentWhite,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: const Key('send_chat_message_button'),
                  icon: const Icon(
                    Icons.send,
                    color: VideoCallColors.accentWhite,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
