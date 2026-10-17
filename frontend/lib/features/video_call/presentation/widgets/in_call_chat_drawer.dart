// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../controllers/video_call_controller.dart';

/// Gaveta lateral deslizante de chat interno durante a chamada de vídeo.
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
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          AppBar(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text(
              'Chat da Chamada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                key: const Key('close_chat_drawer_button'),
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: widget.controller.toggleChatDrawer,
              ),
            ],
          ),
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
                      Text(
                        '${msg.senderName} (${msg.senderRa})',
                        style: const TextStyle(
                          color: Colors.indigoAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msg.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat_input_field'),
                    controller: _textController,
                    maxLength: 500,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      hintStyle: TextStyle(color: Colors.white54),
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  key: const Key('send_chat_message_button'),
                  icon: const Icon(Icons.send, color: Colors.indigoAccent),
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
