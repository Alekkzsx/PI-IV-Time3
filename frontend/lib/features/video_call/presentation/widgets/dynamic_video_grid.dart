// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import '../../domain/entities/participant.dart';
import '../theme/video_call_theme.dart';
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

  /// Construtor opcional para obter o `viewType` de vídeo HTML5 de cada participante.
  final String? Function(Participant)? videoViewTypeBuilder;

  /// `viewType` opcional da transmissão de tela ativa.
  final String? screenShareViewType;

  /// Nome opcional do participante que está apresentando a tela.
  final String? activePresenterName;

  /// Identificador do participante fixado (pin/spotlight), se houver.
  final String? pinnedParticipantId;

  /// Callback opcional disparado ao clicar no tile de um participante.
  final void Function(Participant)? onParticipantTap;

  const DynamicVideoGrid({
    super.key,
    required this.participants,
    this.isScreenSharing = false,
    this.videoViewTypeBuilder,
    this.screenShareViewType,
    this.activePresenterName,
    this.pinnedParticipantId,
    this.onParticipantTap,
  });

  Widget _buildTile(Participant participant) {
    return ParticipantVideoTile(
      participant: participant,
      videoViewType: videoViewTypeBuilder?.call(participant),
      isPinned: pinnedParticipantId == participant.id,
      onTap:
          onParticipantTap != null ? () => onParticipantTap!(participant) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isScreenSharing) {
      return Column(
        children: [
          Expanded(
            flex: 3,
            child: ScreenShareView(
              presenterName: activePresenterName,
              videoViewType: screenShareViewType,
            ),
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
                  child: _buildTile(participant),
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
            color: VideoCallColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (participants.length == 1) {
      final soleParticipant = participants.first;
      return Center(
        child: _buildTile(soleParticipant),
      );
    }

    if (participants.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildTile(participants[0])),
          Expanded(child: _buildTile(participants[1])),
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
        return _buildTile(participants[index]);
      },
    );
  }
}
