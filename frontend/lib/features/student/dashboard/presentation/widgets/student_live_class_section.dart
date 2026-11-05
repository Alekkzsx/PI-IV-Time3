// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Seção "Aula do Dia" da Dashboard do Aluno com card de transmissão ao vivo e horário livre.
class StudentLiveClassSection extends StatelessWidget {
  final String? roomCode;
  final String? className;
  final String? time;
  final String? teacher;
  final bool isOpen;
  final String? freeMessage;

  const StudentLiveClassSection({
    super.key,
    this.roomCode,
    this.className,
    this.time,
    this.teacher,
    this.isOpen = false,
    this.freeMessage,
  });

  @override
  Widget build(BuildContext context) {
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
              _todayLabel(),
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
            final isDesktop = constraints.maxWidth >= 640;
            final liveWidget = _buildLiveCard(context);
            final freeWidget = _buildFreeCard();

            if (!isDesktop) {
              return Column(
                children: [
                  liveWidget,
                  const SizedBox(height: 14),
                  freeWidget,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: liveWidget),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: freeWidget),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveCard(BuildContext context) {
    final effectiveClass = className ?? '';
    final effectiveTeacher = teacher ?? 'Docente responsável';
    final effectiveTime = time ?? 'Horário a definir';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE4E4E7),
        ),
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
            // Borda de destaque verde
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
                            border: Border.all(
                              color: const Color(0xFFE4E4E7),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            effectiveTime,
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
                            border: Border.all(
                              color: const Color(0xFFBBF7D0),
                            ),
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
                                'AO VIVO AGORA',
                                style: jakarta(
                                  size: 10.5,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF166534),
                                  letterSpacing: 0.5,
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
                          effectiveClass,
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
                          effectiveTeacher,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 12.5,
                            color: const Color(0xFF71717A),
                            weight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Sala Virtual AVA • Teams Link',
                                  overflow: TextOverflow.ellipsis,
                                  style: jakarta(
                                    size: 11.5,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF71717A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          key: const Key('btn_entrar_videochamada'),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/video-call',
                              arguments: {'roomCode': roomCode ?? 'APS-II'},
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Entrar na\nVideochamada',
                                  style: jakarta(
                                    size: 10.5,
                                    weight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(width: 8),
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

  Widget _buildFreeCard() {
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
                'Horário Livre',
                style: jakarta(
                  size: 15,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                freeMessage ?? 'Reservado para estudos e atividades práticas',
                textAlign: TextAlign.center,
                style: jakarta(size: 12, color: const Color(0xFF71717A)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _todayLabel() {
    const weekdays = [
      'DOMINGO', 'SEGUNDA', 'TERÇA', 'QUARTA', 'QUINTA', 'SEXTA', 'SÁBADO',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday % 7]}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';
  }
}
