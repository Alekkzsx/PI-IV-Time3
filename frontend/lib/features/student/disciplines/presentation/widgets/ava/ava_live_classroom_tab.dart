// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/core/state/academic_bridge_service.dart';
import 'package:pi_iv_time3/core/state/app_user_session.dart';
import 'package:pi_iv_time3/features/student/shared/controllers/portal_controller.dart';
import 'common/ava_common.dart';

/// [AvaLiveClassroomTab]
///
/// Aba 2 do Cockpit AVA: Sala Virtual e Aulas Síncronas.
/// Monitora a abertura de transmissões síncronas ao vivo via [AcademicBridgeService]
/// e utiliza componentes canônicos [AvaBannerSurfaceCard] e [AvaOpenSectionHeader],
/// eliminando blocos escuros e garantindo 100% de uniformidade com o Design System.
class AvaLiveClassroomTab extends StatelessWidget {
  /// Controlador reativo que provê a disciplina selecionada.
  final StudentPortalController controller;

  /// Cria uma nova instância de [AvaLiveClassroomTab].
  const AvaLiveClassroomTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AcademicBridgeService.instance,
      builder: (context, _) {
        final discipline = controller.selectedDiscipline;
        final disciplineCode = discipline?.code ?? '';
        final isOpen =
            AcademicBridgeService.instance.isSessionOpen(disciplineCode) ||
            discipline?.isLive == true;
        final session = AcademicBridgeService.instance.getSession(
          disciplineCode,
        );

        final recordedSessions = discipline?.recordedSessions ?? const [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvaOpenSectionHeader(
              title: 'Sala Virtual e Aulas Síncronas',
              subtitle:
                  'Transmissão de aulas ao vivo com registro de presença digital via WebRTC.',
              trailing: AvaActionPillButton(
                key: const Key('btn_ingressar_sala_webrtc'),
                label: isOpen ? 'Ingressar na Sala WebRTC' : 'Aguardando Docente',
                icon: isOpen ? Icons.videocam_rounded : Icons.lock_clock,
                variant: isOpen ? AvaButtonVariant.primary : AvaButtonVariant.secondary,
                onPressed: () => _handleJoinSession(
                  context,
                  isOpen: isOpen,
                  disciplineCode: disciplineCode,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card Principal da Transmissão Canônico (Banner #FAF8F5 + Superfície Branca)
            AvaBannerSurfaceCard(
              overlineTag: 'SALA VIRTUAL INSTITUCIONAL • WEBRTC',
              title: isOpen
                  ? 'Sessão WebRTC Ativa'
                  : 'Transmissão Síncrona Aguardando Docente',
              subtitle: isOpen
                  ? 'Transmitida agora por ${session.openedByName ?? discipline?.professor ?? "Docente Titular"}'
                  : 'Apenas o professor da disciplina ou a coordenação podem abrir a chamada da turma.',
              headerTrailing: AvaStatusBadge(
                label: isOpen ? 'AO VIVO' : 'OFFLINE',
                variant: isOpen ? AvaBadgeVariant.success : AvaBadgeVariant.neutral,
                icon: isOpen ? Icons.sensors : Icons.sensors_off,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFAF8F5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isOpen
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Icon(
                          isOpen
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_outlined,
                          size: 22,
                          color: isOpen
                              ? const Color(0xFF166534)
                              : const Color(0xFF71717A),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOpen
                                  ? 'A aula síncrona está em andamento!'
                                  : 'A sala virtual está fechada no momento.',
                              style: jakarta(
                                size: 14,
                                weight: FontWeight.w700,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'A assiduidade acadêmica é apurada e computada automaticamente durante a permanência na sala WebRTC.',
                              style: jakarta(
                                size: 12.5,
                                color: const Color(0xFF71717A),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF4F4F5)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 24,
                    runSpacing: 10,
                    children: [
                      _buildMetaItem(
                        Icons.meeting_room_outlined,
                        'Código da Turma',
                        disciplineCode.isNotEmpty ? disciplineCode : '—',
                      ),
                      _buildMetaItem(
                        Icons.person_outline,
                        'Docente Titular',
                        discipline?.professor ?? '—',
                      ),
                      _buildMetaItem(
                        Icons.schedule_rounded,
                        'Horário Oficial',
                        discipline?.schedule ?? '—',
                      ),
                      _buildMetaItem(
                        Icons.verified_user_outlined,
                        'Registro de Presença',
                        'Presença digital ativa',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      AvaActionPillButton(
                        label: isOpen
                            ? 'Conectar Agora à Aula'
                            : 'Testar Dispositivos',
                        icon: isOpen
                            ? Icons.play_arrow_rounded
                            : Icons.settings_voice_outlined,
                        variant: isOpen
                            ? AvaButtonVariant.primary
                            : AvaButtonVariant.secondary,
                        onPressed: () => _handleJoinSession(
                          context,
                          isOpen: isOpen,
                          disciplineCode: disciplineCode,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Seção de Aulas Gravadas & Acervo Síncrono
            AvaOpenSectionHeader(
              title: 'Aulas Gravadas e Acervo Síncrono',
              subtitle:
                  'Reveja as gravações oficiais das aulas transmitidas nesta disciplina.',
            ),
            const SizedBox(height: 14),

            if (recordedSessions.isEmpty)
              const AvaEmptyStateCard(
                icon: Icons.video_library_outlined,
                title: 'Nenhuma gravação de aula síncrona arquivada.',
                subtitle:
                    'Assim que uma transmissão ao vivo for finalizada e processada pelo docente, o vídeo aparecerá aqui.',
              )
            else
              Column(
                children: recordedSessions.map((rec) {
                  final title = rec['title']?.toString() ?? 'Aula Síncrona';
                  final date = rec['date']?.toString() ?? 'Data recente';
                  final duration = rec['duration']?.toString() ?? '50 min';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 450;
                        if (isCompact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAF8F5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.play_circle_outline_rounded,
                                      size: 20,
                                      color: Color(0xFF18181B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: jakarta(
                                            size: 13,
                                            weight: FontWeight.w700,
                                            color: const Color(0xFF18181B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$date • Duração: $duration',
                                          style: jakarta(
                                            size: 11.5,
                                            color: const Color(0xFF71717A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              AvaActionPillButton(
                                label: 'Assistir Gravação',
                                icon: Icons.play_arrow_rounded,
                                variant: AvaButtonVariant.secondary,
                                compact: true,
                                fullWidth: true,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Iniciando reprodução de "$title"...',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF8F5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: const Icon(
                                Icons.play_circle_outline_rounded,
                                size: 20,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: jakarta(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFF18181B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$date • Duração: $duration',
                                    style: jakarta(
                                      size: 11.5,
                                      color: const Color(0xFF71717A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AvaActionPillButton(
                              label: 'Assistir Gravação',
                              icon: Icons.play_arrow_rounded,
                              variant: AvaButtonVariant.secondary,
                              compact: true,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Iniciando reprodução de "$title"...',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 310),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF71717A)),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: jakarta(size: 10, color: const Color(0xFF71717A)),
                ),
                Text(
                  value,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: const Color(0xFF18181B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleJoinSession(
    BuildContext context, {
    required bool isOpen,
    required String disciplineCode,
  }) {
    if (isOpen) {
      Navigator.of(context).pushNamed(
        '/video-call',
        arguments: {
          'name': AppUserSession.instance.effectiveName,
          'ra': AppUserSession.instance.identity ?? '',
          'roomCode': disciplineCode,
          'role': 'aluno',
        },
      );
      return;
    }

    AvaStandardModal.show<void>(
      context: context,
      maxWidth: 520,
      overlineTag: 'SALA VIRTUAL INSTITUCIONAL',
      title: 'Sessão Não Iniciada',
      subtitle: 'Aguardando abertura pelo docente responsável',
      builder: (ctx) => Text(
        'A videochamada da disciplina $disciplineCode ainda não foi aberta pelo docente responsável.\n\nApenas o professor da disciplina ou a coordenação podem abrir a chamada da turma.',
        style: jakarta(
          size: 13,
          color: const Color(0xFF52525B),
          height: 1.5,
        ),
      ),
      actions: [
        AvaActionPillButton(
          label: 'Compreendido',
          variant: AvaButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

