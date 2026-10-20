// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/theme/docente_colors.dart';

/// Card de "Aula do Dia & Plantão" com indicador de transmissão ao vivo e ações rápidas.
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DocenteColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DocenteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aula do Dia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: DocenteColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DocenteColors.dangerLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: DocenteColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AO VIVO • TRANSMITINDO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DocenteColors.danger,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'HOJE, 20 SET • 19:10 - 20:50',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DocenteColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Análise e Projeto de Sistemas II',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DocenteColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '43 alunos conectados no AVA • Lab 04 • Sala Virtual Teams',
            style: TextStyle(
              fontSize: 14,
              color: DocenteColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onOpenVideoCall,
                icon: const Icon(Icons.videocam_rounded, size: 20),
                label: const Text('Iniciar Transmissão'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DocenteColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => onOpenCourseHub('course-aps2'),
                icon: const Icon(Icons.hub_outlined, size: 18),
                label: const Text('Abrir Course Hub'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DocenteColors.textPrimary,
                  side: const BorderSide(color: DocenteColors.borderDark),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DocenteColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.schedule_rounded, size: 18, color: DocenteColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Atendimento Docente:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Plantão de dúvidas e orientação às 17:30 no Gabinete 12.',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: DocenteColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

