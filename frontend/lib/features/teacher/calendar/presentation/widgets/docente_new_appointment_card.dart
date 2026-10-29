// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/academic_event.dart';

/// Card para formulário de cadastro de novo agendamento acadêmico ou plantão docente.
class DocenteNewAppointmentCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final TextEditingController locationController;
  final EventType selectedType;
  final ValueChanged<EventType?> onTypeChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const DocenteNewAppointmentCard({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.dateController,
    required this.timeController,
    required this.locationController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onCancel,
    required this.onSave,
  });

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: jakarta(
        size: 13,
        weight: FontWeight.w400,
        color: const Color(0xFFA1A1AA),
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
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
          size: 11.5,
          weight: FontWeight.w500,
          color: const Color(0xFF3F3F46),
        ),
      ),
    );
  }

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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Novo Agendamento Institucional',
              style: jakarta(
                size: 14,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 18),
            // Linha 1: Título e Tipo de Compromisso
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Título do Compromisso'),
                      TextFormField(
                        controller: titleController,
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w400,
                          color: const Color(0xFF18181B),
                        ),
                        decoration: _inputDecoration(
                          hintText:
                              'Ex: Plantão de Dúvidas para a Prova P1 - Análise e Projeto de Sistemas II',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Informe o título do compromisso'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Tipo de Compromisso'),
                      DropdownButtonFormField<EventType>(
                        initialValue: selectedType,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF71717A),
                        ),
                        decoration: _inputDecoration(),
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w400,
                          color: const Color(0xFF18181B),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: EventType.plantao,
                            child: Text('Plantão de Atendimento ao Aluno'),
                          ),
                          DropdownMenuItem(
                            value: EventType.aula,
                            child: Text('Aula / Laboratório'),
                          ),
                          DropdownMenuItem(
                            value: EventType.avaliacao,
                            child: Text('Avaliação Regimental'),
                          ),
                          DropdownMenuItem(
                            value: EventType.colegiado,
                            child: Text('Reunião / Colegiado'),
                          ),
                        ],
                        onChanged: onTypeChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Linha 2: Data, Horário e Local
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Data'),
                      TextFormField(
                        controller: dateController,
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w400,
                          color: const Color(0xFF18181B),
                        ),
                        decoration: _inputDecoration(
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Color(0xFF71717A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Horário'),
                      TextFormField(
                        controller: timeController,
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w400,
                          color: const Color(0xFF18181B),
                        ),
                        decoration: _inputDecoration(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Local / Gabinete / Sala'),
                      TextFormField(
                        controller: locationController,
                        style: jakarta(
                          size: 13,
                          weight: FontWeight.w400,
                          color: const Color(0xFF18181B),
                        ),
                        decoration: _inputDecoration(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Ações do Formulário (Cancelar e Salvar na Agenda)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF18181B),
                    side: const BorderSide(color: Color(0xFFD4D4D8)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: Text(
                    'Cancelar',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w500,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Salvar na Agenda',
                    style: jakarta(
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
