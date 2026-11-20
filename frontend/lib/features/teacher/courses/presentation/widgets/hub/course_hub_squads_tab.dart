// Desenvolvido por Marcelo Zarpelon - RA: 25015323

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/institutional_tokens.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'course_hub_ui.dart';

/// Aba de Equipes e Squads Integradores sincronizada com Colaborações no AVA do Aluno.
class CourseHubSquadsTab extends StatelessWidget {
  final DocenteCourse course;
  final DocenteController controller;
  final VoidCallback onAddSquad;

  const CourseHubSquadsTab({
    super.key,
    required this.course,
    required this.controller,
    required this.onAddSquad,
  });

  Future<void> _removeSquad(BuildContext context, int index) async {
    final squads = course.squads;
    final target = squads[index];
    final confirmed = await CourseHubModal.show<bool>(
      context: context,
      overlineTag: 'GERENCIAR EQUIPES',
      title: 'Remover equipe de projeto',
      subtitle: (target['name'] ?? 'Squad').toString(),
      maxWidth: 440,
      actionsBuilder: (ctx) => [
        CourseHubPillButton(
          label: 'Cancelar',
          variant: CourseHubButtonVariant.secondary,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        CourseHubPillButton(
          label: 'Remover',
          variant: CourseHubButtonVariant.danger,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
      builder: (_) => Text(
        'Tem certeza que deseja excluir esta equipe? Os dados do squad deixarão de aparecer para os alunos.',
        style: jakarta(size: 13, color: const Color(0xFF52525B)),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final updated = <Map<String, Object?>>[];
    for (int i = 0; i < squads.length; i++) {
      if (i == index) continue;
      final sq = squads[i];
      updated.add({
        if (sq['id'] != null) 'id': sq['id'].toString(),
        'name': (sq['name'] ?? 'Equipe').toString(),
        'projectTitle': (sq['projectTitle'] ?? sq['name'] ?? 'Projeto Integrador')
            .toString(),
        if ((sq['repoUrl'] ?? '').toString().isNotEmpty)
          'repoUrl': sq['repoUrl'].toString(),
        if ((sq['sprintStatus'] ?? '').toString().isNotEmpty)
          'sprintStatus': sq['sprintStatus'].toString(),
        'members': ((sq['members'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      });
    }
    final ok = await controller.saveSquads(updated);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Equipe removida com sucesso.'
              : (controller.remoteError ?? 'Erro ao remover equipe.'),
        ),
        backgroundColor: ok
            ? const Color(0xFF18181B)
            : const Color(0xFFB91C1C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final squads = course.squads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CourseHubSectionHeader(
          overline: 'PROJETOS INTEGRADOS • ${course.code}',
          title: 'Equipes de Projeto & Squads Integradores',
          subtitle:
              'Organize grupos com título de projeto, integrantes matriculados e acompanhe os repositórios atualizados pelos discentes.',
          trailing: CourseHubPillButton(
            label: 'Nova Equipe',
            icon: Icons.add_rounded,
            onPressed: onAddSquad,
          ),
        ),
        const SizedBox(height: 18),

        if (squads.isEmpty)
          CourseHubEmptyState(
            icon: Icons.groups_outlined,
            title: 'Nenhuma equipe ou squad cadastrado',
            subtitle:
                'Crie equipes de projeto para que os discentes visualizem os colegas e vinculem repositórios Git no AVA.',
            actionLabel: 'Criar Primeira Equipe',
            onAction: onAddSquad,
          )
        else
          for (int i = 0; i < squads.length; i++)
            _buildSquadCard(context, squads[i], i),
      ],
    );
  }

  Widget _buildSquadCard(
    BuildContext context,
    Map<String, dynamic> squad,
    int index,
  ) {
    final name = (squad['name'] ?? 'Squad Integrador').toString();
    final projectTitle =
        (squad['projectTitle'] ?? 'Projeto sem título definido').toString();
    final repoUrl = (squad['repoUrl'] ?? '').toString();
    final statusLabel =
        (squad['sprintStatus'] ?? squad['status'] ?? 'Em andamento').toString();
    final members = (squad['members'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return CourseHubSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      overlineTag: name.toUpperCase(),
      title: projectTitle,
      headerTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CourseHubBadge(label: statusLabel, tone: CourseHubBadgeTone.success),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _removeSquad(context, index),
            tooltip: 'Remover equipe',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (repoUrl.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.code_rounded, size: 14, color: Color(0xFF52525B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    repoUrl,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'Integrantes (${members.length})',
            style: jakarta(
              size: 11.5,
              weight: FontWeight.w600,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 8),
          if (members.isEmpty)
            Text(
              'Nenhum integrante atribuído.',
              style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: members.map((member) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    member,
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w500,
                      color: InstColors.ink,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
