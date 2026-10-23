// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449 e Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';
import 'package:pi_iv_time3/features/admin/shared/data/admin_mock_data.dart';

/// Diálogo modal especializado para alocação e ensalamento de docente titular na turma.
class ClassAlocarDocenteModal extends StatefulWidget {
  final AdminClassModel classModel;
  final ValueChanged<String> onConfirmAllocation;

  const ClassAlocarDocenteModal({
    super.key,
    required this.classModel,
    required this.onConfirmAllocation,
  });

  static Future<void> show({
    required BuildContext context,
    required AdminClassModel classModel,
    required ValueChanged<String> onConfirmAllocation,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ClassAlocarDocenteModal(
        classModel: classModel,
        onConfirmAllocation: onConfirmAllocation,
      ),
    );
  }

  @override
  State<ClassAlocarDocenteModal> createState() => _ClassAlocarDocenteModalState();
}

class _ClassAlocarDocenteModalState extends State<ClassAlocarDocenteModal> {
  late final TextEditingController _profController;

  @override
  void initState() {
    super.initState();
    _profController = TextEditingController(text: widget.classModel.professor);
  }

  @override
  void dispose() {
    _profController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.classModel;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                    ),
                    child: const Icon(
                      Icons.assignment_ind_outlined,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ATRIBUIÇÃO & ENSALAMENTO DOCENTE',
                          style: jakarta(
                            size: 11,
                            weight: FontWeight.w700,
                            color: const Color(0xFF737373),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Alocar Docente Regente Titular',
                          style: jakarta(
                            size: 20,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF737373)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.code} – ${c.subjectName}',
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.courseName} • ${c.semester} • ${c.location}',
                      style: jakarta(size: 12.5, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Text(
                'Nome Completo do Docente Titular',
                style: jakarta(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _profController,
                decoration: InputDecoration(
                  hintText: 'Ex: Profa. Dra. Helena Bittencourt',
                  hintStyle: jakarta(size: 13.5, color: const Color(0xFFA3A3A3)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
                  ),
                ),
                style: jakarta(size: 13.5, color: const Color(0xFF18181B)),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      'Cancelar',
                      style: jakarta(size: 13, weight: FontWeight.w600, color: const Color(0xFF525252)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final newProfessor = _profController.text.trim();
                      if (newProfessor.isNotEmpty) {
                        widget.onConfirmAllocation(newProfessor);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Docente alocado com sucesso! Diário atualizado.',
                              style: jakarta(size: 13, color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFF18181B),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Confirmar Alocação',
                      style: jakarta(size: 13, weight: FontWeight.w600, color: Colors.white),
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
