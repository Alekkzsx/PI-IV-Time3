// Desenvolvido por Alex Gabriel Soares Sousa - RA: 24802449, Marcelo Zarpelon - RA: 25015323, Murillo Caravita - RA: 25014012 e Rafael Henrique Inácio - RA: 25009719

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

/// Visão em lista cronológica (Timeline/Agenda) do Painel Geral do Aluno.
///
/// Exibe prazos imediatos, eventos acadêmicos, estado vazio temático
/// com o mascote institucional Sir Nicolau e marcos semestrais.
class StudentDashboardListView extends StatefulWidget {
  const StudentDashboardListView({super.key});

  @override
  State<StudentDashboardListView> createState() => _StudentDashboardListViewState();
}

class _StudentDashboardListViewState extends State<StudentDashboardListView> {
  bool _isForumCompleted = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // SEÇÃO 1: Amanhã, 21 de setembro
          // ==========================================
          Text(
            'Amanhã, 21 de setembro',
            style: jakarta(
              size: 15,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 14),
          _buildTaskItem(
            title: 'Fórum de Dúvidas: Preparação para a Avaliação A1',
            subtitle: 'Cálculo Diferencial e Integral • Profª. Sandra Helena',
            dueTime: 'até 18:00',
            isCompleted: _isForumCompleted,
            onToggle: () {
              setState(() {
                _isForumCompleted = !_isForumCompleted;
              });
            },
          ),
          const SizedBox(height: 36),

          // ==========================================
          // SEÇÃO 2: setembro 22 a dezembro 12 (Empty State)
          // ==========================================
          Text(
            'setembro 22 a dezembro 12',
            style: jakarta(
              size: 13.5,
              weight: FontWeight.w600,
              color: const Color(0xFF3F3F46),
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
          const SizedBox(height: 28),
          Center(
            child: Image.asset(
              'images/SirNicolau.png',
              height: 160,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback elegante caso a imagem não possa ser carregada em testes sem assets
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.golf_course_rounded,
                      size: 48,
                      color: Color(0xFFA1A1AA),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nada planejado ainda',
                      style: jakarta(
                        size: 14,
                        weight: FontWeight.w500,
                        color: const Color(0xFF18181B),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 36),

          // ==========================================
          // SEÇÃO 3: domingo, 13 de dezembro
          // ==========================================
          _buildMilestoneSection(
            dateHeader: 'domingo, 13 de dezembro',
            description: 'Término das avaliações semestrais',
          ),
          const SizedBox(height: 36),

          // ==========================================
          // SEÇÃO 4: segunda-feira, 14 de dezembro a janeiro 10
          // ==========================================
          _buildMilestoneSection(
            dateHeader: 'segunda-feira, 14 de dezembro a janeiro 10',
            description: 'Férias e encerramento de notas',
          ),
          const SizedBox(height: 36),

          // ==========================================
          // SEÇÃO 5: fevereiro 2027
          // ==========================================
          _buildMilestoneSection(
            dateHeader: 'fevereiro 2027',
            description: 'Início das aulas do próximo período letivo',
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required String subtitle,
    required String dueTime,
    required bool isCompleted,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox quadrado desmarcado
          InkWell(
            key: const Key('btn_toggle_forum_task'),
            onTap: onToggle,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isCompleted ? const Color(0xFF18181B) : const Color(0xFFD4D4D8),
                  width: 1.5,
                ),
                color: isCompleted ? const Color(0xFF18181B) : Colors.transparent,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Ícone de balão de fórum / mensagem
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 18,
            color: Color(0xFF52525B),
          ),
          const SizedBox(width: 12),

          // Título e identificador da disciplina / docente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: const Color(0xFF18181B),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: jakarta(
                    size: 11.5,
                    weight: FontWeight.w400,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Prazo de encerramento
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Color(0xFF71717A),
              ),
              const SizedBox(width: 4),
              Text(
                dueTime,
                style: jakarta(
                  size: 11.5,
                  weight: FontWeight.w400,
                  color: const Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneSection({
    required String dateHeader,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateHeader,
          style: jakarta(
            size: 13.5,
            weight: FontWeight.w700,
            color: const Color(0xFF18181B),
          ),
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E7)),
        const SizedBox(height: 18),
        Center(
          child: Text(
            description,
            style: jakarta(
              size: 12,
              weight: FontWeight.w400,
              color: const Color(0xFF71717A),
            ),
          ),
        ),
      ],
    );
  }
}

