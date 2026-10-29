// Desenvolvido por Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/grade_record.dart';

/// Diálogo para solicitação formal de retificação de nota pós-fechamento perante a Coordenação.
class DocenteRetificacaoDialog extends StatefulWidget {
  final DocenteCourse course;
  final List<StudentGrade> gradebook;
  final void Function({
    required String studentRa,
    required String studentName,
    required String avaliacao,
    required double notaAnterior,
    required double novaNota,
    required String justificativa,
  })
  onConfirm;

  const DocenteRetificacaoDialog({
    super.key,
    required this.course,
    required this.gradebook,
    required this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required DocenteCourse course,
    required List<StudentGrade> gradebook,
    required void Function({
      required String studentRa,
      required String studentName,
      required String avaliacao,
      required double notaAnterior,
      required double novaNota,
      required String justificativa,
    })
    onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DocenteRetificacaoDialog(
        course: course,
        gradebook: gradebook,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<DocenteRetificacaoDialog> createState() =>
      _DocenteRetificacaoDialogState();
}

class _DocenteRetificacaoDialogState extends State<DocenteRetificacaoDialog> {
  late StudentGrade _selectedStudent;
  String _selectedAvaliacao = 'PROVA P1';
  final TextEditingController _novaNotaController = TextEditingController();
  final TextEditingController _justificativaController =
      TextEditingController();

  final List<String> _avaliacoes = const [
    'PROVA P1',
    'ATIV. N1',
    'PROVA P2',
    'PROJ. N2',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.gradebook.isNotEmpty
        ? widget.gradebook.first
        : const StudentGrade(
            studentId: 'st-1',
            ra: '2024.1.00892',
            studentName: 'Gabriel Soares de Oliveira',
            assignmentsScore: 9.0,
            p1Score: 8.5,
            projectsScore: 9.5,
            p2Score: 9.0,
            attendanceRate: 96.0,
          );
    _novaNotaController.text = _getCurrentScore().toStringAsFixed(1);
  }

  @override
  void dispose() {
    _novaNotaController.dispose();
    _justificativaController.dispose();
    super.dispose();
  }

  double _getCurrentScore() {
    switch (_selectedAvaliacao) {
      case 'PROVA P1':
        return _selectedStudent.p1Score;
      case 'ATIV. N1':
        return _selectedStudent.assignmentsScore;
      case 'PROVA P2':
        return _selectedStudent.p2Score;
      case 'PROJ. N2':
        return _selectedStudent.projectsScore;
      default:
        return _selectedStudent.p1Score;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentScore = _getCurrentScore();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Icon(
                    Icons.edit_document,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solicitar Retificação de Nota pós-Fechamento',
                        style: jakarta(
                          size: 18,
                          weight: FontWeight.w700,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requerimento formal com parecer fundamentado à Coordenação de Curso',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w400,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Seleção de Discente
            Text(
              'Discente Beneficiário',
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w600,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E4E7)),
                color: const Color(0xFFFAFAFA),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<StudentGrade>(
                  value: _selectedStudent,
                  isExpanded: true,
                  style: jakarta(size: 13, color: const Color(0xFF18181B)),
                  items: widget.gradebook.map((st) {
                    return DropdownMenuItem<StudentGrade>(
                      value: st,
                      child: Text('${st.studentName} (RA ${st.ra})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStudent = val;
                        _novaNotaController.text = _getCurrentScore()
                            .toStringAsFixed(1);
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Seleção de Avaliação e Notas
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avaliação Alvo',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                          color: const Color(0xFFFAFAFA),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAvaliacao,
                            isExpanded: true,
                            style: jakarta(
                              size: 13,
                              color: const Color(0xFF18181B),
                            ),
                            items: _avaliacoes
                                .map(
                                  (av) => DropdownMenuItem(
                                    value: av,
                                    child: Text(av),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedAvaliacao = val;
                                  _novaNotaController.text = _getCurrentScore()
                                      .toStringAsFixed(1);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nota Registrada',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                          color: const Color(0xFFF1F5F9),
                        ),
                        child: Text(
                          currentScore.toStringAsFixed(1),
                          style: jakarta(
                            size: 14,
                            weight: FontWeight.w700,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nova Nota',
                        style: jakarta(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _novaNotaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: jakarta(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E4E7),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE4E4E7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Justificativa Obrigatória
            Text(
              'Justificativa Institucional & Parecer Docente',
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w600,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _justificativaController,
              maxLines: 2,
              style: jakarta(size: 12.5, color: const Color(0xFF18181B)),
              decoration: InputDecoration(
                hintText:
                    'Ex: Erro material de transcrição da prova física P1. Nota conferida em espelho com o discente.',
                hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF71717A),
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: jakarta(size: 13, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final novaNota =
                        double.tryParse(
                          _novaNotaController.text.replaceAll(',', '.'),
                        ) ??
                        currentScore;
                    final just = _justificativaController.text.trim().isNotEmpty
                        ? _justificativaController.text.trim()
                        : 'Revisão regimental de avaliação deferida pelo docente titular.';

                    Navigator.of(context).pop();
                    widget.onConfirm(
                      studentRa: _selectedStudent.ra,
                      studentName: _selectedStudent.studentName,
                      avaliacao: _selectedAvaliacao,
                      notaAnterior: currentScore,
                      novaNota: novaNota,
                      justificativa: just,
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    'Submeter à Coordenação',
                    style: jakarta(size: 13, weight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
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
