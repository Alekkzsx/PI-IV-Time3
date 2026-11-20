// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';

/// [SubmissionIntegrityTerm]
///
/// Cartão de declaração regimental de integridade acadêmica e anti-plágio
/// com caixa de seleção obrigatória antes da submissão.
class SubmissionIntegrityTerm extends StatelessWidget {
  /// Estado atual de concordância com o termo.
  final bool agreed;

  /// Callback de alteração do checkbox.
  final ValueChanged<bool> onChanged;

  /// Cria uma nova instância de [SubmissionIntegrityTerm].
  const SubmissionIntegrityTerm({
    super.key,
    required this.agreed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: agreed,
            activeColor: const Color(0xFFD97706),
            onChanged: (val) => onChanged(val ?? false),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Declaração de Integridade Acadêmica & Anti-Plágio',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Declaro formalmente sob as penalidades regimentais que o artefato submetido é de minha autoria autêntica e não constitui cópia não autorizada, plágio ou violação às normas pedagógicas da instituição.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF78350F),
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
