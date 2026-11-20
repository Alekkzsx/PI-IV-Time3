// Desenvolvido por Murillo Caravita - RA: 25014012

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/controllers/docente_controller.dart';
import 'package:pi_iv_time3/features/teacher/shared/utils/academic_session_date_picker.dart';
import 'components/session_picker_card_tile.dart';
import 'components/session_picker_filter_chips.dart';

/// Modal institucional para o professor visualizar e selecionar a data/aula letiva da turma.
/// Respeita estritamente o calendário de dias de aula da disciplina (ex: Segundas e Quartas).
class ClassSessionPickerModal extends StatefulWidget {
  final DocenteController controller;

  const ClassSessionPickerModal({super.key, required this.controller});

  @override
  State<ClassSessionPickerModal> createState() =>
      _ClassSessionPickerModalState();
}

class _ClassSessionPickerModalState extends State<ClassSessionPickerModal> {
  int _filterIndex = 0; // 0 = Todas, 1 = Homologadas, 2 = Pendentes

  Future<void> _openInteractiveCalendar() async {
    final course = widget.controller.selectedCourse;
    final currentSession = widget.controller.currentSession;

    final picked = await showAcademicSessionDatePicker(
      context: context,
      initialDate: currentSession.sessionDate,
      course: course,
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
              // Cabeçalho do Modal
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
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF71717A),
                    ),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Informativo de Dias de Aula Regimentais
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFF18181B),
                    ),
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

              // Chips de Filtro
              SessionPickerFilterChips(
                selectedIndex: _filterIndex,
                totalCount: sessions.length,
                homologatedCount: sessions.where((s) => s.isHomologated).length,
                pendingCount: sessions.where((s) => !s.isHomologated).length,
                onSelected: (idx) => setState(() => _filterIndex = idx),
              ),
              const SizedBox(height: 16),

              // Lista de Sessões
              Expanded(
                child: filteredSessions.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma aula encontrada para este filtro.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF71717A),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredSessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final s = filteredSessions[index];
                          final isSelected = s.id == activeSession.id;

                          return SessionPickerCardTile(
                            session: s,
                            isSelected: isSelected,
                            onTap: () {
                              widget.controller.selectSession(s.id);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context)
                                ..removeCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Aula Nº ${s.sessionNumber} selecionada com sucesso!',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 18),

              // Rodapé com Botão de Abertura do Calendário Restritivo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openInteractiveCalendar,
                    icon: const Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: Color(0xFF18181B),
                    ),
                    label: const Text(
                      'Abrir Calendário Interativo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Concluído',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
}
