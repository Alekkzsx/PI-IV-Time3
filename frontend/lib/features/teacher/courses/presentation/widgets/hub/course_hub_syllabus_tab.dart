// Desenvolvido por Guilherme Henrique Moreira

import 'package:flutter/material.dart';

/// Aba de Plano de Ensino & Ementa Homologada do curso no Portal Docente.
class CourseHubSyllabusTab extends StatelessWidget {
  final VoidCallback onEditSyllabus;

  const CourseHubSyllabusTab({super.key, required this.onEditSyllabus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Plano de Ensino & Ementa Homologada (CONSEPE)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF09090B),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onEditSyllabus,
                icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                label: const Text(
                  'Editar / Gerenciar Ementa',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '1. EMENTA DA DISCIPLINA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF09090B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Conceitos de análise e projeto orientado a objetos. Notação UML 2.5: diagramas estruturais e comportamentais. Processo Unificado e metodologias ágeis (Scrum, Kanban). Padrões de projeto GoF (Criacionais, Estruturais e Comportamentais). Arquitetura de software moderna e Clean Architecture.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF52525B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '2. CRITÉRIOS DE AVALIAÇÃO (PPC OFICIAL)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF09090B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Média Semestral = (N1 × 0.40) + (N2 × 0.60). Onde N1 é composto por Prova Teórica P1 (70%) e Projeto Prático T1 (30%). Exame Final obrigatório para alunos com média entre 4.0 e 5.9.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF52525B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
