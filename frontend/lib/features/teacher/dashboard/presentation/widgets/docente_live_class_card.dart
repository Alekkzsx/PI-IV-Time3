// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';

/// Seção "Aula do Dia" do Portal Docente contendo a aula ao vivo e o plantão de atendimento.
class DocenteLiveClassCard extends StatelessWidget {
  final VoidCallback onOpenVideoCall;
  final void Function(String courseId) onOpenCourseHub;

  const DocenteLiveClassCard({
    super.key,
    required this.onOpenVideoCall,
    required this.onOpenCourseHub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da Seção
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Aula do Dia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF09090B),
              ),
            ),
            Text(
              'HOJE, 20 SET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF71717A),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid/Row com Aula ao Vivo e Plantão
        LayoutBuilder(
          builder: (context, box) {
            final isSmall = box.maxWidth < 750;

            final liveCard = Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Stack(
                children: [
                  // Borda verde vertical no canto esquerdo
                  Positioned(
                    left: -18,
                    top: -18,
                    bottom: -18,
                    child: Container(
                      width: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '19:10 • 20:50',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF09090B),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
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
                                  const SizedBox(width: 5),
                                  const Text(
                                    'AO VIVO • TRANSMITINDO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Análise e Projeto de Sistemas II',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF09090B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '43 alunos conectados no AVA',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF71717A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.videocam_outlined,
                                  size: 16,
                                  color: Color(0xFF16A34A),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Lab 04 • Sala Virtual Teams',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF52525B),
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: onOpenVideoCall,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF18181B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Iniciar Transmissão',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            final plantaoCard = Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Color(0xFF71717A),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Atendimento Docente',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF09090B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Plantão de dúvidas e orientação às 17:30',
                      style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );

            if (isSmall) {
              return Column(
                children: [liveCard, const SizedBox(height: 12), plantaoCard],
              );
            }

            return Row(
              children: [
                Expanded(flex: 58, child: liveCard),
                const SizedBox(width: 14),
                Expanded(flex: 42, child: plantaoCard),
              ],
            );
          },
        ),
      ],
    );
  }
}
