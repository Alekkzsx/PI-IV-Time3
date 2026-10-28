// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/features/teacher/shared/domain/models/docente_course.dart';

/// Cabeçalho superior da disciplina com navegação breadcrumb e ações de comando do professor.
class CourseHubHeader extends StatelessWidget {
  final DocenteCourse course;
  final VoidCallback onBack;
  final VoidCallback onQuickNotice;
  final VoidCallback onNewContent;
  final VoidCallback onLiveClass;

  const CourseHubHeader({
    super.key,
    required this.course,
    required this.onBack,
    required this.onQuickNotice,
    required this.onNewContent,
    required this.onLiveClass,
  });

  @override
  Widget build(BuildContext context) {
    final courseCode = course.code.isNotEmpty ? course.code : '218131 - APS-II';
    final courseTitle = course.title.isNotEmpty
        ? course.title
        : 'Análise e Projeto de Sistemas II';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E4E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb de navegação
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 13,
                        color: Color(0xFF71717A),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Minhas Turmas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                '  >  ',
                style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
              ),
              Text(
                courseCode,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF71717A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Título e Botões de Comando e Acessos Rápidos do Professor
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF09090B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Turma $courseCode • 34 Alunos Matriculados • Turno Noturno • Semestre 2026/2 • Sala Lab 04',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onQuickNotice,
                    icon: const Icon(
                      Icons.campaign_outlined,
                      size: 14,
                      color: Color(0xFF09090B),
                    ),
                    label: const Text(
                      'Aviso à Turma',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF09090B),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onNewContent,
                    icon: const Icon(
                      Icons.add,
                      size: 14,
                      color: Color(0xFF09090B),
                    ),
                    label: const Text(
                      'Novo Conteúdo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF09090B),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE4E4E7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onLiveClass,
                    icon: const Icon(
                      Icons.videocam_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Transmissão ao Vivo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18181B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
