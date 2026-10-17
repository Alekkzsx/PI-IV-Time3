// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/entities/emoji_reaction.dart';

/// Overlay transparente para exibição de reações de emoji flutuantes animadas.
///
/// Renderiza os emojis transmitidos em tempo real na tela dos participantes
/// sem interceptar toques ou interações com o restante dos controles da reunião.
class FloatingReactionsOverlay extends StatelessWidget {
  final List<EmojiReaction> reactions;

  const FloatingReactionsOverlay({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: reactions.map((r) {
          final index = reactions.indexOf(r);
          return Positioned(
            key: Key('reaction_item_${r.id}'),
            bottom: 80,
            right: 40 + (index * 30.0) % 200,
            child: Text(
              r.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          );
        }).toList(),
      ),
    );
  }
}
