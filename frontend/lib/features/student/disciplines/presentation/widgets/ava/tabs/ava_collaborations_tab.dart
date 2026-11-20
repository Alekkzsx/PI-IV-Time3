// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import '../common/ava_common.dart';

/// [AvaCollaborationsTab]
///
/// Aba 8 do Cockpit AVA: Projetos e Colaborações em Equipe (Squads).
/// Permite o acompanhamento de grupos de trabalho, integrantes, sprints e repositórios
/// com sincronização completa no backend/MongoDB.
class AvaCollaborationsTab extends StatelessWidget {
  /// Controlador opcional injetado ou obtido do singleton.
  final StudentPortalController? controller;

  /// Cria uma nova instância de [AvaCollaborationsTab].
  const AvaCollaborationsTab({super.key, this.controller});

  StudentPortalController get _controller =>
      controller ?? StudentPortalController.instance;

  void _openUpdateSquadModal(
    BuildContext context, {
    required String classCode,
    required Map<String, dynamic> squad,
  }) {
    final titleCtrl = TextEditingController(
      text: squad['projectTitle']?.toString() ?? '',
    );
    final sprintCtrl = TextEditingController(
      text: squad['sprintStatus']?.toString() ?? '',
    );
    final repoCtrl = TextEditingController(
      text: squad['repoUrl']?.toString() ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AvaStandardModal(
          title: 'Atualizar Dados do Squad',
          subtitle: (squad['name'] ?? 'Squad Integrador').toString(),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancelar',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w600,
                  color: const Color(0xFF71717A),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _controller.updateSquad(
                    classCode: classCode,
                    squadId: (squad['id'] ?? '').toString(),
                    projectTitle: titleCtrl.text,
                    sprintStatus: sprintCtrl.text,
                    repoUrl: repoCtrl.text,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dados do squad atualizados com sucesso.'),
                        backgroundColor: Color(0xFF18181B),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao atualizar: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF18181B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                elevation: 0,
              ),
              child: Text(
                'Salvar Alterações',
                style: jakarta(
                  size: 13,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Título do Projeto / Entregável:',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                style: jakarta(size: 13, color: const Color(0xFF18181B)),
                decoration: InputDecoration(
                  hintText: 'Ex: Sistema de Gestão Distribuída',
                  hintStyle: jakarta(size: 13, color: const Color(0xFFA1A1AA)),
                  filled: true,
                  fillColor: const Color(0xFFFAF8F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Status da Sprint Atual:',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: sprintCtrl,
                style: jakarta(size: 13, color: const Color(0xFF18181B)),
                decoration: InputDecoration(
                  hintText: 'Ex: Sprint 3 • Em Homologação',
                  hintStyle: jakarta(size: 13, color: const Color(0xFFA1A1AA)),
                  filled: true,
                  fillColor: const Color(0xFFFAF8F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Link do Repositório Git (GitHub / GitLab):',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: repoCtrl,
                style: jakarta(size: 13, color: const Color(0xFF18181B)),
                decoration: InputDecoration(
                  hintText: 'https://github.com/usuario/projeto',
                  hintStyle: jakarta(size: 13, color: const Color(0xFFA1A1AA)),
                  filled: true,
                  fillColor: const Color(0xFFFAF8F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final discipline = _controller.selectedDiscipline;
        final squads = discipline?.squads ?? const <Map<String, dynamic>>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvaOpenSectionHeader(
              title: 'Projetos e Colaborações em Equipe',
              subtitle:
                  'Espaço de acompanhamento de squads, sprints ágeis e repositórios compartilhados.',
              trailing: ElevatedButton.icon(
                onPressed: () => _controller.setAvaTab(1),
                icon: const Icon(
                  Icons.assignment_outlined,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  'Ver Entregas da Turma',
                  style: jakarta(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (squads.isEmpty)
              const AvaEmptyStateCard(
                icon: Icons.groups_outlined,
                title: 'Nenhum squad registrado para esta disciplina.',
                subtitle:
                    'Os grupos de trabalho serão disponibilizados pelo docente conforme o cronograma de projetos.',
              )
            else
              for (final squad in squads) ...[
                AvaBannerSurfaceCard(
                  title: (squad['name'] ?? 'Squad Integrador').toString(),
                  subtitle: 'Equipe de desenvolvimento e entregas contínuas',
                  headerTrailing: AvaStatusBadge(
                    label: (squad['sprintStatus'] ?? 'Em Andamento').toString(),
                    variant: AvaBadgeVariant.warning,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.layers_outlined,
                            size: 18,
                            color: Color(0xFF71717A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (squad['projectTitle'] ??
                                      'Projeto Integrador da Disciplina')
                                  .toString(),
                              style: jakarta(
                                size: 14,
                                weight: FontWeight.w700,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Membros
                      Text(
                        'Integrantes da Equipe:',
                        style: jakarta(
                          size: 12,
                          weight: FontWeight.w700,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (squad['members'] is List)
                            for (final m in (squad['members'] as List))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 14,
                                      color: Color(0xFF71717A),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      m.toString(),
                                      style: jakarta(
                                        size: 12,
                                        weight: FontWeight.w600,
                                        color: const Color(0xFF18181B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),

                      if (squad['repoUrl'] != null &&
                          squad['repoUrl'].toString().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.code_rounded,
                                size: 16,
                                color: Color(0xFF18181B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  squad['repoUrl'].toString(),
                                  style: jakarta(
                                    size: 12,
                                    color: const Color(0xFF2563EB),
                                    weight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF4F4F5)),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (discipline != null) {
                              _openUpdateSquadModal(
                                context,
                                classCode: discipline.code,
                                squad: squad,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.edit_note_rounded,
                            size: 16,
                            color: Color(0xFF18181B),
                          ),
                          label: Text(
                            'Atualizar Repositório / Sprint',
                            style: jakarta(
                              size: 12,
                              weight: FontWeight.w600,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
    );
  }
}
