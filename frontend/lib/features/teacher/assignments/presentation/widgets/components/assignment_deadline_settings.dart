// Desenvolvido por Guilherme Henrique Moreira - RA: 25006702

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Configurações moleculares de prazo limite, modalidade e entrega tardia.
class AssignmentDeadlineSettings extends StatelessWidget {
  final TextEditingController dueDateController;
  final VoidCallback onPickDueDate;
  final String selectedModality;
  final ValueChanged<String?> onModalityChanged;
  final bool allowLate;
  final ValueChanged<bool> onAllowLateChanged;

  const AssignmentDeadlineSettings({
    super.key,
    required this.dueDateController,
    required this.onPickDueDate,
    required this.selectedModality,
    required this.onModalityChanged,
    required this.allowLate,
    required this.onAllowLateChanged,
  });

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: jakarta(
        size: 13,
        weight: FontWeight.w400,
        color: const Color(0xFFA1A1AA),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: jakarta(
          size: 12,
          weight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Prazo Limite'),
                  TextFormField(
                    controller: dueDateController,
                    readOnly: true,
                    onTap: onPickDueDate,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Selecione data e horário'
                        : null,
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w500,
                      color: const Color(0xFF18181B),
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Selecionar data e horário',
                    ).copyWith(
                      suffixIcon: const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Modalidade'),
                  DropdownButtonFormField<String>(
                    initialValue: selectedModality,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF71717A),
                    ),
                    decoration: _inputDecoration(),
                    style: jakarta(
                      size: 13,
                      weight: FontWeight.w500,
                      color: const Color(0xFF18181B),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Trabalho em Grupo (Até 4 integrantes)',
                        child: Text('Trabalho em Grupo (Até 4)'),
                      ),
                      DropdownMenuItem(
                        value: 'Trabalho Individual',
                        child: Text('Trabalho Individual'),
                      ),
                    ],
                    onChanged: onModalityChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Checkbox late submission
        InkWell(
          onTap: () => onAllowLateChanged(!allowLate),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: allowLate,
                    onChanged: (v) => onAllowLateChanged(v ?? true),
                    activeColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Permitir submissão com penalidade após o prazo',
                    style: jakarta(
                      size: 12.5,
                      weight: FontWeight.w400,
                      color: const Color(0xFF3F3F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
