// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/entities/participant.dart';
import 'participant_video_tile.dart';
import 'screen_share_view.dart';

/// Grade dinâmica responsiva de videoconferência com garantia de Zero Bots.
///
/// Adapta a disposição visual rigorosamente à contagem de participantes reais:
/// - N = 0: Exibe mensagem informativa centralizada 'Nenhum participante conectado'.
/// - N = 1: Renderiza exatamente 1 quadro em destaque central (Zero Bots).
/// - N = 2: Layout bipartido horizontal (dual split) distribuído equitativamente.
/// - N = 3 ou 4: Grade 2x2 com `GridView` e proporção de aspecto ergonômica (1.3).
/// - N > 4: Grade expansível com rolagem suave.
/// - Modo Compartilhamento de Tela: Transiciona para o modo Spotlight com palco
///   primário [ScreenShareView] no topo e filmstrip horizontal na base.
class DynamicVideoGrid extends StatelessWidget {
  /// Lista estrita de participantes reais atualmente conectados na sala.
  final List<Participant> participants;

  /// Indica se há transmissão de tela ativa no palco principal.
  final bool isScreenSharing;

  /// Callback opcional disparado ao clicar no tile de um participante.
  final void Function(Participant)? onParticipantTap;

  const DynamicVideoGrid({
    super.key,
    required this.participants,
    this.isScreenSharing = false,
    this.onParticipantTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isScreenSharing) {
      return Column(
        children: [
          const Expanded(
            flex: 3,
            child: ScreenShareView(),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                return SizedBox(
                  width: 180,
                  child: ParticipantVideoTile(
                    participant: participant,
                    onTap: onParticipantTap != null
                        ? () => onParticipantTap!(participant)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (participants.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum participante conectado',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (participants.length == 1) {
      final soleParticipant = participants.first;
      return Center(
        child: ParticipantVideoTile(
          participant: soleParticipant,
          onTap: onParticipantTap != null
              ? () => onParticipantTap!(soleParticipant)
              : null,
        ),
      );
    }

    if (participants.length == 2) {
      return Row(
        children: [
          Expanded(
            child: ParticipantVideoTile(
              participant: participants[0],
              onTap: onParticipantTap != null
                  ? () => onParticipantTap!(participants[0])
                  : null,
            ),
          ),
          Expanded(
            child: ParticipantVideoTile(
              participant: participants[1],
              onTap: onParticipantTap != null
                  ? () => onParticipantTap!(participants[1])
                  : null,
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        return ParticipantVideoTile(
          participant: participant,
          onTap: onParticipantTap != null
              ? () => onParticipantTap!(participant)
              : null,
        );
      },
    );
  }
}
