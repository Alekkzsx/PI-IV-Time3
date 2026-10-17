// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/entities/hand_raise_item.dart';

/// Banner superior exibindo a fila ordenada FIFO de participantes com a mão levantada.
///
/// Permite ao anfitrião e aos demais participantes identificar quem solicitou
/// a palavra, respeitando a ordem cronológica estrita de manifestação.
class RaisedHandsBanner extends StatelessWidget {
  final List<HandRaiseItem> queue;

  const RaisedHandsBanner({super.key, required this.queue});

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('raised_hands_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber.shade900.withValues(alpha: 0.9),
      child: Row(
        children: [
          const Text(
            '✋ Mãos Levantadas: ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: queue.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      key: Key('queue_item_${item.peerId}'),
                      label: Text('${item.name} (${item.ra})'),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
