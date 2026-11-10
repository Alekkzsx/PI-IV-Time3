// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Seção atômica para controle de visibilidade de e-mail e presença online institucional.
class PrivacyVisibilitySection extends StatelessWidget {
  final bool exibirEmailTurma;
  final bool mostrarStatusPresenca;
  final ValueChanged<bool?> onExibirEmailChanged;
  final ValueChanged<bool?> onMostrarStatusChanged;

  const PrivacyVisibilitySection({
    super.key,
    required this.exibirEmailTurma,
    required this.mostrarStatusPresenca,
    required this.onExibirEmailChanged,
    required this.onMostrarStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visibilidade de Perfil & Dados entre Colegas',
            style: jakarta(
              size: 14,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Controle quais informações ficam visíveis para outros docentes e alunos da instituição.',
            style: jakarta(size: 12, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 20),

          // Exibir e-mail nas turmas
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: exibirEmailTurma,
                  onChanged: onExibirEmailChanged,
                  activeColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exibir meu e-mail institucional nas listagens de turma',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Permite que alunos matriculados vejam seu e-mail funcional na lista de participantes da disciplina.',
                      style: jakarta(
                        size: 11,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFFF4F4F5)),

          // Mostrar status de presença
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: mostrarStatusPresenca,
                  onChanged: onMostrarStatusChanged,
                  activeColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mostrar status de presença ("Online recentemente")',
                      style: jakarta(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Exibe indicador de presença ativa para colegas de departamento e alunos quando estiver logado.',
                      style: jakarta(
                        size: 11,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
