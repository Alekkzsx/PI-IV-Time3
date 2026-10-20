// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

const _ink = Color(0xFF1A1A1A);
const _muted = Color(0xFF737373);
const _faint = Color(0xFFA3A3A3);
const _border = Color(0xFFE5E5E5);
const _stone = Color(0xFFFAF9F6);

/// Seção "Aula do Dia" da Dashboard do Aluno com card de transmissão ao vivo e horário livre.
class StudentLiveClassSection extends StatelessWidget {
  const StudentLiveClassSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Aula do Dia',
                style: jakarta(size: 18, weight: FontWeight.w500)),
            Text('HOJE, 20 SET',
                style: jakarta(
                    size: 9.5,
                    weight: FontWeight.w600,
                    color: _muted,
                    letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 560) {
            return Column(children: [
              _buildLiveCard(context),
              const SizedBox(height: 12),
              SizedBox(height: 150, child: _buildFreeCard()),
            ]);
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildLiveCard(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildFreeCard()),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLiveCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: const Color(0xFF16A34A)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F4F0),
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          '19:00 - 20:40',
                          style: TextStyle(
                            fontFamily: 'Courier New',
                            fontFamilyFallback: ['Consolas', 'monospace'],
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text('AO VIVO AGORA',
                                style: jakarta(
                                    size: 9,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFF15803D),
                                    letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Análise e Projeto de Sistemas II',
                      style: jakarta(size: 14.5, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text('Profa. Dra. Helena Bittencourt',
                      style: jakarta(size: 10, color: _muted)),
                  const SizedBox(height: 12),
                  Container(height: 1, color: const Color(0xFFF0F0F0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.videocam_outlined,
                          size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Sala Virtual AVA • Teams Link',
                            style: jakarta(size: 9.5)),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: _ink,
                        borderRadius: BorderRadius.circular(4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () =>
                              Navigator.of(context).pushNamed('/video-call'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Entrar na\nVideochamada',
                                    style: jakarta(
                                        size: 9,
                                        weight: FontWeight.w600,
                                        color: Colors.white,
                                        height: 1.2)),
                                const SizedBox(width: 14),
                                const Icon(Icons.arrow_forward,
                                    size: 11, color: Colors.white),
                              ],
                            ),
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
    );
  }

  Widget _buildFreeCard() {
    return Container(
      decoration: BoxDecoration(
        color: _stone,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: _faint),
            const SizedBox(height: 10),
            Text('Horário Livre',
                style: jakarta(
                    size: 12,
                    weight: FontWeight.w600,
                    color: const Color(0xFF525252))),
            const SizedBox(height: 4),
            Text('Reservado para estudos e atividades práticas',
                textAlign: TextAlign.center,
                style: jakarta(size: 9.5, color: _muted)),
          ],
        ),
      ),
    );
  }
}

