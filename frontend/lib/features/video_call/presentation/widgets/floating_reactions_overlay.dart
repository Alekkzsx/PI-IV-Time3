// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/entities/emoji_reaction.dart';
import '../theme/video_call_theme.dart';

/// Overlay transparente para exibição de reações de emoji flutuantes animadas.
///
/// Renderiza os emojis transmitidos em tempo real na área inferior-esquerda/central
/// do palco de vídeo com animação suave de subida vertical e fade-out, garantindo
/// que jamais fiquem escondidos atrás da gaveta lateral de chat ou no canto superior direito.
class FloatingReactionsOverlay extends StatelessWidget {
  final List<EmojiReaction> reactions;

  const FloatingReactionsOverlay({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
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
          left: 40 + (widget.index * 36.0) % 220,
          child: Opacity(
            opacity: _opacityAnimation.value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: VideoCallColors.surfaceElevated.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: VideoCallColors.borderStrong,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.reaction.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  if (widget.reaction.senderName.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      widget.reaction.senderName,
                      style: const TextStyle(
                        color: VideoCallColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
