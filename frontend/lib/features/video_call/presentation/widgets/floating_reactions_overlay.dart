// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/entities/emoji_reaction.dart';

/// Overlay transparente para exibição de reações de emoji flutuantes animadas.
///
/// Renderiza os emojis transmitidos em tempo real na tela dos participantes
/// com animação suave de subida vertical e fade-out, sem interceptar toques.
class FloatingReactionsOverlay extends StatelessWidget {
  final List<EmojiReaction> reactions;

  const FloatingReactionsOverlay({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: reactions.asMap().entries.map((entry) {
          final index = entry.key;
          final r = entry.value;
          return _RisingReactionParticle(
            key: ValueKey('particle_${r.id}'),
            reaction: r,
            index: index,
          );
        }).toList(),
      ),
    );
  }
}

class _RisingReactionParticle extends StatefulWidget {
  final EmojiReaction reaction;
  final int index;

  const _RisingReactionParticle({
    super.key,
    required this.reaction,
    required this.index,
  });

  @override
  State<_RisingReactionParticle> createState() =>
      _RisingReactionParticleState();
}

class _RisingReactionParticleState extends State<_RisingReactionParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _bottomAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    _bottomAnimation = Tween<double>(begin: 60.0, end: 280.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return Positioned(
          key: Key('reaction_item_${widget.reaction.id}'),
          bottom: _bottomAnimation.value,
          right: 40 + (widget.index * 30.0) % 200,
          child: Opacity(
            opacity: _opacityAnimation.value.clamp(0.0, 1.0),
            child: Text(
              widget.reaction.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        );
      },
    );
  }
}
