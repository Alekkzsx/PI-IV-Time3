// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702
// Refatorado por Alex Gabriel Soares Sousa - RA: 24802449
// Aula do Dia do Painel Geral - Padrão estético idêntico às referências
// Dados 100% tratados no backend/MongoDB

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/teacher_dashboard_overview.dart';

/// Seção "Aula do Dia" do Painel Geral do Portal Docente.
/// Renderiza lado a lado o card da aula ao vivo (com barra lateral verde de 4px)
/// e o card de Atendimento Docente (Plantão).
class DocenteLiveClassCard extends StatelessWidget {
  final DocenteController controller;
  final VoidCallback onOpenVideoCall;
  final void Function(String courseId) onOpenCourseHub;

  const DocenteLiveClassCard({
    super.key,
    required this.controller,
    required this.onOpenVideoCall,
    required this.onOpenCourseHub,
  });

  @override
  Widget build(BuildContext context) {
    final todayClass = controller.dashboard.todayClass;
    final session = todayClass.session;
    final officeHours = todayClass.officeHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Aula do Dia',
              style: jakarta(
                size: 20,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            Text(
              todayClass.todayBadge,
              style: jakarta(
                size: 11,
                weight: FontWeight.w700,
                color: const Color(0xFF71717A),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 600;
            final liveWidget = session != null
                ? _buildLiveCard(session)
                : _buildNoClassCard();
            final officeWidget = _buildOfficeHoursCard(officeHours);

            if (!isDesktop) {
              return Column(
                children: [
                  liveWidget,
                  const SizedBox(height: 14),
                  officeWidget,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: liveWidget),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: officeWidget),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveCard(TeacherLiveSessionPreview session) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: const Color(0xFF16A34A),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            session.timeRange,
                            style: jakarta(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: const Color(0xFF52525B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                session.statusLabel,
                                style: jakarta(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF166534),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 16,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.connectedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 12,
                            color: const Color(0xFF71717A),
                            weight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF4F4F5)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam_outlined,
                                size: 16,
                                color: Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  session.locationLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(
                                    size: 11.5,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF52525B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          key: const Key('btn_iniciar_transmissao'),
                          onTap: () {
                            controller.selectCourse(session.courseId);
                            onOpenVideoCall();
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  session.buttonLabel,
                                  style: jakarta(
                                    size: 11,
                                    weight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoClassCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Center(
        child: Text(
          'Nenhuma aula programada para hoje.',
          style: jakarta(
            size: 13,
            weight: FontWeight.w600,
            color: const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }

  Widget _buildOfficeHoursCard(TeacherOfficeHoursInfo officeHours) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 24,
                color: Color(0xFFA1A1AA),
              ),
              const SizedBox(height: 12),
              Text(
                officeHours.title,
                textAlign: TextAlign.center,
                style: jakarta(
                  size: 15,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                officeHours.subtitle,
                textAlign: TextAlign.center,
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
