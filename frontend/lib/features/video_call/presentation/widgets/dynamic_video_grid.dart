// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../../domain/entities/participant.dart';
import '../theme/video_call_theme.dart';
import 'participant_video_tile.dart';
import 'screen_share_view.dart';

/// Grade dinâmica e responsiva de videoconferência com garantia de zero bots.
///
/// Adapta estritamente a apresentação do layout conforme os participantes reais conectados:
/// - N = 0: Renderiza o aviso centralizado 'Nenhum participante conectado'.
/// - N = 1: Renderiza exatamente 1 bloco central em destaque (zero bots).
/// - N = 2: Layout dividido horizontalmente em duas partes com distribuição equitativa de espaço.
/// - N = 3 ou 4: Grade 2x2 via [GridView] com proporção ergonômica (1.3).
/// - N > 4: Grade expansível com rolagem.
/// - Modo de Compartilhamento de Tela: Transiciona para o modo destaque com [ScreenShareView]
///   como palco principal e faixa horizontal de miniaturas na parte inferior.
class DynamicVideoGrid extends StatelessWidget {
  /// Lista estrita de participantes reais atualmente conectados à sala.
  final List<Participant> participants;

  /// Indica se o compartilhamento de tela ativo está sendo exibido no palco principal.
  final bool isScreenSharing;

  /// Construtor opcional para resolver o viewType de vídeo HTML5 para cada participante.
  final String? Function(Participant)? videoViewTypeBuilder;

  /// viewType opcional do stream de compartilhamento de tela ativo.
  final String? screenShareViewType;

  /// Nome de exibição opcional do participante que está compartilhando a tela.
  final String? activePresenterName;

  /// Identificador do participante fixado (em destaque), se houver.
  final String? pinnedParticipantId;

  /// Callback opcional acionado ao tocar no bloco de vídeo de um participante.
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
      onTap: onParticipantTap != null
          ? () => onParticipantTap!(participant)
          : null,
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
                return SizedBox(width: 180, child: _buildTile(participant));
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
      return Center(child: SizedBox.expand(child: _buildTile(soleParticipant)));
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
