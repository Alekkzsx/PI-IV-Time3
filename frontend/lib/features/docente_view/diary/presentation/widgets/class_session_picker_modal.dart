// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/docente_view/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/docente_view/shared/domain/models/attendance_record.dart';

/// Modal institucional para o professor visualizar e selecionar a data/aula letiva da turma.
/// Respeita estritamente o calendário de dias de aula da disciplina (ex: Segundas e Quartas).
class ClassSessionPickerModal extends StatefulWidget {
  final DocenteController controller;

  const ClassSessionPickerModal({
    super.key,
    required this.controller,
  });

  @override
  State<ClassSessionPickerModal> createState() => _ClassSessionPickerModalState();
}

class _ClassSessionPickerModalState extends State<ClassSessionPickerModal> {
  int _filterIndex = 0; // 0 = Todas, 1 = Homologadas, 2 = Pendentes

  Future<void> _openInteractiveCalendar() async {
    final course = widget.controller.selectedCourse;
    final allowedWeekdays = course.classWeekdays;
    final currentSession = widget.controller.currentSession;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentSession.sessionDate,
      firstDate: DateTime(2026, 8, 1),
      lastDate: DateTime(2026, 12, 20),
      helpText: 'CALENDÁRIO DA TURMA (${course.classDaysLabel.toUpperCase()})',
      confirmText: 'SELECIONAR AULA',
      cancelText: 'CANCELAR',
      selectableDayPredicate: (DateTime day) {
        // Apenas dias em que a turma tem aula são selecionáveis
        return allowedWeekdays.contains(day.weekday);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF18181B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF18181B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      widget.controller.selectSessionByDate(picked);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Aula carregada: ${widget.controller.formatSessionDate(picked)}',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final course = controller.selectedCourse;
    final sessions = controller.sessionsForSelectedCourse;
    final activeSession = controller.currentSession;

    final filteredSessions = sessions.where((s) {
      if (_filterIndex == 1) return s.isHomologated;
      if (_filterIndex == 2) return !s.isHomologated;
      return true;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do Modal
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      size: 22,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Grade de Aulas e Chamadas do Semestre',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF09090B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${course.code} • ${course.title}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF71717A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF71717A)),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Informativo de Dias de Aula Regimentais
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF18181B)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aulas regimentais: ${course.classDaysLabel} (${course.schedule}) • ${course.room}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(0, 'Todas (${sessions.length})'),
                  _buildFilterChip(1, 'Homologadas (${sessions.where((s) => s.isHomologated).length})'),
                  _buildFilterChip(2, 'Aguardando (${sessions.where((s) => !s.isHomologated).length})'),
                ],
              ),
              const SizedBox(height: 16),

              // Lista de Sessões
              Expanded(
                child: filteredSessions.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma aula encontrada para este filtro.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF71717A)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredSessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final s = filteredSessions[index];
                          final isSelected = s.id == activeSession.id;

                          return _buildSessionCard(s, isSelected);
                        },
                      ),
              ),
              const SizedBox(height: 18),

              // Footer com Botão de Abertura do Calendário Restritivo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openInteractiveCalendar,
                    icon: const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF18181B)),
                    label: const Text(
                      'Abrir Calendário Interativo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Concluído',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _filterIndex == index;

    return InkWell(
      onTap: () => setState(() => _filterIndex = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18181B) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(ClassSession s, bool isSelected) {
    return InkWell(
      onTap: () {
        widget.controller.selectSession(s.id);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Aula Nº ${s.sessionNumber} selecionada com sucesso!'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBFBFC) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Círculo com o número da aula
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${s.sessionNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF18181B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Informações da Aula
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        s.dateFormatted,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09090B),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'EM EXIBIÇÃO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.contentProgram,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF71717A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: s.isHomologated ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: s.isHomologated ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                ),
              ),
              child: Text(
                s.isHomologated ? 'Homologada' : 'Aguardando',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: s.isHomologated ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
