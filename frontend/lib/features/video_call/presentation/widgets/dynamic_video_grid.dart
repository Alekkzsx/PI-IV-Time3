// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import '../../domain/entities/participant.dart';
import '../theme/video_call_theme.dart';
import 'participant_video_tile.dart';
import 'screen_share_view.dart';

/// Responsive dynamic video conferencing grid with Zero Bots assurance.
///
/// Strictly adapts layout presentation according to connected real participants:
/// - N = 0: Renders centered notice 'Nenhum participante conectado'.
/// - N = 1: Renders exactly 1 highlighted central tile (Zero Bots).
/// - N = 2: Horizontal dual-split layout with equitable space distribution.
/// - N = 3 or 4: 2x2 grid via [GridView] with ergonomic aspect ratio (1.3).
/// - N > 4: Expandable scrolling grid.
/// - Screen Sharing Mode: Transitions to spotlight mode with [ScreenShareView]
///   as primary stage and horizontal filmstrip on the bottom.
class DynamicVideoGrid extends StatelessWidget {
  /// Strict list of real participants currently connected to the room.
  final List<Participant> participants;

  /// Indicates whether active screen sharing is displayed on the main stage.
  final bool isScreenSharing;

  /// Optional builder to resolve HTML5 video viewType for each participant.
  final String? Function(Participant)? videoViewTypeBuilder;

  /// Optional viewType of the active screen share stream.
  final String? screenShareViewType;

  /// Optional display name of the participant currently sharing screen.
  final String? activePresenterName;

  /// Identifier of the pinned (spotlight) participant, if any.
  final String? pinnedParticipantId;

  /// Optional callback triggered when tapping a participant video tile.
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
        child: SizedBox.expand(
          child: _buildTile(soleParticipant),
        ),
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
