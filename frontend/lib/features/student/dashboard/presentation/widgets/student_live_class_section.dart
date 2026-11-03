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
                size: 18,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            Text(
              _todayLabel(),
              style: jakarta(
                size: 10.5,
                weight: FontWeight.w700,
                color: const Color(0xFF71717A),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        className?.trim().isNotEmpty == true
            ? _buildLiveCard(context)
            : _buildFreeCard(),
      ],
    );
  }

  Widget _buildLiveCard(BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOpen ? const Color(0xFF86EFAC) : const Color(0xFFE4E4E7),
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
                // Borda de destaque (verde se ao vivo, cinza/âmbar se aguardando)
                Container(
                  width: 4,
                  color: isOpen
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF59E0B),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                time ?? 'Horário não informado',
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
                                color: isOpen
                                    ? const Color(0xFFF0FDF4)
                                    : const Color(0xFFFEF3C7),
                                border: Border.all(
                                  color: isOpen
                                      ? const Color(0xFFBBF7D0)
                                      : const Color(0xFFFDE68A),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isOpen
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFD97706),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOpen
                                        ? 'AO VIVO AGORA'
                                        : 'AGUARDANDO DOCENTE',
                                    style: jakarta(
                                      size: 10.5,
                                      weight: FontWeight.w700,
                                      color: isOpen
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF92400E),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          className ?? 'Disciplina',
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
                          isOpen
                              ? 'Sala aberta • ${teacher ?? "Docente responsável"}'
                              : '${teacher ?? "Docente responsável"} • Sala Fechada',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(
                            size: 12.5,
                            color: isOpen
                                ? const Color(0xFF166534)
                                : const Color(0xFF71717A),
                            weight: isOpen ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        const Divider(height: 28, color: Color(0xFFF4F4F5)),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.videocam_outlined,
                                    size: 16,
                                    color: isOpen
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF71717A),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      isOpen
                                          ? 'Sessão WebRTC Ativa • Transmissão em andamento'
                                          : 'Aguardando professor iniciar a transmissão',
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
                                if (isOpen) {
                                  Navigator.of(context).pushNamed(
                                    '/video-call',
                                    arguments: {'roomCode': roomCode},
                                  );
                                } else {
                                  showDialog<void>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: const Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Color(0xFFD97706),
                                          ),
                                          SizedBox(width: 10),
                                          Text('Aula ainda não iniciada'),
                                        ],
                                      ),
                                      content: Text(
                                        'A sala de ${className ?? "esta disciplina"} ainda não foi aberta. Aguarde o docente responsável iniciar a aula.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: const Text('Entendi'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF27272A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isOpen ? 'Entrar na' : 'Aguardar',
                                          style: jakarta(
                                            size: 10.5,
                                            weight: FontWeight.w600,
                                            color: Colors.white,
                                            height: 1.15,
                                          ),
                                        ),
                                        Text(
                                          'Videochamada',
                                          style: jakarta(
                                            size: 10.5,
                                            weight: FontWeight.w600,
                                            color: Colors.white,
                                            height: 1.15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isOpen
                                          ? Icons.arrow_forward_rounded
                                          : Icons.lock_clock,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 22,
                color: Color(0xFFA1A1AA),
              ),
              const SizedBox(height: 10),
              Text(
                'Horário Livre',
                style: jakarta(
                  size: 14.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                freeMessage ?? 'Nenhuma aula está agendada para este momento.',
                textAlign: TextAlign.center,
                style: jakarta(size: 11.5, color: const Color(0xFF71717A)),
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
